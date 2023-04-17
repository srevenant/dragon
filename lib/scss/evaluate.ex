defmodule Dragon.Scss.Evaluate do
  @moduledoc """

  """

  use Dragon.Context
  import Dragon.Tools.File

  def all(%Dragon{files: %{scss: l}} = d), do: all(d, Map.keys(l))

  def all(%Dragon{} = d, [file | rest]) do
    with {:ok, path} <- find_file(d.root, file) do
      notify([:green, "SCSS ", :reset, :bright, path])

      with {:ok, content} <- Sass.compile_file(path) do
        path = Path.join(d.build, drop_root(d.root, Path.rootname(path) <> ".css"))
        info([:light_black, "  Saving ", :reset, path])
        Dragon.Tools.IO.write_file(path, content)
      end

      all(d, rest)
    end
  end

  def all(%Dragon{} = d, _), do: {:ok, d}
end
