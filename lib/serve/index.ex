defmodule Dragon.Serve do
  @moduledoc false
  use Dragon.Context

  def start(target, opts) do
    Application.ensure_all_started(:dragon)
    Application.ensure_all_started(:plug)
    Application.ensure_all_started(:logger)
    Application.ensure_all_started(:telemetry)

    Logger.configure(level: :info)

    port = Map.get(opts, :port, 4040)

    # build once first, which also configures Dragon
    with {:ok, _} <- Dragon.Slayer.build(:all, target),
         {:ok, _} <- Dragon.Serve.Watcher.start(opts) do
      server = {Bandit, plug: Dragon.Serve.Plug.Files, scheme: :http, port: port}
      {:ok, _} = Supervisor.start_link([server], strategy: :one_for_one)
      Process.sleep(100)
      stdout([:bright, :green, "\nVisit http://localhost:#{port}\n\n<CTRL-C> to stop server\n"])
      Process.sleep(:infinity)
    else
      {:error, reason} -> abort(reason)
    end
  end
end
