defmodule Dragon.Serve.Watcher do
  @moduledoc false
  use GenServer
  require Logger

  # def start(), do: Supervisor.start_link(__MODULE__, [strategy: :one_for_one, name: Dragon.Supervisor])

  def start(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    with {:ok, root} <- Dragon.get(:root),
         {:ok, build} <- Dragon.get(:build),
         {:ok, base} <- Dragon.Tools.File.get_true_path(root),
         {:ok, pid} <- FileSystem.start_link(dirs: [root]) do
      FileSystem.subscribe(pid)
      build = String.slice(build, (String.length(root) + 1)..-1)
      {:ok, {String.length(base) + 1, base, root, String.length(build) - 1, build}}
    end
  end

  def handle_info({:file_event, _, {path, _events}}, {rx, _, root, bx, build} = state) do
    sliced = String.slice(path, rx..-1)
    prefix = String.slice(sliced, 0..bx)
    target = Path.join(root, sliced)
    # despite absname and expand, this can still come in as a different root path because
    # of funny filesystem business w/symlinks. So instead, just look for build
    # and filter only on that
    if prefix != build do
      try do
        # if an included file, we just do the whole tree
        cond do
          target == Path.join(root, "_dragon.yml") ->
            # start over from the top
            Dragon.Slayer.build(:all, root)

          Path.basename(target) |> String.at(0) == "_" ->
            # rebuild everything but within current configuration
            with {:ok, dragon} <- Dragon.get(), do: Dragon.Slayer.rebuild(:all, dragon)

          true ->
            # or per-file
            with {:ok, dragon} <- Dragon.get() do
              case Dragon.Tools.File.file_type(target) do
                {:ok, :file, target} ->
                  Dragon.Tools.File.Synchronize.synchronize(dragon, [target])

                {:ok, :dragon, target} ->
                  Dragon.Template.Evaluate.all(dragon, [target])

                {:ok, :scss, target} ->
                  Dragon.Scss.Evaluate.all(dragon, [target])
              end
            end
        end
      rescue
        err ->
          Logger.error(Exception.format(:error, err, __STACKTRACE__))
      end
    end

    {:noreply, state}
  catch x, y ->
    IO.inspect({x, y})
  end
end
