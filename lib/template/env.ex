defmodule Dragon.Template.Env do
  @moduledoc """
  Build "environment" for a file's EEX template execution.
  """
  use Dragon.Context
  import Rivet.Utils.Time, only: [utc_offset: 1]

  ##############################################################################
  @doc """
  Get env/context for a file
  """
  #
  # def get_for(origin, header, dragon, args) when is_map(args) do
  #   header = clean_data(header)
  #   with {:ok, page} <- get_file_metadata(dragon.root, origin, header, args) do
  #     {:ok, Map.merge(dragon.data, %{dragon: dragon, page: page})}
  #   end
  # end

  ##############################################################################
  def get_file_metadata(root, origin, header, args) when is_map(header) and is_map(args) do
    parent_header = Map.get(args, :page, %{})
    args = Map.delete(args, :page)

    {:ok,
     case File.stat(origin) do
       {:ok, stat} ->
         date = get_posted_time(stat.ctime, origin, header)

         %{
           date_modified: posix_erl_to_datetime(stat.mtime),
           date_t: DateTime.to_unix(date),
           title: nil,
           path: Dragon.Tools.File.drop_root(root, origin)
         }
         |> Map.merge(parent_header)
         |> Map.merge(header)
         |> Map.merge(args)
         |> Map.put(:date, date)

       _ ->
         abort("file disappeared during processing?")
     end}
  end

  ##############################################################################
  @daterx ~r/(\d{2,4}[-_]\d{1,2}[-_]\d{1,2})([-_T]\d{1,2}:\d{1,2}(:\d{1,2})?([-+]?\d{2}:\d{2}|[A-Z]+)?)?[-_]/

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
