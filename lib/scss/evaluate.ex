defmodule Dragon.Scss.Evaluate do
  @moduledoc """

  """

  use Dragon.Context
  import Dragon.Tools.File

  def all(%Dragon{files: %{scss: l}} = d), do: all(d, Map.keys(l))
  def all(d), do: {:ok, d}

  def all(%Dragon{} = d, [file | rest]) do
    with {:ok, path} <- find_file(d.root, file) do
      notify([:green, "SCSS ", :reset, :bright, path])

      case Sass.compile_file(path) do
        {:ok, content} ->
          build_path = Path.join(d.build, drop_root(d.root, Path.rootname(path) <> ".css"))
          info([:light_black, "  Saving ", :reset, build_path])
          Dragon.Tools.File.write_file(build_path, content)

        {:error, reason} ->
          error("Error processing #{path}\n")
          stderr([reason])
          abort("Cannot continue")
      end

      all(d, rest)
    end
  end

  def all(%Dragon{} = d, _), do: {:ok, d}
end
