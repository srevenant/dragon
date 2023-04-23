defmodule Dragon.Data do
  @moduledoc """
  Tools for loading data
  """
  use Dragon.Context

  def clean_data(data),
    do: Transmogrify.transmogrify(data, key_convert: :atom, deep: true, key_case: :snake)

  ##############################################################################
  def load_data(%Dragon{data: data} = dragon) when is_list(data),
    do: load_data(%Dragon{dragon | data: %{}}, data)

  def load_data(d), do: {:ok, %Dragon{d | data: %{}}}

  def get_into(dragon, %{into: into}), do: data_path(dragon.root, into)
  def get_into(_, _), do: nil

  ##############################################################################
  def data_path(root, path) do
    Dragon.Tools.File.drop_root(root, path)
    |> Path.rootname()
    |> Path.split()
    |> Enum.reduce([], &(&2 ++ String.split(Dragon.Tools.File.export_fname(&1), ".")))
    |> Transmogrify.transmogrify(%{value_convert: :atom, value_case: :snake})
  end

  ##############################################################################
  def load_data(%Dragon{} = dragon, [%{type: "file"} = args | rest]),
    do: Dragon.Data.File.load(dragon, args) |> load_data(rest)

  def load_data(%Dragon{} = dragon, [%{type: "collection"} = args | rest]),
    do: Dragon.Data.Collection.load(dragon, args) |> load_data(rest)

  def load_data(%Dragon{} = dragon, []),
    do: {:ok, %Dragon{dragon | data: Transmogrify.transmogrify(dragon.data)}}

  def load_data(%Dragon{}, [nope | _]) do
    IO.inspect(nope, label: "Invalid config data specification")
    abort("Cannot continue")
  end
end
