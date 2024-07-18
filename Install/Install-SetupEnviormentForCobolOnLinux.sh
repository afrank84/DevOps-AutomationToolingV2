#!/bin/bash

# Update package list and upgrade all packages
echo "Updating package list..."
sudo apt update -y && sudo apt upgrade -y

# Install necessary packages
echo "Installing necessary packages..."
sudo apt install -y build-essential wget

# Download and install GnuCOBOL
echo "Downloading GnuCOBOL..."
wget https://ftp.gnu.org/gnu/gnucobol/gnucobol-3.1.2.tar.xz

echo "Extracting GnuCOBOL..."
tar -xf gnucobol-3.1.2.tar.xz
cd gnucobol-3.1.2

echo "Installing GnuCOBOL..."
./configure
make
sudo make install

# Verify the installation
echo "Verifying the GnuCOBOL installation..."
cobc -v

# Clean up
echo "Cleaning up..."
cd ..
rm -rf gnucobol-3.1.2 gnucobol-3.1.2.tar.xz

# Create a sample COBOL program
echo "Creating a sample COBOL program..."
cat << 'EOF' > hello.cob
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLO.
       PROCEDURE DIVISION.
       DISPLAY 'Hello, World!'.
       STOP RUN.
EOF

# Compile and run the sample COBOL program
echo "Compiling the sample COBOL program..."
cobc -x hello.cob

echo "Running the sample COBOL program..."
./hello

echo "COBOL environment setup is complete!"
