defmodule Dragon.Utils do
  @doc """
  sequence helps you know if any item in a list of tuples failed

  iex> vals = [ok: 1, ok: 2, ok: 3]
  ...> errs_or_oks(vals)
  {:ok, [1,2,3]}
  iex> vals = [ok: 1, error: "nan", ok: 3, error: "hmm"]
  ...> errs_or_oks(vals)
  {:error, ["nan", "hmm"]}
  """
  @spec errs_or_oks(list(keyword())) :: {:error, list(any())} | {:ok, list(any())}
  def errs_or_oks(keywords) do
    keywords
    |> Enum.reverse()
    |> Enum.reduce({:ok, []}, fn
      {:ok, val}, {:ok, vals} -> {:ok, [val | vals]}
      {:ok, _val}, {:error, errs} -> {:error, errs}
      {:error, err}, {:error, errs} -> {:error, [err | errs]}
      {:error, err}, {:ok, _} -> {:error, [err]}
    end)
  end

  @doc """
  sequence helps you know if any item in a list of tuples failed

  iex> files = ["cat/of/the.woods", "cat/of/denmark.txt", "dog/land.man"]
  ...> files_to_sitemap(files)
  %{ cat: %{ of: %{"denmark.txt": "cat/of/denmark.txt", "the.woods": "cat/of/the.woods"} }, dog: %{"land.man": "dog/land.man"} }
  """
  def files_to_sitemap(files) when is_list(files) do
    files
    |> Enum.map(&Path.split(&1))
    |> to_tree("")
  end

  defp to_tree([[]], _) do
    nil
  end

  defp to_tree(files, acc_path) do
    files
    |> Enum.group_by(&hd(&1), &Enum.drop(&1, 1))
    |> Map.new(fn {k, v} ->
      acc_path = Path.join(acc_path, k)
      key = String.to_atom(k)
      tree = to_tree(v, acc_path)
      if tree == nil, do: {key, acc_path}, else: {key, tree}
    end)
  end

  def parse_file(content: content) do
    [frontmatter, content] =
      case String.split(content, ~r/\n-{3,}\n/, parts: 2) do
        [frontmatter, content] -> [frontmatter, content]
        [content] -> ["", content]
        _ -> ["", ""]
      end

    with {:ok, frontmatter_context} <- parse_yaml(frontmatter) do
      {:ok, [content, frontmatter_context]}
    end
  end

  def fast_get_frontmatters(file_paths) when is_list(file_paths) do
    file_paths
    |> Enum.map(&fast_get_frontmatter/1)
    |> errs_or_oks()
  end

  def fast_get_frontmatter(file_path, truncate_after \\ 500) do
    fm =
      File.stream!(file_path)
      |> Stream.take(truncate_after)
      |> Enum.reduce_while([], fn
        line, [] ->
          if String.starts_with?(line, "---"), do: {:cont, [line]}, else: {:cont, []}

        line, fm ->
          if String.starts_with?(line, "---"), do: {:halt, fm}, else: {:cont, [line | fm]}
      end)
      |> Enum.reverse()
      |> Enum.join()
      |> parse_yaml()

    case fm do
      {:ok, fm} -> {:ok, {file_path, fm}}
      {:error, _err} = err -> err
      err -> {:error, err}
    end
  end

  defp parse_yaml(content) do
    with {:ok, parsed} <- YamlElixir.read_from_string(content),
         data <- Transmogrify.transmogrify(parsed) do
      {:ok, data}
    end
  end

  def walk(root: root, match: globs) do
    globs
    |> Enum.flat_map(&Path.wildcard(Path.join(root, &1)))
    |> Enum.uniq()
  end

  def write_file(dest: dest, content: content) do
    File.mkdir_p(Path.dirname(dest))

    case File.write(dest, content) do
      :ok -> IO.puts("✅ #{dest}")
      {:error, err} -> IO.puts("❗#{err} #{dest}")
    end
  end

  def strip_root_prefix(file_path, root) do
    String.replace_prefix(file_path, root <> "/", "")
  end

  def transform_suffix(path) do
    prev_ext = Path.extname(path)

    new_ext =
      case prev_ext do
        ".md" -> ".html"
        ".eex" -> ".html"
        ".htm" -> ".html"
        ".scss" -> ".css"
        ext -> ext
      end

    String.replace_suffix(path, prev_ext, new_ext)
  end

  def is_scss?(file), do: Path.extname(file) === ".scss"
end
