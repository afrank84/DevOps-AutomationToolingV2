import pandas as pd
import yfinance as yf
import tkinter as tk
from tkinter import messagebox

def calculate_monthly_sma_and_candles(data):
    # Convert the data to a DataFrame
    df = pd.DataFrame(data, columns=['Date', 'Open', 'Close'])
    df['Date'] = pd.to_datetime(df['Date'])
    df.set_index('Date', inplace=True)

    # Resample to get monthly averages
    monthly_data = df.resample('M').mean()

    # Calculate the SMAs
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

def fetch_data():
    symbol = symbol_entry.get()
    if not symbol:
        messagebox.showerror("Error", "Please enter a stock symbol.")
        return
    try:
        stock_data = yf.download(symbol, start="2000-01-01")
        data = []
        for date, row in stock_data.iterrows():
            data.append({
                "Date": date,
                "Open": row['Open'],
                "Close": row['Close']
            })
        results = calculate_monthly_sma_and_candles(data)
        display_results(results)
    except Exception as e:
        messagebox.showerror("Error", f"An error occurred: {str(e)}")

def display_results(results):
    result_text = (
        f"Latest 20-month SMA: {results['SMA_20']}\n"
        f"Latest 50-month SMA: {results['SMA_50']}\n"
        f"Latest 200-month SMA: {results['SMA_200']}\n"
        f"Green candles: {results['Green Candles']}\n"
        f"Red candles: {results['Red Candles']}\n"
        f"Total candles: {results['Total Candles']}\n"
    )
    result_label.config(text=result_text)

# GUI Setup
root = tk.Tk()
root.title("SMA and Candle Count Calculator")

# Entry for Stock Symbol
symbol_label = tk.Label(root, text="Stock Symbol:")
symbol_label.pack(pady=5)
symbol_entry = tk.Entry(root)
symbol_entry.pack(pady=5)

# Button to fetch data and calculate SMA and candles
fetch_button = tk.Button(root, text="Fetch Data & Calculate", command=fetch_data)
fetch_button.pack(pady=10)

# Label to display results
result_label = tk.Label(root, text="", justify=tk.LEFT)
result_label.pack(pady=10)

root.mainloop()
