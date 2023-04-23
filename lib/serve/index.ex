defmodule Dragon.Serve do
  @moduledoc false
  use Dragon.Context

  def start(target) do
    port = 5000
    Application.ensure_all_started(:dragon)
    Application.ensure_all_started(:plug)
    Application.ensure_all_started(:logger)
    Application.ensure_all_started(:telemetry)

    Logger.configure(level: :info)

    # build once first, which also configures Dragon
    with {:ok, _} <- Dragon.Slayer.build(:all, target),
         {:ok, _} <- Dragon.Serve.Watcher.start() do
      server = {Bandit, plug: Dragon.Serve.Plug.Files, scheme: :http, port: port}
      {:ok, _} = Supervisor.start_link([server], strategy: :one_for_one)
      Process.sleep(100)
      stdout([:bright, :green, "\n<CTRL-C> to stop server\n"])
      Process.sleep(:infinity)
    else
      {:error, reason} -> abort(reason)
    end
  end
end
