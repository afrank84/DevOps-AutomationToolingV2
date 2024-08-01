var ctx = document.getElementById('chart').getContext('2d');
ctx.canvas.width = 1000;
ctx.canvas.height = 250;

var chart = new Chart(ctx, {
    type: 'candlestick',
    data: {
        datasets: [{
            label: 'Stock Price',
            data: []
        }]
    },
    options: {
        scales: {
            x: {
                type: 'time',
                time: {
                    unit: 'month',
                    tooltipFormat: 'll',
                    displayFormats: {
                        month: 'MMM yyyy'
                    }
                },
                ticks: {
                    source: 'data',
                    autoSkip: false,
                    maxRotation: 0,
                    minRotation: 0
                }
            },
            y: {
                beginAtZero: false
            }
        },
        plugins: {
            zoom: {
                pan: {
                    enabled: true,
                    mode: 'x',  // Allow panning in the x-axis only
                },
                zoom: {
                    enabled: true,
                    mode: 'x',  // Allow zooming in the x-axis only
                    drag: true
                }
            }
        }
    }
});
