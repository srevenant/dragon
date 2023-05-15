defmodule Dragon.Tools.Image.Convert do
  @moduledoc """
  Image handling. Very focused on only a few types of images, so it will break
  if things are given outside of what it expects.

  Requires "Image Magick" or one of it's relatives to be installed.
  """

  import Dragon.Tools.Cmd
  import Transmogrify.As

  @type2atom %{
    "jpg" => :jpg,
    "jpeg" => :jpg,
    "png" => :png,
    "webp" => :webp
  }

  # only those we care about
  @mimetypes %{
    :jpg => "image/jpeg",
    :png => "image/png",
    :webp => "image/webp"
  }
  @types Map.keys(@mimetypes)

  @resolutions [200, 480, 1440, 1920]
  # @social 1000

  # TODO: don't link to anything bigger than this
  # MAXWIDTH = 2000
  # @sizerex Regex.compile("-x[0-9]+(?=\.|-|$)")
  # SIZEREX = re.compile("-x[0-9]+(?=\.|-|$)")

  defp get_type(str) when is_binary(str) do
    down = String.downcase(str)
    with nil <- @type2atom[down], do: as_atom!(down)
  end

  # this can break, doesn't handle all cases; when it breaks we'll fix
  def identify(path) do
    with {:ok, line} <- run(["identify", path]) |> image_magick_error(path) do
      case Regex.run(~r/([A-Z]+) (\d+)x(\d+)/, line) do
        [_, type, width, height] ->
          {:ok, %{type: get_type(type), width: as_int!(width), height: as_int!(height)}}
      end
    end
  end

  def image_magick_error({:error, 1, str}, path) do
    if String.contains?(str, "unable to open image") do
      {:error, "unable to open image: #{path}"}
    else
      {:error, str}
    end
  end

  def image_magick_error(pass, _), do: pass

  def resize(src, dst, w) do
    with {:ok, _} <-
           run(["convert", src, "-resize", "#{w}", dst]) |> image_magick_error(src),
         do: :ok
  end

  def convert(src, dst) do
    with run(["convert", src, dst]) |> image_magick_error(src), do: :ok
  end

  def rename_file(path, target) do
    if path == target do
      :ok
    else
      if File.exists?(target) do
        {:error, "File conflict: #{path} -> #{target} but target already exists"}
      else
        File.rename(path, target)
      end
    end
  end

  def root_name(path), do: Path.rootname(path) |> String.replace(~r/-x[0-9]+(?=\.|-|$)/i, "")

  @default_opts %{resolutions: @resolutions, types: @types}
  def expand_variants(path, opts \\ []) do
    with {:ok, %{type: otype, width: maxw} = orig} <- identify(path) do
      opts = Map.merge(@default_opts, Map.new(opts)) |> Map.merge(orig)
      root = root_name(path)
      target = "#{root}-x#{maxw}.#{otype}"

      opts =
        Map.merge(opts, %{
          origin: target,
          # dirname: Path.dirname(target),
          root: Path.basename(root)
        })

      with :ok <- rename_file(path, target), do: expand_types(%{target => orig}, opts.types, opts)
    end
  end

  ##############################################################################
  def expand_types(acc, [t | rest], opts) do
    with {:ok, acc} <- expand_sizes(acc, t, opts.resolutions, opts),
         do: expand_types(acc, rest, opts)
  end

  def expand_types(acc, [], _), do: {:ok, acc}

  ##############################################################################
  def expand_sizes(acc, type, [width | rest], %{width: max} = opts) when width <= max do
    target = "#{opts.root}-x#{width}.#{type}"

    with {:ok, acc} <- expand_size(acc, target, width, opts),
         do: expand_sizes(acc, type, rest, opts)
  end

  def expand_sizes(acc, t, [_ | rest], o), do: expand_sizes(acc, t, rest, o)

  def expand_sizes(acc, _, [], _), do: {:ok, acc}

  # # #
  defp expand_size(acc, target, _, _) when is_map_key(acc, target), do: acc

  defp expand_size(acc, target, width, opts) do
    with :ok <- resize(opts.origin, target, width),
         {:ok, info} <- identify(target),
         do: {:ok, Map.put(acc, target, info)}
  end
end
