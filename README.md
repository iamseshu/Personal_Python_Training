# Mac Hardware ID Inquiry Script

A comprehensive shell script to remotely query hardware IDs from multiple Mac computers using their IP addresses via SSH.

## Features

- Queries multiple hardware identifiers including:
  - Serial numbers
  - Hardware UUIDs
  - System UUIDs
  - MAC addresses (Ethernet, WiFi, Bluetooth)
  - Model information
  - CPU details
  - System overview
- Supports both password and SSH key authentication
- Configurable SSH timeout
- Colored output for better readability
- Detailed error handling and logging
- Creates individual reports for each Mac
- Generates a summary report
- Verbose mode for debugging

## Prerequisites

1. **SSH Access**: SSH must be enabled on all target Mac computers
   - Go to System Preferences > Sharing > Remote Login (check the box)
   
2. **Network Connectivity**: Target Macs must be reachable on the network

3. **Authentication**: Set up either:
   - SSH key-based authentication (recommended for security)
   - Password authentication (will prompt for each connection)

## Setting Up SSH Key Authentication (Recommended)

1. Generate an SSH key pair on your local machine:
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   ```

2. Copy the public key to each target Mac:
   ```bash
   ssh-copy-id username@mac_ip_address
   ```

3. Test the connection:
   ```bash
   ssh username@mac_ip_address
   ```

## Usage

### Basic Usage

```bash
./mac_hardware_inquiry.sh -u admin -i 192.168.1.10,192.168.1.11,192.168.1.12
```

### Using SSH Key Authentication

```bash
./mac_hardware_inquiry.sh -u admin -k ~/.ssh/id_rsa -i 192.168.1.10,192.168.1.11
```

### Using IP List File

```bash
./mac_hardware_inquiry.sh -u admin -f sample_ip_list.txt
```

### Custom Output Directory with Verbose Mode

```bash
./mac_hardware_inquiry.sh -u admin -i 192.168.1.10 -o my_reports -v
```

### Complete Example

```bash
./mac_hardware_inquiry.sh \
  --user admin \
  --key ~/.ssh/mac_key \
  --file ip_list.txt \
  --output hardware_reports \
  --timeout 15 \
  --verbose
```

## Command Line Options

| Option | Description | Required |
|--------|-------------|----------|
| `-u, --user USERNAME` | SSH username for connecting to Macs | Yes |
| `-k, --key KEY_PATH` | Path to SSH private key file | No |
| `-i, --ips IP_LIST` | Comma-separated list of IP addresses | Yes* |
| `-f, --file IP_FILE` | File containing IP addresses (one per line) | Yes* |
| `-o, --output DIR` | Output directory for reports (default: mac_hardware_reports) | No |
| `-t, --timeout SECONDS` | SSH connection timeout (default: 10) | No |
| `-v, --verbose` | Enable verbose output | No |
| `-h, --help` | Display help message | No |

*Either `-i` or `-f` is required

## Output

The script creates:

1. **Individual Reports**: `hardware_info_<IP>.txt` for each Mac
2. **Summary Report**: `summary_report.txt` with key information from all Macs

### Sample Output Structure

```
mac_hardware_reports/
├── hardware_info_192.168.1.10.txt
├── hardware_info_192.168.1.11.txt
├── hardware_info_192.168.1.12.txt
└── summary_report.txt
```

### Information Collected

Each report includes:
- System overview (OS version, uptime)
- Hardware overview (model, processor, memory)
- Serial number
- Hardware UUID
- System UUID
- Network interface MAC addresses
- Ethernet MAC addresses
- WiFi MAC address
- Bluetooth MAC address
- Model information
- CPU details

## Sample IP List File Format

Create a text file with one IP address per line:

```
# Sample IP list for Mac hardware inquiry
# Lines starting with # are ignored

192.168.1.10
192.168.1.11
192.168.1.12
10.0.0.50
10.0.0.51
```

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify SSH is enabled on target Mac
   - Check network connectivity
   - Verify username and authentication method
   - Try connecting manually: `ssh username@ip_address`

2. **Permission Denied**
   - Check SSH key permissions: `chmod 600 ~/.ssh/id_rsa`
   - Verify username is correct
   - Ensure user has proper privileges on target Mac

3. **Timeout Issues**
   - Increase timeout value with `-t` option
   - Check network latency
   - Verify target Mac is not sleeping/hibernating

4. **Missing Information in Reports**
   - Some commands may require administrator privileges
   - Try running with an admin user account
   - Check if target Mac has security restrictions

### Debug Mode

Use the verbose flag to see detailed execution information:

```bash
./mac_hardware_inquiry.sh -u admin -i 192.168.1.10 -v
```

## Security Considerations

- Use SSH key authentication instead of passwords
- Ensure SSH keys have proper permissions (600)
- Only run the script from trusted locations
- Review target Mac security policies
- Consider network security and firewall rules

## Examples

### Query Single Mac with Verbose Output

```bash
./mac_hardware_inquiry.sh -u admin -i 192.168.1.100 -v
```

### Query Multiple Macs with Custom Settings

```bash
./mac_hardware_inquiry.sh \
  -u macadmin \
  -k ~/.ssh/mac_infrastructure_key \
  -i 10.0.1.10,10.0.1.11,10.0.1.12,10.0.1.13 \
  -o weekly_inventory \
  -t 20
```

### Query Macs from File with Password Authentication

```bash
./mac_hardware_inquiry.sh -u admin -f office_macs.txt -o reports/$(date +%Y%m%d)
```

## License

This script is provided as-is for educational and administrative purposes. Ensure you have proper authorization before accessing remote systems.