#!/usr/bin/perl
use strict;
use warnings;

# Function to execute system commands and handle errors
sub run_cmd {
    my ($cmd) = @_;
    print "Running: $cmd\n";
    system($cmd) == 0 or die "Command failed: $cmd\n";
}

# Function to check if a package is installed
sub is_installed {
    my ($pkg) = @_;
    my $output = `dpkg-query -l | grep $pkg 2>/dev/null`;
    return $output ne '';
}

# Function to install curl if not already installed
sub install_curl_if_needed {
    if (system("command -v curl > /dev/null 2>&1") != 0) {
        print "Installing curl...\n";
        run_cmd("sudo apt update");
        run_cmd("sudo apt install -y curl");
    } else {
        print "curl is already installed.\n";
    }
}

# Function to install Git
sub install_git {
    print "Checking if Git is already installed...\n";
    if (is_installed("git")) {
        print "Git is already installed.\n";
        return;
    }

    print "Installing Git...\n";
    run_cmd("sudo apt update");
    run_cmd("sudo apt install -y git");
    print "Git installation completed.\n";
}

# Function to install Brave Browser
sub install_brave {
    print "Checking if Brave Browser is already installed...\n";
    if (is_installed("brave-browser")) {
        print "Brave Browser is already installed.\n";
        return;
    }

    print "Installing Brave Browser...\n";
    install_curl_if_needed();

    print "Adding Brave's GPG key...\n";
    run_cmd("sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg");

    my $sources_file = "/etc/apt/sources.list.d/brave-browser-release.list";
    unless (-e $sources_file && `grep brave-browser-apt-release.s3.brave.com $sources_file 2>/dev/null`) {
        print "Adding Brave's repository...\n";
        run_cmd("echo 'deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main' | sudo tee $sources_file");
    } else {
        print "Brave repository already exists.\n";
    }

    run_cmd("sudo apt update");
    run_cmd("sudo apt install -y brave-browser");
    print "Brave Browser installation completed.\n";
}

# Function to install Visual Studio Code
sub install_vscode {
    print "Checking if Visual Studio Code is already installed...\n";
    if (is_installed("code")) {
        print "Visual Studio Code is already installed.\n";
        return;
    }

    print "Installing Visual Studio Code...\n";
    install_curl_if_needed();

    print "Adding Microsoft's GPG key...\n";
    run_cmd("sudo curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/vscode-archive-keyring.gpg > /dev/null");

    my $vscode_list = "/etc/apt/sources.list.d/vscode.list";
    unless (-e $vscode_list && `grep packages.microsoft.com/repos/code $vscode_list 2>/dev/null`) {
        print "Adding Visual Studio Code repository...\n";
        run_cmd("echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/vscode-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main' | sudo tee $vscode_list");
    } else {
        print "Visual Studio Code repository already exists.\n";
    }

    run_cmd("sudo apt update");
    run_cmd("sudo apt install -y code");
    print "Visual Studio Code installation completed.\n";
}

# Function to install Obsidian
sub install_obsidian {
    print "Checking if Obsidian is already installed...\n";
    if (is_installed("obsidian")) {
        print "Obsidian is already installed.\n";
        return;
    }

    print "Installing Obsidian...\n";
    install_curl_if_needed();

    # Download the latest Obsidian .deb package
    my $obsidian_deb = "/tmp/obsidian.deb";
    run_cmd("curl -L https://github.com/obsidianmd/obsidian-releases/releases/latest/download/obsidian_amd64.deb -o $obsidian_deb");

    # Install the downloaded package
    run_cmd("sudo dpkg -i $obsidian_deb");

    # Fix any missing dependencies
    run_cmd("sudo apt-get install -f -y");

    # Clean up
    unlink $obsidian_deb;
    print "Obsidian installation completed.\n";
}

# Main menu
while (1) {
    print "\nChoose an option:\n";
    print "1. Install Brave Browser\n";
    print "2. Install Visual Studio Code\n";
    print "3. Install Obsidian\n";
    print "4. Install Git\n";
    print "5. Install All\n";
    print "6. Exit\n";
    print "Enter your choice (1-6): ";

    chomp(my $choice = <STDIN>);

    if    ($choice eq '1') { install_brave(); }
    elsif ($choice eq '2') { install_git(); install_vscode(); }
    elsif ($choice eq '3') { install_obsidian(); }
    elsif ($choice eq '4') { install_git(); }
    elsif ($choice eq '5') {
        install_git();
        install_brave();
        install_vscode();
        install_obsidian();
    }
    elsif ($choice eq '6') {
        print "Exiting.\n";
        last;
    }
    else {
        print "Invalid choice. Please enter a number between 1 and 6.\n";
    }
}
