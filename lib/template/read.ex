defmodule Dragon.Template.Read do
  @moduledoc """
  Reading data from a dragon template, considering separators.
  """

  use Dragon.Context
  import Dragon.Tools.File
  import Dragon.Data, only: [clean_data: 1]

  ##############################################################################
  @spec read_template_header(file :: String.t()) ::
          {:ok, header :: map(), path :: String.t(), end_of_header_offset :: integer(),
           lines_in_header :: integer()}
          | {:error, reason :: String.t() | atom()}

  # scan contents of file and stop at body separator
  def read_template_header(path) do
    with_open_file(path, fn fd ->
      IO.stream(fd, :line)
      |> Enum.reduce_while(nil, &read_header/2)
    end)
    |> case do
      {offset, buffer} when is_integer(offset) ->
        with {:ok, data} <- parse_header(path, buffer),
             do: {:ok, data, path, offset, length(buffer)}

      other ->
        other
    end
  end

  defp read_header("---" <> type, nil) do
    case get_separator_type(type) do
      {:ok, :dragon, _} -> {:cont, {3 + byte_size(type), []}}
      {:error, _} = err -> {:halt, err}
      {:ok, other, _} -> {:halt, {:error, "not dragon header type? (#{other})"}}
    end
  end

  defp read_header("---" <> type, {offset, buffer}) do
    case get_separator_type(type) do
      {:ok, :eex, _} ->
        {:halt, {offset + 3 + byte_size(type), buffer}}

      {:error, _} = err ->
        {:halt, err}

      {:ok, other, _} ->
        {:halt, {:error, "not eex header type? (#{other})"}}
    end
  end

  defp read_header(line, {offset, buffer}),
    do: {:cont, {offset + byte_size(line), [line | buffer]}}

  defp read_header(_line, nil), do: {:halt, {:error, "found data before reading separator?"}}

  ##############################################################################
  @spec read_template_body(file :: String.t(), offset :: integer()) ::
          {:ok, body :: String.t()} | {:error, reason :: String.t() | atom()}
  def read_template_body(path, offset \\ 0) do
    {:ok,
     with_open_file(path, fn fd ->
       # Jump forward past the header
       Dragon.Tools.File.seek!(fd, offset)
       |> IO.stream(:line)
       |> Enum.reduce_while([], &read_body/2)
     end)
     |> Enum.reverse()
     |> Enum.join()}
  end

  defp read_body("---" <> type, []) do
    case get_separator_type(type) do
      {:error, _} = err -> {:halt, err}
      {:ok, :eex, _} -> {:cont, []}
      {:ok, other, _} -> {:halt, {:error, "invalid template type #{other}"}}
    end
  end

  defp read_body(line, buffer), do: {:cont, [line | buffer]}

  ################################################################################
  defp get_separator_type(type) do
    [type | vdata] = String.downcase(type) |> String.trim() |> String.split("-")

    case determine_separator_type(type) do
      {:error, _} = pass -> pass
      type -> {:ok, type, vdata}
    end
  end

  # defp determine_separator_type("", default), do: default
  defp determine_separator_type("dragon"), do: :dragon
  defp determine_separator_type("eex"), do: :eex
  defp determine_separator_type(type), do: {:error, "Unrecognized separator type (#{type})"}

  defp parse_header(path, buffer) do
    Enum.reverse(buffer)
    |> Enum.join()
    |> YamlElixir.read_from_string()
    |> case do
      {:error, msg} ->
        IO.inspect(msg, label: "yaml error")
        abort("error parsing header yaml for #{path}")

      {:ok, data} ->
        {:ok, clean_data(data)}
    end
  end
end
