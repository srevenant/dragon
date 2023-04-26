defmodule Dragon.AbortError do
  defexception message: "abort"
  @impl true
  def exception(value) do
    case value do
      [] ->
        %__MODULE__{}

      value when is_binary(value) ->
        %__MODULE__{message: value}

      value when is_list(value) ->
        struct(__MODULE__, value)
    end
  end
end
