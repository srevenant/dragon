defmodule Dragon.Serve.Plug.RuntimeStatic do
  @moduledoc """
  Clone of Plug.Static, adjusted to handle runtime root folder, rather than
  compile time.

  NOTE: Copyright on this file is from the core Elixir Plug library, not the Dragon.
  """

  @behaviour Plug
  @allowed_methods ~w(GET HEAD)

  import Plug.Conn
  alias Plug.Conn

  # In this module, the `:prim_file` Erlang module along with the `:file_info`
  # record are used instead of the more common and Elixir-y `File` module and
  # `File.Stat` struct, respectively. The reason behind this is performance: all
  # the `File` operations pass through a single process in order to support node
  # operations that we simply don't need when serving assets.

  require Record
  Record.defrecordp(:file_info, Record.extract(:file_info, from_lib: "kernel/include/file.hrl"))

  defmodule InvalidPathError do
    defexception message: "invalid path for static asset", plug_status: 400
  end

  @impl true
  def init(opts) do
    encodings =
      opts
      |> Keyword.get(:encodings, [])
      |> maybe_add("br", ".br", Keyword.get(opts, :brotli, false))
      |> maybe_add("gzip", ".gz", Keyword.get(opts, :gzip, false))

    %{
      encodings: encodings,
      only_rules: {Keyword.get(opts, :only, []), Keyword.get(opts, :only_matching, [])},
      qs_cache: Keyword.get(opts, :cache_control_for_vsn_requests, "public, max-age=31536000"),
      et_cache: Keyword.get(opts, :cache_control_for_etags, "public"),
      et_generation: Keyword.get(opts, :etag_generation, nil),
      headers: Keyword.get(opts, :headers, %{}),
      content_types: Keyword.get(opts, :content_types, %{}),
      from: nil,
      at: opts |> Keyword.fetch!(:at) |> Plug.Router.Utils.split()
    }
  end

  @impl true
  def call(
        conn = %Conn{method: meth},
        %{at: at, encodings: encodings} = options
      )
      when meth in @allowed_methods do
    {:ok, from} = Dragon.get(:build)
    segments = subset(at, conn.path_info)

    segments = Enum.map(segments, &uri_decode/1)

    {path, segments} = path(from, segments) |> folder_to_index(segments)

    if invalid_path?(segments) do
      raise InvalidPathError, "invalid path for static asset: #{conn.request_path}"
    end

    range = get_req_header(conn, "range")
    encoding = file_encoding(conn, path, range, encodings)
    serve_static(encoding, conn, segments, range, options)
  end

  defp folder_to_index(path, segments) do
    if File.dir?(path) do
      path = Path.join(path, "index.html")
      [_ | segments] = Path.split(path)
      {path, segments}
    else
      {path, segments}
    end
  end

  defp uri_decode(path) do
    # TODO: Remove rescue as this can't fail from Elixir v1.13
    try do
      URI.decode(path)
    rescue
      ArgumentError ->
        raise InvalidPathError
    end
  end

  defp serve_static({content_encoding, file_info, path}, conn, segments, _range, options) do
    %{
      qs_cache: qs_cache,
      et_cache: et_cache,
      et_generation: et_generation,
      headers: headers,
      content_types: types
    } = options

    case put_cache_header(conn, qs_cache, et_cache, et_generation, file_info, path) do
      {:stale, conn} ->
        filename = List.last(segments)
        content_type = Map.get(types, filename) || MIME.from_path(filename)

        conn
        |> put_resp_header("content-type", content_type)
        |> put_resp_header("accept-ranges", "bytes")
        |> maybe_add_encoding(content_encoding)
        |> merge_headers(headers)
        |> send_entire_file(path, options)

      {:fresh, conn} ->
        conn
        |> maybe_add_vary(options)
        |> send_resp(304, "")
        |> halt()
    end
  end

  defp serve_static(:error, conn, _segments, _range, _options) do
    conn
  end

  defp send_entire_file(conn, path, options) do
    IO.write(".")

    conn
    |> maybe_add_vary(options)
    |> send_file(200, path)
    |> halt()
  end

  defp maybe_add_encoding(conn, nil), do: conn
  defp maybe_add_encoding(conn, ce), do: put_resp_header(conn, "content-encoding", ce)

  defp maybe_add_vary(conn, %{encodings: encodings}) do
    # If we serve gzip or brotli at any moment, we need to set the proper vary
    # header regardless of whether we are serving gzip content right now.
    # See: http://www.fastly.com/blog/best-practices-for-using-the-vary-header/
    if encodings != [] do
      update_in(conn.resp_headers, &[{"vary", "Accept-Encoding"} | &1])
    else
      conn
    end
  end

  defp put_cache_header(
         %Conn{query_string: "vsn=" <> _} = conn,
         qs_cache,
         _et_cache,
         _et_generation,
         _file_info,
         _path
       )
       when is_binary(qs_cache) do
    {:stale, put_resp_header(conn, "cache-control", qs_cache)}
  end

  defp put_cache_header(conn, _qs_cache, et_cache, et_generation, file_info, path)
       when is_binary(et_cache) do
    etag = etag_for_path(file_info, et_generation, path)

    conn =
      conn
      |> put_resp_header("cache-control", et_cache)
      |> put_resp_header("etag", etag)

    if etag in get_req_header(conn, "if-none-match") do
      {:fresh, conn}
    else
      {:stale, conn}
    end
  end

  defp put_cache_header(conn, _, _, _, _, _) do
    {:stale, conn}
  end

  defp etag_for_path(file_info, et_generation, path) do
    case et_generation do
      {module, function, args} ->
        apply(module, function, [path | args])

      nil ->
        file_info(size: size, mtime: mtime) = file_info
        <<?", {size, mtime} |> :erlang.phash2() |> Integer.to_string(16)::binary, ?">>
    end
  end

  defp file_encoding(conn, path, [_range], _encodings) do
    # We do not support compression for range queries.
    file_encoding(conn, path, nil, [])
  end

  defp file_encoding(conn, path, _range, encodings) do
    encoded =
      Enum.find_value(encodings, fn {encoding, ext} ->
        if file_info = accept_encoding?(conn, encoding) && regular_file_info(path <> ext) do
          {encoding, file_info, path <> ext}
        end
      end)

    cond do
      not is_nil(encoded) ->
        encoded

      file_info = regular_file_info(path) ->
        {nil, file_info, path}

      true ->
        :error
    end
  end

  defp regular_file_info(path) do
    case :prim_file.read_file_info(path) do
      {:ok, file_info(type: :regular) = file_info} ->
        file_info

      _ ->
        nil
    end
  end

  defp accept_encoding?(conn, encoding) do
    encoding? = &String.contains?(&1, [encoding, "*"])

    Enum.any?(get_req_header(conn, "accept-encoding"), fn accept ->
      accept |> Plug.Conn.Utils.list() |> Enum.any?(encoding?)
    end)
  end

  defp maybe_add(list, key, value, true), do: list ++ [{key, value}]
  defp maybe_add(list, _key, _value, false), do: list

  defp path({module, function, arguments}, segments)
       when is_atom(module) and is_atom(function) and is_list(arguments),
       do: Enum.join([apply(module, function, arguments) | segments], "/")

  defp path({app, from}, segments) when is_atom(app) and is_binary(from),
    do: Enum.join([Application.app_dir(app), from | segments], "/")

  defp path(from, segments),
    do: Enum.join([from | segments], "/")

  defp subset([h | expected], [h | actual]), do: subset(expected, actual)
  defp subset([], actual), do: actual
  defp subset(_, _), do: []

  defp invalid_path?(list) do
    invalid_path?(list, :binary.compile_pattern(["/", "\\", ":", "\0"]))
  end

  defp invalid_path?([h | _], _match) when h in [".", "..", ""], do: true
  defp invalid_path?([h | t], match), do: String.contains?(h, match) or invalid_path?(t)
  defp invalid_path?([], _match), do: false

  defp merge_headers(conn, {module, function, args}) do
    merge_headers(conn, apply(module, function, [conn | args]))
  end

  defp merge_headers(conn, headers) do
    merge_resp_headers(conn, headers)
  end
end
