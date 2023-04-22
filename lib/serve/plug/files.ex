defmodule Dragon.Serve.Plug.Files do
  @moduledoc "Development server served by Phoenix"
  use Plug.Builder

  plug(Dragon.Serve.Plug.RuntimeStatic, at: "/")
  plug(:not_found)

  def not_found(conn, _), do: Plug.Conn.send_resp(conn, 404, "Not found")
end
