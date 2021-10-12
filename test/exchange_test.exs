defmodule ExchangeTest do
  use ExUnit.Case
  doctest Exchange

  @valid_bid_data %{instruction: :new, side: :bid, price_level_index: 1, price: 50.0, quantity: 30 }
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

  test "create new with invalid instruction" do
    {:ok, exchange_pid} = Exchange.start_link()
    assert Exchange.send_instruction(exchange_pid, @invalid_instruction_data) == {:error, :invalid_instruction}
  end
end
