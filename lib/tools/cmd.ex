defmodule Dragon.Tools.Cmd do
  @doc """
  More user friendly command system
  """
  def run([cmd | argv]) do
    case System.cmd(cmd, argv, stderr_to_stdout: true) do
      {output, 0} -> {:ok, output}
      {output, err} -> {:error, err, output}
    end
  rescue
    err ->
      case err do
        %ErlangError{original: :enoent} -> {:error, "Command not found: #{cmd}"}
        %ErlangError{original: what} -> {:error, what}
      end
  end
end
