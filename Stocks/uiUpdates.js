function updateMovingAverages(ma20, ma50, ma200) {
    document.getElementById('ma20').textContent = ma20.length ? ma20[ma20.length - 1].toFixed(2) : 'N/A';
    document.getElementById('ma50').textContent = ma50.length ? ma50[ma50.length - 1].toFixed(2) : 'N/A';
    document.getElementById('ma200').textContent = ma200.length ? ma200[ma200.length - 1].toFixed(2) : 'N/A';
}
