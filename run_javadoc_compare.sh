#!/bin/bash

set -e

# --- Config ---
REPO_LIST_FILE="$1"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/javadoc_compare_repos"
OUTPUT_DIR="$SCRIPT_DIR/output-reports"
SUMMARY_FILE="$OUTPUT_DIR/summary.csv"
LAST_YEAR_DATE="2025-01-01 00:00"

# Clear output directory for a fresh run
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Save the original working directory
ORIG_DIR="$(pwd)"

if [ -z "$REPO_LIST_FILE" ]; then
  echo "Usage: $0 <repo_list.txt>"
  exit 1
fi

echo "Project,Prev Total,Prev Missing,Prev %,Curr Total,Curr Missing,Curr %" > "$SUMMARY_FILE"
mkdir -p "$BASE_DIR"
# Ensure output directory exists before writing summary
mkdir -p "$OUTPUT_DIR"
echo "Project,Prev Total,Prev Missing,Prev %,Curr Total,Curr Missing,Curr %" > "$SUMMARY_FILE"

while IFS= read -r REPO_URL || [ -n "$REPO_URL" ]; do
  # Skip blank lines and comments
  [[ -z "$REPO_URL" || "$REPO_URL" =~ ^# ]] && continue
  REPO_NAME=$(basename -s .git "$REPO_URL")
  REPO_PATH="$BASE_DIR/$REPO_NAME"
  echo "=== Processing $REPO_NAME ==="

  # Clone fresh
  rm -rf "$REPO_PATH"
  if ! git clone --quiet "$REPO_URL" "$REPO_PATH"; then
    echo "Failed to clone $REPO_URL, skipping."
    continue
  fi
  cd "$REPO_PATH"

  # Get last year's commit
  LAST_YEAR_COMMIT=$(git rev-list -1 --before="$LAST_YEAR_DATE" origin/master 2>/dev/null || git rev-list -1 --before="$LAST_YEAR_DATE" origin/main)
  if [ -z "$LAST_YEAR_COMMIT" ]; then
    echo "No commit found before $LAST_YEAR_DATE for $REPO_NAME, skipping."
  cd "$ORIG_DIR"
    continue
  fi

  # Checkout and run checker for last year
  git checkout --quiet "$LAST_YEAR_COMMIT"
  MODULES_PATH="$REPO_PATH/src/main/java/modules"
  PREV_REPORT="$OUTPUT_DIR/${REPO_NAME}_prev.csv"
  if [ -d "$MODULES_PATH" ]; then
    java -jar ../../JavadocChecker.jar "$MODULES_PATH" "$PREV_REPORT" /dev/null || true
    PREV_TOTAL=$(tail -n +2 "$PREV_REPORT" | wc -l | awk '{print $1}')
    PREV_MISSING=$(awk -F, 'NR>1 && $4=="false" {c++} END{print c+0}' "$PREV_REPORT")
    if [ "$PREV_TOTAL" -eq 0 ]; then
      PREV_PCT=0
    else
      PREV_PCT=$(awk -v t="$PREV_TOTAL" -v m="$PREV_MISSING" 'BEGIN{printf "%.2f", (t==0?0:100*m/t)}')
    fi
  else
    PREV_TOTAL=0; PREV_MISSING=0; PREV_PCT=0
  fi

  # Checkout latest and run checker
  (git switch --quiet master 2>/dev/null || git switch --quiet main)
  git pull --quiet
  MODULES_PATH="$REPO_PATH/src/main/java/modules"
  CURR_REPORT="$OUTPUT_DIR/${REPO_NAME}_curr.csv"
  if [ -d "$MODULES_PATH" ]; then
    java -jar ../../JavadocChecker.jar "$MODULES_PATH" "$CURR_REPORT" /dev/null || true
    CURR_TOTAL=$(tail -n +2 "$CURR_REPORT" | wc -l | awk '{print $1}')
    CURR_MISSING=$(awk -F, 'NR>1 && $4=="false" {c++} END{print c+0}' "$CURR_REPORT")
    if [ "$CURR_TOTAL" -eq 0 ]; then
      CURR_PCT=0
    else
      CURR_PCT=$(awk -v t="$CURR_TOTAL" -v m="$CURR_MISSING" 'BEGIN{printf "%.2f", (t==0?0:100*m/t)}')
    fi
  else
    CURR_TOTAL=0; CURR_MISSING=0; CURR_PCT=0
  fi

  # Write to summary
  echo "$REPO_NAME,$PREV_TOTAL,$PREV_MISSING,$PREV_PCT,$CURR_TOTAL,$CURR_MISSING,$CURR_PCT" >> "$SUMMARY_FILE"

  cd "$ORIG_DIR"
done < "$REPO_LIST_FILE"

echo "✅ Comparison complete. See $SUMMARY_FILE for results."
