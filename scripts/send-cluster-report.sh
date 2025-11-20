#!/bin/bash

# send-cluster-report.sh - Generate and email cluster status report
# Usage: ./send-cluster-report.sh [target_host]
# Configuration: Set EMAIL_TO environment variable or create ~/.cluster-report-config
# Example cron: 0 9 * * * /home/owner/ansible_microk8s/scripts/send-cluster-report.sh k8s1.home.arpa

set -e

TARGET_HOST=${1:-"k8s1.home.arpa"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_FILE="/tmp/cluster-report-$(date +%s).txt"
HTML_REPORT="/tmp/cluster-report-$(date +%s).html"

# Configuration sources (in order of precedence)
if [ -f ~/.cluster-report-config ]; then
    source ~/.cluster-report-config
fi

# Email configuration - can also be set via environment variables
EMAIL_TO=${EMAIL_TO:-""}
SMTP_SERVER=${SMTP_SERVER:-"localhost"}
SMTP_PORT=${SMTP_PORT:-"25"}
FROM_ADDRESS=${FROM_ADDRESS:-"cluster-admin@home.arpa"}

# Validate email is configured
if [ -z "$EMAIL_TO" ]; then
    echo "Error: EMAIL_TO not configured. Set it in ~/.cluster-report-config or as environment variable"
    exit 1
fi

# Check for mail command
if ! command -v mail &> /dev/null && ! command -v mailx &> /dev/null && ! command -v sendmail &> /dev/null; then
    echo "Error: No mail command found (install mailutils or postfix)"
    exit 1
fi

echo "Generating cluster report for $TARGET_HOST..."

# Generate plain text report
"$SCRIPT_DIR/describe-cluster.sh" "$TARGET_HOST" > "$REPORT_FILE" 2>&1

# Create HTML version with styling
create_html_report() {
    local text_file=$1
    local html_file=$2
    
    cat > "$html_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>MicroK8s Cluster Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .header {
            background-color: #2c3e50;
            color: white;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .section {
            background-color: white;
            margin: 15px 0;
            padding: 15px;
            border-left: 4px solid #3498db;
            border-radius: 3px;
        }
        .section-title {
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 10px;
            font-size: 14px;
        }
        pre {
            background-color: #f8f8f8;
            padding: 10px;
            border-radius: 3px;
            overflow-x: auto;
            font-size: 12px;
            line-height: 1.4;
        }
        .warning {
            color: #e74c3c;
        }
        .success {
            color: #27ae60;
        }
        .info {
            color: #3498db;
        }
        .footer {
            margin-top: 20px;
            padding-top: 10px;
            border-top: 1px solid #ddd;
            font-size: 12px;
            color: #7f8c8d;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>MicroK8s Cluster Status Report</h1>
        <p>Generated: <strong>$(date '+%Y-%m-%d %H:%M:%S')</strong></p>
        <p>Target: <strong>$TARGET_HOST</strong></p>
    </div>
EOF

    # Parse the text report and convert sections to HTML
    local current_section=""
    local in_pre=false
    
    while IFS= read -r line; do
        # Detect section headers
        if [[ $line =~ ^---\ (.*)\ ---$ ]]; then
            if [ "$in_pre" = true ]; then
                echo "</pre>" >> "$html_file"
                in_pre=false
            fi
            current_section="${BASH_REMATCH[1]}"
            echo "<div class=\"section\">" >> "$html_file"
            echo "<div class=\"section-title\">📊 $current_section</div>" >> "$html_file"
            echo "<pre>" >> "$html_file"
            in_pre=true
        elif [[ $line =~ ^=+ ]]; then
            # Skip separator lines
            continue
        elif [ -z "$line" ]; then
            # Skip empty lines in pre blocks
            if [ "$in_pre" = true ]; then
                echo "" >> "$html_file"
            fi
        else
            # Regular content
            if [ "$in_pre" = false ] && [ -n "$current_section" ]; then
                echo "<pre>" >> "$html_file"
                in_pre=true
            fi
            # Escape HTML entities
            line=$(echo "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            echo "$line" >> "$html_file"
        fi
    done < "$text_file"
    
    if [ "$in_pre" = true ]; then
        echo "</pre>" >> "$html_file"
    fi
    
    echo "</div>" >> "$html_file"
    
    cat >> "$html_file" << 'EOF'
    <div class="footer">
        <p>This is an automated report from your MicroK8s cluster monitoring system.</p>
    </div>
</body>
</html>
EOF
}

echo "Creating HTML report..."
create_html_report "$REPORT_FILE" "$HTML_REPORT"

# Send email
echo "Sending report to $EMAIL_TO..."

if command -v mail &> /dev/null; then
    mail -s "MicroK8s Cluster Report - $TARGET_HOST - $(date '+%Y-%m-%d')" \
         -a "Content-Type: text/html; charset=utf-8" \
         "$EMAIL_TO" < "$HTML_REPORT"
elif command -v mailx &> /dev/null; then
    mailx -s "MicroK8s Cluster Report - $TARGET_HOST - $(date '+%Y-%m-%d')" \
          -a "Content-Type: text/html; charset=utf-8" \
          "$EMAIL_TO" < "$HTML_REPORT"
else
    # Fallback to sendmail
    {
        echo "To: $EMAIL_TO"
        echo "From: $FROM_ADDRESS"
        echo "Subject: MicroK8s Cluster Report - $TARGET_HOST - $(date '+%Y-%m-%d')"
        echo "Content-Type: text/html; charset=utf-8"
        echo ""
        cat "$HTML_REPORT"
    } | sendmail -t
fi

if [ $? -eq 0 ]; then
    echo "✓ Report sent successfully to $EMAIL_TO"
else
    echo "✗ Failed to send report"
    exit 1
fi

# Cleanup
rm -f "$REPORT_FILE" "$HTML_REPORT"

echo "Done!"
