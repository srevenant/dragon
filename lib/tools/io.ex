defmodule Dragon.Tools.IO do
  import Rivet.Utils.Cli.Print
  # alias IO.ANSI

  def open_file(path) do
    case File.open(path, [:read]) do
      {:ok, fd} ->
        {:ok, fd}

      {:error, :enoent} ->
        abort("Cannot open file '#{path}', cannot continue")

      _err ->
        # IO.puts("\n\n\n\nReminder: This often is a 'blame' which is breaking parsing the actual exception\n\n\n")
        # IO.inspect(err, label: "File open error")
        abort("Cannot open file, cannot continue")
    end
  end

  def with_open_file(path, func) do
    with {:ok, fd} <- open_file(path) do
      try do
        func.(fd)
      after
        :ok = File.close(fd)
      end
    end
  end

  def write_file(dest, content) do
    Dragon.Tools.File.makedirs_for_file(dest)

    case File.write(dest, content) do
      :ok -> :ok
      {:error, err} -> abort("Cannot write file '#{dest}': #{err}")
    end
  end
end
