import random
import string

# Function to generate a random key
def generate_key(length=16):
    characters = string.ascii_uppercase + string.digits
    key = ''.join(random.choice(characters) for _ in range(length))
    
    # Optional: Add dashes to the key to make it more readable (like XXXXX-XXXXX-XXXXX)
    formatted_key = '-'.join(key[i:i+4] for i in range(0, len(key), 4))
    return formatted_key

# Generate multiple keys
def generate_multiple_keys(count, length=16):
    keys = []
    for _ in range(count):
        keys.append(generate_key(length))
    return keys

# Simple key validation function
def validate_key(key):
    # Check if the key is the right format (length and dash positions)
    if len(key) != 19:
        return False
    
    # Check if key only contains valid characters (letters and numbers, and dashes)
    allowed_chars = string.ascii_uppercase + string.digits + '-'
    return all(c in allowed_chars for c in key)

# Generate and print 5 keys
if __name__ == "__main__":
    number_of_keys = 5
    keys = generate_multiple_keys(number_of_keys)
    for key in keys:
        print("Generated Key:", key)
