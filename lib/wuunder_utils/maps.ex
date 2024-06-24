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
  Note: This function does not generate new atoms on the fly.

  ## Examples

      iex> WuunderUtils.Maps.get_field(%{value: 20}, :value)
      20

      iex> WuunderUtils.Maps.get_field(%{"value" => 20}, :value)
      20

      iex> WuunderUtils.Maps.get_field(%{value: 20}, "value")
      20

      iex> WuunderUtils.Maps.get_field(%{value: 20}, "non-existent")
      nil

      iex> WuunderUtils.Maps.get_field(%{value: 20}, :weight)
      nil

      iex> WuunderUtils.Maps.get_field(%{value: 20}, :weight, 350)
      350

      iex> WuunderUtils.Maps.get_field(%{value: 20}, "currency", "EUR")
      "EUR"

      iex> WuunderUtils.Maps.get_field(["a", "b", "c"], 1)
      "b"

      iex> WuunderUtils.Maps.get_field(["a", "b", "c"], 3, "d")
      "d"

  """
  @spec get_field(map() | list(), map_key() | non_neg_integer(), any()) :: any()
  def get_field(map, key, default \\ nil)

  def get_field(map, index, default) when is_list(map) and is_number(index) do
    Enum.at(map, index, default)
  end

  def get_field(map, key, default)
      when is_map(map) and is_valid_map_atom_key(key) do
    if Map.has_key?(map, key) do
      Map.get(map, key)
    else
      Map.get(map, "#{key}", default)
    end
  end

  def get_field(map, key, default) when is_map(map) and is_valid_map_binary_key(key) do
    atom_key = get_safe_key(key)

    if is_atom(atom_key) && Map.has_key?(map, atom_key) do
      Map.get(map, atom_key)
    else
      Map.get(map, key, default)
    end
  end

  @doc """
  Acts as Kernel.get_in but can also be used on Structs.
  Has a lot of more extra functionalities:
  - You can access lists (nested too)
  - You can use mixed keys, they can be Atoms or Strings
  - You can use a list to access the properties or a string representation

  ## Examples

      iex> person = %Person{
      ...>   country: %Country{code: "NL"},
      ...>   address: %Address{
      ...>     street: "Teststreet",
      ...>     company: %Company{name: "Wuunder"}
      ...>   },
      ...>   meta: %{
      ...>     skills: [
      ...>       "programmer",
      ...>       "manager",
      ...>       %{type: "hobby", name: "painting"}
      ...>     ]
      ...>   }
      ...> }
      ...>
      ...> WuunderUtils.Maps.get_field_in(person, [:country, :code])
      "NL"
      iex> WuunderUtils.Maps.get_field_in(person, "country.code")
      "NL"
      iex> WuunderUtils.Maps.get_field_in(person, [:address, :company])
      %Company{name: "Wuunder"}
      iex> WuunderUtils.Maps.get_field_in(person, [:address, :company, :name])
      "Wuunder"
      iex> WuunderUtils.Maps.get_field_in(person, [:meta, :skills])
      ["programmer", "manager", %{name: "painting", type: "hobby"}]
      iex> WuunderUtils.Maps.get_field_in(person, [:meta, :skills, 1])
      "manager"
      iex> WuunderUtils.Maps.get_field_in(person, "meta.skills.1")
      "manager"
      iex> WuunderUtils.Maps.get_field_in(person, [:meta, :skills, 2, :type])
      "hobby"
      iex> WuunderUtils.Maps.get_field_in(person, "meta.skills.2.type")
      "hobby"

  """
  @spec get_field_in(map() | struct() | nil, list(atom()) | String.t()) :: any()
  def get_field_in(value, path) when is_binary(path) do
    keys = keys_from_path(path)

    get_field_in(value, keys)
  end

  def get_field_in(nil, _keys), do: nil

  def get_field_in(value, []), do: value

  def get_field_in(value, _keys) when not is_map(value) and not is_list(value), do: nil

  def get_field_in(map_or_list, [key | rest]) when is_map(map_or_list) or is_list(map_or_list) do
    map_or_list
    |> get_field(key)
    |> get_field_in(rest)
  end

  def get_field_in(nil, keys) when is_list(keys), do: nil

  @doc """
  Creates a map from a given set of fields. The output will always be a string.

  ## Examples

      iex> person = %Person{
      ...>   country: %Country{code: "NL"},
      ...>   address: %Address{
      ...>     street: "Teststreet",
      ...>     company: %Company{name: "Wuunder"}
      ...>   },
      ...>   meta: %{
      ...>     skills: [
      ...>       "programmer",
      ...>       "manager",
      ...>       %{type: "hobby", name: "painting"}
      ...>     ]
      ...>   }
      ...> }
      ...>
      ...> WuunderUtils.Maps.get_fields_in(
      ...>   person,
      ...>   [
      ...>     [:country, :code],
      ...>     [:address, :street],
      ...>     [:meta, :skills, 2, :type]
      ...>   ]
      ...> )
      %{
        "address" => %{"street" => "Teststreet"},
        "country" => %{"code" => "NL"},
        "meta" => %{
          "skills" => [
            %{"type" => "hobby"}
          ]
        }
      }

  """
  @spec get_fields_in(map() | struct() | list(), list()) :: map()
  def get_fields_in(value, fields) do
    initial_map =
      Enum.reduce(fields, %{}, fn field, initial_map ->
        keys =
          field
          |> get_keys()
          |> ensure_zero_index()

        Map.merge(initial_map, empty_map(keys))
      end)

    Enum.reduce(fields, initial_map, fn field, final_map ->
      value = get_field_in(value, field)

      keys =
        field
        |> get_keys()
        |> ensure_zero_index()

      put_field_in(final_map, keys, value)
    end)
  end

  @doc """
  Generates an empty map and list from a given set of keys

  ## Examples

      iex> WuunderUtils.Maps.empty_map([:person, :name, :meta, 0, :hobby, :type])
      %{"person" => %{"name" => %{"meta" => [%{"hobby" => %{"type" => %{}}}]}}}

      iex> WuunderUtils.Maps.empty_map([:person, :name, :meta, 0, :hobbies, 0, :type])
      %{"person" => %{"name" => %{"meta" => [%{"hobbies" => [%{"type" => %{}}]}]}}}

  """
  @spec empty_map(String.t() | list()) :: map()
  def empty_map(path) when is_binary(path) do
    path
    |> keys_from_path()
    |> empty_map()
  end

  def empty_map(keys) when is_list(keys), do: empty_map(%{}, keys)

  @spec empty_map(map() | list(), list()) :: map() | list()
  def empty_map(list, [key | rest]) when is_list(list) do
    if is_integer(key) do
      [empty_map(rest)]
    else
      [%{"key" => empty_map(rest)}]
    end
  end

  def empty_map(map, [key | rest]) when is_map(map) do
    if is_integer(key) do
      [empty_map(rest)]
    else
      Map.put(map, "#{key}", empty_map(rest))
    end
  end

  def empty_map(map_or_list, []), do: map_or_list

  @doc """
  Acts as an IndifferentMap. Put a key/value regardless of the key type. If the map
  contains keys as atoms, the value will be stored as atom: value. If the map contains
  strings as keys it will store the value as binary: value

  ## Examples

      iex> WuunderUtils.Maps.put_field(%{value: 20}, :weight, 350)
      %{value: 20, weight: 350}

      iex> WuunderUtils.Maps.put_field(["a", "b", "c"], 1, "d")
      ["a", "d", "c"]

      iex> WuunderUtils.Maps.put_field(["a", "b", "c"], 4, "d")
      ["a", "b", "c"]

      iex> WuunderUtils.Maps.put_field(%{value: 20, weight: 200}, "weight", 350)
      %{value: 20, weight: 350}

      iex> WuunderUtils.Maps.put_field(%{value: 20}, "weight", 350)
      %{:value => 20, "weight" => 350}

      iex> WuunderUtils.Maps.put_field(%{"weight" => 350}, :value, 25)
      %{"weight" => 350, "value" => 25}

      iex> WuunderUtils.Maps.put_field(%{"weight" => 350}, "value", 25)
      %{"weight" => 350, "value" => 25}

  """
  @spec put_field(map() | struct() | nil, list(atom()) | String.t() | atom(), any()) :: any()
  def put_field(map, key, value)
      when is_map(map) and is_valid_map_atom_key(key) do
    if Map.has_key?(map, key) || has_only_atom_keys?(map) do
      Map.put(map, key, value)
    else
      Map.put(map, "#{key}", value)
    end
  end

  def put_field(list, index, value) when is_list(list) and is_integer(index) do
    List.replace_at(list, index, value)
  end

  def put_field(map, key, value) when is_map(map) and is_valid_map_binary_key(key) do
    atom_key = get_safe_key(key)

    if Map.has_key?(map, atom_key) do
      Map.put(map, atom_key, value)
    else
      Map.put(map, key, value)
    end
  end

  @doc """
  Acts as Kernel.put-in but can also be used on Structs.
  Has a lot of more extra functionalities:
  - You can access lists (nested too)
  - You can use mixed keys, they can be Atoms or Strings
  - You can use a list to access the properties or a string representation

  ## Examples

      iex> person = %Person{
      ...>   country: %Country{code: "NL"},
      ...>   address: %Address{
      ...>     street: "Teststreet",
      ...>     company: %Company{name: "Wuunder"}
      ...>   },
      ...>   meta: %{
      ...>     skills: [
      ...>       "programmer",
      ...>       "manager",
      ...>       %{type: "hobby", name: "painting"}
      ...>     ]
      ...>   }
      ...> }
      iex> WuunderUtils.Maps.put_field_in(person, [:first_name], "Piet")
      %Person{person | first_name: "Piet"}
      iex> WuunderUtils.Maps.put_field_in(person, [:country, :code], "US")
      %Person{person | country: %Country{code: "US"}}
      iex> WuunderUtils.Maps.put_field_in(person, [:meta, :skills, 1], "vaultdweller")
      %Person{person | meta: %{skills: ["programmer", "vaultdweller", %{name: "painting", type: "hobby"}]}}
      iex> WuunderUtils.Maps.put_field_in(person, [:meta, :skills, 2, :name], "walking")
      %Person{person | meta: %{skills: ["programmer", "manager", %{name: "walking", type: "hobby"}]}}
      iex> WuunderUtils.Maps.put_field_in(person, "meta.skills.2.name", "walking")
      %Person{person | meta: %{skills: ["programmer", "manager", %{name: "walking", type: "hobby"}]}}

  """
  @spec put_field_in(map() | struct() | nil, list(atom()) | String.t(), any()) :: any()
  def put_field_in(value, path, value_to_set)
      when (is_map(value) or is_list(value)) and is_binary(path) do
    keys = keys_from_path(path)

    put_field_in(value, keys, value_to_set)
  end

  def put_field_in(map_or_list, [key | rest], value_to_set)
      when is_map(map_or_list) or is_list(map_or_list) do
    current = get_field(map_or_list, key)
    put_field(map_or_list, key, put_field_in(current, rest, value_to_set))
  end

  def put_field_in(_map_or_list, [], value_to_set), do: value_to_set

  @doc """
  Removes a key from a map. Doesn't matter if the key is an atom or string

  ## Examples

      iex> WuunderUtils.Maps.delete_field(%{length: 255, weight: 100}, :length)
      %{weight: 100}

      iex> WuunderUtils.Maps.delete_field(%{length: 255, weight: 100}, "length")
      %{weight: 100}

      iex> WuunderUtils.Maps.delete_field(%{"value" => 50, "currency" => "EUR"}, "currency")
      %{"value" => 50}

      iex> WuunderUtils.Maps.delete_field(%{"value" => 50, "currency" => "EUR"}, :currency)
      %{"value" => 50}

  """
  @spec delete_field(map(), map_key()) :: map
  def delete_field(map, key) when is_map(map) and is_valid_map_atom_key(key) do
    if has_only_atom_keys?(map) do
      Map.delete(map, key)
    else
      Map.delete(map, "#{key}")
    end
  end

  def delete_field(map, key) when is_map(map) and is_valid_map_binary_key(key) do
    atom_key = get_safe_key(key)

    if Map.has_key?(map, atom_key) do
      Map.delete(map, atom_key)
    else
      Map.delete(map, key)
    end
  end

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

  def has_only_atom_keys?(map) when is_map(map) do
    map
    |> Map.keys()
    |> Enum.all?(&is_atom/1)
  end

  @doc """
  Maps a given field from given (if not in map)

  ## Examples

      iex> WuunderUtils.Maps.alias_field(%{country: "NL"}, :country, :country_code)
      %{country_code: "NL"}

      iex> WuunderUtils.Maps.alias_field(%{"country" => "NL"}, :country, :country_code)
      %{"country_code" => "NL"}

      iex> WuunderUtils.Maps.alias_field(%{street_name: "Straatnaam"}, :street, :street_address)
      %{street_name: "Straatnaam"}

  """
  @spec alias_field(map(), atom(), atom()) :: map()
  def alias_field(map, from, to)
      when is_map(map) and is_valid_map_atom_key(from) and is_valid_map_atom_key(to) do
    from_key = if Enum.empty?(map) || has_only_atom_keys?(map), do: from, else: "#{from}"
    to_key = if Enum.empty?(map) || has_only_atom_keys?(map), do: to, else: "#{to}"

    if is_nil(Map.get(map, from_key)) == false && is_nil(Map.get(map, to_key)) do
      map
      |> Map.put(to_key, Map.get(map, from_key))
      |> Map.delete(from_key)
    else
      Map.delete(map, from_key)
    end
  end

  @doc """
  Mass maps a given input with aliasses

  ## Examples

      iex> WuunderUtils.Maps.alias_fields(%{country: "NL", street: "Straat", number: 666}, %{country: :country_code, street: :street_name, number: :house_number})
      %{country_code: "NL", house_number: 666, street_name: "Straat"}

  """
  @spec alias_fields(map(), map()) :: map()
  def alias_fields(map, aliasses),
    do:
      Enum.reduce(Map.keys(aliasses), map, fn key, alias_params ->
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

      iex> WuunderUtils.Maps.from_struct(%Person{
      ...>   first_name: "Peter",
      ...>   last_name: "Pan",
      ...>   date_of_birth: ~D[1980-01-02],
      ...>   weight: Decimal.new("81.5"),
      ...>   country: %{code: "UK"},
      ...>   time_of_death: ~T[13:37:37]
      ...> })
      %{
        address: nil,
        date_of_birth: "1980-01-02",
        first_name: "Peter",
        last_name: "Pan",
        time_of_death: "13:37:37",
        weight: "81.5",
        country: %{code: "UK"},
        meta: %{}
      }

      iex> WuunderUtils.Maps.from_struct(
      ...>   %Person{
      ...>     first_name: "Peter",
      ...>     last_name: "Pan",
      ...>     date_of_birth: ~D[1980-01-02],
      ...>     weight: Decimal.new("81.5"),
      ...>     country: %Country{code: "UK"},
      ...>     time_of_death: ~T[13:37:37]
      ...>   },
      ...>   transform: [{Country, fn x -> "COUNTRY:" <> x.code end}]
      ...> )
      %{
        address: nil,
        date_of_birth: "1980-01-02",
        first_name: "Peter",
        last_name: "Pan",
        time_of_death: "13:37:37",
        weight: "81.5",
        country: "COUNTRY:UK",
        meta: %{}
      }

      iex> WuunderUtils.Maps.from_struct(
      ...>   %Person{
      ...>     address: %Address{
      ...>       street: "Straat",
      ...>       number: 13,
      ...>       zipcode: "1122AB"
      ...>     },
      ...>     first_name: "Peter",
      ...>     last_name: "Pan",
      ...>     date_of_birth: ~D[1980-01-02],
      ...>     weight: Decimal.new("81.5"),
      ...>     country: %{code: "UK"},
      ...>     time_of_death: ~T[13:37:37]
      ...>   }
      ...> )
      %{
        address: %{company: nil, number: 13, street: "Straat", zipcode: "1122AB"},
        date_of_birth: "1980-01-02",
        first_name: "Peter",
        last_name: "Pan",
        time_of_death: "13:37:37",
        weight: "81.5",
        country: %{code: "UK"},
        meta: %{}
      }

  """
  @spec from_struct(any()) :: any()
  def from_struct(value), do: from_struct(value, transform: [])

  @spec from_struct(any(), list()) :: any()
  def from_struct(value, transform: extra_transformers),
    do: from_struct(value, default_struct_transforms() ++ extra_transformers)

  def from_struct(%module{} = struct, transform) when is_list(transform) do
    transform_fn = Keyword.get(transform, module)

    if is_function(transform_fn, 1) do
      transform_fn.(struct)
    else
      transform_struct(module, struct, transform)
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
  def put_when(map, condition, key, value)
      when is_map(map) and is_function(condition) and is_valid_map_key(key),
      do: put_when(map, !!condition.(), key, value)

  def put_when(map, true, key, value) when is_map(map) and is_valid_map_key(key),
    do: put_field(map, key, value)

  def put_when(map, false, key, _value) when is_map(map) and is_valid_map_key(key),
    do: map

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
  def put_if_present(map, key, value) when is_map(map) and is_valid_map_key(key),
    do: put_when(map, Presence.any?(value), key, value)

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

      iex> WuunderUtils.Maps.any?(nil)
      false

      iex> WuunderUtils.Maps.any?(%{})
      false

      iex> WuunderUtils.Maps.any?(%{a: 1})
      true

      iex> WuunderUtils.Maps.any?(%Person{})
      true

      iex> WuunderUtils.Maps.any?(%Ecto.Association.NotLoaded{})
      false

  """
  @spec any?(Ecto.Association.NotLoaded.t() | nil | map()) :: boolean()
  def any?(%Ecto.Association.NotLoaded{}), do: false
  def any?(nil), do: false
  def any?(value) when is_map(value) and map_size(value) == 0, do: false
  def any?(value) when is_map(value) and map_size(value) > 0, do: true

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

      iex> WuunderUtils.Maps.flatten_map([
      ...>     %{sku: "123", description: "test"},
      ...>     %{sku: "456", description: "test 2"}
      ...> ])
      %{
        "1.sku" => "123",
        "1.description" => "test",
        "2.sku" => "456",
        "2.description" => "test 2"
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
  @spec flatten_map(map() | list()) :: map()
  def flatten_map(map_or_list), do: flatten_map(map_or_list, [])

  @spec flatten_map(map() | list(), Keyword.t()) :: map()
  def flatten_map(map, options) when is_map(map) and not is_struct(map) and is_list(options),
    do: flatten_map(map, %{}, "", options)

  def flatten_map(list, options) when is_list(list) and is_list(options),
    do: flatten_list(list, %{}, "", options)

  @spec flatten_map(map() | list(), map(), String.t(), Keyword.t()) :: map()
  def flatten_map(map_or_list, %{} = initial_map, key_prefix, options)
      when (is_map(map_or_list) or is_list(map_or_list)) and is_binary(key_prefix) and
             is_list(options) do
    underscore_key = Keyword.get(options, :underscore_key, true)
    key_separator = Keyword.get(options, :key_separator, ".")

    Enum.reduce(map_or_list, initial_map, fn {key, value}, flat_map ->
      key = if underscore_key, do: Macro.underscore("#{key}"), else: "#{key}"

      new_key = "#{key_prefix}#{key}"
      prefix = "#{new_key}#{key_separator}"

      cond do
        is_map(value) -> flatten_map(value, flat_map, prefix, options)
        is_list(value) -> flatten_list(value, flat_map, prefix, options)
        true -> Map.put(flat_map, "#{new_key}", value)
      end
    end)
  end

  @spec flatten_list(list(), map(), String.t(), Keyword.t()) :: map()
  defp flatten_list(list, initial_map, prefix, options) do
    list_index_start = Keyword.get(options, :list_index_start, 1)

    list
    |> Enum.with_index(fn element, index -> {index + list_index_start, element} end)
    |> flatten_map(initial_map, prefix, options)
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

      iex> WuunderUtils.Maps.delete_all([
      ...>   %{id: "123", name: "test1"},
      ...>   %{id: "456", name: "test2"},
      ...>   %{id: "789", name: "test3"}
      ...> ], [:id])
      [%{name: "test1"}, %{name: "test2"}, %{name: "test3"}]

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

  defp get_safe_key(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end

  defp keys_from_path(path) do
    path
    |> String.split(".")
    |> Enum.map(fn key ->
      if key =~ ~r/^[0-9]+$/ do
        String.to_integer(key)
      else
        key
      end
    end)
  end

  defp get_keys(field) do
    if is_binary(field) do
      keys_from_path(field)
    else
      field
    end
  end

  defp ensure_zero_index(keys) do
    Enum.map(keys, fn key ->
      if is_integer(key) do
        0
      else
        key
      end
    end)
  end
end
