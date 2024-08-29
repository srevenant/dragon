defmodule Dragon.Template.Evaluate do
  use Dragon.Context
  import Dragon.Template.Env, only: [get_file_metadata: 4]
  import Dragon.Data, only: [clean_data: 1]
  import Dragon.Template.Read
  import Dragon.Tools.File
  # Todo: after moved to Transmogrify remove import
  import Transmogrify.As

  @moduledoc """
  Core heart of evaluating EEX Templates.

  Although Dragon is a standalone genserver for its data, we still try to push
  the Dragon struct on the current processes' stack to keep data movement to
  a minimum, and bring it in again with Dragon.get() only when we've lost the
  context (such as when called from within a template's helper functions).

  """

  def all(%Dragon{files: %{dragon: l}} = d), do: all(d, Map.keys(l) |> Enum.sort())

  def all(%Dragon{} = d, [file | rest]) do
    with {:ok, path} <- find_file(d.root, file) do
      read_template_header(path)
      |> evaluate(:primary, d, %{})
      |> validate()
      |> commit_file(d.root)

      all(d, rest)
    end
  end

  def all(%Dragon{} = d, _), do: {:ok, d}

  ##############################################################################
  def processing(file, layout \\ nil)
  def processing(file, nil), do: stdout([:green, "EEX Template ", :reset, :bright, file])

  def processing(file, layout),
    do:
      stdout([:green, "EEX Template ", :reset, :bright, file, :reset, :light_blue, " (#{layout})"])

  ##############################################################################
  # process files with a layout directive slightly differently. First, process
  # the current file and get the output results. Then call, as an include,
  # the layout template, sending the current output into that as a page
  # argument (@page.content)
  defp origin_frame(d, path, layout, func) do
    with_frame(
      fn
        nil ->
          %{origin: path, prev: nil, this: nil, page: nil}

        _existing ->
          raise Dragon.AbortError,
            message: "Starting new execution frame but an existing one still exists!"
      end,
      fn frame ->
        processing(drop_root(d.root, path), layout)
        func.(frame)
      end
    )
  end

  def evaluate(
        {:ok, %{"@spec": %{layout: layout}} = headers, path, offset, _},
        :primary,
        %Dragon{} = d,
        args
      )
      when is_map(args) do
    origin_frame(d, path, layout, fn _ ->
      with {:ok, target, headers, output} <-
             evaluate_frame(path, offset, headers, d, args),
           # then insert into layout as an include
           {:ok, _, _, output} <-
             Enum.map(d.layouts, &Path.join(&1, layout))
             |> include_first_file({d, [content: output], headers}),
           do: {:ok, target, headers, output}
    end)
  end

  def evaluate({:ok, headers, path, offset, _}, :primary, %Dragon{} = d, args)
      when is_map(args),
      do:
        origin_frame(d, path, nil, fn _ ->
          evaluate_frame(path, offset, headers, d, args)
        end)

  def evaluate({:ok, headers, path, offset, _}, :layout, %Dragon{} = d, args) when is_map(args),
    do: evaluate_frame(path, offset, headers, d, args)

  def evaluate({:error, reason}, _, _, _), do: abort("Unable to continue: #{reason}")

  defp evaluate_frame(path, offset, headers, %Dragon{} = d, args) do
    headers = clean_data(headers)

    with {:ok, content} <- read_template_body(path, offset),
         {:ok, page} <- get_file_metadata(d.root, path, headers, args),
         env <- Map.merge(d.data, %{dragon: d, page: page}),
         {:ok, output} <- evaluate_template(d, path, content, env),
         do: posteval(d, headers, path, output)
  end

  ################################################################################
  defp include_first_file([path | rest], {d, _, _} = args) do
    case find_file(d.root, path) do
      {:ok, target} ->
        include_file_inner(target, args)

      {:error, msg} ->
        case rest do
          [] ->
            raise ArgumentError, message: "Include failed: #{msg}"

          _ ->
            include_first_file(rest, args)
        end
    end
  end

  defp include_first_file([], _),
    do: raise(ArgumentError, message: "Include failed, paths exhausted")

  ##############################################################################
  def include_file(x, d, unknown, args, page \\ nil)

  def include_file(paths, %Dragon{} = d, _, args, page) when is_list(paths),
    do: include_first_file(paths, {d, args, page})

  def include_file(path, %Dragon{} = d, _, args, page),
    do: include_first_file([path], {d, args, page})

  ##############################################################################
  # we don't pay attention to layout here
  defp include_file_inner(target, {d, args, page}) do
    stderr([:light_black, "+ Including #{drop_root(d.root, target)}"])

    inputs =
      read_template_header(target)
      |> handle_non_template(target)

    parent_page =
      if is_nil(page) do
        Map.get(Dragon.frame_head() || %{}, :page) || %{}
      else
        page
      end

    args =
      check_include_args(inputs, Map.new(args))
      |> Map.put(:page, parent_page)

    evaluate(inputs, :layout, d, args)
  end

  defp handle_non_template({:error, _}, target), do: {:ok, %{}, target, 0, 0}
  defp handle_non_template({:ok, _, _, _, _} = pass, _), do: pass

  defp check_include_args({:ok, %{"@spec": %{args: argref}}, _, _, _}, args) do
    Enum.map(argref, fn
      "?" <> k ->
        {:optional, as_key!(k)}

      k when is_binary(k) ->
        {:required, as_key!(k)}

      m when is_map(m) ->
        case Map.to_list(m) do
          [{k, v}] -> {:default, as_key!(k), v}
          value -> raise ArgumentError, message: "invalid @spec.args #{inspect(value)}"
        end

      other ->
        raise ArgumentError, message: "invalid @spec.args #{inspect(other)}"
    end)
    |> Enum.reduce(args, fn spec, args ->
      case spec do
        {:required, key} when is_map_key(args, key) ->
          args

        {:required, key} ->
          raise ArgumentError, message: "Include missing arg: #{key}"

        {:default, key, value} when is_map_key(args, key) ->
          if not is_nil(args[key]), do: args, else: Map.put(args, key, value)

        {:default, key, value} ->
          Map.put(args, key, value)

        {:optional, _} ->
          args
      end
    end)
  end

  defp check_include_args(_, args), do: args

  ################################################################################
  def validate({:ok, dst, headers, content}) do
    # future: scan html content for breaks
    {:ok, dst, headers, content}
  end

  ##############################################################################
  def posteval(%{root: root, build: build} = d, headers, origin, content) do
    target = Path.join(build, Dragon.Tools.File.drop_root(root, origin))
    Dragon.Plugin.posteval(d, origin, target, headers, content)
  end

  ##############################################################################
  def commit_file({:ok, path, headers, content}, root) do
    stderr([:light_black, "✓ Saving ", :reset, drop_root(root, path)])

    file =
      case headers do
        %{"@spec": %{output: "folder/index"}} -> Path.join(Path.rootname(path), "index.html")
        _ -> path
      end

    Dragon.Tools.File.write_file(file, content)
  end

  # side-effect execution frame state management
  defp with_frame(update, inner) do
    try do
      update.(Dragon.frame_head()) |> Dragon.frame_push() |> inner.()
    after
      Dragon.frame_pop()
    end
  end

  ##############################################################################
  def evaluate_template(%Dragon{imports: imports}, path, template, env) do
    with_frame(
      fn
        nil ->
          raise Dragon.AbortError, message: "Mid-frame execution without parent?"

        frame ->
          %{
            frame
            | prev: Map.get(frame, :this),
              this: path,
              # drop content—that shouldn't go into frame state
              page: (Map.get(env, :page) || %{}) |> Map.delete(:content)
          }
      end,
      fn frame ->
        exec_frame(frame, imports, path, template, env)
      end
    )
  end

  def error_message(%{message: msg}) when not is_nil(msg), do: msg
  def error_message(err), do: inspect(err)

  def nofile_line([{:elixir_eval, :__FILE__, 1, [file: ~c"nofile", line: line]} | _]), do: line
  def nofile_line([_ | rest]), do: nofile_line(rest)
  def nofile_line([]), do: 0

  # sort | reverse
  defp exec_frame(frame, imports, path, template, env) do
    try do
      env = Map.put(env, :frame, frame)
      {:ok, EEx.eval_string(imports <> template, assigns: Map.to_list(env))}
    rescue
      err ->
        case err do
          ## TODO: include offset in line count so you can find it in the editor!
          %{file: "nofile", line: line, description: msg} ->
            # minus one to the line because we added a line above
            abort_nofile_error(template, path, line - 1, msg)

          %KeyError{key: key, term: data} ->
            abort_nofile_error(
              template,
              path,
              __STACKTRACE__,
              "key #{inspect(key)} not found in: #{inspect(data)}"
            )

          _ ->
            nofile_error(template, path, __STACKTRACE__, err)
            Kernel.reraise(err, __STACKTRACE__)
        end
    end
  end

  @dialyzer {:nowarn_function, [abort_nofile_error: 4]}
  def abort_nofile_error(a, b, c, d) do
    nofile_error(a, b, c, d)
    abort("Cannot continue")
  end

  def nofile_error(template, path, lineno, msg) when is_integer(lineno) and is_binary(msg) do
    header_lines =
      case read_template_header(path) do
        {:ok, _, _, _, lines} -> lines + 2
        _ -> 0
      end

    first = lineno - 2
    first = if first < 0, do: 0, else: first
    last = lineno + 2

    stderr(["\n", :yellow, "? ", "#{path}:#{lineno}", :reset, " — ", :yellow, :bright, msg, "\n"])

    String.split(template, "\n")
    |> Enum.reduce_while(1, fn line, index ->
      cond do
        index == lineno -> print_with_line("»", index + header_lines, line)
        index > first and index < last -> print_with_line(" ", index + header_lines, line)
        true -> :ok
      end

      if index == last do
        {:halt, index}
      else
        {:cont, index + 1}
      end
    end)

    IO.puts(:stderr, "\n")
  end

  def nofile_error(t, p, l, m) when not is_binary(m), do: nofile_error(t, p, l, error_message(m))
  def nofile_error(t, p, tb, m) when is_list(tb), do: nofile_error(t, p, nofile_line(tb), m)

  defp print_with_line(prefix, index, line) do
    padded = String.pad_leading("#{index}", 3)
    IO.puts(:stderr, IO.ANSI.format([:blue, :bright, "#{prefix}#{padded}: ", :reset, line]))
  end
end
