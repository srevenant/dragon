defmodule Dragon.Plugin.Redirects do
  @behaviour Dragon.Plugin

  @impl Dragon.Plugin
  def run(%Dragon{} = _d, path, %{redirect_from: _redirects}, content) do
    # IO.inspect({path, redirects})
    # scan headers & update
    {:ok, path, content}
  end
  def run(_, path, _, content), do: {:ok, path, content}

  #   with {:ok, file_paths_and_frontmatter} <- Utils.fast_get_frontmatters(file_paths) do
  #     file_paths_and_frontmatter
  #     |> Enum.filter(fn
  #       {_path, %{redirect_from: _urls}} -> true
  #       {_path, _fm} -> false
  #     end)
  #     |> Enum.flat_map(fn {path, %{redirect_from: urls}} ->
  #       content =
  #         path
  #         |> Utils.strip_root_prefix(root)
  #         |> Utils.transform_suffix()
  #         |> Kernel.then(&Path.join("/", &1))
  #         |> redirect_body()
  #
  #       Enum.map(urls, fn url ->
  #         dest = Path.join(build, String.replace_suffix(url, "/", "/index.html"))
  #         {dest, content}
  #       end)
  #     end)
  #     |> Enum.each(fn {dest, content} ->
  #       Utils.write_file(dest: dest, content: content)
  #     end)
  # end
end
