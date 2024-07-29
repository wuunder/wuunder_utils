defmodule WuunderUtils.Results do
  @moduledoc """
  A set of handy helpers to deal with {:ok, _} or {:error, _} tuples
  """

  # poor mans typing, but it covers most usecases
  @type ok :: :ok

  @type error :: :error

  @type ok_tuple ::
          {ok(), term()}
          | {ok(), term(), term()}
          | {ok(), term(), term(), term()}
          | {ok(), term(), term(), term(), term()}
          | {ok(), term(), term(), term(), term(), term()}

  @type error_tuple ::
          {error(), term()}
          | {error(), term(), term()}
          | {error(), term(), term(), term()}
          | {error(), term(), term(), term(), term()}
          | {error(), term(), term(), term(), term(), term()}

  @type result :: ok() | error() | ok_tuple() | error_tuple()

  @type result_list :: list(result())

  defguard is_result(result)
           when result == :ok or result == :error or
                  (is_tuple(result) and tuple_size(result) >= 2 and
                     (elem(result, 0) == :ok or elem(result, 0) == :error))

  defguard is_result_tuple(result)
           when is_tuple(result) and tuple_size(result) >= 2 and
                  (elem(result, 0) == :ok or elem(result, 0) == :error)

  defguard is_error_tuple(result)
           when is_tuple(result) and tuple_size(result) >= 2 and elem(result, 0) == :error

  defguard is_ok_tuple(result)
           when is_tuple(result) and tuple_size(result) >= 2 and elem(result, 0) == :ok

  defguard is_error_result(result)
           when result == :error or
                  (is_tuple(result) and tuple_size(result) >= 2 and elem(result, 0) == :error)

  defguard is_ok_result(result)
           when result == :ok or
                  (is_tuple(result) and tuple_size(result) >= 2 and elem(result, 0) == :ok)

  @doc """
  Checks if there are no errors and all results are {:ok, ...}

  ## Examples

      iex> WuunderUtils.Results.all_ok?([
      ...>   {:ok, %Shipment{id: 1}},
      ...>   {:ok, %Shipment{id: 2}}
      ...> ])
      true

      iex> WuunderUtils.Results.all_ok?([{:ok, %Shipment{id: 2}}, {:error, %Shipment{id: 3}}])
      false

  """
  @spec all_ok?(result_list()) :: boolean()
  def all_ok?(results) when is_list(results), do: Enum.all?(results, &ok?/1)

  @doc """
  Checks if all results errored

  ## Examples

      iex> WuunderUtils.Results.all_error?([
      ...>   {:error, %Shipment{id: 1}},
      ...>   {:error, %Shipment{id: 2}}
      ...> ])
      true

      iex> WuunderUtils.Results.all_error?([{:ok, %Shipment{id: 2}}, {:error, %Shipment{id: 3}}])
      false

  """
  @spec all_error?(result_list()) :: boolean()
  def all_error?(results) when is_list(results), do: Enum.all?(results, &error?/1)

  @doc """
  Checks if there any OK results in the list.

  ## Examples

      iex> WuunderUtils.Results.has_ok?([{:ok, "hello world"}, {:error, :faulty}])
      true

      iex> WuunderUtils.Results.has_ok?([{:error, "connection lost"}, {:error, :faulty}])
      false

  """
  @spec has_ok?(result_list()) :: boolean()
  def has_ok?(results) when is_list(results), do: Enum.any?(results, &ok?/1)

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

      iex> WuunderUtils.Results.has_error?([
      ...>   {:ok, %Shipment{id: 1}},
      ...>   {:ok, %Shipment{id: 2}},
      ...>   :ok
      ...> ])
      false
  """
  @spec has_error?(result_list()) :: boolean()
  def has_error?(results) when is_list(results), do: Enum.any?(results, &error?/1)

  @doc """
  Returns error or ok from result list. Gives priority to error in list.

  ## Examples

      iex> WuunderUtils.Results.get_result([
      ...>   {:ok, %Shipment{id: 1}},
      ...>   {:ok, %Shipment{id: 2}},
      ...>   {:error, :creation_error},
      ...>   :error
      ...> ])
      {:error, :creation_error}

      iex> WuunderUtils.Results.get_result([
      ...>   {:ok, %Shipment{id: 1}},
      ...>   {:ok, %Shipment{id: 2}},
      ...> ])
      {:ok, %Shipment{id: 1}}
  """
  @spec get_result(result_list()) :: result()
  def get_result(results) when is_list(results) do
    if has_error?(results) do
      get_error(results)
    else
      get_ok(results)
    end
  end

  @doc """
  Gets a list of errors or a list of ok's.
  Gives the priority to list of errors

  ## Examples

      iex> WuunderUtils.Results.get_results([
      ...>   {:ok, %Shipment{id: 1}},
      ...>   {:ok, %Shipment{id: 2}},
      ...>   {:error, :creation_error},
      ...>   :error
      ...> ])
      [{:error, :creation_error}, :error]

      iex> WuunderUtils.Results.get_results([
      ...>   {:ok, %Shipment{id: 1}},
      ...>   {:ok, %Shipment{id: 2}},
      ...> ])
      [{:ok, %Shipment{id: 1}}, {:ok, %Shipment{id: 2}}]
  """
  @spec get_results(result_list()) :: result_list()
  def get_results(results) when is_list(results) do
    if has_error?(results) do
      get_errors(results)
    else
      get_oks(results)
    end
  end

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
       {:error, :creation_error}

       iex> results = [
       ...>   {:ok, %Shipment{id: 1}},
       ...>   {:ok, %Shipment{id: 2}},
       ...> ]
       ...>
       ...> WuunderUtils.Results.get_error(results)
       nil

  """
  @spec get_error(result_list()) :: result() | nil
  def get_error(results) when is_list(results),
    do:
      results
      |> get_errors()
      |> List.first()

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
       [{:error, "other-error"}, {:error, :creation_error}]

  """
  @spec get_errors(result_list()) :: result_list()
  def get_errors(results) when is_list(results), do: Enum.filter(results, &error?/1)

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
       {:ok, %Shipment{id: 1}}

       iex> results = [
       ...>   {:error, :creation_error}
       ...> ]
       ...>
       ...> WuunderUtils.Results.get_ok(results)
       nil

  """
  @spec get_ok(result_list()) :: result() | nil
  def get_ok(results) when is_list(results),
    do:
      results
      |> get_oks()
      |> List.first()

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
       [{:ok, %WuunderUtils.ResultsTest.Shipment{id: 1, weight: 0}}, {:ok, %WuunderUtils.ResultsTest.Shipment{id: 2, weight: 0}}]

  """
  @spec get_oks(result_list()) :: result_list()
  def get_oks(results) when is_list(results),
    do: Enum.filter(results, &ok?/1)

  @doc """
  Tests if result is OK

  ## Examples

      iex> WuunderUtils.Results.ok?({:ok, "value"})
      true

      iex> WuunderUtils.Results.ok?(:ok)
      true

      iex> WuunderUtils.Results.ok?("some-value")
      false

      iex> WuunderUtils.Results.ok?({:error, "error message"})
      false

      iex> WuunderUtils.Results.ok?([])
      false

  """
  @spec ok?(result()) :: boolean()
  def ok?(result) when is_ok_result(result), do: true
  def ok?(_result), do: false

  @doc """
  Tests if result contains an error

  ## Examples

      iex> WuunderUtils.Results.error?({:error, "error message"})
      true

      iex> WuunderUtils.Results.error?(:error)
      true

      iex> WuunderUtils.Results.error?({:error})
      false

      iex> WuunderUtils.Results.error?({:ok, "value"})
      false

      iex> WuunderUtils.Results.error?([])
      false

  """
  @spec error?(any()) :: boolean()
  def error?(result) when is_error_result(result), do: true
  def error?(_result), do: false

  @doc """
  Checks if given value is :ok, :error or {:ok, _} or {:error, _}

  ## Examples

      iex> WuunderUtils.Results.result?({:ok, "value"})
      true

      iex> WuunderUtils.Results.result?({:error, "value"})
      true

      iex> WuunderUtils.Results.result?(:ok)
      true

      iex> WuunderUtils.Results.result?(:error)
      true

      iex> WuunderUtils.Results.result?({:error})
      false

      iex> WuunderUtils.Results.result?({:ok})
      false

      iex> WuunderUtils.Results.result?("value")
      false

  """
  @spec result?(any()) :: boolean()
  def result?(value) when is_result(value), do: true
  def result?(_value), do: false

  @doc """
  Retrieves the data is stored inside a {:ok, X} or {:error, Y} tuple.
  Only gets everything after the :ok or :error. All other values are left alone and just returned.

  ## Examples

      iex> WuunderUtils.Results.get_value({:ok, "value-1"})
      "value-1"

      iex> WuunderUtils.Results.get_value({:ok, "value-1", "value-2"})
      {"value-1", "value-2"}

      iex> WuunderUtils.Results.get_value({:error, :internal_server_error})
      :internal_server_error

      iex> WuunderUtils.Results.get_value({:error, :error_a, :error_b, :error_c})
      {:error_a, :error_b, :error_c}

      iex> WuunderUtils.Results.get_value(:ok)
      nil

      iex> WuunderUtils.Results.get_value(:error)
      nil

  """
  @spec get_value(result()) :: term()
  def get_value(result) when is_result_tuple(result) do
    values = Tuple.delete_at(result, 0)

    if tuple_size(values) == 1 do
      elem(values, 0)
    else
      values
    end
  end

  def get_value(:ok), do: nil
  def get_value(:error), do: nil

  @doc """
  Grabs the values of a list of result tuples

  ## Examples

      iex> WuunderUtils.Results.get_values([{:ok, "value-1"}])
      ["value-1"]

      iex> WuunderUtils.Results.get_values([{:ok, "value-1", "value-2"}, {:ok, "value-3"}])
      [{"value-1", "value-2"}, "value-3"]

      iex> WuunderUtils.Results.get_values([{:error, :internal_server_error}])
      [:internal_server_error]

      iex> WuunderUtils.Results.get_values([:ok, :error])
      [nil, nil]

  """
  @spec get_value(result_list()) :: term()
  def get_values(result) when is_list(result), do: Enum.map(result, &get_value/1)

  @doc """
  Flattens a result tuple. Comes in handy when functions return a {:ok, _} or {:error, _} tuple with another set of tuples nested inside of it.

  ## Examples

      iex> WuunderUtils.Results.flatten({:error, {:internal_error, :get_orders, "Internal Server Error"}})
      {:error, :internal_error, :get_orders, "Internal Server Error"}

      iex> WuunderUtils.Results.flatten({:error, {:internal_error, :get_orders}, {1, 2}})
      {:error, :internal_error, :get_orders, 1, 2}

      iex> WuunderUtils.Results.flatten({:error, {:internal_error, :get_orders, [1, 2]}, {1, 2}})
      {:error, :internal_error, :get_orders, [1, 2], 1, 2}

      iex> WuunderUtils.Results.flatten({:error, :internal_error, :get_orders})
      {:error, :internal_error, :get_orders}

      iex> WuunderUtils.Results.flatten(:error)
      :error
  """
  @spec flatten(result()) :: result()
  def flatten(result) when is_result_tuple(result) do
    result
    |> Tuple.to_list()
    |> Enum.reduce([], fn value, acc ->
      if is_tuple(value) do
        acc ++ Tuple.to_list(value)
      else
        acc ++ [value]
      end
    end)
    |> List.to_tuple()
  end

  def flatten(result) when is_result(result), do: result

  @doc """
  Wraps the given value in an ok tuple.

  ## Examples

      iex> WuunderUtils.Results.ok("value")
      {:ok, "value"}
  """
  @spec ok(term()) :: {:ok, term()}
  def ok(value) when not is_ok_result(value), do: {:ok, value}

  @doc """
  Wraps the given value in an error tuple.

  ## Examples

      iex> WuunderUtils.Results.error("value")
      {:error, "value"}
  """
  @spec error(term()) :: {:error, term()}
  def error(value) when not is_error_result(value), do: {:error, value}
end
