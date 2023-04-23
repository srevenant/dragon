defmodule Mix.Tasks.Dragon.Convert do
  @moduledoc false
  @shortdoc "Convert a Jekyll Project to a Dragon Project"
  use Mix.Task
  import Mix.Generator
  import Dragon.Tools.File.WalkTree

  @templates Mix.Tasks.Dragon.New
  @doc """
  scan all yml w/headermatter and convert to dragon template syntax
  scan templates and replace liquid prefixes with eex
  convert known liquid things

    include file/name args=args -> include "file.name", args: args

  """
  @impl true
  def run([target]), do: convert(target)
  def run(_), do: IO.puts("Syntax: mix dragon.convert {target}")

  def convert(target) do
    p = fn x -> Path.join(target, x) end

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

  def handle_file(dragon, "_" <> path, meta) do
    IO.inspect(meta)
    meta = Map.put(meta, :in_meta, true)

    #   # ...
    #   Map.delete(meta, :in_meta, true)
    # end
    #
    #   with_open_file(path, fn fd -> IO.binread(fd, 3) end)
    #   |> case do
    #     "---" ->
    #           read_
    #
    #         _ ->
    #           case Path.extname(path) do
    #             ".scss" -> :scss
    #             _ -> :file
    #           end
    #       end
    #     end)

    # inspect file for header info to convert
    # IO.inspect(path)
    dragon
  end
end
