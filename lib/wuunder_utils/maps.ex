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

      iex> WuunderUtils.Maps.get(%{value: 20}, :value)
      20

      iex> WuunderUtils.Maps.get(%{"value" => 20}, :value)
      20

      iex> WuunderUtils.Maps.get(%{value: 20}, "value")
      20

      iex> WuunderUtils.Maps.get(%{value: 20}, "non-existent")
      nil

      iex> WuunderUtils.Maps.get(%{value: 20}, :weight)
      nil

      iex> WuunderUtils.Maps.get(%{value: 20}, :weight, 350)
      350

      iex> WuunderUtils.Maps.get(%{value: 20}, "currency", "EUR")
      "EUR"

      iex> WuunderUtils.Maps.get([name: "Henk", name: "Kees", last_name: "Jansen"], "name")
      "Henk"

      iex> WuunderUtils.Maps.get(["a", "b", "c"], 1)
      "b"


      iex> WuunderUtils.Maps.get(["a", "b", "c"], 3, "d")
      "d"

      iex> WuunderUtils.Maps.get({"a", "b", "c"}, 1)
      "b"

      iex> WuunderUtils.Maps.get({"a", "b", "c"}, 3, "d")
      "d"

  """
  @spec get(any(), map_key() | non_neg_integer(), any()) :: any()
  def get(map, key, default \\ nil)

  def get(list, index, default) when is_list(list) and is_number(index),
    do: Enum.at(list, index, default)

  def get(list, key, default) when is_list(list) and is_binary(key) do
    atom_key = get_safe_key(key)

    if is_atom(atom_key) && Keyword.keyword?(list) do
      Keyword.get(list, atom_key, default)
    else
      default
    end
  end

  def get(tuple, index, _default)
      when is_tuple(tuple) and is_number(index) and index < tuple_size(tuple),
      do: elem(tuple, index)

  def get(tuple, index, default)
      when is_tuple(tuple) and is_number(index) and index >= tuple_size(tuple),
      do: default

  def get(map, key, default)
      when is_map(map) and is_valid_map_atom_key(key) do
    if Map.has_key?(map, key) do
      Map.get(map, key)
    else
      Map.get(map, "#{key}", default)
    end
  end

  def get(map, key, default) when is_map(map) and is_valid_map_binary_key(key) do
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
      ...>       %{type: "hobby", name: "painting", grades: {"A+", "C"}}
      ...>     ]
      ...>   }
      ...> }
      ...>
      ...> WuunderUtils.Maps.deep_get(person, [:country, :code])
      "NL"
      iex> WuunderUtils.Maps.deep_get(person, "country.code")
      "NL"
      iex> WuunderUtils.Maps.deep_get(person, [:address, :company])
      %Company{name: "Wuunder"}
      iex> WuunderUtils.Maps.deep_get(person, [:address, :company, :name])
      "Wuunder"
      iex> WuunderUtils.Maps.deep_get(person, [:meta, :skills])
      ["programmer", "manager", %{name: "painting", type: "hobby", grades: {"A+", "C"}}]
      iex> WuunderUtils.Maps.deep_get(person, [:meta, :skills, 1])
      "manager"
      iex> WuunderUtils.Maps.deep_get(person, "meta.skills.1")
      "manager"
      iex> WuunderUtils.Maps.deep_get(person, [:meta, :skills, 2, :type])
      "hobby"
      iex> WuunderUtils.Maps.deep_get(person, "meta.skills.2.type")
      "hobby"
      iex> WuunderUtils.Maps.deep_get(person, "meta.skills.2.non_existent")
      nil
      iex> WuunderUtils.Maps.deep_get(person, "meta.skills.2.non_existent", "default")
      "default"
      iex> WuunderUtils.Maps.deep_get(person, "meta.skills.2.grades.0")
      "A+"
      iex> WuunderUtils.Maps.deep_get(person, "meta.skills.2.grades.2", "none")
      "none"

      iex> keyword_list = [
      ...>   name: "Henk",
      ...>   last_name: "Jansen",
      ...>   addresses: [
      ...>     %{"street" => "Laan", "number" => 1},
      ...>     %{"street" => "Straat", "number" => 1337}
      ...>   ]
      ...> ]
      ...>
      iex> WuunderUtils.Maps.deep_get(keyword_list, "name")
      "Henk"
      iex> WuunderUtils.Maps.deep_get(keyword_list, "addresses")
      [%{"number" => 1, "street" => "Laan"}, %{"number" => 1337, "street" => "Straat"}]
      iex> WuunderUtils.Maps.deep_get(keyword_list, "addresses.0")
      %{"number" => 1, "street" => "Laan"}
      iex> WuunderUtils.Maps.deep_get(keyword_list, "addresses.1.street")
      "Straat"
      iex> WuunderUtils.Maps.deep_get(keyword_list, "addresses.1.other_field", "none")
      "none"
      iex> WuunderUtils.Maps.deep_get(keyword_list, "addresses.2.other_field", "none")
      nil

  """
  @spec deep_get(any(), list(atom()) | String.t()) :: any()
  def deep_get(value, path, default \\ nil)

  def deep_get(value, path, default) when is_binary(path) do
    keys = keys_from_path(path)

    deep_get(value, keys, default)
  end

  def deep_get(nil, _keys, _default), do: nil

  def deep_get(value, [], _default), do: value

  def deep_get(value, _keys, _default)
      when not is_map(value) and not is_list(value) and not is_tuple(value),
      do: nil

  def deep_get(map_list_or_tuple, [key | rest], default)
      when is_map(map_list_or_tuple) or is_list(map_list_or_tuple) or is_tuple(map_list_or_tuple) do
    map_list_or_tuple
    |> get(key, default)
    |> deep_get(rest, default)
  end

  def deep_get(nil, keys, _default) when is_list(keys), do: nil

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
      ...> WuunderUtils.Maps.deep_get_values(
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
  @spec deep_get_values(map() | struct() | list(), list()) :: map()
  def deep_get_values(value, fields) do
    initial_map =
      Enum.reduce(fields, %{}, fn field, initial_map ->
        keys =
          field
          |> get_keys()
          |> ensure_zero_index()

        Map.merge(initial_map, new(keys))
      end)

    Enum.reduce(fields, initial_map, fn field, final_map ->
      value = deep_get(value, field)

      keys =
        field
        |> get_keys()
        |> ensure_zero_index()

      deep_put(final_map, keys, value)
    end)
  end

  @doc """
  Generates an empty map and list from a given set of keys

  ## Examples

      iex> WuunderUtils.Maps.new([:person, :name, :meta, 0, :hobby, :type])
      %{"person" => %{"name" => %{"meta" => [%{"hobby" => %{"type" => %{}}}]}}}

      iex> WuunderUtils.Maps.new([:person, :name, :meta, 0, :hobbies, 0, :type])
      %{"person" => %{"name" => %{"meta" => [%{"hobbies" => [%{"type" => %{}}]}]}}}

  """
  @spec new(String.t() | list()) :: map()
  def new(path) when is_binary(path) do
    path
    |> keys_from_path()
    |> new()
  end

  def new(keys) when is_list(keys), do: new(%{}, keys)

  @spec new(map() | list(), list()) :: map() | list()
  def new(list, [key | rest]) when is_list(list) do
    if is_integer(key) do
      [new(rest)]
    else
      [%{"key" => new(rest)}]
    end
  end

  def new(map, [key | rest]) when is_map(map) do
    if is_integer(key) do
      [new(rest)]
    else
      Map.put(map, "#{key}", new(rest))
    end
  end

  def new(map_or_list, []), do: map_or_list

  @doc """
  Acts as an IndifferentMap. Put a key/value regardless of the key type. If the map
  contains keys as atoms, the value will be stored as atom: value. If the map contains
  strings as keys it will store the value as binary: value

  ## Examples

      iex> WuunderUtils.Maps.put(%{value: 20}, :weight, 350)
      %{value: 20, weight: 350}

      iex> WuunderUtils.Maps.put(["a", "b", "c"], 1, "d")
      ["a", "d", "c"]

      iex> WuunderUtils.Maps.put(["a", "b", "c"], 4, "d")
      ["a", "b", "c"]

      iex> WuunderUtils.Maps.put(%{value: 20, weight: 200}, "weight", 350)
      %{value: 20, weight: 350}

      iex> WuunderUtils.Maps.put(%{value: 20}, "weight", 350)
      %{:value => 20, "weight" => 350}

      iex> WuunderUtils.Maps.put(%{"weight" => 350}, :value, 25)
      %{"weight" => 350, "value" => 25}

      iex> WuunderUtils.Maps.put(%{"weight" => 350}, "value", 25)
      %{"weight" => 350, "value" => 25}

  """
  @spec put(map() | struct() | list() | nil, String.t() | atom(), any()) ::
          map() | struct() | list()
  def put(map, key, value)
      when is_map(map) and is_valid_map_atom_key(key) do
    if Map.has_key?(map, key) || only_atom_keys?(map) do
      Map.put(map, key, value)
    else
      Map.put(map, "#{key}", value)
    end
  end

  def put(list, index, value) when is_list(list) and is_integer(index),
    do: List.replace_at(list, index, value)

  def put(map, key, value) when is_map(map) and is_valid_map_binary_key(key) do
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
      iex> WuunderUtils.Maps.deep_put(person, [:first_name], "Piet")
      %Person{person | first_name: "Piet"}
      iex> WuunderUtils.Maps.deep_put(person, [:country, :code], "US")
      %Person{person | country: %Country{code: "US"}}
      iex> WuunderUtils.Maps.deep_put(person, [:meta, :skills, 1], "vaultdweller")
      %Person{person | meta: %{skills: ["programmer", "vaultdweller", %{name: "painting", type: "hobby"}]}}
      iex> WuunderUtils.Maps.deep_put(person, [:meta, :skills, 2, :name], "walking")
      %Person{person | meta: %{skills: ["programmer", "manager", %{name: "walking", type: "hobby"}]}}
      iex> WuunderUtils.Maps.deep_put(person, "meta.skills.2.name", "walking")
      %Person{person | meta: %{skills: ["programmer", "manager", %{name: "walking", type: "hobby"}]}}

  """
  @spec deep_put(
          map() | struct() | list() | nil,
          list(atom() | String.t()) | String.t(),
          any()
        ) :: any()
  def deep_put(value, path, value_to_set)
      when (is_map(value) or is_list(value)) and is_binary(path) do
    keys = keys_from_path(path)

    deep_put(value, keys, value_to_set)
  end

  def deep_put(map_or_list, [key | rest], value_to_set)
      when is_map(map_or_list) or is_list(map_or_list) do
    current = get(map_or_list, key)
    put(map_or_list, key, deep_put(current, rest, value_to_set))
  end

  def deep_put(_map_or_list, [], value_to_set), do: value_to_set

  @doc """
  Removes a key from a map. Doesn't matter if the key is an atom or string

  ## Examples

      iex> WuunderUtils.Maps.delete(%{length: 255, weight: 100}, :length)
      %{weight: 100}

      iex> WuunderUtils.Maps.delete(%{length: 255, weight: 100}, "length")
      %{weight: 100}

      iex> WuunderUtils.Maps.delete(%{"value" => 50, "currency" => "EUR"}, "currency")
      %{"value" => 50}

      iex> WuunderUtils.Maps.delete(%{"value" => 50, "currency" => "EUR"}, :currency)
      %{"value" => 50}

      iex> WuunderUtils.Maps.delete(["a", "b", "c"], 1)
      ["a", "c"]

      iex> WuunderUtils.Maps.delete({"a", "b", "c"}, 1)
      {"a", "c"}

      iex> country = %Country{code: "NL"}
      ...>
      ...> WuunderUtils.Maps.delete(country, :code)
      %Country{code: ""}

      iex> country = %Country{code: "NL"}
      ...>
      ...> WuunderUtils.Maps.delete(country, "code")
      %Country{code: ""}

      iex> country = %Country{code: "NL"}
      ...>
      ...> WuunderUtils.Maps.delete(country, "does_not_exist")
      %Country{code: "NL"}

  """
  @spec delete(any(), map_key() | non_neg_integer()) :: any()
  def delete(%module{} = struct, key)
      when is_struct(struct) and is_valid_map_atom_key(key) do
    default = struct(module, %{})

    if Map.has_key?(default, key) do
      put(struct, key, Map.get(default, key))
    else
      struct
    end
  end

  def delete(struct, key) when is_struct(struct) and is_valid_map_binary_key(key) do
    atom_key = get_safe_key(key)

    if Map.has_key?(struct, atom_key) do
      delete(struct, atom_key)
    else
      struct
    end
  end

  def delete(map, key) when is_map(map) and is_valid_map_atom_key(key) do
    if only_atom_keys?(map) do
      Map.delete(map, key)
    else
      Map.delete(map, "#{key}")
    end
  end

  def delete(tuple, index)
      when is_tuple(tuple) and is_number(index) and index < tuple_size(tuple),
      do: Tuple.delete_at(tuple, index)

  def delete(tuple, index)
      when is_tuple(tuple) and is_number(index) and index >= tuple_size(tuple),
      do: tuple

  def delete(list, index) when is_list(list) and is_number(index) and index < length(list),
    do: List.delete_at(list, index)

  def delete(list, index) when is_list(list) and is_number(index) and index >= length(list),
    do: list

  def delete(map, key) when is_map(map) and is_valid_map_binary_key(key) do
    atom_key = get_safe_key(key)

    if Map.has_key?(map, atom_key) do
      Map.delete(map, atom_key)
    else
      Map.delete(map, key)
    end
  end

  @doc """
  Removes a deeply nested set of keys

  ## Examples

      iex> WuunderUtils.Maps.deep_delete(%{"data" => [%{"name" => "Piet"}, %{"name" => "Henk"}]}, "data.0.name")
      %{"data" => [%{}, %{"name" => "Henk"}]}

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
      ...>       %{type: "hobby", name: "painting", grades: {"A+", "C"}}
      ...>     ]
      ...>   }
      ...> }
      ...>
      ...> WuunderUtils.Maps.deep_delete(person, [:country, :code])
      %Person{
        country: %Country{code: ""},
        address: %Address{
          street: "Teststreet",
          company: %Company{name: "Wuunder"}
        },
        meta: %{
          skills: [
            "programmer",
            "manager",
            %{type: "hobby", name: "painting", grades: {"A+", "C"}}
          ]
        }
      }
      iex> WuunderUtils.Maps.deep_delete(person, "meta.skills.1")
      %Person{
        country: %Country{code: "NL"},
        address: %Address{
          street: "Teststreet",
          company: %Company{name: "Wuunder"}
        },
        meta: %{
          skills: [
            "programmer",
            %{type: "hobby", name: "painting", grades: {"A+", "C"}}
          ]
        }
      }
  """
  @spec deep_delete(any(), list(atom()) | String.t()) :: any()
  def deep_delete(value, path) when is_binary(path) do
    keys = keys_from_path(path)
    deep_delete(value, keys)
  end

  def deep_delete(nil, _keys), do: nil

  def deep_delete(value, []), do: value

  def deep_delete(value, _keys)
      when not is_map(value) and not is_list(value) and not is_tuple(value),
      do: nil

  def deep_delete(map_list_or_tuple, [key])
      when is_map(map_list_or_tuple) or is_list(map_list_or_tuple) or is_tuple(map_list_or_tuple),
      do: delete(map_list_or_tuple, key)

  def deep_delete(map_list_or_tuple, [_head | _tail] = keys)
      when is_map(map_list_or_tuple) or is_list(map_list_or_tuple) or is_tuple(map_list_or_tuple) do
    before_last_key = Enum.slice(keys, 0..-2//1)
    last_key = List.last(keys)

    new_value =
      map_list_or_tuple
      |> deep_get(before_last_key)
      |> delete(last_key)

    deep_put(map_list_or_tuple, before_last_key, new_value)
  end

  def deep_delete(nil, keys) when is_list(keys), do: nil

  @doc """
  Tests if the given map only consists of atom keys

  ## Examples

      iex> WuunderUtils.Maps.only_atom_keys?(%{a: 1, b: 2})
      true

      iex> WuunderUtils.Maps.only_atom_keys?(%{:a => 1, "b" => 2})
      false

      iex> WuunderUtils.Maps.only_atom_keys?(%{"a" => 1, "b" => 2})
      false

  """
  @spec only_atom_keys?(map() | struct()) :: boolean()
  def only_atom_keys?(struct) when is_struct(struct), do: true

  def only_atom_keys?(map) when is_map(map) do
    map
    |> Map.keys()
    |> Enum.all?(&is_atom/1)
  end

  @doc """
  Maps a given field from given (if not in map)

  ## Examples

      iex> WuunderUtils.Maps.rename_key(%{country: "NL"}, :country, :country_code)
      %{country_code: "NL"}

      iex> WuunderUtils.Maps.rename_key(%{"country" => "NL"}, :country, :country_code)
      %{"country_code" => "NL"}

      iex> WuunderUtils.Maps.rename_key(%{street_name: "Straatnaam"}, :street, :street_address)
      %{street_name: "Straatnaam"}

  """
  @spec rename_key(map(), atom(), atom()) :: map()
  def rename_key(map, from, to)
      when is_map(map) and is_valid_map_atom_key(from) and is_valid_map_atom_key(to) do
    from_key = if Enum.empty?(map) || only_atom_keys?(map), do: from, else: "#{from}"
    to_key = if Enum.empty?(map) || only_atom_keys?(map), do: to, else: "#{to}"

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

      iex> WuunderUtils.Maps.rename_keys(%{country: "NL", street: "Straat", number: 666}, %{country: :country_code, street: :street_name, number: :house_number})
      %{country_code: "NL", house_number: 666, street_name: "Straat"}

  """
  @spec rename_keys(map(), map()) :: map()
  def rename_keys(map, aliasses),
    do:
      Enum.reduce(Map.keys(aliasses), map, fn key, alias_params ->
        rename_key(alias_params, key, Map.get(aliasses, key))
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
    do: put(map, key, value)

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

      iex> WuunderUtils.Maps.flatten(%{
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

      iex> WuunderUtils.Maps.flatten({1, 2, 3})
      %{
        "1" => 1,
        "2" => 2,
        "3" => 3,
      }

      iex> WuunderUtils.Maps.flatten([
      ...>     %{sku: "123", description: "test"},
      ...>     %{sku: "456", description: "test 2"}
      ...> ])
      %{
        "1.sku" => "123",
        "1.description" => "test",
        "2.sku" => "456",
        "2.description" => "test 2"
      }

      iex> WuunderUtils.Maps.flatten(
      ...>   %{
      ...>     test: "123",
      ...>     order_lines: [
      ...>       %{sku: "123", description: "test"},
      ...>       %{sku: "456", description: "test 2"}
      ...>     ],
      ...>     meta: %{
      ...>       data: "test"
      ...>     },
      ...>     tuple: {1, 2, 3}
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
        "tuple_0" => 1,
        "tuple_1" => 2,
        "tuple_2" => 3,
        "meta_data" => "test"
      }
  """
  @spec flatten(map() | list() | tuple()) :: map()
  def flatten(map_list_or_tuple), do: flatten(map_list_or_tuple, [])

  @spec flatten(map() | list() | tuple(), Keyword.t()) :: map()
  def flatten(map, options) when is_map(map) and not is_struct(map) and is_list(options),
    do: flatten(map, %{}, "", options)

  def flatten(list, options) when is_list(list) and is_list(options),
    do: flatten_list(list, %{}, "", options)

  def flatten(tuple, options) when is_tuple(tuple) and is_list(options),
    do: flatten_tuple(tuple, %{}, "", options)

  @spec flatten(map() | list() | tuple(), map(), String.t(), Keyword.t()) :: map()
  def flatten(tuple, %{} = initial_map, key_prefix, options)
      when is_tuple(tuple) and
             is_binary(key_prefix) and
             is_list(options),
      do: flatten(Tuple.to_list(tuple), initial_map, key_prefix, options)

  def flatten(map_or_list, %{} = initial_map, key_prefix, options)
      when (is_map(map_or_list) or is_list(map_or_list)) and
             is_binary(key_prefix) and
             is_list(options) do
    underscore_key = Keyword.get(options, :underscore_key, true)
    key_separator = Keyword.get(options, :key_separator, ".")

    Enum.reduce(map_or_list, initial_map, fn {key, value}, flat_map ->
      key = if underscore_key, do: Macro.underscore("#{key}"), else: "#{key}"

      new_key = "#{key_prefix}#{key}"
      prefix = "#{new_key}#{key_separator}"

      cond do
        is_map(value) -> flatten(value, flat_map, prefix, options)
        is_list(value) -> flatten_list(value, flat_map, prefix, options)
        is_tuple(value) -> flatten_tuple(value, flat_map, prefix, options)
        true -> Map.put(flat_map, "#{new_key}", value)
      end
    end)
  end

  @spec flatten_list(list(), map(), String.t(), Keyword.t()) :: map()
  defp flatten_list(list, initial_map, prefix, options) do
    list_index_start = Keyword.get(options, :list_index_start, 1)

    list
    |> Enum.with_index(fn element, index -> {index + list_index_start, element} end)
    |> flatten(initial_map, prefix, options)
  end

  defp flatten_tuple(tuple, initial_map, prefix, options),
    do: flatten_list(Tuple.to_list(tuple), initial_map, prefix, options)

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

  @doc """
  Trims an incoming map/list/tuple. Removes all keys that have a `nil` value. Structs with an empty value
  will reset to the default value. Items in lists and tuples that contain nil values will be deleted.

  ## Examples

        iex> WuunderUtils.Maps.delete_empty(%{name: nil, last_name: "Jansen"})
        %{last_name: "Jansen"}

        iex> WuunderUtils.Maps.delete_empty(%{name: nil, last_name: nil})
        nil

        iex> WuunderUtils.Maps.delete_empty({1, 2, nil, 3, 4})
        {1, 2, 3, 4}

        iex> WuunderUtils.Maps.delete_empty([1, 2, nil, 3, 4])
        [1, 2, 3, 4]

        iex> WuunderUtils.Maps.delete_empty(%{items: [%{a: nil, b: nil}, %{a: 1, b: 2}]})
        %{items: [%{a: 1, b: 2}]}

        iex> WuunderUtils.Maps.delete_empty(%{items: [%{a: [1, nil, %{x: 1337, y: {1, nil, 2, {nil, nil}}}], b: nil}, %{a: 1, b: 2}]})
        %{items: [%{a: [1, %{y: {1, 2}, x: 1337}]}, %{a: 1, b: 2}]}
  """
  @spec delete_empty(any()) :: any()
  def delete_empty(value) when is_map(value) do
    new_map =
      value
      |> Map.keys()
      |> Enum.reduce(value, fn key, new_map ->
        value = Map.get(new_map, key)
        new_value = delete_empty(value)

        if is_nil(new_value) do
          delete(new_map, key)
        else
          put(new_map, key, new_value)
        end
      end)

    cond do
      is_struct(new_map) -> new_map
      is_map(new_map) && Enum.empty?(Map.keys(new_map)) -> nil
      true -> new_map
    end
  end

  def delete_empty(list) when is_list(list) do
    new_list =
      list
      |> Enum.map(&delete_empty/1)
      |> Enum.reject(&is_nil/1)

    if Enum.any?(new_list) do
      new_list
    else
      nil
    end
  end

  def delete_empty(tuple) when is_tuple(tuple) do
    new_tuple =
      tuple
      |> Tuple.to_list()
      |> Enum.map(&delete_empty/1)
      |> Enum.reject(&is_nil/1)

    if Enum.any?(new_tuple) do
      List.to_tuple(new_tuple)
    else
      nil
    end
  end

  def delete_empty(value), do: value

  @doc """
  Maps a given function over entire structure (map/list/struct/tuple)

  ## Examples

        iex> WuunderUtils.Maps.map_all(%{name: " test ", data: ["some item", "other item   ", %{x: "  value"}]}, &WuunderUtils.Presence.trim/1)
        %{data: ["some item", "other item", %{x: "value"}], name: "test"}
  """
  @spec map_all(any(), function()) :: any()
  def map_all(value, map_fn) when is_map(value) and is_function(map_fn) do
    value
    |> Map.keys()
    |> Enum.reduce(value, fn key, new_map ->
      value = Map.get(new_map, key)
      new_value = map_all(value, map_fn)

      put(new_map, key, new_value)
    end)
  end

  def map_all(values, map_fn) when is_list(values) and is_function(map_fn),
    do: Enum.map(values, &map_all(&1, map_fn))

  def map_all(values, map_fn) when is_tuple(values) and is_function(map_fn) do
    values
    |> Tuple.to_list()
    |> map_all(map_fn)
    |> List.to_tuple()
  end

  def map_all(value, map_fn), do: map_fn.(value)

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
