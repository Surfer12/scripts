#!/usr/bin/env bash
#
# network_stats.sh - A script to display current network configuration and statistics
#
# This script gathers and displays comprehensive network information including:
# - Interface details
# - IP configurations
# - DNS settings
# - Network routes
# - Active connections
# - Network statistics
#

# Text formatting
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Function to print section headers
print_header() {
  echo -e "\n${BOLD}${BLUE}$1${RESET}\n"
}

# Function to check if command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Function to display interface information
show_interfaces() {
  print_header "Network Interfaces"
  
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS specific commands
    echo -e "${BOLD}Active Interfaces:${RESET}"
    networksetup -listallhardwareports | grep -E "Hardware Port:|Device:|Ethernet Address:" | sed 's/^/  /'
    
    echo -e "\n${BOLD}Interface Details:${RESET}"
    ifconfig | grep -E "^[a-z0-9]+:|inet |status:|media:" | sed 's/^/  /'
  else
    # Linux and other Unix-like systems
    echo -e "${BOLD}Interface List:${RESET}"
    ip -brief link show | sed 's/^/  /'
    
    echo -e "\n${BOLD}Interface Details:${RESET}"
    ip addr | grep -E "^[0-9]+:|inet " | sed 's/^/  /'
  fi
}

# Function to display IP configuration
show_ip_config() {
  print_header "IP Configuration"
  
  if [[ "$(uname)" == "Darwin" ]]; then
    # Get primary interface
    PRIMARY_INTERFACE=$(route -n get default 2>/dev/null | grep interface | awk '{print $2}')
    if [[ -z "$PRIMARY_INTERFACE" ]]; then
      PRIMARY_INTERFACE=$(netstat -rn | grep default | head -1 | awk '{print $NF}')
    fi
    
    if [[ -n "$PRIMARY_INTERFACE" ]]; then
      echo -e "${BOLD}Primary Interface:${RESET} $PRIMARY_INTERFACE"
      
      # Get IP information
      IP_INFO=$(ifconfig "$PRIMARY_INTERFACE" | grep "inet " | awk '{print $2}')
      NETMASK=$(ifconfig "$PRIMARY_INTERFACE" | grep "inet " | awk '{print $4}')
      BROADCAST=$(ifconfig "$PRIMARY_INTERFACE" | grep "inet " | awk '{print $6}')
      
      echo -e "${BOLD}IPv4 Address:${RESET} $IP_INFO"
      echo -e "${BOLD}Netmask:${RESET} $NETMASK"
      [[ -n "$BROADCAST" ]] && echo -e "${BOLD}Broadcast:${RESET} $BROADCAST"
      
      # Get IPv6 information
      IPv6_INFO=$(ifconfig "$PRIMARY_INTERFACE" | grep "inet6 " | grep -v "%$PRIMARY_INTERFACE" | awk '{print $2}')
      if [[ -n "$IPv6_INFO" ]]; then
        echo -e "${BOLD}IPv6 Address:${RESET} $IPv6_INFO"
      fi
      
      # Get public IP
      if command_exists curl; then
        echo -e "\n${BOLD}Public IP Address:${RESET}"
        curl -s https://api.ipify.org && echo
      fi
    else
      echo -e "${RED}Could not determine primary interface.${RESET}"
    fi
  else
    # Linux and other Unix-like systems
    # Get primary interface
    PRIMARY_INTERFACE=$(ip route | grep default | head -1 | awk '{print $5}')
    
    if [[ -n "$PRIMARY_INTERFACE" ]]; then
      echo -e "${BOLD}Primary Interface:${RESET} $PRIMARY_INTERFACE"
      
      # Get IP information
      IP_INFO=$(ip addr show "$PRIMARY_INTERFACE" | grep "inet " | awk '{print $2}')
      
      echo -e "${BOLD}IPv4 Address:${RESET} $IP_INFO"
      
      # Get IPv6 information
      IPv6_INFO=$(ip addr show "$PRIMARY_INTERFACE" | grep "inet6 " | awk '{print $2}')
      if [[ -n "$IPv6_INFO" ]]; then
        echo -e "${BOLD}IPv6 Address:${RESET} $IPv6_INFO"
      fi
      
      # Get public IP
      if command_exists curl; then
        echo -e "\n${BOLD}Public IP Address:${RESET}"
        curl -s https://api.ipify.org && echo
      fi
    else
      echo -e "${RED}Could not determine primary interface.${RESET}"
    fi
  fi
}

# Function to display DNS settings
show_dns_settings() {
  print_header "DNS Configuration"
  
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS specific commands
    echo -e "${BOLD}DNS Servers:${RESET}"
    scutil --dns | grep "nameserver\[[0-9]*\]" | sed 's/^/  /'
    
    echo -e "\n${BOLD}Search Domains:${RESET}"
    scutil --dns | grep "search domain" | sed 's/^/  /'
  else
    # Linux and other Unix-like systems
    echo -e "${BOLD}DNS Configuration:${RESET}"
    cat /etc/resolv.conf | grep -E "^nameserver|^search|^domain" | sed 's/^/  /'
  fi
}

# Function to display network routes
show_routes() {
  print_header "Network Routes"
  
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS specific commands
    echo -e "${BOLD}Routing Table:${RESET}"
    netstat -rn | sed 's/^/  /'
  else
    # Linux and other Unix-like systems
    echo -e "${BOLD}Routing Table:${RESET}"
    ip route | sed 's/^/  /'
  fi
}

# Function to display active connections
show_connections() {
  print_header "Active Network Connections"
  
  echo -e "${BOLD}Active TCP Connections:${RESET}"
  netstat -tn | head -n 30 | sed 's/^/  /'
  
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS specific commands
    echo -e "\n${BOLD}Top 10 Connections by Process:${RESET}"
    lsof -i -n -P | grep ESTABLISHED | awk '{print $1,$9}' | sort | uniq -c | sort -rn | head -10 | sed 's/^/  /'
  else
    # Linux and other Unix-like systems
    if command_exists ss; then
      echo -e "\n${BOLD}Top 10 Connections by Process:${RESET}"
      ss -tp | grep ESTAB | awk '{print $6}' | sort | uniq -c | sort -rn | head -10 | sed 's/^/  /'
    fi
  fi
}

# Function to display network statistics
show_network_stats() {
  print_header "Network Statistics"
  
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS specific commands
    echo -e "${BOLD}Network Statistics:${RESET}"
    netstat -s | head -n 40 | sed 's/^/  /'
  else
    # Linux and other Unix-like systems
    echo -e "${BOLD}Network Interface Statistics:${RESET}"
    netstat -i | sed 's/^/  /'
    
    echo -e "\n${BOLD}Protocol Statistics:${RESET}"
    netstat -s | head -n 40 | sed 's/^/  /'
  fi
}

# Function to display wireless information
show_wireless_info() {
  print_header "Wireless Information"
  
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS specific commands
    if command_exists airport; then
      echo -e "${BOLD}Current Wi-Fi Information:${RESET}"
      airport -I | sed 's/^/  /'
    else
      AIRPORT="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
      if [[ -f "$AIRPORT" ]]; then
        echo -e "${BOLD}Current Wi-Fi Information:${RESET}"
        "$AIRPORT" -I | sed 's/^/  /'
      else
        echo -e "${BOLD}Wi-Fi Information:${RESET}"
        networksetup -getairportnetwork en0 | sed 's/^/  /'
      fi
    fi
  else
    # Linux and other Unix-like systems
    if command_exists iwconfig; then
      echo -e "${BOLD}Wireless Information:${RESET}"
      iwconfig 2>/dev/null | grep -v "no wireless" | sed 's/^/  /'
    elif command_exists iw; then
      echo -e "${BOLD}Wireless Information:${RESET}"
      iw dev | sed 's/^/  /'
    else
      echo -e "${YELLOW}No wireless tools found (iwconfig/iw)${RESET}"
    fi
  fi
}

# Main function
main() {
  echo -e "${BOLD}Network Configuration and Statistics${RESET}"
  echo -e "System: $(uname -s) $(uname -r)"
  echo -e "Date: $(date)"
  
  # Show various network information
  show_interfaces
  show_ip_config
  show_dns_settings
  show_routes
  show_wireless_info
  show_connections
  show_network_stats
  
  print_header "Done"
  echo -e "Network configuration and statistics displayed successfully."
}

# Run the main function
main