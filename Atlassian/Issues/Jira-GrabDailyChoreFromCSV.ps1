function Get-ChoreForToday {
    param (
        [string]$csvFilePath = "..\DATA\2024_ChoreList.csv"
    )

    # Get today's date without the time component
    $today = Get-Date -Format "yyyy-MM-dd"

    # Import the CSV file
    $chores = Import-Csv -Path $csvFilePath

    # Initialize a variable to store the output
    $output = ""

    # Iterate through the chores and find the one for today's date
    foreach ($chore in $chores) {
        if ($chore.Date -eq $today) {
            $output += "Today's chore is: $($chore.Chore). "
            if ($chore.Day) {
                $output += "It's scheduled for $($chore.Day)."
            }
            break  # Exit the loop once the chore for today is found
        }
    }

    # If today's chore is not found, set a message
    if ($output -eq "") {
        $output = "No chore found for today."
    }

    return $output
}

# Function to perform text-to-speech (TTS)
function Convert-TextToSpeech {
    param (
        [string]$text
    )

    Add-Type -TypeDefinition @"
    using System;
    using System.Speech.Synthesis;
"@

    $synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $synthesizer.Rate = 1
    $synthesizer.Speak($text)
    # Dispose of the SpeechSynthesizer object
    $synthesizer.Dispose()
}

# Call the function to get today's chore in natural language
$choreText = Get-ChoreForToday

# Call the function to convert and read out the text using TTS
Convert-TextToSpeech -text $choreText
