defmodule Dragon.English do
  @doc """
  iex> oxford_comma([])
  ""
  iex> oxford_comma(["one"])
  "one"
  iex> oxford_comma(["one", "two"])
  "one, and two"
  iex> oxford_comma(["one", "two", "three", "four"])
  "one, two, three, and four"
  iex> oxford_comma(["one", "two", "three", "four"], "or")
  "one, two, three, or four"
  """
  def oxford_comma(list, joiner \\ "and")

  def oxford_comma([], _joiner), do: ""
  def oxford_comma([one], _joiner), do: to_string(one)
  def oxford_comma(list, joiner), do: _oxford_comma(list, [], joiner)

  defp _oxford_comma([], [h, n | t], joiner),
    do: _list_to_str(t, "#{to_string(n)}, #{joiner} #{to_string(h)}")

  defp _oxford_comma([h | t], rest, joiner), do: _oxford_comma(t, [h | rest], joiner)
  defp _list_to_str([], str), do: str
  defp _list_to_str([h | t], str), do: _list_to_str(t, to_string(h) <> ", " <> str)

  @doc """
  iex> plural("red", [1])
  "red"
  iex> plural("red", [1,1])
  "reds"
  """
  def plural(word, list) when length(list) > 1, do: plural(word)
  def plural(word, _), do: word

  @doc """
  iex> plural("red")
  "reds"
  iex> plural("redy")
  "redies"
  iex> plural("rey")
  "reys"
  iex> plural("rex")
  "rexes"
  iex> plural("rech")
  "reches"
  """
  def plural(word) do
    last1 = String.slice(word, -1..-1//1)
    last2 = String.slice(word, -2..-2//1)
    last3 = String.slice(word, -2..-1//1)

    cond do
      last1 == "y" and not str_in?(last2, "aeiou") ->
        String.slice(word, 0..-2//1) <> "ies"

      last1 == "o" and not str_in?(last2, "aeiouy") ->
        word <> "es"

      str_in?(last1, "sx") ->
        word <> "es"

      last3 == "ch" or last3 == "sh" ->
        word <> "es"

      true ->
        word <> "s"
    end
  end

  @vowels MapSet.new([?a, ?e, ?i, ?o, ?u])
  @dialyzer {:nowarn_function, [a_or_an: 1]}
  def a_or_an(str) do
    <<first::utf8, _rest::binary>> = str

    if MapSet.member?(@vowels, first) do
      "an " <> str
    else
      "a " <> str
    end
  end

  defp str_in?(c, set) do
    String.contains?(set, c)
  end

  ##############################################################################
  def have_has(list) when length(list) > 1, do: "have"
  def have_has(_), do: "has"
end
