defmodule Dragon.Slayer do
  @moduledoc """
  The Dragon process itself manages state, and as such does not include any
  processing work. This is run from tasks external, where the actual heavy
  lifting happens.
  """

  def build(:all, target) do
    with {:ok, dragon} <- Dragon.configure(Path.expand(target)), do: rebuild(:all, dragon)
  end

  def rebuild(:all, dragon) do
    with {:ok, dragon} <- Dragon.prepare_build(dragon),
         {:ok, dragon} <- Dragon.Scss.Evaluate.all(dragon) do
      # do Dragon Template last so prior things can be generated, allowing the
      # 'path' function to properly find things
      Dragon.Template.Evaluate.all(dragon)
    end
  end
end
