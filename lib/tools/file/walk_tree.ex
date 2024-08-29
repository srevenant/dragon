defmodule Dragon.Tools.File.WalkTree.NoMatch do
  use Dragon.Context
  import Dragon.Tools.File, only: [drop_root: 2]

  def no_match(dragon, path, _) do
    info("Ignoring file: #{drop_root(dragon.root, path)}")
    dragon
  end
end

defmodule Dragon.Tools.File.WalkTree do
  @moduledoc """
  File handling tools.
  """
  use Dragon.Context
  import Dragon.Tools.File, only: [drop_root: 2]
  import Dragon.Tools.File.WalkTree.NoMatch

  ##############################################################################
  @doc """
  Recursive directory tree walker. I prefer this to Path.wildcard(), as I have
  more fine-grained control.

  Match and Ignore can be string or regex. If string it matches exactly on the
  file extension. Match is a dictionary where the value is a handler function,
  and the key is a regex or string, where ignore is simply a list.
  """
  @opts %{
    match: %{},
    ignore: [~r{^\.}],
    follow_meta: false,
    in_meta: false,
    no_match: &no_match/3
  }

  def walk_tree(dragon, path, cfg) when is_list(cfg),
    do: walk_tree_(dragon, path, normal_opts(cfg))

  def walk_tree_(%{root: root} = dragon, path, opts) when is_binary(path) and is_map(opts) do
    fname = Path.basename(path)
    first = String.at(fname, 0)

    in_meta =
      if opts.in_meta do
        true
      else
        first == "_"
      end

    opts = Map.put(opts, :in_meta, in_meta)

    cond do
      in_meta and opts.follow_meta != true ->
        dragon

      ignore_file?(fname, opts.ignore) ->
        stderr([:light_black, "Ignoring file: #{drop_root(root, fname)}"])
        dragon

      true ->
        fullpath = Path.join(root, path)

        case File.stat(fullpath) do
          {:ok, %File.Stat{type: :directory}} ->
            File.ls!(fullpath)
            |> Enum.reduce(dragon, &walk_tree_(&2, Path.join(path, &1), opts))

          {:ok, %File.Stat{type: :regular}} ->
            handler = match_file(fname, opts.match)

            if handler == false,
              do: opts.no_match.(dragon, fullpath, opts),
              else: handler.(dragon, fullpath, opts)

          {:error, reason} ->
            abort("Unable to process file '#{fullpath}': #{reason}")
        end
    end
  end

  ##############################################################################
  defp normal_opts(cfg) do
    opts = Map.merge(@opts, Map.new(cfg))
    Map.replace(opts, :match, Enum.to_list(opts.match))
  end

  ##############################################################################
  defp ignore_file?(fname, list),
    do: ignore_file?(fname, Path.extname(fname) |> String.slice(1..-1//1), list)

  defp ignore_file?(fname, ext, [pattern | rest]) when is_binary(pattern) do
    if ext == pattern, do: true, else: ignore_file?(fname, ext, rest)
  end

  # assume if not binary it's a regex
  defp ignore_file?(fname, ext, [rex | rest]) do
    if Regex.match?(rex, fname), do: true, else: ignore_file?(fname, ext, rest)
  end

  defp ignore_file?(_fname, _ext, []), do: false

  ##############################################################################
  defp match_file(fname, match),
    do: match_file(fname, Path.extname(fname) |> String.slice(1..-1//1), match)

  defp match_file(fname, ext, [{pattern, handler} | rest]) when is_binary(pattern) do
    if ext == pattern, do: handler, else: match_file(fname, ext, rest)
  end

  # assume if not binary it's a regex
  defp match_file(fname, ext, [{rex, handler} | rest]) do
    if Regex.match?(rex, fname), do: handler, else: match_file(fname, ext, rest)
  end

  defp match_file(_fname, _ext, []), do: false
end
