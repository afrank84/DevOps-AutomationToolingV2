import pandas as pd
import yfinance as yf
import argparse

def calculate_monthly_sma_and_candles(data):
    df = pd.DataFrame(data, columns=['Date', 'Open', 'Close'])
    df['Date'] = pd.to_datetime(df['Date'])
    df.set_index('Date', inplace=True)

    # Update the resampling to use 'ME' instead of 'M'
    monthly_data = df.resample('ME').mean()

    sma_20 = monthly_data['Close'].rolling(window=20).mean()
    sma_50 = monthly_data['Close'].rolling(window=50).mean()
    sma_200 = monthly_data['Close'].rolling(window=200).mean()

    latest_sma_20 = sma_20.iloc[-1] if len(sma_20) >= 20 else None
    latest_sma_50 = sma_50.iloc[-1] if len(sma_50) >= 50 else None
    latest_sma_200 = sma_200.iloc[-1] if len(sma_200) >= 200 else None

    prev_sma_20 = sma_20.iloc[-2] if len(sma_20) >= 20 else None
    prev_sma_50 = sma_50.iloc[-2] if len(sma_50) >= 50 else None
    prev_sma_200 = sma_200.iloc[-2] if len(sma_200) >= 200 else None

    monthly_data['Green'] = monthly_data['Close'] > monthly_data['Open']
    monthly_data['Red'] = monthly_data['Close'] < monthly_data['Open']

    green_candles_count = monthly_data['Green'].sum()
    red_candles_count = monthly_data['Red'].sum()

    total_candles_count = monthly_data.shape[0]

    return {
        "SMA_20": latest_sma_20,
        "SMA_50": latest_sma_50,
        "SMA_200": latest_sma_200,
        "Prev_SMA_20": prev_sma_20,
        "Prev_SMA_50": prev_sma_50,
        "Prev_SMA_200": prev_sma_200,
        "Green Candles": green_candles_count,
        "Red Candles": red_candles_count,
        "Total Candles": total_candles_count,
        "Monthly Data": monthly_data,
        "SMA_20_Series": sma_20,
        "SMA_50_Series": sma_50,
        "SMA_200_Series": sma_200,
        "Current Price": data[-1]['Close']
    }

def fetch_data(symbol):
    stock_data = yf.download(symbol, start="2000-01-01")
    current_price = yf.Ticker(symbol).history(period="1d")['Close'].iloc[-1]

    data = []
    for date, row in stock_data.iterrows():
        data.append({
            "Date": date,
            "Open": row['Open'],
            "Close": row['Close']
        })
    results = calculate_monthly_sma_and_candles(data)
    results["Current Price"] = current_price
    return results

def display_results(results, symbol):
    print(f"Results for {symbol}:")
    print(f"Current Price: {results['Current Price']}")
    print(f"Latest 20-month SMA: {results['SMA_20']}")
    print(f"Latest 50-month SMA: {results['SMA_50']}")
    print(f"Latest 200-month SMA: {results['SMA_200']}")
    print(f"Green candles: {results['Green Candles']}")
    print(f"Red candles: {results['Red Candles']}")
    print(f"Total candles: {results['Total Candles']}")

    # Checklist
    print("\nChecklist:")

    # Check if there are more green candles than red
    if results["Green Candles"] > results["Red Candles"]:
        print("✓ More green candles than red")
    else:
        print("✗ More red candles than green")

    # Check if the current price is below any of the moving averages
    if (results["Current Price"] <= results["SMA_20"] or 
        results["Current Price"] <= results["SMA_50"] or 
        results["Current Price"] <= results["SMA_200"]):
        print("✓ Current price is equal to or below the 20MA, 50MA, or 200MA")
    else:
        print("✗ Current price is above the 20MA, 50MA, and 200MA")

    # Check if all SMAs are rising
    if (results["SMA_20"] > results["Prev_SMA_20"] and 
        results["SMA_50"] > results["Prev_SMA_50"] and 
        results["SMA_200"] > results["Prev_SMA_200"]):
        print("✓ All SMAs are rising")
    else:
        print("✗ Not all SMAs are rising")

def plot_chart(results, symbol):
    import matplotlib.pyplot as plt

    monthly_data = results["Monthly Data"]
    sma_20 = results["SMA_20_Series"]
    sma_50 = results["SMA_50_Series"]
    sma_200 = results["SMA_200_Series"]

    plt.figure(figsize=(10, 5))
    plt.plot(monthly_data.index, monthly_data['Close'], label=f'{symbol} Close Price', color='blue')
    plt.plot(monthly_data.index, sma_20, label='20-month SMA', color='orange')
    plt.plot(monthly_data.index, sma_50, label='50-month SMA', color='green')
    plt.plot(monthly_data.index, sma_200, label='200-month SMA', color='red')

    plt.title(f'{symbol} Monthly Price with SMAs')
    plt.xlabel('Date')
    plt.ylabel('Price')
    plt.legend()
    plt.show()

def main():
    parser = argparse.ArgumentParser(description="Fetch and analyze stock data.")
    parser.add_argument("--plot", action="store_true", help="Plot the data with SMAs")

    args = parser.parse_args()

    # Ask for stock symbol from the user
    symbol = input("Enter the stock symbol: ").strip().upper()

    results = fetch_data(symbol)
    display_results(results, symbol)

    if args.plot:
        plot_chart(results, symbol)

if __name__ == "__main__":
    main()
