import pandas as pd
import yfinance as yf
import matplotlib.pyplot as plt
import mplfinance as mpf
from matplotlib.dates import DateFormatter
from datetime import datetime

def analyze_stock(stock_symbol, start_date, end_date=None):
    # Set end date to today's date if not provided
    if end_date is None:
        end_date = datetime.today().strftime('%Y-%m-%d')
    
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
    # Updated to use 10% instead of 1% for determining closeness
    data['Close_to_MA20'] = abs(data['Close'] - data['MA20']) < (data['Close'] * 0.10)  # within 10% of MA20
    data['Between_MA20_MA50'] = (data['Close'] > data['MA20']) & (data['Close'] < data['MA50'])

    close_to_ma20 = data['Close_to_MA20'].iloc[-1] if not data['Close_to_MA20'].empty else False
    between_ma20_ma50 = data['Between_MA20_MA50'].iloc[-1] if not data['Between_MA20_MA50'].empty else False

    # Calculate buy signal prices
    data['Buy_Above_MA20'] = data['MA20'] * 1.10  # 10% above MA20
    data['Buy_On_MA20'] = data['MA20']             # On MA20
    data['Buy_Below_MA20'] = data['MA20'] * 0.90  # 10% below MA20

    buy_above_ma20 = data['Buy_Above_MA20'].iloc[-1]
    buy_on_ma20 = data['Buy_On_MA20'].iloc[-1]
    buy_below_ma20 = data['Buy_Below_MA20'].iloc[-1]

    # Print results
    analysis_info = (f"Total Green Candlesticks: {green_count}\n"
                     f"Total Red Candlesticks: {red_count}\n"
                     f"Longest Green Streak: {max_green_streak}\n"
                     f"Longest Red Streak: {max_red_streak}\n"
                     f"20 MA is moving upward: {ma20_upward}\n"
                     f"Close price is close to 20 MA: {close_to_ma20}\n"
                     f"Close price is between 20 MA and 50 MA: {between_ma20_ma50}\n"
                     f"Buy 10% above MA20: {buy_above_ma20:.2f}\n"
                     f"Buy on MA20: {buy_on_ma20:.2f}\n"
                     f"Buy 10% below MA20: {buy_below_ma20:.2f}")
    print(analysis_info)

    # Plotting the chart
    apds = [mpf.make_addplot(data['MA20'], color='blue', linestyle='--', label='MA20'),
            mpf.make_addplot(data['MA50'], color='orange', linestyle='--', label='MA50'),
            mpf.make_addplot(data['MA200'], color='red', linestyle='--', label='MA200')]

    fig, axlist = mpf.plot(data, type='candle', style='charles', addplot=apds, returnfig=True, volume=False)
    
    # Add horizontal lines for buy levels
    axlist[0].axhline(y=buy_above_ma20, color='green', linestyle=':', label='Buy 10% Above MA20')
    axlist[0].axhline(y=buy_on_ma20, color='blue', linestyle=':', label='Buy On MA20')
    axlist[0].axhline(y=buy_below_ma20, color='red', linestyle=':', label='Buy 10% Below MA20')
    
    # Display analysis info on chart
    plt.figtext(0.14, 0.01, analysis_info, horizontalalignment='left', fontsize=10)

    plt.title(f'{stock_symbol} Monthly Analysis')
    plt.xlabel('Date')
    plt.ylabel('Price')
    
    # Formatting date axis
    date_form = DateFormatter("%Y-%m")
    axlist[0].xaxis.set_major_formatter(date_form)
    
    # Add legend
    handles, labels = axlist[0].get_legend_handles_labels()
    axlist[0].legend(handles=handles, labels=labels)

    plt.show()

# Example usage
analyze_stock('AMD', '2020-01-01')
