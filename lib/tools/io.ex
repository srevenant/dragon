defmodule Dragon.Tools.IO do
  alias IO.ANSI

  def open_file(path) do
    case File.open(path, [:read]) do
      {:ok, fd} ->
        {:ok, fd}

      {:error, :enoent} ->
        raise "oops"
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

  def abort(reason) do
    error(reason)
    exit({:shutdown, 1})
  end

  def info(msg) when is_binary(msg), do: IO.puts(ANSI.format([:light_black, "  ", msg]))
  def info(msg) when is_list(msg), do: IO.puts(ANSI.format(["  " | msg]))

  def error(msg) when is_binary(msg),
    do: IO.puts(:stderr, ANSI.format([:red, :bright, "! ", msg]))

  def warn(msg) when is_binary(msg),
    do: IO.puts(:stderr, ANSI.format([:yellow, :bright, "? ", msg]))

  def notify(msg) when is_binary(msg),
    do: IO.puts(ANSI.format_fragment([:green, :bright, ?✓, :reset, " ", msg]))

  def notify(msg) when is_list(msg),
    do: IO.puts(ANSI.format_fragment([:green, :bright, ?✓, :reset, " "] ++ msg))
end
