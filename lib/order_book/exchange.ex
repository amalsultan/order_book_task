defmodule Exchange do
  use Agent

  @spec start_link :: {:error, any} | {:ok, pid}
  def start_link() do
    Agent.start_link(fn -> %{bid: [], ask: []} end, name: __MODULE__)
    |> case do
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:ok, pid} -> {:ok, pid}
      _-> {:error, :failed}
    end
  end

  @spec send_instruction(any, %{:instruction => any, optional(any) => any}) ::
          :ok | {:error, :invalid_instruction}
  def send_instruction(exchange_pid, %{instruction: instruction} = event) do
    case instruction do
      :new -> insert_new_price_level(exchange_pid, event)
      :update -> :ok
      :delete -> :ok
      _-> {:error, :invalid_instruction}
    end
  end

  #This is a private method used by insert_new_price_level/2 method incase of instruction = :new. It inserts the values at given price level and in the list of given side. That means we have two separate lists for side and bid. indexes are maintained on the basis of array index. So values are stored at the same index of array as provided in input. For example value for price_level 2 would be stored at 2nd index of array. That way moving index up and down would be easy operation.
  @spec insert(atom | pid | {atom, any} | {:via, atom, any}, integer, any, any) :: :ok
  defp insert(exchange_pid, price_level_index, values, side) do
    default_value = List.insert_at([], price_level_index, values)
    list_count =
      Agent.get(exchange_pid, &Map.get(&1, side))
      |> Enum.count()
    cond do
      list_count < price_level_index ->
        new_list =
          List.duplicate(nil, price_level_index - list_count)
          |> List.insert_at(price_level_index, values)
        Agent.update(exchange_pid, & Map.update(&1, side, default_value, fn existing_value -> existing_value ++ new_list end))
      true ->
        Agent.update(exchange_pid, & Map.update(&1, side, default_value, fn existing_value -> List.insert_at(existing_value, price_level_index, values) end))
    end
  end

  #This is a private method used by send_instruction/2 method incase of instruction = :new.
  @spec insert_new_price_level(atom | pid | {atom, any} | {:via, atom, any}, %{
          :price => any,
          :price_level_index => any,
          :quantity => any,
          :side => :ask | :bid,
          optional(any) => any
        }) :: :ok
  defp insert_new_price_level(exchange_pid, %{side: :ask, price_level_index: price_level_index, price: price, quantity: quantity } = _event) do
    insert(exchange_pid, price_level_index, %{ask_price: price, ask_quantity: quantity}, :ask)
  end

  defp insert_new_price_level(exchange_pid, %{side: :bid, price_level_index: price_level_index, price: price, quantity: quantity } = _event) do
    insert(exchange_pid, price_level_index, %{bid_price: price, bid_quantity: quantity}, :bid)
  end

  #This is a private method used by order_book/2 method to get the bid and ask values till given price_level. Initially index = 0 and output_list is []. This method is using tail recursion to get all the order book values till given price_level.
  @spec format_order_book_output(list, list, list, number, number) :: list
  def format_order_book_output(output_list, ask_list, bid_list, price_level, index) when index == 0  do
    {_, bid_list} = List.pop_at(bid_list, 0)
    {_, ask_list} = List.pop_at(ask_list, 0)
    format_order_book_output(output_list, ask_list, bid_list, price_level, index+1)
  end

  def format_order_book_output(output_list, ask_list, bid_list, price_level, index) when index <= price_level  do
    default_bid_data = %{bid_price: nil, bid_quantity: nil}
    default_ask_data = %{ask_price: nil, ask_quantity: nil}
    {bid_data, bid_list} = List.pop_at(bid_list, 0)
    {ask_data, ask_list} = List.pop_at(ask_list, 0)
    cond do
      bid_data == nil and ask_data == nil ->
        output_list
      true ->
        [Map.merge(ask_data || default_ask_data ,bid_data || default_bid_data) | output_list ]
    end
    |> format_order_book_output(ask_list, bid_list, price_level, index+1)
  end

  def format_order_book_output(output_list, _, _, _, _)  do
    output_list
    |> Enum.reverse()
  end

  @spec order_book(atom | pid | {atom, any} | {:via, atom, any}, any) :: list
  def order_book(exchange_pid, price_level) do
    %{ask: ask_list, bid: bid_list} = Agent.get(exchange_pid, & &1)
    format_order_book_output([], ask_list, bid_list, price_level, 0)
  end
end