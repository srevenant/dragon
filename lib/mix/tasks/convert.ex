defmodule Mix.Tasks.Dragon.Convert do
  @moduledoc false
  @shortdoc "Convert a Jekyll Project to a Dragon Project"
  use Mix.Task
  import Mix.Generator
  use Dragon.Context
  import Dragon.Tools.File.WalkTree
  import Dragon.Tools.File

  @templates Mix.Tasks.Dragon.New
  @impl true
  def run([target]), do: convert(target)
  def run(_), do: IO.puts("Syntax: mix dragon.convert {target}")

  def is_symlink?(path) do
    case File.lstat(path) do
      {:ok, %{type: :symlink}} -> true
      _ -> false
    end
  end

  defp safe_mvdir(src, dst) do
    if is_symlink?(src) do
      warn("not moving #{src} because it is a symlink")
    else
      if File.dir?(src) do
        if File.exists?(dst) do
          warn("Cannot move #{src} to #{dst}: already exists")
        else
          stdout([:green, "* moving #{src} to #{dst}"])
          :ok = File.rename(src, dst)
        end
      else
        create_directory(dst)
      end
    end
  end

  def convert(target) do
    p = fn x -> Path.join(target, x) end

    stdout([:green, "* cleaning old files"])

    # remove old unecessary files
    ["Gemfile", "Gemfile.lock", "_site", ".jekyll-cache"]
    |> Enum.each(fn f ->
      IO.puts("Removing #{f}")
      File.rm_rf!(p.(f))
    end)

    create_file(p.("_dragon.yml"), @templates.dragon_config([]))

    Application.ensure_all_started(:dragon)

    {:ok, dragon} = Dragon.get()

    safe_mvdir(p.("_includes"), p.("_lib"))
    safe_mvdir(p.("_layouts"), p.(Path.join("_lib", "_layout")))

    if File.exists?(p.("_config.yml")),
      do: :ok = File.rename(p.("_config.yml"), p.(Path.join("_lib", "_site.yml")))

    walk_tree(dragon, target, follow_meta: true, no_match: &handle_file/3)

    IO.puts(
      "\nConversion complete. This is only a blind-conversion on some known parts; you will still have to do more work."
    )
  end

  defp has_separator?(path),
    do: with_open_file(path, fn fd -> IO.binread(fd, 3) end) == "---"

  defp convert_line("---\n", {:start, []}), do: {:head, ["--- dragon-1.0\n"]}
  defp convert_line("---\n", {:head, buf}), do: {:body, ["--- eex\n" | buf]}

  defp convert_line("layout:" <> file, {:head, buf}),
    do: {:head, ["@spec:\n  layout: #{String.trim(file)}.html\n" | buf]}

  defp convert_line(line, {where, buf}), do: {where, [convert_liquid(line) | buf]}

  # Todo: could get more complex regexes that are intelligent about start/end of
  # template expressions and then also convert the expression and also some
  # keywords to assigns:
  #
  #    page -> @page
  #    include file/name args=args -> include "file.name", args: args
  #

  defp convert_liquid(line) do
    line
    |> String.replace(~r/-[%}]}/, "%}")
    |> match_expression()
    |> String.replace(~r/{[%{]-?/, "<%=")
    |> String.replace(~r/-?[%}]}/, "%>")
    |> String.replace(~r/<%=\s*end(if|for)\s+/, "<% end ")
  end

  defp match_expression(line),
    do: Regex.replace(~r/{%-?\s*([^%-]+)\s*-?%}/u, line, &convert_expression/2, global: true)

  defp convert_expression(_, expr) do
    fixed =
      case String.split(expr, " ") do
        ["if" | rest] ->
          "if #{Enum.join(rest, " ")} do"

        ["else", "if" | rest] ->
          warn("WARNING: else if conversion does not add an extra 'end' in the template")
          "else if #{Enum.join(rest, " ")} do"

        # this isn't even right but it's out there...
        ["elsif" | rest] ->
          warn("WARNING: else if conversion does not add an extra 'end' in the template")
          "else if #{Enum.join(rest, " ")} do"

        ["assign" | rest] ->
          Enum.join(rest, " ")

        ["for" | rest] ->
          case Enum.split_with(rest, &(&1 == "in")) do
            {x, y} ->
              "for #{Enum.join(x)} <- #{Enum.join(y)} do"

            _ ->
              "for #{Enum.join(rest)} do"
              |> tap(&IO.puts(">>> MISSED: #{&1}"))
          end

        ["include", file | rest] ->
          args =
            rest
            |> Enum.filter(&(&1 != ""))
            |> Enum.map(&String.replace(&1, "=", ": "))

          "include " <> Enum.join(["\"_lib/#{file}\""] ++ args, ", ")

        ["else" | _] ->
          "else"

        ["endif" | _] ->
          "end"

        ["endfor" | _] ->
          "end"

        miss ->
          IO.inspect(miss)

          expr
          |> tap(&IO.puts(">>> MISSED: #{&1}"))
      end

    "<%= #{fixed} %>"
  end

  defp convert_file(path) do
    stdout([:green, "* converting #{path}"])

    {_, content} =
      with_open_file(path, fn fd ->
        IO.stream(fd, :line)
        |> Enum.reduce({:start, []}, &convert_line/2)
      end)

    File.write(path, Enum.reverse(content))
    # raise "narf #{path}"
  end

  defp handle_file(dragon, path, opts) do
    if opts.in_meta or has_separator?(path), do: convert_file(path)
    dragon
  end
end
