import yfinance as yf
import sys
import json
import os

def get_percent_change(path, symbols):
    symbol_string = " ".join(symbols)

    try:
        # Fetch data for the stock
        stock = yf.Tickers(symbol_string)
        history = stock.history(period="1mo")

        # Check if data was fetched
        if history.empty:
            print("No data fetched. Check the symbols or connection.")
            return

        data = {}

        for symbol in symbols:
            # Check if the symbol is valid
            if symbol not in history.columns.levels[1]:
                print(f"Data not available for {symbol}.")
                continue

            # Extract the closing price for today
            today_close = history['Close'][symbol].iloc[-1]
            percent_changes = {}

            # Calculate percent change for today
            yesterday_close = history['Close'][symbol].iloc[-2]
            percent_changes['today'] = ((today_close - yesterday_close) / yesterday_close) * 100

            # Calculate percent change for the past 5 days
            five_days_ago_close = history['Close'][symbol].iloc[-6]
            percent_changes['five_days'] = ((today_close - five_days_ago_close) / five_days_ago_close) * 100

            # Calculate percent change for the past month
            month_ago_close = history['Close'][symbol].iloc[0]
            percent_changes['month'] = ((today_close - month_ago_close) / month_ago_close) * 100

            # Add the data to the dictionary
            if not any(str(value) == "nan" for value in percent_changes.values()):
                data[symbol] = percent_changes

        # Write the data to a file
        path = os.path.join(path, "data")
        os.makedirs(path, exist_ok=True)
        with open(os.path.join(path, "stock_data.json"), "w") as f:
            f.write(json.dumps(data))

    except Exception as e:
        print(f"Error fetching data for {symbol_string}: {e}")

# Ensure a path and symbol are provided as arguments
if len(sys.argv) < 3:
    print("Usage: python stocks.py <output path> <symbols>")
    sys.exit(1)

get_percent_change(sys.argv[1], sys.argv[2:])
