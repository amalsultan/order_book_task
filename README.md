# Order Book Task

This application uses Agent to manage an order book data

To start your server:

  * Start Phoenix endpoint with `iex -S mix run --no-halt`

Now you can start the exchanger in iex shell
# Sample Calls
## Start Exchanger
{:ok, exchange_pid} = Exchange.start_link()

## Insert New Price Level
Exchange.send_instruction(exchange_pid, %{instruction: :new, side: :bid, price_level_index: 1, price: 50.0, quantity: 30 })
Exchange.send_instruction(exchange_pid, %{instruction: :new, side: :ask, price_level_index: 1, price: 20.0, quantity: 10 })

## Update Existing Price Level
Exchange.send_instruction(exchange_pid, %{instruction: :update,side: :ask,price_level_index: 1,price: 70.0,quantity: 20})
Exchange.send_instruction(exchange_pid, %{instruction: :update,side: :bid,price_level_index: 1,price: 50.0,quantity: 40})

## Delete Existing Price level
Exchange.send_instruction(exchange_pid, %{instruction: :delete, side: :bid, price_level_index: 1})

## Get order book till a given price level
Exchange.order_book(exchange_pid, 1)
