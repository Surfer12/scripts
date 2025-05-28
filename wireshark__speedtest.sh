#!/usr/bin/env bash
# Save as wireshark_speedtest.sh and make executable with: chmod +x wireshark_speedtest.sh

# Check for required tools
if ! command -v tshark &> /dev/null; then
    echo "Error: tshark is not installed. Please install Wireshark first."
    echo "You can install it via Homebrew: brew install --cask wireshark"
    exit 1
fi

if ! command -v capinfos &> /dev/null; then
    echo "Error: capinfos is not installed. It should come with Wireshark."
    exit 1
fi

# Detect interface more reliably across different Unix systems
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    INTERFACE=$(route -n get default 2>/dev/null | grep interface | awk '{print $2}')
    if [[ -z "$INTERFACE" ]]; then
        INTERFACE=$(netstat -rn | grep default | head -1 | awk '{print $NF}')
    fi
else
    # Linux and other Unix-like systems
    INTERFACE=$(ip route | grep default | head -1 | awk '{print $5}')
    if [[ -z "$INTERFACE" ]]; then
        INTERFACE=$(netstat -rn | grep UG | head -1 | awk '{print $NF}')
    fi
fi

# If still no interface found, ask the user
if [[ -z "$INTERFACE" ]]; then
    echo "Could not automatically detect network interface."
    echo "Available interfaces:"
    tshark -D
    echo -n "Please enter interface name or number: "
    read INTERFACE
fi

DURATION=30
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="$HOME/wireshark_speedtests"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/speed_capture_$TIMESTAMP.pcap"

echo "Running network capture on $INTERFACE for $DURATION seconds..."
echo "During this time, please generate the traffic you want to measure (e.g., download a large file)"
echo "Capture will be saved to: $OUTPUT_FILE"

# Start capture
tshark -i "$INTERFACE" -a duration:$DURATION -w "$OUTPUT_FILE"
if [[ $? -ne 0 ]]; then
    echo "Error: Capture failed. Please check your permissions and interface name."
    exit 1
fi

# Analyze captured traffic
echo "Capture complete. Analyzing results..."
# Use individual options instead of -T -M -R to get line-by-line output
STATS=$(capinfos "$OUTPUT_FILE")

if [[ $? -ne 0 ]]; then
    echo "Error: Could not analyze capture file."
    exit 1
fi

# Format and display statistics in a table
echo "Network Statistics:"
echo
echo "| Attribute                        | Value                                                 |"
echo "|----------------------------------|-------------------------------------------------------|"

# Parse and format each line from capinfos output
while IFS= read -r line; do
    if [[ -n "$line" && "$line" != *"Capinfos"* ]]; then
        # Extract attribute and value
        attr=$(echo "$line" | awk -F': ' '{print $1}')
        val=$(echo "$line" | awk -F': ' '{print $2}')

        # Only display if we successfully split the line
        if [[ -n "$attr" && -n "$val" ]]; then
            # Format into table row
            printf "| %-32s | %-53s |\n" "$attr" "$val"
        fi
    fi
done < <(echo "$STATS")

# Extract data bit rate and byte rate
DATA_BIT_RATE=$(echo "$STATS" | grep "Data bit rate" | awk -F': ' '{print $2}')
DATA_BYTE_RATE=$(echo "$STATS" | grep "Data byte rate" | awk -F': ' '{print $2}')

echo
echo "Speed Summary:"
echo "- Data byte rate: $DATA_BYTE_RATE"
echo "- Data bit rate: $DATA_BIT_RATE"

# Extract numeric value and unit
BIT_VALUE=$(echo "$DATA_BIT_RATE" | sed 's/[[:space:]].*//' | sed 's/,//g')
BIT_UNIT=$(echo "$DATA_BIT_RATE" | sed 's/^[0-9,.][0-9,.]*//' | sed 's/^[[:space:]]*//')

BYTE_VALUE=$(echo "$DATA_BYTE_RATE" | sed 's/[[:space:]].*//' | sed 's/,//g')
BYTE_UNIT=$(echo "$DATA_BYTE_RATE" | sed 's/^[0-9,.][0-9,.]*//' | sed 's/^[[:space:]]*//')

# Calculate MB/sec from byte rate
if [[ "$BYTE_UNIT" == "kBps" ]]; then
    MB_PER_SEC=$(echo "scale=2; $BYTE_VALUE/1000" | bc)
elif [[ "$BYTE_UNIT" == "Bps" ]]; then
    MB_PER_SEC=$(echo "scale=2; $BYTE_VALUE/1000000" | bc)
elif [[ "$BYTE_UNIT" == "MBps" ]]; then
    MB_PER_SEC=$BYTE_VALUE
else
    MB_PER_SEC="unknown"
fi

# Calculate Mbps from bit rate if needed
if [[ "$BIT_UNIT" == "kbps" ]]; then
    MBPS=$(echo "scale=2; $BIT_VALUE/1000" | bc)
elif [[ "$BIT_UNIT" == "bps" ]]; then
    MBPS=$(echo "scale=2; $BIT_VALUE/1000000" | bc)
elif [[ "$BIT_UNIT" == "Mbps" ]]; then
    MBPS=$BIT_VALUE
else
    MBPS="unknown"
fi

echo
echo "Calculated values:"
if [[ "$MB_PER_SEC" != "unknown" ]]; then
    echo "- Approximately $MB_PER_SEC MB/sec"
fi
if [[ "$MBPS" != "unknown" ]]; then
    echo "- Approximately $MBPS Mbps"
    echo
    echo "Thus, the network traffic captured has an average throughput of approximately $MBPS Mbps."
fi
echo
echo "Capture file saved to: $OUTPUT_FILE"
