defmodule Dragon.Plugin.Redirects do
  @moduledoc """
  Dragon Redirect plugin.

  To use, include in headermatter:

  ```
  redirect_from:
    - /path-of-origin-link/
  ```

  And this plugin will create html redirects to the "current" file where the
  redirects_from are located.
  """
  use Dragon.Context
  import Dragon.Tools.File
  import Dragon.Template.Functions, only: [eex: 1]
  @behaviour Dragon.Plugin

  @impl Dragon.Plugin
  def run(%Dragon{} = _d, _origin, target, %{redirect_to: dest}, _content) do
    {:ok, target, redirect_body(eex(dest))}
  end

  def run(%Dragon{} = _d, _origin, target, %{redirect_from: redirects} = h, content) do
    with {:ok, build} <- Dragon.get(:build) do
      target =
        case h do
          %{"@spec": %{output: "folder/index"}} -> Path.rootname(target)
          _ -> Path.dirname(target)
        end

      redirect_body("#{Path.join("/", drop_root(build, target))}/")
      |> create_redirects(build, redirects)
    end

    {:ok, target, content}
  end

  def run(_, _, target, _, content), do: {:ok, target, content}

  defp create_redirects(content, build, [redirect | rest]) do
    stderr([:light_black, "+ Redirect from ", :reset, :bright, redirect])
    :ok = File.mkdir_p(Path.join(build, redirect))
    write_file(Path.join([build, redirect, "index.html"]), content)
    create_redirects(content, build, rest)
  end

  defp create_redirects(_, _, []), do: :ok

  # redirects aren't bad anymore for SEO... is this still needed?
  # probably not: <meta name="robots" content="noindex">
  def redirect_body(canonical_url) do
    # special case if redirecting to root it can be a double slash, which causes
    # issues.
    canonical_url = Regex.replace(~r{^//+}, canonical_url, "/")

    """
    <!DOCTYPE html>
    <html lang="en-US">
    <head>
    <title>Redirecting&hellip;</title>
    <link rel="canonical" href="#{canonical_url}">
    <meta http-equiv="Refresh" content="0; URL=#{canonical_url}" />
    </head>
    <body>
    <h1>Redirecting</h1>
    <a href="#{canonical_url}">Click here if you are not redirected.</a>
    </body>
    </html>
    """
  end
end
