defmodule WuunderUtils.Presence do
  @moduledoc """
  Acts as proxy module towards any? functions of String and Map
  """
  alias WuunderUtils.Numbers
  alias WuunderUtils.Strings
  alias WuunderUtils.Maps

  import Decimal, only: [is_decimal: 1]

  @type t() ::
          number()
          | list()
          | Decimal.t()
          | map()
          | Elixir.String.t()
          | Ecto.Association.NotLoaded.t()
          | nil

  @doc """
  Checks if value is present

  ## Examples

      iex> WuunderUtils.Presence.any?(nil)
      false

      iex> WuunderUtils.Presence.any?(%{})
      false

      iex> WuunderUtils.Presence.any?(%{value: 1200})
      true

      iex> WuunderUtils.Presence.any?("")
      false

      iex> WuunderUtils.Presence.any?("test")
      true

  """
  @spec any?(t()) :: boolean()
  def any?(value) when is_number(value) or is_decimal(value), do: Numbers.any?(value)
  def any?(map) when is_map(map), do: Maps.any?(map)
  def any?(value) when is_binary(value) or is_nil(value), do: Strings.any?(value)
  def any?([]), do: false
  def any?([_head | _tail]), do: true

  @doc """
  The inverse of any?

  ## Examples

      iex> WuunderUtils.Presence.empty?(nil)
      true

      iex> WuunderUtils.Presence.empty?(%{})
      true

      iex> WuunderUtils.Presence.empty?(%{value: 1200})
      false

      iex> WuunderUtils.Presence.empty?("")
      true

      iex> WuunderUtils.Presence.empty?("test")
      false
  """
  @spec empty?(t()) :: boolean()
  def empty?(value), do: any?(value) == false
end
