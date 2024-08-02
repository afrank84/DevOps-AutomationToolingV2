document.getElementById('csvForm').addEventListener('submit', function (event) {
    event.preventDefault();

    const fileInput = document.getElementById('csvFile');
    const file = fileInput.files[0];

    if (file) {
        const reader = new FileReader();
        reader.onload = function (e) {
            const csvData = e.target.result;
            parseCSVData(csvData);
        };
        reader.readAsText(file);
    } else {
        alert("Please upload a CSV file.");
    }
});
