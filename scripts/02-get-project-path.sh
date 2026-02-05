#!/bin/bash
# get-project-path.sh

PROJECT_PATH="$1"

# If no argument provided, prompt user
if [ -z "$PROJECT_PATH" ]; then
    read -p "Please enter project path (absolute or relative path): " PROJECT_PATH
fi

# Expand path
PROJECT_PATH=$(realpath "$PROJECT_PATH" 2>/dev/null)

if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Path does not exist: $PROJECT_PATH"
    exit 1
fi

if [ ! -f "$PROJECT_PATH/pom.xml" ]; then
    echo "❌ pom.xml not found, this is not a Maven project"
    echo "Path: $PROJECT_PATH"
    exit 1
fi

echo "✅ Project path: $PROJECT_PATH"
echo "$PROJECT_PATH" > .migration-project-path
