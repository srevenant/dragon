defmodule Dragon.Process.Synchronize do
  @moduledoc """
  Lightweight file synchronizer.
  For performance, do not synchronize files to the build folder unless:

    * original timestamp is different
    * file size is different

  """

  use Dragon.Context

  ##############################################################################
  def file_difference(file1, file2) do
    case {File.stat(file1), File.stat(file2)} do
      {{:ok, %{size: size, type: type, mtime: mtime, mode: mode}},
       {:ok, %{size: size, type: type, mtime: mtime, mode: mode}}} ->
        false

      {{:ok, stat}, result} ->
        {stat, result}
    end
  end

  def synchronize(%Dragon{files: %{file: files}} = dragon),
    do: synchronize(dragon, Map.keys(files))

  def synchronize(dragon), do: {:ok, dragon}

  ##############################################################################
  def synchronize(%Dragon{root: root, build: build} = dragon, [file | rest]) do
    src = Path.join(root, file)
    dst = Path.join(build, file)
    Dragon.Tools.File.makedirs_for_file(dst)

    diff = file_difference(src, dst)

    if diff != false do
      # cleanup first
      case diff do
        {_, {:ok, %{type: :directory}}} ->
          File.rmdir!(dst)

        {_, {:ok, %{type: :regular}}} ->
          File.rm!(dst)

        _ ->
          nil
      end

      {stat, _} = diff

      synchronize_file(src, dst, stat)
    end

    synchronize(dragon, rest)
  end

  def synchronize(%Dragon{} = dragon, _), do: {:ok, dragon}

  def synchronize_file(src, dst, stat) do
    notify([:green, "Synchronizing file: ", :reset, :bright, src])

    case File.cp(src, dst) do
      :ok ->
        # update modified time to match
        File.touch(dst, stat.mtime)
    end
  end
end
