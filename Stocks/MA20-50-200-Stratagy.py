import pandas as pd
import yfinance as yf
import ta

def analyze_stock(stock_symbol, start_date, end_date):
    # Download stock data from Yahoo Finance
    data = yf.download(stock_symbol, start=start_date, end=end_date, interval="1mo")
    
    # Calculate moving averages
    data['MA20'] = data['Close'].rolling(window=20).mean()
    data['MA50'] = data['Close'].rolling(window=50).mean()

    # Identify green (close > open) and red (open > close) candlesticks
    data['Green'] = data['Close'] > data['Open']
    data['Red'] = data['Open'] > data['Close']

    # Count total green and red candlesticks
    green_count = data['Green'].sum()
    red_count = data['Red'].sum()

    # Calculate most consecutive green and red bars
    data['Green_streak'] = (data['Green'] != data['Green'].shift()).cumsum()
    data['Red_streak'] = (data['Red'] != data['Red'].shift()).cumsum()
    
    green_streaks = data[data['Green']].groupby('Green_streak').size()
    red_streaks = data[data['Red']].groupby('Red_streak').size()
    
    max_green_streak = green_streaks.max()
    max_red_streak = red_streaks.max()

    # Identify if MA is moving upward (last 2 months for simplicity)
    data['MA20_slope'] = data['MA20'].diff()
    data['MA20_upward'] = data['MA20_slope'] > 0
    ma20_upward = data['MA20_upward'].iloc[-2:].all()

    # Check if close price is close to 20 MA or between 20 MA and 50 MA
    data['Close_to_MA20'] = abs(data['Close'] - data['MA20']) < (data['Close'] * 0.01)  # within 1% of MA20
    data['Between_MA20_MA50'] = (data['Close'] > data['MA20']) & (data['Close'] < data['MA50'])

    close_to_ma20 = data['Close_to_MA20'].iloc[-1]
    between_ma20_ma50 = data['Between_MA20_MA50'].iloc[-1]

    # Print results
    print(f"Total Green Candlesticks: {green_count}")
    print(f"Total Red Candlesticks: {red_count}")
    print(f"Longest Green Streak: {max_green_streak}")
    print(f"Longest Red Streak: {max_red_streak}")
    print(f"20 MA is moving upward: {ma20_upward}")
    print(f"Close price is close to 20 MA: {close_to_ma20}")
    print(f"Close price is between 20 MA and 50 MA: {between_ma20_ma50}")

# Example usage
analyze_stock('AAPL', '2020-01-01', '2023-12-31')
