import pandas as pd

def calculate_monthly_sma_and_candles(csv_file):
    # Step 1: Read the CSV file
    data = pd.read_csv(csv_file, parse_dates=['Date'])

    # Step 2: Set the Date as the index
    data.set_index('Date', inplace=True)

    # Step 3: Resample to get monthly averages
    monthly_data = data.resample('M').mean()

    # Step 4: Calculate the SMAs
    sma_20 = monthly_data['Close'].rolling(window=20).mean()
    sma_50 = monthly_data['Close'].rolling(window=50).mean()
    sma_200 = monthly_data['Close'].rolling(window=200).mean()

    # Get the latest SMA values
    latest_sma_20 = sma_20.iloc[-1] if len(sma_20) >= 20 else None
    latest_sma_50 = sma_50.iloc[-1] if len(sma_50) >= 50 else None
    latest_sma_200 = sma_200.iloc[-1] if len(sma_200) >= 200 else None

    # Determine the monthly green and red candles
    monthly_data['Green'] = monthly_data['Close'] > monthly_data['Open']
    monthly_data['Red'] = monthly_data['Close'] < monthly_data['Open']

    # Count the number of green and red candles
    green_candles_count = monthly_data['Green'].sum()
    red_candles_count = monthly_data['Red'].sum()

    # Count the total number of candles
    total_candles_count = monthly_data.shape[0]

    return {
        "SMA_20": latest_sma_20,
        "SMA_50": latest_sma_50,
        "SMA_200": latest_sma_200,
        "Green Candles": green_candles_count,
        "Red Candles": red_candles_count,
        "Total Candles": total_candles_count
    }

# Usage
csv_file_path = "D:\\Downloads\\StockData\\MSFT.csv"
results = calculate_monthly_sma_and_candles(csv_file_path)

print(f"Latest 20-month SMA: {results['SMA_20']}")
print(f"Latest 50-month SMA: {results['SMA_50']}")
print(f"Latest 200-month SMA: {results['SMA_200']}")
print(f"Green candles: {results['Green Candles']}")
print(f"Red candles: {results['Red Candles']}")
print(f"Total candles: {results['Total Candles']}")
