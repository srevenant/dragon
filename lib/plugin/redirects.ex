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
  import Dragon.Tools
  @behaviour Dragon.Plugin

  @impl Dragon.Plugin
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
