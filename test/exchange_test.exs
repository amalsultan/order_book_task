defmodule ExchangeTest do
  use ExUnit.Case
  doctest Exchange

  @valid_bid_data %{instruction: :new, side: :bid, price_level_index: 1, price: 50.0, quantity: 30 }
  @valid_ask_data %{instruction: :new, side: :ask, price_level_index: 1, price: 20.0, quantity: 30 }
  @valid_update_ask_data %{instruction: :update, side: :ask, price_level_index: 1, price: 60.0, quantity: 20 }
  @invalid_update_data %{instruction: :update, side: :ask, price_level_index: 3, price: 30.0, quantity: 10 }
  @invalid_instruction_data %{instruction: :xyz, side: :bid, price_level_index: 1, price: 50.0, quantity: 30 }

  test "start exchange" do
    {:ok, pid} = Exchange.start_link()
    assert Exchange.start_link() == {:ok, pid}
  end

  test "create new with valid input" do
    {:ok, exchange_pid} = Exchange.start_link()
    assert Exchange.send_instruction(exchange_pid, @valid_bid_data) == :ok
    assert Exchange.order_book(exchange_pid, @valid_bid_data[:price_level_index]) == [%{ask_price: nil, ask_quantity: nil, bid_price: @valid_bid_data[:price], bid_quantity: @valid_bid_data[:quantity]}]
  end

  test "update non existing value" do
    {:ok, exchange_pid} = Exchange.start_link()
    assert Exchange.send_instruction(exchange_pid, @invalid_update_data) == {:error, :not_found}
    assert Exchange.order_book(exchange_pid, @invalid_update_data[:price_level_index]) == []
  end

  test "update with valid input" do
    {:ok, exchange_pid} = Exchange.start_link()
    Exchange.send_instruction(exchange_pid, @valid_ask_data)
    assert Exchange.send_instruction(exchange_pid, @valid_update_ask_data) == :ok
    assert Exchange.order_book(exchange_pid, @valid_update_ask_data[:price_level_index]) == [%{ask_price: @valid_update_ask_data[:price], ask_quantity:  @valid_update_ask_data[:quantity], bid_price: nil, bid_quantity: nil}]
  end

  test "create new with invalid instruction" do
    {:ok, exchange_pid} = Exchange.start_link()
    assert Exchange.send_instruction(exchange_pid, @invalid_instruction_data) == {:error, :invalid_instruction}
  end

  test "delete existing value" do
    {:ok, exchange_pid} = Exchange.start_link()
    Exchange.send_instruction(exchange_pid, @valid_bid_data)
    assert Exchange.send_instruction(exchange_pid, %{instruction: :delete, side: @valid_bid_data[:side], price_level_index: @valid_bid_data[:price_level_index]}) == :ok
    assert Exchange.order_book(exchange_pid, @valid_bid_data[:price_level_index]) == []
  end

  test "delete non existing value" do
    {:ok, exchange_pid} = Exchange.start_link()
    assert Exchange.send_instruction(exchange_pid, %{instruction: :delete, side: @valid_bid_data[:side], price_level_index: @valid_bid_data[:price_level_index]}) == {:error, :not_found}
    assert Exchange.order_book(exchange_pid, @valid_bid_data[:price_level_index]) == []
  end
end
