defmodule WuunderUtils.ResultTest do
  use ExUnit.Case

  defmodule Shipment do
    use Ecto.Schema

    embedded_schema do
      field(:weight, :integer, default: 0)
    end
  end

  doctest WuunderUtils.Result
end
