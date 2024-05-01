defmodule WuunderUtils.Maps do
  @moduledoc """
  Contains a set of helpers to deal with some complex stuff with Maps and Structs
  """
  alias WuunderUtils.Presence

  @type map_key() :: atom() | binary()

  defguard is_valid_map_atom_key(key) when is_atom(key) and is_nil(key) == false
  defguard is_valid_map_binary_key(key) when is_binary(key) and key != ""
  defguard is_valid_map_key(key) when is_binary(key) or (is_atom(key) and is_nil(key) == false)

  @doc """
  Retrieves a key from a map regardless of the key type (atom/string)
  Note that this function does not try to convert a given string key to an atom
  to prevent an atom overload.

  ## Examples

      iex> WuunderUtils.Maps.get_field(%{value: 20}, :value)
      20

      iex> WuunderUtils.Maps.get_field(%{"value" => 20}, :value)
      20

      iex> WuunderUtils.Maps.get_field(%{value: 20}, "value")
      nil

      iex> WuunderUtils.Maps.get_field(%{value: 20}, "non-existent")
      nil

      iex> WuunderUtils.Maps.get_field(%{value: 20}, :weight)
      nil

      iex> WuunderUtils.Maps.get_field(%{value: 20}, :weight, 350)
      350

      iex> WuunderUtils.Maps.get_field(%{value: 20}, "currency", "EUR")
      "EUR"

  """
  @spec get_field(map(), map_key(), any()) :: any()
  def get_field(params, key, default \\ nil)

  def get_field(params, key, default)
      when is_map(params) and is_valid_map_atom_key(key) do
    if Map.has_key?(params, key) do
      Map.get(params, key, default)
    else
      Map.get(params, "#{key}", default)
    end
  end

  def get_field(params, key, default) when is_map(params) and is_valid_map_binary_key(key) do
    if Map.has_key?(params, key) do
      Map.get(params, key, default)
    else
      default
    end
  end

  @doc """
  Acts as an IndifferentMap. Put a key/value regardless of the key type. If the map
  contains keys as atoms, the value will be stored as atom: value. If the map contains
  strings as keys it will store the value as binary: value

  Note that this will not try to convert the given string key to an atom if
  the map contains only atom keys (the same reason as stated in helper function `get_field`)

  ## Examples

      iex> WuunderUtils.Maps.put_field(%{value: 20}, :weight, 350)
      %{value: 20, weight: 350}

      iex> WuunderUtils.Maps.put_field(%{value: 20}, "weight", 350)
      %{:value => 20, "weight" => 350}

      iex> WuunderUtils.Maps.put_field(%{"weight" => 350}, :value, 25)
      %{"weight" => 350, "value" => 25}

      iex> WuunderUtils.Maps.put_field(%{"weight" => 350}, "value", 25)
      %{"weight" => 350, "value" => 25}

  """
  @spec put_field(map(), map_key(), any()) :: map()
  def put_field(params, key, value)
      when is_map(params) and is_valid_map_atom_key(key) do
    if has_only_atom_keys?(params) do
      Map.put(params, key, value)
    else
      Map.put(params, "#{key}", value)
    end
  end

  def put_field(params, key, value) when is_map(params) and is_valid_map_binary_key(key),
    do: Map.put(params, key, value)

  @doc """
  Removes a key from a map. Doesn't matter if the key is an atom or string

  ## Examples

      iex> WuunderUtils.Maps.delete_field(%{length: 255, weight: 100}, :length)
      %{weight: 100}

      iex> WuunderUtils.Maps.delete_field(%{length: 255, weight: 100}, "length")
      %{weight: 100, length: 255}

      iex> WuunderUtils.Maps.delete_field(%{"value" => 50, "currency" => "EUR"}, "currency")
      %{"value" => 50}

      iex> WuunderUtils.Maps.delete_field(%{"value" => 50, "currency" => "EUR"}, :currency)
      %{"value" => 50}

  """
  @spec delete_field(map(), map_key()) :: map
  def delete_field(params, key) when is_map(params) and is_valid_map_atom_key(key) do
    if has_only_atom_keys?(params) do
      Map.delete(params, key)
    else
      Map.delete(params, "#{key}")
    end
  end

  def delete_field(params, key) when is_map(params) and is_valid_map_binary_key(key),
    do: Map.delete(params, key)

  @doc """
  Tests if the given map only consists of atom keys

  ## Examples

      iex> WuunderUtils.Maps.has_only_atom_keys?(%{a: 1, b: 2})
      true

      iex> WuunderUtils.Maps.has_only_atom_keys?(%{:a => 1, "b" => 2})
      false

      iex> WuunderUtils.Maps.has_only_atom_keys?(%{"a" => 1, "b" => 2})
      false

  """
  @spec has_only_atom_keys?(map() | struct()) :: boolean()
  def has_only_atom_keys?(struct) when is_struct(struct), do: true

  def has_only_atom_keys?(params) when is_map(params) do
    params
    |> Map.keys()
    |> Enum.all?(&is_atom/1)
  end

  @doc """
  Maps a given field from given (if not in params)

  ## Examples

      iex> WuunderUtils.Maps.alias_field(%{country: "NL"}, :country, :country_code)
      %{country_code: "NL"}

      iex> WuunderUtils.Maps.alias_field(%{"country" => "NL"}, :country, :country_code)
      %{"country_code" => "NL"}

      iex> WuunderUtils.Maps.alias_field(%{street_name: "Straatnaam"}, :street, :street_address)
      %{street_name: "Straatnaam"}

  """
  @spec alias_field(map(), atom(), atom()) :: map()
  def alias_field(params, from, to)
      when is_map(params) and is_valid_map_atom_key(from) and is_valid_map_atom_key(to) do
    from_key = if Enum.empty?(params) || has_only_atom_keys?(params), do: from, else: "#{from}"
    to_key = if Enum.empty?(params) || has_only_atom_keys?(params), do: to, else: "#{to}"

    if is_nil(Map.get(params, from_key)) == false && is_nil(Map.get(params, to_key)) do
      params
      |> Map.put(to_key, Map.get(params, from_key))
      |> Map.delete(from_key)
    else
      Map.delete(params, from_key)
    end
  end

  @doc """
  Mass maps a given input with aliasses

  ## Examples

      iex> WuunderUtils.Maps.alias_fields(%{country: "NL", street: "Straat", number: 666}, %{country: :country_code, street: :street_name, number: :house_number})
      %{country_code: "NL", house_number: 666, street_name: "Straat"}

  """
  @spec alias_fields(map(), map()) :: map()
  def alias_fields(params, aliasses),
    do:
      Enum.reduce(Map.keys(aliasses), params, fn key, alias_params ->
        alias_field(alias_params, key, Map.get(aliasses, key))
      end)

  @doc """
  Creates a clean map from a given struct.
  This function deep structs, maps, lists etc. to a map
  and uses a set of default transformers as defined in `default_struct_fransform/0`.

  There is also an option to omit the `transform` option to add an extra set of transformers.

  Took some inspiration from this great lib: https://github.com/prodis/miss-elixir/blob/0.1.5/lib/miss/map.ex

  Note: It's also able to convert Ecto models to flat maps. It uses the defined Ecto fields for that.

  ## Examples

      iex> WuunderUtils.Maps.from_struct(%TestStruct{
      ...>   first_name: "Peter",
      ...>   last_name: "Pan",
      ...>   date_of_birth: ~D[1980-01-02],
      ...>   weight: Decimal.new("81.5"),
      ...>   country: %TestStruct2{code: "UK"},
      ...>   time_of_death: ~T[13:37:37]
      ...> })
      %{
        address: nil,
        date_of_birth: "1980-01-02",
        first_name: "Peter",
        last_name: "Pan",
        time_of_death: "13:37:37",
        weight: "81.5",
        country: %{code: "UK"}
      }

      iex> WuunderUtils.Maps.from_struct(
      ...>   %TestStruct{
      ...>     first_name: "Peter",
      ...>     last_name: "Pan",
      ...>     date_of_birth: ~D[1980-01-02],
      ...>     weight: Decimal.new("81.5"),
      ...>     country: %TestStruct2{code: "UK"},
      ...>     time_of_death: ~T[13:37:37]
      ...>   },
      ...>   transform: [{TestStruct2, fn x -> "COUNTRY:" <> x.code end}]
      ...> )
      %{
        address: nil,
        date_of_birth: "1980-01-02",
        first_name: "Peter",
        last_name: "Pan",
        time_of_death: "13:37:37",
        weight: "81.5",
        country: "COUNTRY:UK"
      }

      iex> WuunderUtils.Maps.from_struct(
      ...>   %TestStruct{
      ...>     address: %TestSchema{
      ...>       street: "Straat",
      ...>       number: 13,
      ...>       zipcode: "1122AB"
      ...>     },
      ...>     first_name: "Peter",
      ...>     last_name: "Pan",
      ...>     date_of_birth: ~D[1980-01-02],
      ...>     weight: Decimal.new("81.5"),
      ...>     country: %TestStruct2{code: "UK"},
      ...>     time_of_death: ~T[13:37:37]
      ...>   }
      ...> )
      %{
        address: %{number: 13, street: "Straat", zipcode: "1122AB"},
        date_of_birth: "1980-01-02",
        first_name: "Peter",
        last_name: "Pan",
        time_of_death: "13:37:37",
        weight: "81.5",
        country: %{code: "UK"}
      }

  """
  @spec from_struct(any()) :: any()
  def from_struct(value), do: from_struct(value, transform: [])

  @spec from_struct(any(), list()) :: any()
  def from_struct(value, transform: extra_transformers),
    do: from_struct(value, default_struct_transforms() ++ extra_transformers)

  def from_struct(%module{} = struct, transform) when is_list(transform) do
    transform
    |> Keyword.get(module)
    |> case do
      nil ->
        transform_struct(module, struct, transform)

      fun when is_function(fun, 1) ->
        fun.(struct)
    end
  end

  def from_struct(struct, transform) when is_map(struct) and is_list(transform) do
    Enum.reduce(struct, %{}, fn {key, value}, result ->
      Map.put(result, key, from_struct(value, transform))
    end)
  end

  def from_struct(list, transform) when is_list(list) and is_list(transform),
    do: Enum.map(list, &from_struct(&1, transform))

  def from_struct(value, transform) when is_list(transform), do: value

  @doc """
  Conditionally puts a value to a given map. Depending on the condition or the value, the
  key+value will be set to the map

  ## Examples

      iex> WuunderUtils.Maps.put_when(%{street: "Straat"}, 1 == 1, :number, 13)
      %{number: 13, street: "Straat"}

      iex> WuunderUtils.Maps.put_when(%{street: "Straat"}, fn -> "value" == "value" end, :number, 13)
      %{number: 13, street: "Straat"}

      iex> WuunderUtils.Maps.put_when(%{street: "Straat"}, 10 > 20, :number, 13)
      %{street: "Straat"}

  """
  @spec put_when(map(), function() | boolean(), map_key(), any()) :: map()
  def put_when(params, condition, key, value)
      when is_map(params) and is_function(condition) and is_valid_map_key(key),
      do: put_when(params, !!condition.(), key, value)

  def put_when(params, true, key, value) when is_map(params) and is_valid_map_key(key),
    do: put_field(params, key, value)

  def put_when(params, false, key, _value) when is_map(params) and is_valid_map_key(key),
    do: params

  @doc """
  Only puts value in map when the value is considered empty

  ## Examples

      iex> WuunderUtils.Maps.put_if_present(%{street: "Straat"}, :street, "Laan")
      %{street: "Laan"}

      iex> WuunderUtils.Maps.put_if_present(%{street: "Straat"}, :street, nil)
      %{street: "Straat"}

      iex> WuunderUtils.Maps.put_if_present(%{street: "Straat"}, :street, "     ")
      %{street: "Straat"}

  """
  @spec put_if_present(map(), map_key(), any()) :: map
  def put_if_present(params, key, value) when is_map(params) and is_valid_map_key(key),
    do: put_when(params, Presence.present?(value), key, value)

  @doc """
  Only puts value in map when value is actually nil (not the same as empty)

  ## Examples

      iex> WuunderUtils.Maps.put_if_not_nil(%{street: "Straat"}, :street, "Laan")
      %{street: "Laan"}

      iex> WuunderUtils.Maps.put_if_not_nil(%{street: "Straat"}, :street, nil)
      %{street: "Straat"}

      iex> WuunderUtils.Maps.put_if_not_nil(%{street: "Straat"}, :street, "     ")
      %{street: "     "}
  """
  @spec put_if_not_nil(map(), map_key(), any()) :: map()
  def put_if_not_nil(map, key, nil) when is_map(map) and is_valid_map_key(key), do: map

  def put_if_not_nil(map, key, value) when is_map(map) and is_valid_map_key(key),
    do: Map.put(map, key, value)

  @doc """
  Tests if the map or struct is present

  ## Examples

      iex> WuunderUtils.Maps.present?(nil)
      false

      iex> WuunderUtils.Maps.present?(%{})
      false

      iex> WuunderUtils.Maps.present?(%{a: 1})
      true

      iex> WuunderUtils.Maps.present?(%TestStruct{})
      true

      iex> WuunderUtils.Maps.present?(%Ecto.Association.NotLoaded{})
      false

  """
  @spec present?(Ecto.Association.NotLoaded.t() | nil | map()) :: boolean()
  def present?(%Ecto.Association.NotLoaded{}), do: false
  def present?(nil), do: false
  def present?(value) when is_map(value) and map_size(value) == 0, do: false
  def present?(value) when is_map(value) and map_size(value) > 0, do: true

  @doc """
  Flattens a map. This results in a map that just contains one level

  ## Options

  - key_separator (default .)
  - underscore_key (default true)
  - list_index_start (default 1)

  ## Example

      iex> WuunderUtils.Maps.flatten_map(%{
      ...>   test: "123",
      ...>   order_lines: [
      ...>     %{sku: "123", description: "test"},
      ...>     %{sku: "456", description: "test 2"}
      ...>   ],
      ...>   meta: %{
      ...>     data: "test"
      ...>   }
      ...> })
      %{
        "test" => "123",
        "order_lines.1.sku" => "123",
        "order_lines.1.description" => "test",
        "order_lines.2.sku" => "456",
        "order_lines.2.description" => "test 2",
        "meta.data" => "test"
      }

      iex> WuunderUtils.Maps.flatten_map(
      ...>   %{
      ...>     test: "123",
      ...>     order_lines: [
      ...>       %{sku: "123", description: "test"},
      ...>       %{sku: "456", description: "test 2"}
      ...>     ],
      ...>     meta: %{
      ...>       data: "test"
      ...>     }
      ...>   },
      ...>   key_separator: "_",
      ...>   list_index_start: 0
      ...> )
      %{
        "test" => "123",
        "order_lines_0_sku" => "123",
        "order_lines_0_description" => "test",
        "order_lines_1_sku" => "456",
        "order_lines_1_description" => "test 2",
        "meta_data" => "test"
      }

  """
  @spec flatten_map(map(), Keyword.t()) :: map()
  def flatten_map(map, options \\ []) when is_map(map) and is_list(options),
    do:
      map
      |> from_struct()
      |> flatten_map(%{}, "", options)

  @spec flatten_map(map() | list(), map(), String.t(), Keyword.t()) :: map()
  def flatten_map(map_or_list, %{} = initial_map, key_prefix, options)
      when (is_map(map_or_list) or is_list(map_or_list)) and is_binary(key_prefix) and
             is_list(options) do
    underscore_key = Keyword.get(options, :underscore_key, true)
    key_separator = Keyword.get(options, :key_separator, ".")
    list_index_start = Keyword.get(options, :list_index_start, 1)

    Enum.reduce(map_or_list, initial_map, fn {key, value}, flat_map ->
      key = if underscore_key, do: Macro.underscore("#{key}"), else: "#{key}"
      new_key = "#{key_prefix}#{key}"

      cond do
        is_map(value) ->
          flatten_map(value, flat_map, "#{new_key}#{key_separator}", options)

        is_list(value) ->
          value
          |> Enum.with_index()
          |> Enum.map(&{elem(&1, 1) + list_index_start, elem(&1, 0)})
          |> flatten_map(flat_map, "#{new_key}#{key_separator}", options)

        true ->
          Map.put(flat_map, "#{new_key}", value)
      end
    end)
  end

  @doc """
  Deletes a list of keys from a map (and all nested maps, lists)
  Usefull when you want to scrub out IDs for instance.

  ## Examples

      iex> WuunderUtils.Maps.delete_all(
      ...>   %{
      ...>      shipment: %{
      ...>        id: "shipment-id",
      ...>        wuunder_id: "WUUNDERID"
      ...>      },
      ...>      order_lines: [
      ...>        %{id: "123", sku: "SKU01"},
      ...>        %{id: "456", sku: "SKU02"},
      ...>        %{id: "789", sku: "SKU03"}
      ...>      ],
      ...>      meta: %{
      ...>        configuration_id: "nothing"
      ...>      }
      ...>   },
      ...>   [:id, :configuration_id]
      ...> )
      %{
        meta: %{},
        order_lines: [%{sku: "SKU01"}, %{sku: "SKU02"}, %{sku: "SKU03"}],
        shipment: %{wuunder_id: "WUUNDERID"}
      }

  """
  @spec delete_all(map(), list(String.t() | atom())) :: map()
  def delete_all(map, keys_to_delete) when is_map(map) and is_list(keys_to_delete) do
    Enum.reduce(map, map, fn {key, value}, new_map ->
      if is_map(value) || is_list(value) do
        Map.put(new_map, key, delete_all(value, keys_to_delete))
      else
        Enum.reduce(keys_to_delete, new_map, &Map.delete(&2, &1))
      end
    end)
  end

  def delete_all(list, keys_to_delete) when is_list(list) and is_list(keys_to_delete) do
    Enum.map(list, fn value ->
      if is_map(value) || is_list(value) do
        delete_all(value, keys_to_delete)
      else
        value
      end
    end)
  end

  defp transform_struct(module, struct, transform) do
    if has_ecto_schema?(module) do
      module
      |> get_ecto_schema_fields()
      |> Enum.reduce(%{}, fn field, result ->
        value = Map.get(struct, field)

        Map.put(result, field, from_struct(value, transform))
      end)
    else
      struct
      |> Map.from_struct()
      |> Map.delete(:__meta__)
      |> from_struct(transform)
    end
  end

  defp has_ecto_schema?(module) when is_atom(module),
    do: Kernel.function_exported?(module, :__schema__, 1)

  defp get_ecto_schema_fields(module) when is_atom(module), do: module.__schema__(:fields)

  defp default_struct_transforms do
    [
      {Date, &to_string/1},
      {DateTime, &to_string/1},
      {Decimal, &to_string/1},
      {NaiveDateTime, &to_string/1},
      {Time, &to_string/1}
    ]
  end
end
