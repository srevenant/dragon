defmodule Dragon.Serve.Watcher do
  @moduledoc false
  use GenServer
  use Dragon.Context
  import Rivet.Utils.Cli.Print
  import Dragon.Tools.File, only: [get_true_path: 1]
  require Logger

  # def start(), do: Supervisor.start_link(__MODULE__, [strategy: :one_for_one, name: Dragon.Supervisor])

  def start(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def init(opts) do
    paths =
      Enum.reduce(opts.watch, [], fn f, acc ->
        case get_true_path(f) do
          {:ok, path} ->
            stderr([:green, "Watching path: #{path}"])
            [path | acc]

          _ ->
            warn("Ignoring path: #{f}")
            acc
        end
      end)

    with {:ok, root} <- Dragon.get(:root),
         {:ok, build} <- Dragon.get(:build),
         {:ok, base} <- Dragon.Tools.File.get_true_path(root),
         {:ok, pid} <- FileSystem.start_link(dirs: [root] ++ paths) do
      FileSystem.subscribe(pid)
      build = String.slice(build, (String.length(root) + 1)..-1)
      {:ok, {String.length(base) + 1, base, root, String.length(build) - 1, build}}
    end
  end

  def is_meta?(path),
    do:
      not is_nil(
        Path.split(path)
        |> Enum.find(fn
          "_" <> _ -> true
          _ -> false
        end)
      )

  def resolve_target(path, {rx, base, root, bx, build}) do
    target_base = String.slice(path, 0..(rx - 1)) |> Path.split() |> Path.join()

    if target_base != base do
      :all
    else
      sliced = String.slice(path, rx..-1)
      prefix = String.slice(sliced, 0..bx)
      # this shouldn't ever error, but just to be safe
      if prefix == build do
        :none
      else
        with {:ok, target} <- Dragon.Tools.File.find_file(root, sliced) do
          cond do
            target == Path.join(root, "_dragon.yml") ->
              :rebuild

            File.dir?(target) ->
              :none

            is_meta?(target) ->
              {:ok, dpaths} = Dragon.get(:data_paths)

              if String.starts_with?(target, Map.keys(dpaths)) do
                :rebuild
              else
                :all
              end

            true ->
              {:only, target}
          end
        end
      end
    end
  end

  def handle_info({:file_event, _, {path, _events}}, {_, _, root, _, _} = state) do
    resolved = resolve_target(path, state)

    if resolved != :none do
      try do
        case resolved do
          :all ->
            with {:ok, dragon} <- Dragon.get(), do: Dragon.Slayer.rebuild(:all, dragon)

          :rebuild ->
            Dragon.Slayer.build(:all, root)

          {:only, target} ->
            # filter data and meta files
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
          case err do
            %Dragon.AbortError{message: msg} -> error(msg)
            e -> Logger.error(Exception.format(:error, e, __STACKTRACE__))
          end
      end
    end

    {:noreply, state}
  catch
    x, y ->
      IO.inspect({x, y}, label: "Caught watcher error:")
      {:noreply, state}
  end
end
