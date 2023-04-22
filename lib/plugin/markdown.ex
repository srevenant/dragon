defmodule Dragon.Plugin.Markdown do
  @moduledoc """
  Dragon markdown plugin
  """
  @behaviour Dragon.Plugin

  @impl Dragon.Plugin
  def run(_, _, path, _, content) do
    case Path.extname(path) do
      ".md" ->
        newname = Path.rootname(path) <> ".html"

        case Earmark.as_html(content, escape: false) do
          {:ok, content, _} -> {:ok, newname, content}
          {:error, _ast, error} -> {:error, error}
        end

      _ ->
        {:ok, path, content}
    end
  end
end
