defmodule Dragon.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [Dragon]

    opts = [strategy: :one_for_one, name: Dragon.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
