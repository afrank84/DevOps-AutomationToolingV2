function updateCandleCounts(data) {
    let greenCount = 0;
    let redCount = 0;
    let totalCount = data.length;

    data.forEach(candle => {
        if (candle.c > candle.o) {
            greenCount++;
        } else if (candle.c < candle.o) {
            redCount++;
        }
    });

    document.getElementById('totalCount').textContent = totalCount;
    document.getElementById('greenCount').textContent = greenCount;
    document.getElementById('redCount').textContent = redCount;
}

function calculateMovingAverage(data, period) {
    let movingAverages = [];
    for (let i = 0; i <= data.length - period; i++) {
        let sum = 0;
        for (let j = 0; j < period; j++) {
            sum += data[i + j].c;
        }
        movingAverages.push(sum / period);
    }
    return movingAverages;
}

function aggregateToMonthly(data) {
    const monthlyData = [];
    let currentMonth = null;
    let monthlyCandle = null;

    data.forEach(candle => {
        const date = new Date(candle.x);
        const month = `${date.getFullYear()}-${date.getMonth() + 1}`; // Format: YYYY-MM

        if (currentMonth !== month) {
            if (monthlyCandle) {
                monthlyData.push(monthlyCandle);
            }
            currentMonth = month;
            monthlyCandle = {
                x: date.getTime(), // Set the timestamp for the first day of the month
                o: candle.o,
                h: candle.h,
                l: candle.l,
                c: candle.c
            };
        } else {
            monthlyCandle.h = Math.max(monthlyCandle.h, candle.h);
            monthlyCandle.l = Math.min(monthlyCandle.l, candle.l);
            monthlyCandle.c = candle.c; // Close price of the last day in the month
        }
    });

    // Push the last monthly candle
    if (monthlyCandle) {
        monthlyData.push(monthlyCandle);
    }

    return monthlyData;
}

function parseCSVData(csvData) {
    Papa.parse(csvData, {
        header: true,
        dynamicTyping: true,
        skipEmptyLines: true,
        complete: function (results) {
            const candlestickData = results.data.map(row => ({
                x: new Date(row['Date']).getTime(),
                o: row['Open'],
                h: row['High'],
                l: row['Low'],
                c: row['Close']
            }));

            // Calculate 200MA on daily data
            const ma200 = calculateMovingAverage(candlestickData, 200);

            // Aggregate data into monthly candles
            const monthlyCandlestickData = aggregateToMonthly(candlestickData);

            // Calculate moving averages on monthly data
            const ma20 = calculateMovingAverage(monthlyCandlestickData, 20);
            const ma50 = calculateMovingAverage(monthlyCandlestickData, 50);

            // Update moving averages in UI
            updateMovingAverages(ma20, ma50, ma200);

            // Update the chart with the monthly data
            chart.config.data.datasets[0].data = monthlyCandlestickData;
            chart.update();

            // Update the candle counts
            updateCandleCounts(monthlyCandlestickData);
        }
    });
}
