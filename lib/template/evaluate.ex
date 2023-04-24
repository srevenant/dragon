defmodule Dragon.Template.Evaluate do
  use Dragon.Context
  import Dragon.Template.Read
  import Dragon.Tools.File

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
      |> evaluate(:primary, d)
      |> validate()
      |> commit_file()

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
  def evaluate(read_result, type, dragon, args \\ [])

  # process files with a layout directive slightly differently. First, process
  # the current file and get the output results. Then call, as an include,
  # the layout template, sending the current output into that as a page
  # argument (@page.content)
  def evaluate(
        {:ok, %{"@spec": %{layout: layout}} = headers, path, offset, _},
        :primary,
        %Dragon{} = d,
        args
      ) do
    processing(path, layout)

    with {:ok, content} <- read_template_body(path, offset),
         {:ok, env} <- Dragon.Template.Env.get_for(path, :primary, headers, d, args),
         {:ok, output} <- evaluate_template(d, path, content, env),
         # posteval first, before insertion by layout; for markdown/etc
         {:ok, target, headers, output} <- posteval(d, headers, path, output),
         # then insert into layout
         {:ok, _, _, output} <-
           include_file(Path.join(d.layouts, "_#{layout}"), d, :layout,
             content: output,
             parent: headers
           ),
         do: {:ok, target, headers, output}
  end

  def evaluate({:ok, headers, path, offset, _}, type, %Dragon{} = d, args) do
    if type != :layout do
      processing(path)
    end

    with {:ok, content} <- read_template_body(path, offset),
         {:ok, env} <- Dragon.Template.Env.get_for(path, type, headers, d, args),
         {:ok, output} <- evaluate_template(d, path, content, env),
         do: posteval(d, headers, path, output)
  end

  def evaluate({:error, reason}, _, _, _), do: abort("Unable to continue: #{reason}")

  ################################################################################
  # we don't pay attention to layout here
  def include_file(path, %Dragon{} = d, _, args) do
    case find_file(d.root, path) do
      {:ok, target} ->
        stderr([:light_black, "+ Including #{target}"])

        read_template_header(target)
        |> handle_non_template(target)
        |> evaluate(:layout, d, args)

      {:error, msg} ->
        raise ArgumentError, message: "Include failed: #{msg}"
    end
  end

  def handle_non_template({:error, _}, target), do: {:ok, %{}, target, 0, 0}
  def handle_non_template({:ok, _, _, _, _} = pass, _), do: pass

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
  def commit_file({:ok, path, headers, content}) do
    stderr([:light_black, "✓ Saving ", :reset, path])

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
  defp evaluate_template(%Dragon{imports: imports}, path, template, env) do
    with_frame(
      fn prev ->
        case prev do
          nil -> %{prev: nil, this: path, top: path}
          %{this: prev} = frame -> %{frame | prev: prev, this: path}
        end
      end,
      fn frame ->
        evaluate_frame(frame, imports, path, template, env)
      end
    )
  end

  def error_message(%{message: msg}) when not is_nil(msg), do: msg
  def error_message(err), do: inspect(err)

  def nofile_line([{:elixir_eval, :__FILE__, 1, [file: 'nofile', line: line]} | _]), do: line
  def nofile_line([_ | rest]), do: nofile_line(rest)
  def nofile_line([]), do: 0

  # sort | reverse
  defp evaluate_frame(frame, imports, path, template, env) do
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
