#!/bin/bash

# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "GITHUB_EMAIL" -f ~/.ssh/id_rsa

# Output public key
echo "Your public SSH key is:"
cat ~/.ssh/id_rsa.pub
