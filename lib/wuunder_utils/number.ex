defmodule WuunderUtils.Number do
  @moduledoc """
  Helper functions for floats, ints and Decimal's
  """
  alias WuunderUtils.Presence

  @doc """
  Parses a string to an int. Returns `nil` if that didn't work out.

  ## Examples

      iex> WuunderUtils.Number.parse_int("10005")
      10005

      iex> WuunderUtils.Number.parse_int(10005)
      10005

      iex> WuunderUtils.Number.parse_int(10.5)
      10.5

      iex> WuunderUtils.Number.parse_int("10.50")
      10

      iex> WuunderUtils.Number.parse_int("TEST10.50")
      nil

      iex> WuunderUtils.Number.parse_int("10TEST2")
      10

  """
  @spec parse_int(any()) :: integer() | float() | nil
  def parse_int(value) when is_number(value), do: value

  def parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, _} -> integer
      _ -> nil
    end
  end

  def parse_int(_other_value), do: nil

  @doc """
  Parses a String.t() to a float(). Just passes float()
  but does convert integer() to a float().

  When parsing fails, this function returns a `nil`.

  ## Examples

      iex> WuunderUtils.Number.parse_float("10005")
      10005.0

      iex> WuunderUtils.Number.parse_float(10005)
      10005

      iex> WuunderUtils.Number.parse_float(10.5)
      10.5

      iex> WuunderUtils.Number.parse_float("10.50")
      10.5

      iex> WuunderUtils.Number.parse_float("TEST10.50")
      nil

      iex> WuunderUtils.Number.parse_float("10TEST2")
      10.0
  """
  @spec parse_float(any()) :: integer() | float() | nil
  def parse_float(value) when is_number(value), do: value

  def parse_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      _ -> nil
    end
  end

  def parse_float(_other_value), do: nil

  @doc """
  Tries to convert any value to a Decimal.
  It will also convert a `nil` to a 0.

  ## Examples

      iex> WuunderUtils.Number.to_decimal("15")
      Decimal.new("15")

      iex> WuunderUtils.Number.to_decimal("15")
      Decimal.new("15")
  """
  @spec to_decimal(any()) :: Decimal.t()
  def to_decimal(value) do
    cond do
      Presence.empty?(value) -> Decimal.new(0)
      is_decimal?(value) -> value
      true -> Decimal.new("#{value}")
    end
  end

  @doc """
  Tests if the given value is a Decimal

  ## Examples

      iex> WuunderUtils.Number.is_decimal?(1)
      false

      iex> WuunderUtils.Number.is_decimal?(nil)
      false

      iex> WuunderUtils.Number.is_decimal?(Decimal.new("10"))
      true

  """
  @spec is_decimal?(any()) :: boolean()
  def is_decimal?(%Decimal{}), do: true
  def is_decimal?(_), do: false
end
