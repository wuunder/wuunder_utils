defmodule WuunderUtils.MapTest do
  use ExUnit.Case

  defmodule TestStruct do
    defstruct first_name: "",
              last_name: "",
              weight: nil,
              date_of_birth: nil,
              time_of_death: nil,
              country: nil,
              address: nil
  end

  defmodule TestStruct2 do
    defstruct code: ""
  end

  defmodule TestSchema do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field(:street, :string)
      field(:number, :integer)
      field(:zipcode, :string)
    end
  end

  doctest WuunderUtils.Map
end
