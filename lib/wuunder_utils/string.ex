defmodule WuunderUtils.String do
  @moduledoc """
  Contains a set of String helpers
  """

  @doc """
  Tests is given string is an UUID

  ## Examples

      iex> WuunderUtils.String.uuid?("")
      false

      iex> WuunderUtils.String.uuid?("39169cb3-03ea")
      false

      iex> WuunderUtils.String.uuid?("39169CB3-03EA-47E5-9B3C-BD4C53E7FE3F")
      true

      iex> WuunderUtils.String.uuid?("39169cb3-03ea-47e5-9b3c-bd4c53e7fe3f")
      true

  """
  @spec uuid?(String.t()) :: boolean()
  def uuid?(uuid) when is_binary(uuid),
    do: String.match?(uuid, ~r/[\w]{8}-?[\w]{4}-?[\w]{4}-?[\w]{4}-?[\w]{12}/)

  @doc """
  Capitalizes each word in a given string.
  Note that it will downcase the remainders of each word by default.

  ## Examples

      iex> WuunderUtils.String.capitalize("this is sparta!")
      "This Is Sparta!"

      iex> WuunderUtils.String.capitalize("is this spArTA?")
      "Is This Sparta?"

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

      iex> WuunderUtils.String.empty?(nil)
      true

      iex> WuunderUtils.String.empty?("   ")
      true

      iex> WuunderUtils.String.empty?("a string")
      false

  """
  @spec empty?(String.t() | nil) :: boolean()
  def empty?(nil), do: true
  def empty?(string) when is_binary(string), do: String.trim(string) == ""

  @doc """
  The inverse of `is_nil_or_empty`

  ## Examples

      iex> WuunderUtils.String.present?("   ")
      false

      iex> WuunderUtils.String.present?(nil)
      false

      iex> WuunderUtils.String.present?("yes")
      true

  """
  @spec present?(String.t() | nil) :: boolean()
  def present?(string) when is_binary(string) or is_nil(string), do: not empty?(string)

  @doc """
  Converts an empty string to nil or returns the original string

  ## Examples

      iex> WuunderUtils.String.empty_to_nil(nil)
      nil

      iex> WuunderUtils.String.empty_to_nil("")
      nil

      iex> WuunderUtils.String.empty_to_nil("    ")
      nil

      iex> WuunderUtils.String.empty_to_nil("this_is_a_string")
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

      iex> WuunderUtils.String.clean(" well    this is a sentence")
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

      iex> WuunderUtils.String.as_string("this is a string")
      "this is a string"

      iex> WuunderUtils.String.as_string(%{a: 10, b: 30, c: 50})
      "%{a: 10, b: 30, c: 50}"

  """
  @spec as_string(any()) :: String.t()
  def as_string(value) when is_binary(value), do: truncate(value, 255)
  def as_string(value), do: as_string(inspect(value))

  @doc """
  Truncates a string with a given string. If string is longer than
  given length, it will add a suffix to that string.
  By default this is `...`

  ## Examples

      iex> WuunderUtils.String.truncate("this is a long string", 30)
      "this is a long string"

      iex> WuunderUtils.String.truncate("this is a long string", 10)
      "this is ..."
  """
  @spec truncate(String.t(), integer()) :: String.t()
  def truncate(value, max_length)
      when is_binary(value) and is_integer(max_length) and max_length > 3 do
    if String.length(value) > max_length - 3 do
      String.slice(value, 0..(max_length - 3)) <> "..."
    else
      value
    end
  end

  defmodule Guards do
    defguard is_empty(string) when string == nil or string == ""
  end
end
