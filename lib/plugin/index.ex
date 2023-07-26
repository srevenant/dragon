defmodule Dragon.Plugin do
  @moduledoc """
  Dragon Plugin behavior. See [Markdown](Dragon.Plugin.Markdown.html) and [Redirects](Dragon.Plugin.Redirects.html) plugins for examples.
  """
  use Dragon.Context

  @callback run(
              Dragon.t(),
              originfile :: String.t(),
              buildfile :: String.t(),
              headers :: map(),
              content :: String.t()
            ) ::
              {:error, reason :: String.t()}
              | {:ok, buildfile :: String.t(), content :: String.t()}

  @spec posteval(Dragon.t(), String.t(), String.t(), headers :: map(), String.t()) ::
          {:ok, String.t(), headers :: map(), String.t()}

  # add other stages here as we need/want them
  def posteval(%Dragon{plugins: %{posteval: list}} = dragon, origin, target, headers, content)
      when is_list(list),
      do: posteval(dragon, origin, target, headers, content, list)

  def posteval(_, _, target, headers, content), do: {:ok, target, headers, content}

  ##############################################################################
  def posteval(d, o, t, h, c, [module | rest]) do
    try do
      apply(module, :run, [d, o, t, h, c])
    rescue
      err ->
        error("Error while in plugin #{module}")

        Kernel.reraise(err, __STACKTRACE__)
    end
    |> case do
      {:ok, target, content} ->
        posteval(d, o, target, h, content, rest)

      other ->
        error("Unexpected result from plugin (#{module}):")
        IO.inspect(other, label: "RESULT")
        abort("Cannot continue")
    end
  end

  def posteval(_, _, target, h, content, []), do: {:ok, target, h, content}
end
