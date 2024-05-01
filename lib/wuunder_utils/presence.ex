defmodule WuunderUtils.Presence do
  @moduledoc """
  Acts as proxy module towards present? functions of String and Map
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

      iex> WuunderUtils.Presence.present?(nil)
      false

      iex> WuunderUtils.Presence.present?(%{})
      false

      iex> WuunderUtils.Presence.present?(%{value: 1200})
      true

      iex> WuunderUtils.Presence.present?("")
      false

      iex> WuunderUtils.Presence.present?("test")
      true

  """
  @spec present?(t()) :: boolean()
  def present?(value) when is_number(value) or is_decimal(value), do: Numbers.present?(value)
  def present?(map) when is_map(map), do: Maps.present?(map)
  def present?(value) when is_binary(value) or is_nil(value), do: Strings.present?(value)
  def present?([]), do: false
  def present?([_head | _tail]), do: true

  @doc """
  The inverse of present?

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
  def empty?(value), do: present?(value) == false
end
