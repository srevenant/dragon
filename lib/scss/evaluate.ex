defmodule Dragon.Scss.Evaluate do
  @moduledoc """
  Render SCSS
  """

  use Dragon.Context
  import Dragon.Tools.File

  def all(%Dragon{files: %{scss: l}} = d), do: all(d, Map.keys(l) |> Enum.sort())
  def all(d), do: {:ok, d}

  def all(%Dragon{} = d, [file | rest]) do
    with {:ok, path} <- find_file(d.root, file) do
      stdout([:green, "SCSS ", :reset, :bright, path])

      ## TODO: Make a runtime argument for adding this — this will minify
      ## the CSS after its run. During a separate stage perhaps
      # Sass.compile_file(path, %{output_style: Sass.sass_style_compressed})
      case Sass.compile_file(path) do
        {:ok, content} ->
          build_path = Path.join(d.build, drop_root(d.root, Path.rootname(path) <> ".css"))
          stderr([:light_black, "✓ Saving ", :reset, build_path])
          write_file(build_path, content)

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
