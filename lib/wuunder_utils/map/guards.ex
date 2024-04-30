defmodule WuunderUtils.Map.Guards do
  defguard is_valid_map_atom_key(key) when is_atom(key) and is_nil(key) == false
  defguard is_valid_map_binary_key(key) when is_binary(key) and key != ""
  defguard is_valid_map_key(key) when is_binary(key) or (is_atom(key) and is_nil(key) == false)
end
