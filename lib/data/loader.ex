defmodule Dragon.Data.Loader do
  @moduledoc """
  Load data from an elixir module... still cannot handle variable deps,
  as Mix.install doesn't want to run from within Mix :table_flip:
  """

  use Dragon.Context
  import Dragon.Tools.Dict
  import Dragon.Tools.File, only: [drop_root: 2, find_file: 2]
  import Dragon.Data, only: [data_path: 2]

  def load(%Dragon{} = dragon, %{type: "loader", path: path, into: into}) do
    stdout([:green, "Loader ", :reset, :bright, drop_root(dragon.root, path)])
    into = data_path(dragon.root, into)

    with {:ok, path} <- find_file(dragon.root, path),
         {:error, reason} <- run_loader(dragon, path, into) do
      abort(reason)
    end
  end

  def load(%Dragon{} = dragon, args), do: abort("Invalid loader args: #{inspect(args)}")

  defp run_loader(dragon, path, into) do
    if File.exists?(path) do
      case Code.eval_file(path) do
        {{:module, module, _, _}, _} ->
          if Kernel.function_exported?(module, :load, 1) do
            stdout([:green, "Loader ", :reset, :bright, "#{module}.load/1"])

            case module.load(dragon) do
              {:ok, data} ->
                put_into(dragon, [:data] ++ into, data)

              {:error, _} = pass ->
                pass

              error ->
                IO.inspect(error, label: "Invalid Result")
                {:error, "Invalid result from Loader"}
            end
          else
            {:error, "Loader module #{module} does not have load/1 function"}
          end

        error ->
          IO.inspect(error, label: "Load Error")
          {:error, "Cannot load file '#{path}': Invalid contents"}
      end
    else
      {:error, "Cannot find file '#{path}'"}
    end

    # rescue
    #   error ->
    #     IO.inspect(error)
    #     {:error, "Cannot load file '#{path}': #{error.description}"}
  end
end
