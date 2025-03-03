defmodule WuunderUtils.Strings do
  @moduledoc """
  Contains a set of String helpers
  """

  defguard is_empty(string) when string == nil or string == ""

  @doc """
  Capitalizes each word in a given string.
  Note that it will downcase the remainders of each word by default.

  ## Examples

      iex> WuunderUtils.Strings.capitalize("this is sparta!")
      "This Is Sparta!"

      iex> WuunderUtils.Strings.capitalize("is this spArTA?")
      "Is This Sparta?"

      iex> WuunderUtils.Strings.capitalize("Michał")
      "Michał"

      iex> WuunderUtils.Strings.capitalize("łukasz")
      "Łukasz"

  """
  @spec capitalize(String.t()) :: String.t()
  def capitalize(string) when is_binary(string) do
    string
    |> String.split(" ")
    |> Enum.map_join(" ", fn part ->
      String.capitalize(part)
    end)
  end

  @doc """
  Checks if given value is nil, or a string that (after trimming) is empty

  ## Examples

      iex> WuunderUtils.Strings.empty?(nil)
      true

      iex> WuunderUtils.Strings.empty?("   ")
      true

      iex> WuunderUtils.Strings.empty?("a string")
      false

  """
  @spec empty?(String.t() | nil) :: boolean()
  def empty?(nil), do: true
  def empty?(string) when is_binary(string), do: String.trim(string) == ""

  @doc """
  The inverse of `is_nil_or_empty`

  ## Examples

      iex> WuunderUtils.Strings.any?("   ")
      false

      iex> WuunderUtils.Strings.any?(nil)
      false

      iex> WuunderUtils.Strings.any?("yes")
      true

  """
  @spec any?(String.t() | nil) :: boolean()
  def any?(string) when is_binary(string) or is_nil(string), do: not empty?(string)

  @doc """
  Converts an empty string to nil or returns the original string

  ## Examples

      iex> WuunderUtils.Strings.empty_to_nil(nil)
      nil

      iex> WuunderUtils.Strings.empty_to_nil("")
      nil

      iex> WuunderUtils.Strings.empty_to_nil("    ")
      nil

      iex> WuunderUtils.Strings.empty_to_nil("this_is_a_string")
      "this_is_a_string"
  """
  @spec empty_to_nil(String.t() | nil) :: nil | String.t()
  def empty_to_nil(value) when is_binary(value) or is_nil(value) do
    if empty?(value) do
      nil
    else
      value
    end
  end

  @doc """
  Trims and cleans up double spaces. Converts `nil` to empty string.

  ## Examples

      iex> WuunderUtils.Strings.clean(" well    this is a sentence")
      "well this is a sentence"

  """
  @spec clean(String.t() | nil) :: String.t()
  def clean(value) when is_binary(value) do
    value
    |> String.split()
    |> Enum.join(" ")
  end

  def clean(nil), do: ""

  @doc """
  Converts any given value to a string by using `inspect`.
  If the given value is already a string, the value is left as it is.
  Every value is truncated to max 255 chars.

  ## Examples

      iex> WuunderUtils.Strings.inspect_value("this is a string")
      "this is a string"

      iex> "This is " <> WuunderUtils.Strings.inspect_value("a string")
      "This is a string"

      iex> WuunderUtils.Strings.inspect_value(%{a: 10})
      "%{a: 10}"

  """
  @spec inspect_value(any()) :: String.t()
  def inspect_value(value) when is_binary(value), do: value
  def inspect_value(value), do: inspect(value)

  @doc """
  Truncates a string with a given string. If string is longer than
  given length, it will add a suffix to that string.
  By default this is `...`

  ## Examples

      iex> WuunderUtils.Strings.truncate("this is a long string", 30)
      "this is a long string"

      iex> WuunderUtils.Strings.truncate("this is a long string", 21)
      "this is a long string"

      iex> WuunderUtils.Strings.truncate("this is a long string", 20)
      "this is a long st..."

      iex> WuunderUtils.Strings.truncate("this is a long string", 10)
      "this is..."

      iex> WuunderUtils.Strings.truncate("this is a long string", 20, "... data truncated")
      "th... data truncated"

      iex> WuunderUtils.Strings.truncate("this is a long string", 21, "... data truncated")
      "this is a long string"

      iex> WuunderUtils.Strings.truncate("this is a long string", 10, "very long suffix")
      "very long "

  """
  @spec truncate(String.t(), integer(), String.t()) :: String.t()
  def truncate(value, max_length, suffix \\ "...")
      when is_binary(value) and is_integer(max_length) and max_length > 1 and is_binary(suffix) do
    if max_length >= String.length(suffix) do
      suffix_length = String.length(suffix)

      if String.length(value) > max_length do
        String.slice(value, 0..(max_length - suffix_length - 1)) <> suffix
      else
        value
      end
    else
      truncate(suffix, max_length, "")
    end
  end

  @doc """
  Compares two strings, ignoring the casing:

  ## Examples

    iex> WuunderUtils.Strings.compare("case_x", "CASE_X")
    true

    iex> WuunderUtils.Strings.compare("CASE_X", "CASE_X")
    true

    iex> WuunderUtils.Strings.compare("CASE_X", "CaSe_X")
    true

    iex> WuunderUtils.Strings.compare("CASE_Y", "CASE_X")
    false

    iex> WuunderUtils.Strings.compare("CASE_y", "CASE_x")
    false

  """
  @spec compare(String.t(), String.t()) :: boolean()
  def compare(left, right) when is_binary(left) and is_binary(right),
    do: String.downcase(left) == String.downcase(right)
end
