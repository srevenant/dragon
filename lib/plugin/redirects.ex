defmodule Dragon.Plugin.Redirects do
  use Dragon.Context
  import Dragon.Tools.File
  @behaviour Dragon.Plugin

  @impl Dragon.Plugin
  def run(%Dragon{} = _d, _origin, target, %{redirect_from: redirects}, content) do
    with {:ok, build} <- Dragon.get(:build) do
      redirect_body("#{Path.join("/", drop_root(build, target)) |> Path.rootname()}/")
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
end
