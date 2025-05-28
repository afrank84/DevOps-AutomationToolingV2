#!/usr/bin/perl
use strict;
use warnings;

# Function to execute system commands and handle errors
sub run_cmd {
    my ($cmd) = @_;
    print "Executing: $cmd\n";
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

# Function to install Brave Browser
sub install_brave {
    print "\n--- Installing Brave Browser ---\n";
    if (is_installed("brave-browser")) {
        print "Brave Browser is already installed.\n";
        return;
    }

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
    print "\n--- Installing Visual Studio Code ---\n";
    if (is_installed("code")) {
        print "Visual Studio Code is already installed.\n";
        return;
    }

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
    print "\n--- Installing Obsidian ---\n";
    if (is_installed("obsidian")) {
        print "Obsidian is already installed.\n";
        return;
    }

    # Check if snap is installed
    if (system("command -v snap > /dev/null 2>&1") != 0) {
        print "Installing snapd...\n";
        run_cmd("sudo apt update");
        run_cmd("sudo apt install -y snapd");
    } else {
        print "snapd is already installed.\n";
    }

    print "Installing Obsidian via snap...\n";
    run_cmd("sudo snap install obsidian --classic");
    print "Obsidian installation completed.\n";
}

# Function to install Git
sub install_git {
    print "\n--- Installing Git ---\n";
    if (is_installed("git")) {
        print "Git is already installed.\n";
        return;
    }

    run_cmd("sudo apt update");
    run_cmd("sudo apt install -y git");
    print "Git installation completed.\n";
}

# Main menu
sub main_menu {
    print "\nSelect an option to install:\n";
    print "1. Brave Browser\n";
    print "2. Visual Studio Code\n";
    print "3. Obsidian\n";
    print "4. Git\n";
    print "5. Install All\n";
    print "6. Exit\n";
    print "Enter your choice (1-6): ";

    chomp(my $choice = <STDIN>);

    if    ($choice eq '1') { install_brave(); }
    elsif ($choice eq '2') { install_vscode(); }
    elsif ($choice eq '3') { install_obsidian(); }
    elsif ($choice eq '4') { install_git(); }
    elsif ($choice eq '5') {
        install_brave();
        install_vscode();
        install_obsidian();
        install_git();
    }
    elsif ($choice eq '6') {
        print "Exiting the installer. Goodbye!\n";
        exit 0;
    }
    else {
        print "Invalid choice. Please enter a number between 1 and 6.\n";
    }
}

# Run the main menu
main_menu();
