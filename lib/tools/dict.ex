defmodule Dragon.Tools.Dict do
  @moduledoc """
  File handling tools.
  """
  use Dragon.Context

  def put_into(dict, [key], value), do: Map.put(dict, key, value)

  def put_into(dict, [key | keys], value) do
    case Map.get(dict, key) do
      nil -> Map.put(dict, key, put_into(%{}, keys, value))
      d when is_map(d) -> Map.replace(dict, key, put_into(d, keys, value))
      _ -> raise ArgumentError
    end
  end
end
