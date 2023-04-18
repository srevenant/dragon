defmodule Dragon.Plugin do
  use Dragon.Context

  @callback run(Dragon.t(), path :: String.t(), map(), content :: String.t()) ::
              {:error, reason :: String.t()} | {:ok, path :: String.t(), content :: String.t()}

  # add other stages here as we need/want them
  def posteval(%Dragon{plugins: %{posteval: list}} = dragon, path, headers, content)
      when is_list(list),
      do: posteval(dragon, path, headers, content, list)

  def posteval(_, path, _, content), do: {:ok, path, content}

  ##############################################################################
  def posteval(d, p, h, c, [module | rest]) do
    try do
      apply(module, :run, [d, p, h, c])
    rescue
      err ->
        error("Error while in plugin #{module}")

        Kernel.reraise(err, __STACKTRACE__)
    end
    |> case do
      {:ok, path, content} ->
        posteval(d, path, h, content, rest)

      other ->
        error("Unexpected result from plugin:")
        IO.inspect(other, label: "RESULT")
        abort("Cannot continue")
    end
  end

  def posteval(_, path, _, content, []), do: {:ok, path, content}
end
