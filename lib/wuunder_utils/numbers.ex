defmodule WuunderUtils.Numbers do
  @moduledoc """
  Helper functions for floats, ints and Decimal's
  """
  alias WuunderUtils.Presence

  import Decimal, only: [is_decimal: 1]

  @doc """
  Parses a string to an int. Returns `nil` if that didn't work out.

  ## Examples

      iex> WuunderUtils.Numbers.parse_int("10005")
      10005

      iex> WuunderUtils.Numbers.parse_int(10005)
      10005

      iex> WuunderUtils.Numbers.parse_int(10.5)
      10.5

      iex> WuunderUtils.Numbers.parse_int("10.50")
      10

      iex> WuunderUtils.Numbers.parse_int("TEST10.50")
      nil

      iex> WuunderUtils.Numbers.parse_int("10TEST2")
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

      iex> WuunderUtils.Numbers.parse_float("10005")
      10005.0

      iex> WuunderUtils.Numbers.parse_float(10005)
      10005

      iex> WuunderUtils.Numbers.parse_float(10.5)
      10.5

      iex> WuunderUtils.Numbers.parse_float("10.50")
      10.5

      iex> WuunderUtils.Numbers.parse_float("TEST10.50")
      nil

      iex> WuunderUtils.Numbers.parse_float("10TEST2")
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

      iex> WuunderUtils.Numbers.to_decimal("15")
      Decimal.new("15")

      iex> WuunderUtils.Numbers.to_decimal("15")
      Decimal.new("15")
  """
  @spec to_decimal(any()) :: Decimal.t()
  def to_decimal(value) do
    cond do
      Presence.empty?(value) -> Decimal.new(0)
      is_decimal(value) -> value
      true -> Decimal.new("#{value}")
    end
  end

  @doc """
  Adds two Decimal's together. Defaults back to 0.

  ## Examples

      iex> WuunderUtils.Numbers.add_decimal(nil, nil)
      Decimal.new("0")

      iex> WuunderUtils.Numbers.add_decimal(nil, Decimal.new("15.5"))
      Decimal.new("15.5")

      iex> WuunderUtils.Numbers.add_decimal(Decimal.new("6.5"), Decimal.new("15.5"))
      Decimal.new("22.0")

      iex> WuunderUtils.Numbers.add_decimal(Decimal.new("15.5"), nil)
      Decimal.new("15.5")

  """
  @spec add_decimal(nil | Decimal.t(), nil | Decimal.t()) :: Decimal.t()
  def add_decimal(nil, nil), do: Decimal.new("0")
  def add_decimal(nil, decimal) when is_decimal(decimal), do: decimal
  def add_decimal(decimal, nil) when is_decimal(decimal), do: decimal
  def add_decimal(d1, d2) when is_decimal(d1) and is_decimal(d2), do: Decimal.add(d1, d2)

  @doc """
  Tests if number is "present". Meaning: the number must not be 0, 0.0. Positive or negative is ok.
  Also a tiny fraction just above 0 is allowed.

  ## Examples

      iex> WuunderUtils.Numbers.present?(-1)
      true

      iex> WuunderUtils.Numbers.present?(1)
      true

      iex> WuunderUtils.Numbers.present?(Decimal.new("1"))
      true

      iex> WuunderUtils.Numbers.present?(0.000001)
      true

      iex> WuunderUtils.Numbers.present?(0.0)
      false

      iex> WuunderUtils.Numbers.present?(0)
      false

      iex> WuunderUtils.Numbers.present?(Decimal.new("0"))
      false

      iex> WuunderUtils.Numbers.present?(Decimal.new("0.0"))
      false
  """
  @spec present?(Decimal.t() | number() | nil) :: boolean()
  def present?(nil), do: false
  def present?(decimal) when is_decimal(decimal), do: Decimal.to_float(decimal) != 0.0
  def present?(value) when is_integer(value), do: value != 0
  def present?(value) when is_float(value), do: value != 0.0

  @doc """
  Reverse of present?
  """
  @spec empty?(Decimal.t() | number() | nil) :: boolean()
  def empty?(value), do: not present?(value)
end
