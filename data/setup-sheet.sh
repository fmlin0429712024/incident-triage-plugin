#!/bin/bash
# Setup script: creates a Google Sheet from system-inventory.csv using gws CLI
# Run once to populate the demo spreadsheet.
#
# Prerequisites:
#   gws auth login  (uses personal Gmail: fmlin0429712024@gmail.com)
#
# Usage:
#   bash data/setup-sheet.sh
#
# After running, copy the spreadsheet ID into data/sheet-config.json

set -euo pipefail

TITLE="Incident Triage Demo — System Inventory"

echo "Creating Google Sheet: $TITLE"
RESULT=$(gws sheets spreadsheets create --params "{\"title\": \"$TITLE\"}")
SHEET_ID=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['spreadsheetId'])")

echo "Spreadsheet ID: $SHEET_ID"
echo "URL: https://docs.google.com/spreadsheets/d/$SHEET_ID"

# Write header + data rows
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CSV_FILE="$SCRIPT_DIR/system-inventory.csv"

ROWS=""
while IFS=, read -r hostname role team criticality environment escalation; do
    ROWS="$ROWS,[\"$hostname\",\"$role\",\"$team\",\"$criticality\",\"$environment\",\"$escalation\"]"
done < "$CSV_FILE"
ROWS="${ROWS:1}"  # remove leading comma

gws sheets spreadsheets values update --params "{
  \"spreadsheetId\": \"$SHEET_ID\",
  \"range\": \"Sheet1!A1\",
  \"valueInputOption\": \"RAW\",
  \"requestBody\": {\"values\": [$ROWS]}
}"

echo ""
echo "Done. Save this config:"
cat <<EOF > "$SCRIPT_DIR/sheet-config.json"
{
  "spreadsheet_id": "$SHEET_ID",
  "sheet_name": "Sheet1",
  "range": "A1:F100"
}
EOF
echo "Config written to data/sheet-config.json"
