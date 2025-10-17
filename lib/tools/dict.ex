defmodule Dragon.Tools.Dict do
  @moduledoc """
  File handling tools.
  """
  use Dragon.Context

  def put_into(dict, [key], value) do
    case Map.get(dict, key) do
      d when is_map(d) ->
        if not is_map(value) do
          IO.puts("INCOMPATIBLE DATA for key=#{key}")
          IO.inspect(d, label: "---DATA1")
          IO.inspect(value, label: "---DATA2")
          raise ArgumentError
        end
        Map.put(dict, key, Map.merge(d, value))
      _ -> Map.put(dict, key, value)
    end
  end

  def put_into(dict, [key | keys], value) do
    case Map.get(dict, key) do
      nil -> Map.put(dict, key, put_into(%{}, keys, value))
      d when is_map(d) -> Map.replace(dict, key, put_into(d, keys, value))
      _ -> raise ArgumentError
    end
  end
end
