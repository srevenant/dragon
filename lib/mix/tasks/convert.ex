defmodule Mix.Tasks.Dragon.Convert do
  @moduledoc false
  @shortdoc "Convert a Jekyll Project to a Dragon Project"
  use Mix.Task
  import Mix.Generator
  import Dragon.Tools.File.WalkTree
  import Dragon.Tools.File

  @templates Mix.Tasks.Dragon.New
  @impl true
  def run([target]), do: convert(target)
  def run(_), do: IO.puts("Syntax: mix dragon.convert {target}")

  def convert(target) do
    p = fn x -> Path.join(target, x) end

    stdout([:green, "Cleaning old files"])

    # remove old unecessary files
    ["Gemfile", "Gemfile.lock", "_site", ".jekyll-cache"]
    |> Enum.each(fn f ->
      stdout("Removing #{f}\n")
      File.rm_rf!(p.(f))
    end)


    create_file(p.("_dragon.yml"), @templates.dragon_config([]))

    Application.ensure_all_started(:dragon)

    {:ok, dragon} = Dragon.get()

    if File.exists?(p.("_layouts")) do
      :ok = File.rename(p.("_layouts"), p.(Path.join("_lib", "_layout")))
    else
      create_directory(p.(Path.join("_lib", "_layout")))
    end

    if File.exists?(p.("_config.yml")),
      do: :ok = File.rename(p.("_config.yml"), p.(Path.join("_lib", "_site.yml")))

    walk_tree(dragon, target, follow_meta: true, no_match: &handle_file/3)

  end

  defp has_separator?(path),
    do: with_open_file(path, fn fd -> IO.binread(fd, 3) end) == "---"

  defp convert_line("---\n", {:start, []}), do: {:head, ["--- dragon-1.0\n"]}
  defp convert_line("---\n", {:head, buf}), do: {:body, ["--- eex\n" | buf]}
  defp convert_line(line, {where, buf}), do: {where, [convert_liquid(line) | buf]}

  @doc """
  Todo: could get more complex regexes that are intelligent about start/end of
  template expressions and then also convert the expression and also some
  keywords to assigns:

    page -> @page
    include file/name args=args -> include "file.name", args: args

  """
  defp convert_liquid(line) do
    line
    |> String.replace(~r/{[%{]-?/, "<%=")
    |> String.replace(~r/-?[%}]}/, "%>")
    |> String.replace(~r/<%=\s*end(if|for)\s+/, "<% end ")
  end

  defp convert_file(path) do
    {_, content} =
      with_open_file(path, fn fd ->
        IO.stream(fd, :line)
        |> Enum.reduce({:start, []}, &convert_line/2)
      end)

    File.write(path, Enum.reverse(content))
    raise "narf #{path}"
  end

  defp handle_file(dragon, path, opts) do
    if opts.in_meta or has_separator?(path), do: convert_file(path)
    dragon
  end
end
