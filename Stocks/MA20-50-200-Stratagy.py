import pandas as pd
import yfinance as yf
import ta
import matplotlib.pyplot as plt
import mplfinance as mpf
from matplotlib.dates import DateFormatter

def analyze_stock(stock_symbol, start_date, end_date):
    # Download stock data from Yahoo Finance
    data = yf.download(stock_symbol, start=start_date, end=end_date, interval="1mo")
    
    # Drop rows with NaN values to avoid plotting issues
    data.dropna(inplace=True)

    # Calculate moving averages with a minimum period to ensure they have enough data points
    data['MA20'] = data['Close'].rolling(window=20, min_periods=1).mean()
    data['MA50'] = data['Close'].rolling(window=50, min_periods=1).mean()
    data['MA200'] = data['Close'].rolling(window=200, min_periods=1).mean()

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
    
    max_green_streak = green_streaks.max() if not green_streaks.empty else 0
    max_red_streak = red_streaks.max() if not red_streaks.empty else 0

    # Identify if MA is moving upward (last 2 months for simplicity)
    data['MA20_slope'] = data['MA20'].diff()
    data['MA20_upward'] = data['MA20_slope'] > 0
    ma20_upward = data['MA20_upward'].iloc[-2:].all() if len(data) > 1 else False

    # Check if close price is close to 20 MA or between 20 MA and 50 MA
    data['Close_to_MA20'] = abs(data['Close'] - data['MA20']) < (data['Close'] * 0.01)  # within 1% of MA20
    data['Between_MA20_MA50'] = (data['Close'] > data['MA20']) & (data['Close'] < data['MA50'])

    close_to_ma20 = data['Close_to_MA20'].iloc[-1] if not data['Close_to_MA20'].empty else False
    between_ma20_ma50 = data['Between_MA20_MA50'].iloc[-1] if not data['Between_MA20_MA50'].empty else False

    # Print results
    analysis_info = (f"Total Green Candlesticks: {green_count}\n"
                     f"Total Red Candlesticks: {red_count}\n"
                     f"Longest Green Streak: {max_green_streak}\n"
                     f"Longest Red Streak: {max_red_streak}\n"
                     f"20 MA is moving upward: {ma20_upward}\n"
                     f"Close price is close to 20 MA: {close_to_ma20}\n"
                     f"Close price is between 20 MA and 50 MA: {between_ma20_ma50}")
    print(analysis_info)

    # Plotting the chart
    apds = [mpf.make_addplot(data['MA20'], color='blue', linestyle='--'),
            mpf.make_addplot(data['MA50'], color='orange', linestyle='--'),
            mpf.make_addplot(data['MA200'], color='red', linestyle='--')]

    fig, axlist = mpf.plot(data, type='candle', style='charles', addplot=apds, returnfig=True, volume=False)
    
    # Display analysis info on chart
    plt.figtext(0.14, 0.01, analysis_info, horizontalalignment='left', fontsize=10)

    plt.title(f'{stock_symbol} Monthly Analysis')
    plt.xlabel('Date')
    plt.ylabel('Price')
    
    # Formatting date axis
    date_form = DateFormatter("%Y-%m")
    axlist[0].xaxis.set_major_formatter(date_form)
    
    plt.show()

# Example usage
analyze_stock('AMD', '2020-01-01', '2023-12-31')
