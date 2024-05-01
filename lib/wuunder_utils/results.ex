defmodule WuunderUtils.Results do
  @moduledoc """
  A set of handy helpers to deal with {:ok, _} or {:error, _} tuples
  """

  @doc """
  Checks if there are no errors and all results are {:ok, ...}

  ## Examples

      iex> WuunderUtils.Results.all_ok?([
      ...>   {:ok, %Shipment{id: 1}},
      ...>   {:ok, %Shipment{id: 2}}
      ...> ])
      true

      iex> WuunderUtils.Results.all_ok?(:ok)
      true

      iex> WuunderUtils.Results.all_ok?({:ok, %Shipment{id: 2}})
      true

      iex> WuunderUtils.Results.all_ok?([{:ok, %Shipment{id: 2}}, {:error, %Shipment{id: 3}}])
      false

  """
  @spec all_ok?(term()) :: boolean()
  def all_ok?(results) when is_list(results), do: Enum.all?(results, &is_ok?/1)

  def all_ok?(results), do: is_ok?(results)

  @doc """
  Checks if all results errored

  ## Examples

      iex> WuunderUtils.Results.all_error?([
      ...>   {:error, %Shipment{id: 1}},
      ...>   {:error, %Shipment{id: 2}}
      ...> ])
      true

      iex> WuunderUtils.Results.all_error?(:error)
      true

      iex> WuunderUtils.Results.all_error?({:error, %Shipment{id: 2}})
      true

      iex> WuunderUtils.Results.all_error?([{:ok, %Shipment{id: 2}}, {:error, %Shipment{id: 3}}])
      false

  """
  @spec all_error?(term()) :: boolean()
  def all_error?(results) when is_list(results), do: Enum.all?(results, &is_error?/1)

  def all_error?(results), do: is_error?(results)

  @doc """
  Checks if there any OKs in the value. Could be a list or a single value.

  ## Examples

      iex> WuunderUtils.Results.has_ok?(:ok)
      true

      iex> WuunderUtils.Results.has_ok?({:ok, "hello world"})
      true

      iex> WuunderUtils.Results.has_ok?([{:ok, "hello world"}, {:error, :faulty}])
      true

      iex> WuunderUtils.Results.has_ok?([{:error, "connection lost"}, {:error, :faulty}])
      false

  """
  @spec has_ok?(term()) :: boolean()
  def has_ok?(results) when is_list(results), do: Enum.any?(results, &is_ok?/1)

  def has_ok?(results), do: is_ok?(results)

  @doc """
  Checks if any items in the list contains an error

  ## Examples

      iex> WuunderUtils.Results.has_error?([
      ...>   {:ok, %Shipment{id: 1}},
      ...>   {:ok, %Shipment{id: 2}},
      ...>   {:error, :creation_error},
      ...>   :error
      ...> ])
      true

      iex> WuunderUtils.Results.has_error?(:error)
      true

      iex> WuunderUtils.Results.has_error?({:error, :creating_error})
      true

      iex> WuunderUtils.Results.has_error?({:ok, %Shipment{id: 1}})
      false

  """
  @spec has_error?(term()) :: boolean()
  def has_error?(results) when is_list(results), do: Enum.any?(results, &is_error?/1)

  def has_error?(results), do: is_error?(results)

  @doc """
  Retrieves the first occurence of an error tuple in the result list

  ## Examples

       iex> results = [
       ...>   {:ok, %Shipment{id: 1}},
       ...>   {:ok, %Shipment{id: 2}},
       ...>   {:error, :creation_error}
       ...> ]
       ...>
       ...> WuunderUtils.Results.get_error(results)
       :creation_error

  """
  @spec get_error(list() | term()) :: any()
  def get_error(results) when is_list(results),
    do:
      results
      |> get_errors()
      |> List.first()

  def get_error(result) do
    if is_error?(result) do
      get_result_value(result)
    else
      nil
    end
  end

  @doc """
  Retrieves all occurences of an error tuple in the result list

  ## Examples

       iex> results = [
       ...>   {:ok, %Shipment{id: 1}},
       ...>   {:ok, %Shipment{id: 2}},
       ...>   {:error, "other-error"},
       ...>   {:error, :creation_error}
       ...> ]
       ...>
       ...> WuunderUtils.Results.get_errors(results)
       ["other-error", :creation_error]

  """
  @spec get_errors(list() | term()) :: any()
  def get_errors(results) when is_list(results),
    do:
      results
      |> Enum.filter(&is_error?/1)
      |> Enum.map(&get_error/1)

  def get_errors(result), do: get_errors([result])

  @doc """
  If an error is encountered in given value, it will return {:error, _}.
  The value can be a list or a single value

  ## Examples

       iex> WuunderUtils.Results.get_error_as_result([{:ok, "value"}, {:error, "something went wrong"}])
       {:error, "something went wrong"}

       iex> WuunderUtils.Results.get_error_as_result({:ok, "value"})
       nil

       iex> WuunderUtils.Results.get_error_as_result("some-value")
       nil

  """
  @spec get_error_as_result(any()) :: {:error, term()} | nil
  def get_error_as_result(results) do
    if has_error?(results) do
      first_error(results)
    else
      nil
    end
  end

  @doc """
  If an error is encountered in given value, it will return {:error, _}.
  The value can be a list or a single value or a list with errors.

  ## Examples

       iex> WuunderUtils.Results.get_errors_as_result({:error, "some-value"})
       {:error, ["some-value"]}

       iex> WuunderUtils.Results.get_errors_as_result([{:error, "value-1"}, {:error, "value-2"}, {:ok, "value"}])
       {:error, ["value-1", "value-2"]}

  """
  @spec get_errors_as_result(any()) :: {:error, list()} | nil
  def get_errors_as_result(results) do
    if has_error?(results) do
      {:error, get_errors(results)}
    else
      nil
    end
  end

  @doc """
  Retrieve the first :ok result from a list of results. Returns the value
  of OK, not the tuple itself.

  ## Examples

       iex> results = [
       ...>   {:ok, %Shipment{id: 1}},
       ...>   {:ok, %Shipment{id: 2}},
       ...>   {:error, :creation_error}
       ...> ]
       ...>
       ...> WuunderUtils.Results.get_ok(results)
       %Shipment{id: 1}

  """
  @spec get_ok(any()) :: term() | nil
  def get_ok(results) when is_list(results),
    do:
      results
      |> get_oks()
      |> List.first()

  def get_ok(result) do
    if is_ok?(result) do
      get_result_value(result)
    else
      nil
    end
  end

  @doc """
  Retrieve all :ok results from a list of results. Returns the values of OK,
  not the tuple itself.

  ## Examples

       iex> results = [
       ...>   {:ok, %Shipment{id: 1}},
       ...>   {:ok, %Shipment{id: 2}},
       ...>   {:error, :creation_error}
       ...> ]
       ...>
       ...> WuunderUtils.Results.get_oks(results)
       [%Shipment{id: 1}, %Shipment{id: 2}]

  """
  @spec get_oks(list() | term()) :: list()
  def get_oks(results) when is_list(results),
    do:
      results
      |> Enum.filter(&is_ok?/1)
      |> Enum.map(&get_ok/1)

  def get_oks(result), do: get_oks([result])

  @doc """
  If an ok is encountered in given value, it will return {:ok, _}.
  The value can be a list or a single value. Note that it will only return first ok from a list.

  ## Examples

         iex> WuunderUtils.Results.get_ok_as_result({:ok, "some-value"})
         {:ok, "some-value"}

         iex> WuunderUtils.Results.get_ok_as_result([{:ok, "value-1"}, {:error, "error"}, {:ok, "value-2"}])
         {:ok, "value-1"}

         iex> WuunderUtils.Results.get_ok_as_result({:error, "value"})
         nil

  """
  @spec get_ok_as_result(any()) :: {:ok, any()} | nil
  def get_ok_as_result(results) do
    if has_ok?(results) do
      first_ok(results)
    else
      nil
    end
  end

  @doc """
  Returns the values from a list with result tuples when all are OK
  Or return {:error, _} when an error has eccoured in one of the items

  ## Examples

         iex> WuunderUtils.Results.get_oks_or_error_result([{:ok, "value"}, {:ok, "value-2"}, :ok])
         ["value", "value-2", nil]

         iex> WuunderUtils.Results.get_oks_or_error_result([{:ok, "value"}, {:ok, "value-2"}, {:error, "faulty"}])
         {:error, "faulty"}

  """
  @spec get_oks_or_error_result(any()) :: any()
  def get_oks_or_error_result(results) when is_list(results) do
    if all_ok?(results) do
      get_oks(results)
    else
      first_error(results)
    end
  end

  def get_oks_or_error_result(result), do: get_oks_or_error_result([result])

  @doc """
  If an ok is encountered in given value, it will return {:ok, _}.
  The value can be a list or a single value. It will return the entire list if the given
  value is a list.

  ## Examples

      iex> WuunderUtils.Results.get_oks_as_result({:ok, "some-value"})
      {:ok, ["some-value"]}

      iex> WuunderUtils.Results.get_oks_as_result([{:ok, "value-1"}, {:ok, "value-2"}])
      {:ok, ["value-1", "value-2"]}

      iex> WuunderUtils.Results.get_oks_as_result({:error, "value"})
      []

  """
  @spec get_oks_as_result(list() | term()) :: {:ok, list()} | nil
  def get_oks_as_result(results) do
    if has_ok?(results) do
      {:ok, get_oks(results)}
    else
      []
    end
  end

  @doc """
  Returns the result from a list of results ({:ok, _}, {:error, _}).
  Will return {:ok, first_result} with the first result when all of the values
  in the list are :ok. If one of the results has an :error, it will return {:error, first_error_result}

  ## Example

      iex> WuunderUtils.Results.get_as_result([{:ok, "value"}, {:ok, "value-2"}])
      {:ok, "value"}

      iex> WuunderUtils.Results.get_as_result([{:ok, "value"}, {:error, "value-2"}])
      {:error, "value-2"}

      iex> WuunderUtils.Results.get_as_result([{:error, "value"}, {:error, "value-2"}])
      {:error, "value"}

  """
  @spec get_as_result(list() | term()) :: tuple()
  def get_as_result(results) do
    if all_ok?(results) do
      first_ok(results)
    else
      first_error(results)
    end
  end

  @doc """
  Retrieve the first success result from a list of results. Returns the original values.
  Will parse {:ok} tuples if needed.

  ## Examples

      iex> results = [
      ...>   {:ok, %Shipment{id: 1}},
      ...>   {:ok, %Shipment{id: 2}},
      ...>   "some-value",
      ...>   nil,
      ...>   {:error, :creation_error}
      ...> ]
      ...>
      ...> WuunderUtils.Results.get_success(results)
      %Shipment{id: 1}

  """
  @spec get_success(term()) :: term() | nil
  def get_success(results) when is_list(results),
    do:
      results
      |> get_successes()
      |> List.first()

  def get_success(result) do
    if is_success?(result) do
      get_result_value(result)
    else
      nil
    end
  end

  @doc """
  Retrieve all success results from a list of results. Returns the values of a
  {:ok, x} or the original value.

  ## Examples

      iex> results = [
      ...>   {:ok, %Shipment{id: 1}},
      ...>   {:ok, %Shipment{id: 2}},
      ...>   %Shipment{id: 3},
      ...>   {:error, :creation_error}
      ...> ]
      ...>
      ...> WuunderUtils.Results.get_successes(results)
      [%Shipment{id: 1}, %Shipment{id: 2}, %Shipment{id: 3}]

  """
  @spec get_successes(list() | term()) :: list()
  def get_successes(results) when is_list(results),
    do:
      results
      |> Enum.filter(&is_success?/1)
      |> Enum.map(&get_success/1)

  def get_successes(result), do: get_successes([result])

  @doc """
  Tests if result is OK

  ## Examples

      iex> WuunderUtils.Results.is_ok?({:ok, "value"})
      true

      iex> WuunderUtils.Results.is_ok?(:ok)
      true

      iex> WuunderUtils.Results.is_ok?("some-value")
      false

      iex> WuunderUtils.Results.is_ok?({:error, "error message"})
      false

      iex> WuunderUtils.Results.is_ok?([])
      false

  """
  @spec is_ok?(any()) :: boolean()
  def is_ok?(result) when is_tuple(result),
    do: is_ok?(elem(result, 0))

  def is_ok?(:ok), do: true
  def is_ok?(:error), do: false

  def is_ok?(_result), do: false

  @doc """
  Tests if result is a success. Meaning: :ok, {:ok, X} or any other value othen than
  {:error, x} or :error

  ## Examples

      iex> WuunderUtils.Results.is_success?({:ok, "value"})
      true

      iex> WuunderUtils.Results.is_success?([])
      true

      iex> WuunderUtils.Results.is_success?(nil)
      true

      iex> WuunderUtils.Results.is_success?({:error, "error message"})
      false

  """
  @spec is_success?(any()) :: boolean()
  def is_success?(result) when is_tuple(result), do: is_success?(elem(result, 0))

  def is_success?(:ok), do: true
  def is_success?(:error), do: false

  def is_success?(_result), do: true

  @doc """
  Tests if result contains an error

  ## Examples

      iex> WuunderUtils.Results.is_error?({:error, "error message"})
      true

      iex> WuunderUtils.Results.is_error?({:ok, "value"})
      false

      iex> WuunderUtils.Results.is_error?([])
      false

  """
  @spec is_error?(any()) :: boolean()
  def is_error?(result) when is_tuple(result),
    do: is_error?(elem(result, 0))

  def is_error?(:error), do: true
  def is_error?(_result), do: false

  @doc """
  Checks if given value is :ok, :error or {:ok, _} or {:error, _}

  ## Examples

      iex> WuunderUtils.Results.is_result?({:ok, "value"})
      true

      iex> WuunderUtils.Results.is_result?({:error, "value"})
      true

      iex> WuunderUtils.Results.is_result?(:ok)
      true

      iex> WuunderUtils.Results.is_result?(:error)
      true

      iex> WuunderUtils.Results.is_result?("value")
      false

  """
  @spec is_result?(any()) :: boolean()
  def is_result?(value), do: not is_nil(get_result_code(value))

  @doc """
  Grabs result code from tuple or value. Valid values are :ok, :error or {:ok, _} or {:error, _}

  ## Examples

      iex> WuunderUtils.Results.get_result_code({:ok, "value"})
      :ok

      iex> WuunderUtils.Results.get_result_code(:ok)
      :ok

      iex> WuunderUtils.Results.get_result_code({:error, "value", "whatever"})
      :error

      iex> WuunderUtils.Results.get_result_code(:error)
      :error

      iex> WuunderUtils.Results.get_result_code("value")
      nil

  """
  @spec get_result_code(any()) :: :ok | :error | nil
  def get_result_code(value) when is_tuple(value),
    do:
      value
      |> elem(0)
      |> get_result_code()

  def get_result_code(:ok), do: :ok
  def get_result_code(:error), do: :error
  def get_result_code(_value), do: nil

  @doc """
  Retrieves the data is stored inside a {:ok, X} or {:error, Y} tuple.
  Only gets everything after the :ok or :error. All other values are left alone and just returned.

  ## Examples

      iex> WuunderUtils.Results.get_result_value({:ok, "value-1"})
      "value-1"

      iex> WuunderUtils.Results.get_result_value({:ok, "value-1", "value-2"})
      {"value-1", "value-2"}

      iex> WuunderUtils.Results.get_result_value({:error, :internal_server_error})
      :internal_server_error

      iex> WuunderUtils.Results.get_result_value({:error, :error_a, :error_b, :error_c})
      {:error_a, :error_b, :error_c}

      iex> WuunderUtils.Results.get_result_value("any-value")
      "any-value"

      iex> WuunderUtils.Results.get_result_value(:ok)
      nil

      iex> WuunderUtils.Results.get_result_value(:error)
      nil

  """
  @spec get_result_value(any()) :: any() | nil
  def get_result_value(value) when is_tuple(value) do
    if is_result?(value) do
      values_after_code = Tuple.delete_at(value, 0)

      if tuple_size(values_after_code) == 1 do
        elem(values_after_code, 0)
      else
        values_after_code
      end
    else
      value
    end
  end

  def get_result_value(value) do
    if is_result?(value) do
      nil
    else
      value
    end
  end

  @doc """
  Only returns ok results from a list. Besides :ok this means anything other than an error.
  So in practice: {:ok, _} tuples, :ok, non :error / {:error, _} values. Note that nills are also considered ok.
  And also note: an :ok will be transformed to `nil`.

  ## Examples

      iex> results = [
      ...>   {:ok, "value1"},
      ...>   :ok,
      ...>   {:ok, "value2", "value3"},
      ...>   {:ok, {"value4", "value5"}},
      ...>   {:error, "something went wrong"},
      ...>   nil
      ...> ]
      ...>
      ...> WuunderUtils.Results.get_success_values(results)
      ["value1", nil, {"value2", "value3"}, {"value4", "value5"}, nil]

  """
  @spec get_success_values(list() | term()) :: list()
  def get_success_values(values) when is_list(values) do
    values
    |> Enum.reduce([], fn value, acc ->
      if is_success?(value) do
        acc ++ [get_result_value(value)]
      else
        acc
      end
    end)
  end

  def get_success_values(value), do: get_success_values([value])

  defp first_ok(results) when is_list(results),
    do:
      results
      |> Enum.filter(&is_ok?/1)
      |> List.first()

  defp first_ok(value) do
    if is_ok?(value) do
      value
    else
      nil
    end
  end

  defp first_error(results) when is_list(results),
    do:
      results
      |> Enum.filter(&is_error?/1)
      |> List.first()

  defp first_error(value) do
    if is_error?(value) do
      value
    else
      nil
    end
  end
end
