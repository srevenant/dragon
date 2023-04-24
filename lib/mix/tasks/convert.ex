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

    create_directory(p.("_data"))
    jekyll_cfg = p.("_config.yml")
    target_site = p.(Path.join("_data", "_site.yml"))

    if File.exists?(jekyll_cfg) do
      if File.exists?(target_site) do
        warn("Cannot move #{jekyll_cfg} to #{target_site}: already exists")
      else
        :ok = File.rename(p.("_config.yml"), p.(Path.join("_data", "_site.yml")))
      end
    end

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

  defp convert_liquid(line) do
    line
    |> String.replace(~r/\s*-?[%}]}/, "%}")
    |> String.replace(~r/{[%{]-?\s*/, "{%")
    |> match_expression()
  end

  def match_expression(line),
    do: Regex.replace(~r/{%(.+?(?=%}))%}/u, line, &convert_expression/2, global: true)

  def convert_expression(_, expr) do
    fixed =
      case String.split(expr, " ") do
        ["if" | rest] ->
          "= if #{Enum.join(rest, " ")} do"
          |> String.replace(~r/^= if (page|site)/, "= if @\\1")

        ["else", "if" | rest] ->
          warn("WARNING: else if conversion does not add an extra 'end' in the template")
          "= else if #{Enum.join(rest, " ")} do"

        # this isn't even right but it's out there...
        ["elsif" | rest] ->
          warn("WARNING: else if conversion does not add an extra 'end' in the template")
          "= else if #{Enum.join(rest, " ")} do"

        ["assign" | rest] ->
          " " <> Enum.join(rest, " ")

        ["for" | rest] ->
          body =
            Enum.map(rest, fn
              "in" -> "<-"
              x -> x
            end)

          "= for #{Enum.join(body, " ")} do"

        ["include", file | rest] ->
          args =
            rest
            |> Enum.filter(&(&1 != ""))
            |> Enum.map(&String.replace(&1, "=", ": "))

          "= include " <> Enum.join(["\"/_lib/#{file}\""] ++ args, ", ")

        ["else" | _] ->
          " else"

        ["endif" | _] ->
          " end"

        ["endfor" | _] ->
          " end"

        miss ->
          "= " <> expr
          # |> tap(&IO.puts(">>> MISSED: #{&1}"))
      end
      |> String.replace(~r/  +do$/, " do")
      |> String.replace("| markdownify", "|> markdownify")
      |> String.replace(~r/^= (page|site)/, "= @\\1")

    "<%#{fixed} %>"
  end

  defp convert_file(path) do
    stdout([:green, "* converting #{path}"])

    {_, content} =
      with_open_file(path, fn fd ->
        IO.stream(fd, :line)
        |> Enum.reduce({:start, []}, &convert_line/2)
      end)

    File.write(path, Enum.reverse(content))
  end

  @always_convert MapSet.new([".html", ".htm"])
  defp always_convert?(ext), do: MapSet.member?(@always_convert, ext)

  defp handle_file(dragon, path, opts) do
    ext = Path.extname(path)
    if has_separator?(path) or (opts.in_meta and always_convert?(ext)), do: convert_file(path)
    dragon
  end
end
