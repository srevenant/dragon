defmodule Dragon.Serve.Plug.Files do
  @moduledoc "Development server served by Phoenix"
  use Plug.Builder

  # something is holding connections, probably the janky way we had to override
  # call in this clone of Static serving. So to address this, just dial down
  # the timeouts really small. This isn't intended for production, just local
  # development.
  plug(Dragon.Serve.Plug.RuntimeStatic, at: "/", inactivity_timeout: 1000, idle_timeout: 1000)
  plug(:not_found)

  def not_found(conn, _), do: Plug.Conn.send_resp(conn, 404, "Not found")
end
