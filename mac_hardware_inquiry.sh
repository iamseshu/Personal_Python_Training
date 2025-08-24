#!/bin/bash

#################################################
# Mac Hardware ID Inquiry Script
# 
# This script queries various hardware IDs from a series of Mac computers
# using their IP addresses via SSH connection.
# 
# Author: Assistant
# Version: 1.0
#################################################

# Colors for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SSH_USER=""
SSH_KEY=""
OUTPUT_DIR="mac_hardware_reports"
TIMEOUT=10
VERBOSE=false

# Array to store IP addresses
declare -a MAC_IPS=()

# Function to display usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS] -u USERNAME -i IP1,IP2,IP3...

Mac Hardware ID Inquiry Script

This script connects to Mac computers via SSH and retrieves various hardware IDs
including serial numbers, hardware UUIDs, MAC addresses, and system information.

OPTIONS:
    -u, --user USERNAME        SSH username for connecting to Macs (required)
    -k, --key KEY_PATH        Path to SSH private key file (optional)
    -i, --ips IP_LIST         Comma-separated list of IP addresses (required)
    -f, --file IP_FILE        File containing IP addresses (one per line)
    -o, --output DIR          Output directory for reports (default: mac_hardware_reports)
    -t, --timeout SECONDS    SSH connection timeout (default: 10)
    -v, --verbose             Enable verbose output
    -h, --help               Display this help message

EXAMPLES:
    $0 -u admin -i 192.168.1.10,192.168.1.11,192.168.1.12
    $0 -u admin -k ~/.ssh/mac_key -f ip_list.txt -o reports
    $0 -u admin -i 192.168.1.10 -v

PREREQUISITES:
    1. SSH access must be enabled on target Macs
    2. SSH key-based authentication recommended
    3. Target Macs must be reachable on the network

EOF
}

# Function to log messages
log() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
    fi
}

# Function to print error messages
error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to print success messages
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to print warning messages
warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if SSH connection is possible
check_ssh_connection() {
    local ip=$1
    local ssh_opts="-o ConnectTimeout=$TIMEOUT -o BatchMode=yes -o StrictHostKeyChecking=no"
    
    if [[ -n "$SSH_KEY" ]]; then
        ssh_opts="$ssh_opts -i $SSH_KEY"
    fi
    
    log "Testing SSH connection to $ip"
    
    if ssh $ssh_opts "$SSH_USER@$ip" "echo 'SSH connection successful'" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to retrieve hardware information from a Mac
get_mac_hardware_info() {
    local ip=$1
    local output_file="$OUTPUT_DIR/hardware_info_${ip}.txt"
    local ssh_opts="-o ConnectTimeout=$TIMEOUT -o BatchMode=yes -o StrictHostKeyChecking=no"
    
    if [[ -n "$SSH_KEY" ]]; then
        ssh_opts="$ssh_opts -i $SSH_KEY"
    fi
    
    echo "=================================================" > "$output_file"
    echo "Hardware Information for Mac at IP: $ip" >> "$output_file"
    echo "Date: $(date)" >> "$output_file"
    echo "=================================================" >> "$output_file"
    echo >> "$output_file"
    
    # Test SSH connection first
    if ! check_ssh_connection "$ip"; then
        error "Cannot establish SSH connection to $ip"
        echo "ERROR: SSH connection failed" >> "$output_file"
        return 1
    fi
    
    success "Connected to $ip - Retrieving hardware information..."
    
    # Get system overview
    echo "=== SYSTEM OVERVIEW ===" >> "$output_file"
    ssh $ssh_opts "$SSH_USER@$ip" "system_profiler SPSoftwareDataType | head -20" >> "$output_file" 2>/dev/null
    echo >> "$output_file"
    
    # Get hardware overview
    echo "=== HARDWARE OVERVIEW ===" >> "$output_file"
    ssh $ssh_opts "$SSH_USER@$ip" "system_profiler SPHardwareDataType" >> "$output_file" 2>/dev/null
    echo >> "$output_file"
    
    # Get serial number
    echo "=== SERIAL NUMBER ===" >> "$output_file"
    ssh $ssh_opts "$SSH_USER@$ip" "system_profiler SPHardwareDataType | grep 'Serial Number'" >> "$output_file" 2>/dev/null
    echo >> "$output_file"
    
    # Get hardware UUID
    echo "=== HARDWARE UUID ===" >> "$output_file"
    ssh $ssh_opts "$SSH_USER@$ip" "system_profiler SPHardwareDataType | grep 'Hardware UUID'" >> "$output_file" 2>/dev/null
    echo >> "$output_file"
    
    # Get system UUID using ioreg
    echo "=== SYSTEM UUID (ioreg) ===" >> "$output_file"
    ssh $ssh_opts "$SSH_USER@$ip" "ioreg -rd1 -c IOPlatformExpertDevice | grep -E '(UUID|Serial)'" >> "$output_file" 2>/dev/null
    echo >> "$output_file"
    
    # Get network interfaces and MAC addresses
    echo "=== NETWORK INTERFACES ===" >> "$output_file"
    ssh $ssh_opts "$SSH_USER@$ip" "ifconfig | grep -E '^[a-z]|ether'" >> "$output_file" 2>/dev/null
    echo >> "$output_file"
    
    # Get Ethernet MAC addresses specifically
    echo "=== ETHERNET MAC ADDRESSES ===" >> "$output_file"
    ssh $ssh_opts "$SSH_USER@$ip" "system_profiler SPNetworkDataType | grep -A 5 -B 5 'Ethernet Address'" >> "$output_file" 2>/dev/null
    echo >> "$output_file"
    
    # Get WiFi MAC address
    echo "=== WIFI MAC ADDRESS ===" >> "$output_file"
    ssh $ssh_opts "$SSH_USER@$ip" "networksetup -getmacaddress Wi-Fi" >> "$output_file" 2>/dev/null
    echo >> "$output_file"
    
    # Get Bluetooth MAC address
    echo "=== BLUETOOTH MAC ADDRESS ===" >> "$output_file"
    ssh $ssh_opts "$SSH_USER@$ip" "system_profiler SPBluetoothDataType | grep 'Address'" >> "$output_file" 2>/dev/null
    echo >> "$output_file"
    
    # Get model information
    echo "=== MODEL INFORMATION ===" >> "$output_file"
    ssh $ssh_opts "$SSH_USER@$ip" "sysctl hw.model" >> "$output_file" 2>/dev/null
    echo >> "$output_file"
    
    # Get CPU information
    echo "=== CPU INFORMATION ===" >> "$output_file"
    ssh $ssh_opts "$SSH_USER@$ip" "sysctl -n machdep.cpu.brand_string" >> "$output_file" 2>/dev/null
    echo >> "$output_file"
    
    success "Hardware information for $ip saved to $output_file"
    return 0
}

# Function to create summary report
create_summary_report() {
    local summary_file="$OUTPUT_DIR/summary_report.txt"
    
    echo "=================================================" > "$summary_file"
    echo "Mac Hardware Inquiry Summary Report" >> "$summary_file"
    echo "Date: $(date)" >> "$summary_file"
    echo "=================================================" >> "$summary_file"
    echo >> "$summary_file"
    
    for ip in "${MAC_IPS[@]}"; do
        local detail_file="$OUTPUT_DIR/hardware_info_${ip}.txt"
        
        echo "--- Mac at IP: $ip ---" >> "$summary_file"
        
        if [[ -f "$detail_file" ]] && ! grep -q "ERROR: SSH connection failed" "$detail_file"; then
            # Extract key information
            echo "Status: Connected" >> "$summary_file"
            
            # Extract serial number
            local serial=$(grep "Serial Number" "$detail_file" | sed 's/.*Serial Number: //' | tr -d ' ')
            echo "Serial Number: ${serial:-Not found}" >> "$summary_file"
            
            # Extract hardware UUID
            local hw_uuid=$(grep "Hardware UUID" "$detail_file" | sed 's/.*Hardware UUID: //' | tr -d ' ')
            echo "Hardware UUID: ${hw_uuid:-Not found}" >> "$summary_file"
            
            # Extract model
            local model=$(grep "Model Name\|Model Identifier" "$detail_file" | head -1 | sed 's/.*: //')
            echo "Model: ${model:-Not found}" >> "$summary_file"
            
        else
            echo "Status: Connection Failed" >> "$summary_file"
        fi
        
        echo >> "$summary_file"
    done
    
    success "Summary report created: $summary_file"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--user)
            SSH_USER="$2"
            shift 2
            ;;
        -k|--key)
            SSH_KEY="$2"
            shift 2
            ;;
        -i|--ips)
            IFS=',' read -ra MAC_IPS <<< "$2"
            shift 2
            ;;
        -f|--file)
            if [[ -f "$2" ]]; then
                while IFS= read -r line; do
                    [[ -n "$line" ]] && MAC_IPS+=("$line")
                done < "$2"
            else
                error "IP file '$2' not found"
                exit 1
            fi
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$SSH_USER" ]]; then
    error "SSH username is required. Use -u or --user option."
    usage
    exit 1
fi

if [[ ${#MAC_IPS[@]} -eq 0 ]]; then
    error "At least one IP address is required. Use -i or --ips option."
    usage
    exit 1
fi

# Validate SSH key file if provided
if [[ -n "$SSH_KEY" ]] && [[ ! -f "$SSH_KEY" ]]; then
    error "SSH key file '$SSH_KEY' not found"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Main execution
echo "================================================="
echo "Mac Hardware ID Inquiry Script"
echo "================================================="
echo "SSH User: $SSH_USER"
echo "SSH Key: ${SSH_KEY:-Password authentication}"
echo "Output Directory: $OUTPUT_DIR"
echo "Timeout: $TIMEOUT seconds"
echo "Target IPs: ${MAC_IPS[*]}"
echo "================================================="
echo

# Process each Mac
success_count=0
failure_count=0

for ip in "${MAC_IPS[@]}"; do
    echo "Processing Mac at IP: $ip"
    
    if get_mac_hardware_info "$ip"; then
        ((success_count++))
    else
        ((failure_count++))
    fi
    
    echo
done

# Create summary report
create_summary_report

# Final summary
echo "================================================="
echo "Operation Complete"
echo "================================================="
echo "Successfully processed: $success_count Mac(s)"
echo "Failed to process: $failure_count Mac(s)"
echo "Reports saved in: $OUTPUT_DIR"
echo "================================================="

# Exit with appropriate code
if [[ $failure_count -gt 0 ]]; then
    exit 1
else
    exit 0
fi