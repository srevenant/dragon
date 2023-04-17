defmodule Dragon.Template do
  use Dragon.Context
  import Dragon.Tools.File
  import Dragon.Template.Read
  import Dragon.Process.Data, only: [clean_data: 1]

  @moduledoc """
  Core bits for Template handling.

  Although Dragon is a standalone genserver for its data, we still try to push
  the Dragon struct on the current processes' stack to keep data movement to
  a minimum, and bring it in again with Dragon.get() only when we've lost the
  context (such as when called from within a template's helper functions).

  """

  def evaluate_all(%Dragon{files: %{dragon: l}} = d), do: evaluate_all(d, Map.keys(l))

  def evaluate_all(%Dragon{} = d, [file | rest]) do
    with {:ok, path} <- find_file(d.root, file) do
      read_template_header(path)
      |> evaluate(:primary, d)
      |> validate()
      |> commit_file()

      evaluate_all(d, rest)
    end
  end

  def evaluate_all(%Dragon{} = d, []), do: {:ok, d}

  def processing(file, layout \\ nil)
  def processing(file, nil), do: notify([:green, "EEX Template ", :reset, :bright, file])

  def processing(file, layout),
    do:
      notify([:green, "EEX Template ", :reset, :bright, file, :reset, :light_blue, " (#{layout})"])

  ##############################################################################
  def evaluate(read_result, type, dragon, args \\ [])

  # process files with a layout directive slightly differently. First, process
  # the current file and get the output results. Then call, as an include,
  # the layout template, sending the current output into that as a page
  # argument (@page.content)
  def evaluate(
        {:ok, %{"@spec": %{layout: layout}} = h, path, offset},
        :primary,
        %Dragon{} = d,
        args
      ) do
    processing(path, layout)

    with {:ok, content} <- read_template_body(path, offset),
         {:ok, context} <- generate_context(path, h, d, args),
         {:ok, output} <- evaluate_template(d, path, content, context),
         {:ok, _, output} <-
           include_file(Path.join(d.layouts, "_#{layout}"), d, :layout, content: output),
         do: postprocess(d, path, output)
  end

  def evaluate({:ok, h, path, offset}, type, %Dragon{} = d, args) do
    if type != :layout do
      processing(path)
    end

    with {:ok, content} <- read_template_body(path, offset),
         {:ok, context} <- generate_context(path, h, d, args),
         {:ok, output} <- evaluate_template(d, path, content, context),
         do: postprocess(d, path, output)
  end

  def evaluate({:error, reason}, _, _, _), do: abort("Unable to continue: #{reason}")

  ################################################################################
  # we don't pay attention to layout here
  def include_file(path, %Dragon{} = d, _, args) do
    case find_file(d.root, path) do
      {:ok, target} ->
        info("+ Including #{target}")

        read_template_header(target)
        |> handle_non_template(target)
        |> evaluate(:layout, d, args)

      {:error, msg} ->
        abort("+ Include failed: #{msg}")
    end
  end

  def handle_non_template({:error, _}, target), do: {:ok, %{}, target, 0}
  def handle_non_template({:ok, _, _, _} = pass, _), do: pass

  ################################################################################
  def validate({:ok, dst, content}) do
    # future: scan html content for breaks
    {:ok, dst, content}
  end

  ##############################################################################
  def postprocess(%{root: root, build: build}, path, content) do
    path = Path.join(build, Dragon.Tools.File.drop_root(root, path))

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

  ##############################################################################
  def commit_file({:ok, path, content}) do
    info([:light_black, "  Saving ", :reset, path])
    Dragon.Tools.IO.write_file(path, content)
   end

  ##############################################################################
  defp evaluate_template(%Dragon{imports: imports}, path, template, context) do
    # enrich some functions — TEMPORARY option, this is hacky and we need a
    # better way...
    helpers = Dragon.Template.Helpers.generate_context(%{parent: path})
    context = [{:assigns, Map.to_list(context)} | helpers]

    try do
      {:ok, EEx.eval_string(imports <> template, context)}
    rescue
      err ->
        case err do
          ## TODO: include offset in line count so you can find it in the editor!
          %CompileError{file: "nofile", line: line, description: msg} ->
            # minus one to the line because we added a line above
            abort_nofile_error(template, path, line - 1, msg)

          error ->
            error("Error processing #{path}")
            Kernel.reraise(error, __STACKTRACE__)
        end
    end
  end

  def abort_nofile_error(template, path, lineno, msg) do
    first = lineno - 2
    first = if first < 0, do: 0, else: first

    last = lineno + 2

    IO.puts("\n")

    IO.puts(
      :stderr,
      IO.ANSI.format([
        :yellow,
        "? ",
        "#{path}:#{lineno}",
        :reset,
        " — ",
        :yellow,
        :bright,
        msg,
        "\n"
      ])
    )

    String.split(template, "\n")
    |> Enum.reduce_while(1, fn line, index ->
      cond do
        index == lineno -> print_with_line("»", index, line)
        index > first and index < last -> print_with_line(" ", index, line)
        true -> :ok
      end

      if index == last do
        {:halt, index}
      else
        {:cont, index + 1}
      end
    end)

    IO.puts(:stderr, "\n")
    abort("Cannot continue")
  end

  defp print_with_line(prefix, index, line) do
    padded = String.pad_leading("#{index}", 3)
    IO.puts(:stderr, IO.ANSI.format([:blue, :bright, "#{prefix}#{padded}: ", :reset, line]))
  end

  ##############################################################################
  @daterx ~r/(\d{2,4}[-_]\d{1,2}[-_]\d{1,2})([-_T]\d{1,2}:\d{1,2}(:\d{1,2})?([-+]?\d{2}:\d{2}|[A-Z]+)?)?[-_]/

  def get_title_from_file(origin) do
    origin = Path.basename(origin) |> Path.rootname()
    Regex.replace(@daterx, origin, "") |> String.replace("_", " ")
  end

  def get_posted_time(_, origin, %{date: date}), do: to_datetime(date, origin)

  def get_posted_time(ctime, origin, _) do
    case Regex.run(@daterx, origin) do
      nil ->
        posix_erl_to_datetime(ctime)

      [_, date, "-" <> time] ->
        to_datetime("#{date}T#{time}:00#{iso_utc_offset()}", origin)

      [_, date, "T" <> time] ->
        to_datetime("#{date}T#{time}:00#{iso_utc_offset()}", origin)

      [_, date, "-" <> time, _] ->
        to_datetime("#{date}T#{time}#{iso_utc_offset()}", origin)

      [_, date, "T" <> time, _] ->
        to_datetime("#{date}T#{time}#{iso_utc_offset()}", origin)

      [_, date, "-" <> time, _, _] ->
        to_datetime("#{date}T#{time}", origin)

      [_, date, "T" <> time, _, _] ->
        to_datetime("#{date}T#{time}", origin)

      [_, date] ->
        to_datetime("#{date}T00:00:00Z", origin)
    end
  end

  # there is probably a better way
  def iso_utc_offset() do
    padded = fn x -> String.pad_leading("#{x}", 2, "0") end
    offset = Timex.Timezone.local().offset_utc / 3600
    sep = if offset > 0, do: "+", else: "-"
    offset = abs(offset)
    hour = padded.(trunc(offset))
    min = padded.(trunc(offset - trunc(offset) * 60))
    "#{sep}#{hour}:#{min}"
  end

  # need to figure out TZ offset adjustments
  def to_datetime(date, origin) do
    case DateTime.from_iso8601(date) do
      {:ok, datetime, _} -> datetime
      {:error, what} -> abort("Unrecognized datetime for #{origin}: #{date} — #{what}")
    end
  end

  def posix_erl_to_datetime(erl) do
    NaiveDateTime.from_erl!(erl) |> DateTime.from_naive!("Etc/UTC")
  end

  ##############################################################################
  def get_file_context(origin, data) when is_map(data) do
    # case YamlElixir.read_from_string(header) do
    #   {:ok, data} ->
    data = clean_data(data)

    {:ok,
     case File.stat(origin) do
       {:ok, stat} ->
         date = get_posted_time(stat.ctime, origin, data)

         %{
           date_modified: posix_erl_to_datetime(stat.mtime),
           date: date,
           date_t: DateTime.to_unix(date),
           title: get_title_from_file(origin)
         }

       _ ->
         abort("file disappeared during processing?")
     end
     |> Map.merge(Map.delete(data, :date))}

    #
    #   {:error, msg} ->
    #     IO.inspect(msg, label: "generate_context error")
    #     abort("ERR")
    # end
  end

  def generate_context(origin, header, dragon, args \\ []) do
    with {:ok, data} <- get_file_context(origin, header) do
      args = Map.new(args)

      Map.get(data, :"@page", %{args: []})
      |> Map.get(:args, [])
      |> Enum.each(fn required ->
        if not Map.has_key?(args, String.to_atom(required)) do
          abort("Template #{origin} requires input arg '#{required}' which is missing")
        end
      end)

      page = Map.merge(data, args)

      {:ok, Map.merge(dragon.data, %{dragon: dragon, page: page})}
    end
  end
end
