function decodeBase64Password(base64Password) {
    // Validate Base64 string
    if (/^[a-zA-Z0-9+/]*={0,2}$/.test(base64Password)) {
        try {
            // Decode from base64 to binary
            const bytes = atob(base64Password);
            if (bytes) {
                try {
                    // Convert binary data to plain text
                    const plainTextPassword = decodeURIComponent(escape(bytes));
                    console.log("Plain text password:", plainTextPassword);
                } catch (e) {
                    console.error("Error: Unable to convert binary data to plain text.");
                }
            }
        } catch (e) {
            console.error("Error: The input is not a valid Base-64 string.");
        }
    } else {
        console.error("Error: The input is not a valid Base-64 string format.");
    }
}

// Example usage
// Should equal: Plain text password: P@ssw0rd123
const exampleBase64Password = "UEBzc3cwcmQxMjM=";
decodeBase64Password(exampleBase64Password);
