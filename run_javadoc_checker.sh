#!/bin/bash

set -e

# --- Step 1: Compile the JAR ---
echo "🔧 Packaging JavadocChecker..."
mvn clean package

# Copy the resulting JAR (assumes you built a fat jar with Maven Shade plugin)
JAR_SOURCE=$(find target -name "JavadocChecker.jar" | head -n 1)
if [ -z "$JAR_SOURCE" ]; then
  echo "❌ Error: Could not find fat jar in target/. Make sure the Maven Shade plugin is configured."
  exit 1
fi

cp "$JAR_SOURCE" ./JavadocChecker.jar
echo "✅ Fat jar copied to: ./JavadocChecker.jar"
echo

# --- Step 2: Scan Projects ---
# Path to workspace (default to ~/workspace)
WORKSPACE="${1:-$HOME/workspace}"

# Output directory
OUTPUT_DIR="./output-reports"
SUMMARY_FILE="$OUTPUT_DIR/summary.csv"
mkdir -p "$OUTPUT_DIR"

# Reset the summary file with headers
echo "Project,Total Items,Without Javadoc,Javadoc Missing %" > "$SUMMARY_FILE"

echo "📁 Scanning projects under: $WORKSPACE"
echo

for project in "$WORKSPACE"/*; do
  MODULES_PATH="$project/src/main/java/modules"
  if [ -d "$MODULES_PATH" ]; then
    PROJECT_NAME=$(basename "$project")
    OUTPUT_FILE="$OUTPUT_DIR/${PROJECT_NAME}_javadoc_report.csv"

    echo "▶ Running JavadocChecker on $PROJECT_NAME"
    java -jar JavadocChecker.jar "$MODULES_PATH" "$OUTPUT_FILE" "$SUMMARY_FILE"
    echo
  else
    echo "⏭ Skipping $project (no src/main/java/modules)"
  fi
done

echo "✅ All done. Reports saved to: $OUTPUT_DIR"