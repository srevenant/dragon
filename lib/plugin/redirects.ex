defmodule Dragon.Plugin.Redirects do
  use Dragon.Context
  import Dragon.Tools.File
  @behaviour Dragon.Plugin

  @impl Dragon.Plugin
  def run(%Dragon{} = _d, origin, target, %{redirect_from: redirects}, content) do
    with {:ok, root} <- Dragon.get(:root), {:ok, build} <- Dragon.get(:build) do
      redirect_body(Path.join("/", drop_root(root, origin)))
      |> create_redirects(build, redirects)
    end
    {:ok, target, content}
  end

  def run(_, _, target, _, content), do: {:ok, target, content}

  defp create_redirects(content, build, [redirect | rest]) do
    info([:light_black, "+ Redirect from ", :reset, :bright, redirect])
    :ok = File.mkdir_p(Path.join(build, redirect))
    write_file(Path.join([build, redirect, "index.html"]), content)
    create_redirects(content, build, rest)
  end

  defp create_redirects(_, _, []), do: :ok

  def redirect_body(canonical_url) do
    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>Redirecting&hellip;</title>
      <link rel="canonical" href="#{canonical_url}">
      <meta http-equiv="Refresh" content="0; URL=#{canonical_url}" />
    </head>
    </html>
    """
  end

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
