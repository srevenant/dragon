defmodule Dragon.Scss do
  @moduledoc """

  """

  use Dragon.Context
  import Dragon.Tools.File
  import Dragon.Template.Read
  import Dragon.Process.Data, only: [clean_data: 1]

  def evaluate_all(%Dragon{files: %{scss: l}} = d), do: evaluate_all(d, Map.keys(l))

  def evaluate_all(%Dragon{} = d, [file | rest]) do
    with {:ok, path} <- find_file(d.root, file) do
      notify([:green, "SCSS ", :reset, :bright, path])
      with {:ok, content} <- Sass.compile_file(path) do
        path = Path.join(d.build, drop_root(d.root, Path.rootname(path) <> ".css"))
        info([:light_black, "  Saving ", :reset, path])
        Dragon.Tools.IO.write_file(path, content)
      end

      evaluate_all(d, rest)
    end
  end

  def evaluate_all(%Dragon{} = d, []), do: {:ok, d}
end
