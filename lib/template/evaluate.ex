defmodule Dragon.Template.Evaluate do
  use Dragon.Context
  import Dragon.Tools
  import Dragon.Template.Read

  @moduledoc """
  Core heart of evaluating EEX Templates.

  Although Dragon is a standalone genserver for its data, we still try to push
  the Dragon struct on the current processes' stack to keep data movement to
  a minimum, and bring it in again with Dragon.get() only when we've lost the
  context (such as when called from within a template's helper functions).

  """

  def all(%Dragon{files: %{dragon: l}} = d), do: all(d, Map.keys(l))

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
  def processing(file, nil), do: notify([:green, "EEX Template ", :reset, :bright, file])

  def processing(file, layout),
    do:
      notify([:green, "EEX Template ", :reset, :bright, file, :reset, :light_blue, " (#{layout})"])

  ##############################################################################
  def evaluate(read_result, type, dragon, args \\ [])

  # process files with a layout directive slightly differently. First, process
  # the current file and get the output results. Then call, as an include,
  # the layout template, sending the current output into that as a page
  # argument (@page.content)
  def evaluate(
        {:ok, %{"@spec": %{layout: layout}} = headers, path, offset},
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
         {:ok, _, _, output} <- include_file(Path.join(d.layouts, "_#{layout}"), d, :layout,
             content: output,
             parent: headers
           ),
           do: {:ok, target, headers, output}
  end

  def evaluate({:ok, headers, path, offset}, type, %Dragon{} = d, args) do
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
        info("+ Including #{target}")

        read_template_header(target)
        |> handle_non_template(target)
        |> evaluate(:layout, d, args)

      {:error, msg} ->
        abort("+ Include failed: #{msg}")
    end
  end

  def handle_non_template({:error, _}, target), do: {:ok, %{}, target, 0}
  def handle_non_template({:ok, _, _, _} = pass, _), do: pass

  ################################################################################
  def validate({:ok, dst, headers, content}) do
    # future: scan html content for breaks
    {:ok, dst, headers, content}
  end

  ##############################################################################
  def posteval(%{root: root, build: build} = d, headers, origin, content) do
    target = Path.join(build, Dragon.Tools.drop_root(root, origin))
    Dragon.Plugin.posteval(d, origin, target, headers, content)
  end

  ##############################################################################
  def commit_file({:ok, path, headers, content}) do
    info([:light_black, "  Saving ", :reset, path])

    file =
      case headers do
        %{"@spec": %{output: "folder/index"}} -> Path.join(Path.rootname(path), "index.html")
        _ -> path
      end

    Dragon.Tools.write_file(file, content)
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

  defp evaluate_frame(_frame, imports, path, template, env) do
    try do
      {:ok, EEx.eval_string(imports <> template, assigns: Map.to_list(env))}
    rescue
      err ->
        case err do
          ## TODO: include offset in line count so you can find it in the editor!
          %CompileError{file: "nofile", line: line, description: msg} ->
            # minus one to the line because we added a line above
            abort_nofile_error(template, path, line - 1, msg)

          error ->
            error("Error processing #{path}")
            Kernel.reraise(error, __STACKTRACE__)
        end
    end
  end

  def abort_nofile_error(template, path, lineno, msg) do
    first = lineno - 2
    first = if first < 0, do: 0, else: first

    last = lineno + 2

    stderr(["\n", :yellow, "? ", "#{path}:#{lineno}", :reset, " — ", :yellow, :bright, msg, "\n"])

    String.split(template, "\n")
    |> Enum.reduce_while(1, fn line, index ->
      cond do
        index == lineno -> print_with_line("»", index, line)
        index > first and index < last -> print_with_line(" ", index, line)
        true -> :ok
      end

      if index == last do
        {:halt, index}
      else
        {:cont, index + 1}
      end
    end)

    IO.puts(:stderr, "\n")
    abort("Cannot continue")
  end

  defp print_with_line(prefix, index, line) do
    padded = String.pad_leading("#{index}", 3)
    IO.puts(:stderr, IO.ANSI.format([:blue, :bright, "#{prefix}#{padded}: ", :reset, line]))
  end
end
