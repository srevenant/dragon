defmodule Dragon.Tools do
  use Dragon.Context

  def data_path(path) do
    Path.split(path)
    |> Enum.reduce([], &(&2 ++ String.split(Dragon.Tools.File.export_fname(&1), ".")))
    |> Transmogrify.transmogrify(%{value_convert: :atom, value_case: :snake})
  end

  def put_into(dict, [key], value), do: Map.put(dict, key, value)

  def put_into(dict, [key | keys], value) do
    case Map.get(dict, key) do
      nil -> Map.put(dict, key, put_into(%{}, keys, value))
      d when is_map(d) -> Map.replace(dict, key, put_into(d, keys, value))
      _ -> raise ArgumentError
    end
  end
end
