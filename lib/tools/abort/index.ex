defmodule Dragon.Abort do
  def abort(msg), do: raise(Dragon.AbortError, msg)
end
