#!/bin/bash

# Ensure the script is running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

# Prompt user for necessary variables
read -p "Enter your Client IPv4 address [YOUR_CLIENT_IPV4]: " YOUR_CLIENT_IPV4
read -p "Enter the Tunnel Server IPv4 address [TUNNEL_SERVER_IPV4]: " TUNNEL_SERVER_IPV4
read -p "Enter your IPv6 block [YOUR_IPV6_BLOCK]: " YOUR_IPV6_BLOCK

# Update package list and install required packages
echo "Updating package list and installing required packages..."
apt-get update -y
apt-get install -y iputils-ping 

# Enabling IPv6 Non-Local Bind
sysctl -w net.ipv6.ip_nonlocal_bind=1
echo 'net.ipv6.ip_nonlocal_bind = 1' >> /etc/sysctl.conf

# Set up the IPv6 tunnel using the tunnel broker service
echo "Setting up IPv6 tunnel..."

# Command 1: Add IPv6 Tunnel Interface
ip tunnel add he-ipv6 mode sit remote $TUNNEL_SERVER_IPV4 local $YOUR_CLIENT_IPV4 ttl 255

# Command 2: Set up IPv6 Tunnel Interface
ip link set he-ipv6 up

# Command 3: Add IPv6 Address to the Tunnel Interface
ip addr add $YOUR_IPV6_BLOCK::2/48 dev he-ipv6

# Command 4: Add IPv6 Default Route
ip route add ::/0 via $YOUR_IPV6_BLOCK::1 dev he-ipv6

# Command 5: Handle Limited Pingability
ip -6 route replace local $YOUR_IPV6_BLOCK::/48 dev lo

# Verify that the tunnel is working by pinging an IPv6 address
echo "Verifying tunnel setup..."
ping6 -c 4 ipv6.google.com

# Check if the ping was successful
if [ $? -eq 0 ]; then
  echo "IPv6 tunnel is working correctly!"
else
  echo "IPv6 tunnel setup failed. Please check your configuration."
  exit 1
fi

echo "To make the tunnel persistent across reboots, read the documentation to Persist for next boot"
