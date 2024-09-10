import hashlib

# Function to generate a key based on user information (like email)
def generate_key_from_user_info(user_info, secret_key, length=16):
    hash_input = user_info + secret_key
    key = hashlib.sha256(hash_input.encode()).hexdigest().upper()[:length]
    
    # Optional: Add dashes for readability
    formatted_key = '-'.join(key[i:i+4] for i in range(0, len(key), 4))
    return formatted_key

# Example of generating a key tied to user information
user_email = "user@example.com"
secret = "MySecretKey"

generated_key = generate_key_from_user_info(user_email, secret)
print("Generated Key for User:", generated_key)
