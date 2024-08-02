import pandas as pd
import yfinance as yf
import ttkbootstrap as ttk
from ttkbootstrap.constants import *
from tkinter import messagebox
from matplotlib.figure import Figure
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

def calculate_monthly_sma_and_candles(data):
    df = pd.DataFrame(data, columns=['Date', 'Open', 'Close'])
    df['Date'] = pd.to_datetime(df['Date'])
    df.set_index('Date', inplace=True)

    monthly_data = df.resample('M').mean()

    sma_20 = monthly_data['Close'].rolling(window=20).mean()
    sma_50 = monthly_data['Close'].rolling(window=50).mean()
    sma_200 = monthly_data['Close'].rolling(window=200).mean()

    latest_sma_20 = sma_20.iloc[-1] if len(sma_20) >= 20 else None
    latest_sma_50 = sma_50.iloc[-1] if len(sma_50) >= 50 else None
    latest_sma_200 = sma_200.iloc[-1] if len(sma_200) >= 200 else None

    monthly_data['Green'] = monthly_data['Close'] > monthly_data['Open']
    monthly_data['Red'] = monthly_data['Close'] < monthly_data['Open']

    green_candles_count = monthly_data['Green'].sum()
    red_candles_count = monthly_data['Red'].sum()

    total_candles_count = monthly_data.shape[0]

    return {
        "SMA_20": latest_sma_20,
        "SMA_50": latest_sma_50,
        "SMA_200": latest_sma_200,
        "Green Candles": green_candles_count,
        "Red Candles": red_candles_count,
        "Total Candles": total_candles_count,
        "Monthly Data": monthly_data,
        "SMA_20_Series": sma_20,
        "SMA_50_Series": sma_50,
        "SMA_200_Series": sma_200
    }

def fetch_data():
    symbol = symbol_entry.get()
    if not symbol:
        messagebox.showerror("Error", "Please enter a stock symbol.")
        return
    try:
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
        display_results(results)
        plot_chart(results, symbol)
    except Exception as e:
        messagebox.showerror("Error", f"An error occurred: {str(e)}")

def display_results(results):
    result_text = (
        f"Current Price: {results['Current Price']}\n"
        f"Latest 20-month SMA: {results['SMA_20']}\n"
        f"Latest 50-month SMA: {results['SMA_50']}\n"
        f"Latest 200-month SMA: {results['SMA_200']}\n"
        f"Green candles: {results['Green Candles']}\n"
        f"Red candles: {results['Red Candles']}\n"
        f"Total candles: {results['Total Candles']}\n"
    )
    result_label.config(text=result_text)

def plot_chart(results, symbol):
    monthly_data = results["Monthly Data"]
    sma_20 = results["SMA_20_Series"]
    sma_50 = results["SMA_50_Series"]
    sma_200 = results["SMA_200_Series"]

    fig = Figure(figsize=(10, 5), dpi=100)
    ax = fig.add_subplot(111)

    ax.plot(monthly_data.index, monthly_data['Close'], label=f'{symbol} Close Price', color='blue')
    ax.plot(monthly_data.index, sma_20, label='20-month SMA', color='orange')
    ax.plot(monthly_data.index, sma_50, label='50-month SMA', color='green')
    ax.plot(monthly_data.index, sma_200, label='200-month SMA', color='red')

    ax.set_title(f'{symbol} Monthly Price with SMAs')
    ax.set_xlabel('Date')
    ax.set_ylabel('Price')
    ax.legend()

    global canvas
    if canvas:
        canvas.get_tk_widget().pack_forget()

    canvas = FigureCanvasTkAgg(fig, master=app)  # Updated from root to app
    canvas.draw()
    canvas.get_tk_widget().pack()

# GUI Setup
app = ttk.Window(themename="darkly")  # Choose a modern theme
app.title("SMA and Candle Count Calculator")
app.geometry("800x600")

canvas = None

symbol_label = ttk.Label(app, text="Stock Symbol:", bootstyle="info")
symbol_label.pack(pady=5)
symbol_entry = ttk.Entry(app, bootstyle="info")
symbol_entry.pack(pady=5)

fetch_button = ttk.Button(app, text="Fetch Data & Calculate", command=fetch_data, bootstyle="success")
fetch_button.pack(pady=10)

result_label = ttk.Label(app, text="", justify=LEFT, bootstyle="dark")
result_label.pack(pady=10)

app.mainloop()
