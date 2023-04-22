defmodule Dragon.Template.Env do
  @moduledoc """
  Build "environment" for a file's EEX template execution.
  """
  use Dragon.Context
  import Rivet.Utils.Time, only: [utc_offset: 1]
  import Dragon.Data, only: [clean_data: 1]


  ##############################################################################
  @doc """
  Get env/context for a file
  """
  def get_for(origin, type, header, dragon, args \\ []) do
    with {:ok, data} <- get_file_metadata(origin, header) do
      args = Map.new(args)

      args =
        case {type, args} do
          {:layout, %{parent: parent}} -> Map.delete(args, :parent) |> Map.merge(parent)
          _ -> args
        end

      Map.get(data, :"@page", %{args: []})
      |> Map.get(:args, [])
      |> Enum.each(fn required ->
        if not Map.has_key?(args, String.to_atom(required)) do
          abort("Template #{origin} requires input arg '#{required}' which is missing")
        end
      end)

      page = Map.merge(data, args)

      {:ok, Map.merge(dragon.data, %{dragon: dragon, page: page})}
    end
  end

  ##############################################################################
  def get_file_metadata(origin, data) when is_map(data) do
    data = clean_data(data)

    {:ok,
     case File.stat(origin) do
       {:ok, stat} ->
         date = get_posted_time(stat.ctime, origin, data)

         %{
           date_modified: posix_erl_to_datetime(stat.mtime),
           date: date,
           date_t: DateTime.to_unix(date),
           title: get_title_from_file(origin)
         }

       _ ->
         abort("file disappeared during processing?")
     end
     |> Map.merge(Map.delete(data, :date))}
  end

  ##############################################################################
  @daterx ~r/(\d{2,4}[-_]\d{1,2}[-_]\d{1,2})([-_T]\d{1,2}:\d{1,2}(:\d{1,2})?([-+]?\d{2}:\d{2}|[A-Z]+)?)?[-_]/

  defp get_title_from_file(origin) do
    origin = Path.basename(origin) |> Path.rootname()
    Regex.replace(@daterx, origin, "") |> String.replace("_", " ")
  end

  defp get_posted_time(_, origin, %{date: date}), do: to_datetime(date, origin)

  defp get_posted_time(ctime, origin, _) do
    case Regex.run(@daterx, origin) do
      nil ->
        posix_erl_to_datetime(ctime)

      [_, date, "-" <> time] ->
        to_datetime("#{date}T#{time}:00#{utc_offset(:string)}", origin)

      [_, date, "T" <> time] ->
        to_datetime("#{date}T#{time}:00#{utc_offset(:string)}", origin)

      [_, date, "-" <> time, _] ->
        to_datetime("#{date}T#{time}#{utc_offset(:string)}", origin)

      [_, date, "T" <> time, _] ->
        to_datetime("#{date}T#{time}#{utc_offset(:string)}", origin)

      [_, date, "-" <> time, _, _] ->
        to_datetime("#{date}T#{time}", origin)

      [_, date, "T" <> time, _, _] ->
        to_datetime("#{date}T#{time}", origin)

      [_, date] ->
        to_datetime("#{date}T00:00:00Z", origin)
    end
  end

  # need to figure out TZ offset adjustments
  defp to_datetime(date, origin) do
    case DateTime.from_iso8601(date) do
      {:ok, datetime, _} -> datetime
      {:error, what} -> abort("Unrecognized datetime for #{origin}: #{date} — #{what}")
    end
  end

  defp posix_erl_to_datetime(erl) do
    NaiveDateTime.from_erl!(erl) |> DateTime.from_naive!("Etc/UTC")
  end
end
