#!/bin/bash

# Function to display the help message
display_help() {
    echo "Usage: $0 [options] username"
    echo
    echo "Create a new user, install NvChad, Oh My Zsh, and set up Antigen."
    echo
    echo "Options:"
    echo "  --help         Display this help message and exit"
    echo "  --wheel        Add the user to the wheel group for sudo access"
}

# Check if the script is being run with superuser privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Check if the argument is --help
if [[ $1 == "--help" ]]; then
    display_help
    exit 0
fi

# Check if the argument is --wheel
if [[ $1 == "--wheel" ]]; then
    if [[ $# -lt 2 ]]; then
        echo "You must provide the username when using the --wheel option" >&2
        display_help
        exit 1
    fi
    wheel_group=true
    username=$2
else
    if [[ $# -eq 0 ]]; then
        echo "You must provide the username as an argument" >&2
        display_help
        exit 1
    fi
    username=$1
fi

resources=/root/utils/resources
default_permisions="770"

# Reverse the username to set it as the default password
password=$(echo "$username" | rev)

# Create the user with the default password and Zsh as the default shell
useradd_cmd="useradd -m -p $(openssl passwd -1 "$password") -s /bin/zsh $username -G users"
if [[ $wheel_group ]]; then
    useradd_cmd+="wheel"
fi
$useradd_cmd


# Switch to the user and install NvChad for Neovim
su - "$username" -c 'git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1'

# Instal NvChad custom config
su - "$username" -c 'git clone https://github.com/adrian-cancio/NvChad-custom ~/.config/nvim/lua/custom/'

# Set correct ownership on the home directory
sudo chown -R "$username:$username" "/home/$username"

# Set correct permissions on the home directory
sudo chmod $default_permisions "/home/$username"

# Install Oh My Zsh
su - "$username" -c 'sh -c "RUNZSH=\"no\" && $(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

# Install Antigen
su - "$username" -c 'curl -L git.io/antigen > ~/.antigen.zsh'

# Copy default .zshrc file
rm "/home/$username/.zshrc"
cp $resources/zshrc "/home/$username/.zshrc"
chown "$username:$username" "/home/$username/.zshrc"

su - "$username" -c "zsh -c \"echo 'User $username created sucesfully'\""
