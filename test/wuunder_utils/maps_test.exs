defmodule WuunderUtils.MapsTest do
  use ExUnit.Case

  defmodule Person do
    defstruct first_name: "",
              last_name: "",
              weight: nil,
              date_of_birth: nil,
              time_of_death: nil,
              country: nil,
              address: nil,
              meta: %{}
  end

  defmodule Country do
    defstruct code: ""
  end

  defmodule Company do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field(:name, :string)
    end
  end

  defmodule Address do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field(:street, :string)
      field(:number, :integer)
      field(:zipcode, :string)
      embeds_one(:company, Company, on_replace: :delete)
    end
  end

  doctest WuunderUtils.Maps
end
