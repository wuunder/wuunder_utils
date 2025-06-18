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
  Checks if given String.t() or float() ends with a zero decimal.

  A String.t() is parsed and returns `false` if the parsing failed.

  ## Examples

      iex> WuunderUtils.Numbers.decimal_zero?(4.5)
      false

      iex> WuunderUtils.Numbers.decimal_zero?(1.0003)
      false

      iex> WuunderUtils.Numbers.decimal_zero?("4.0000")
      true

      iex> WuunderUtils.Numbers.decimal_zero?(6)
      true

      iex> WuunderUtils.Numbers.decimal_zero?("5.0")
      true

      iex> WuunderUtils.Numbers.decimal_zero?(nil)
      false
  """
  @spec decimal_zero?(term) :: boolean
  def decimal_zero?(value) when is_integer(value), do: true

  def decimal_zero?(value) when is_binary(value) do
    value
    |> parse_float()
    |> decimal_zero?()
  end

  def decimal_zero?(value) when is_float(value) do
    value
    |> Kernel.trunc()
    |> Kernel.-(value)
    |> Kernel.==(0)
  end

  def decimal_zero?(_), do: false

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
  Tries to convert a number to a string. When the given value is already a binary, it tries to parse it and output it accordingly.

  ## Examples

      iex> WuunderUtils.Numbers.as_string(13.37)
      "13.37"

      iex> WuunderUtils.Numbers.as_string(Decimal.new("13.37"))
      "13.37"

      iex> WuunderUtils.Numbers.as_string(1337)
      "1337"

      iex> WuunderUtils.Numbers.as_string("1337")
      "1337.0"

      iex> WuunderUtils.Numbers.as_string("1abc300")
      "1.0"

  """
  @spec as_string(term()) :: nil | String.t()
  def as_string(nil), do: nil

  def as_string(value) when is_decimal(value), do: Decimal.to_string(value)
  def as_string(value) when is_float(value), do: Float.to_string(value)
  def as_string(value) when is_integer(value), do: Integer.to_string(value)

  def as_string(value) when is_binary(value) do
    value
    |> parse_float()
    |> as_string()
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

      iex> WuunderUtils.Numbers.any?(-1)
      true

      iex> WuunderUtils.Numbers.any?(1)
      true

      iex> WuunderUtils.Numbers.any?(Decimal.new("1"))
      true

      iex> WuunderUtils.Numbers.any?(0.000001)
      true

      iex> WuunderUtils.Numbers.any?(0.0)
      false

      iex> WuunderUtils.Numbers.any?(0)
      false

      iex> WuunderUtils.Numbers.any?(Decimal.new("0"))
      false

      iex> WuunderUtils.Numbers.any?(Decimal.new("0.0"))
      false
  """
  @spec any?(Decimal.t() | number() | nil) :: boolean()
  def any?(nil), do: false
  def any?(decimal) when is_decimal(decimal), do: Decimal.to_float(decimal) != 0.0
  def any?(value) when is_integer(value), do: value != 0
  def any?(value) when is_float(value), do: value != 0.0

  @doc """
  Reverse of any?
  """
  @spec empty?(Decimal.t() | number() | nil) :: boolean()
  def empty?(value), do: not any?(value)
end
