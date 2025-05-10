#!/bin/bash

# Set working directory
PROJECT_DIR="$1"
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR=$(pwd)
fi

# Define variables
HOME_DIR="$HOME"
JDTLS_PATH="$HOME_DIR/.local/share/nvim/mason/packages/jdtls"
WORKSPACE_DIR="$HOME_DIR/.cache/jdtls-workspaces/$(basename "$PROJECT_DIR")"
LOMBOK_PATH="$HOME_DIR/.local/share/nvim/java-libs/lombok.jar"
LOG_FILE="/tmp/jdtls_debug_$(date +%Y%m%d_%H%M%S).log"

# Check for Java - prefer Java 17
if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    JAVA_CMD="$JAVA_HOME/bin/java"
elif [ -x "/usr/lib/jvm/java-17-openjdk/bin/java" ]; then
    JAVA_CMD="/usr/lib/jvm/java-17-openjdk/bin/java"
else
    JAVA_CMD="/usr/bin/java"
fi

# Ensure workspace directory exists
mkdir -p "$WORKSPACE_DIR"

# Determine OS config
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_CONFIG="config_mac"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    OS_CONFIG="config_win"
else
    OS_CONFIG="config_linux"
fi

# Launcher jar
LAUNCHER_JAR=$(ls "$JDTLS_PATH/plugins/org.eclipse.equinox.launcher_"*.jar)

echo "===== JDTLS Debug Info =====" > "$LOG_FILE"
echo "Current Date: $(date)" >> "$LOG_FILE"
echo "Project Directory: $PROJECT_DIR" >> "$LOG_FILE"
echo "Java Command: $JAVA_CMD" >> "$LOG_FILE"
echo "Java Version: $($JAVA_CMD -version 2>&1)" >> "$LOG_FILE"
echo "JDTLS Path: $JDTLS_PATH" >> "$LOG_FILE"
echo "Workspace: $WORKSPACE_DIR" >> "$LOG_FILE"
echo "OS Config: $OS_CONFIG" >> "$LOG_FILE"
echo "Launcher JAR: $LAUNCHER_JAR" >> "$LOG_FILE"
echo "Lombok Path: $LOMBOK_PATH" >> "$LOG_FILE"
echo "=========================" >> "$LOG_FILE"

# Create Java debug logging configuration
cat > /tmp/java-debug-logging.properties << EOF
handlers=java.util.logging.ConsoleHandler,java.util.logging.FileHandler
.level=ALL
java.util.logging.FileHandler.pattern=$LOG_FILE
java.util.logging.FileHandler.limit=50000
java.util.logging.FileHandler.count=1
java.util.logging.FileHandler.formatter=java.util.logging.SimpleFormatter
java.util.logging.ConsoleHandler.level=ALL
java.util.logging.ConsoleHandler.formatter=java.util.logging.SimpleFormatter
EOF

# Check if this is a multi-module Maven project
POM_COUNT=$(find "$PROJECT_DIR" -name pom.xml | wc -l)
echo "Number of pom.xml files found: $POM_COUNT" >> "$LOG_FILE"

# Set memory based on project size
if [ "$POM_COUNT" -gt 1 ]; then
    MEMORY_OPTS="-Xmx4g -XX:+UseG1GC -XX:+UseStringDeduplication"
    echo "Using increased memory for multi-module project" >> "$LOG_FILE"
else
    MEMORY_OPTS="-Xmx2g -XX:+UseG1GC"
    echo "Using standard memory configuration" >> "$LOG_FILE"
fi

# Try launching JDTLS with strace to capture system calls
if command -v strace &> /dev/null; then
    echo "Launching JDTLS with strace..." >> "$LOG_FILE"
    strace -f -e trace=process $JAVA_CMD $MEMORY_OPTS \
        -Declipse.application=org.eclipse.jdt.ls.core.id1 \
        -Dosgi.bundles.defaultStartLevel=4 \
        -Declipse.product=org.eclipse.jdt.ls.core.product \
        -Dlog.protocol=true \
        -Dlog.level=ALL \
        -Djava.util.logging.config.file=/tmp/java-debug-logging.properties \
        -XX:ErrorFile=/tmp/jdtls_crash_%p.log \
        -XX:+HeapDumpOnOutOfMemoryError \
        -javaagent:"$LOMBOK_PATH" \
        --add-modules=ALL-SYSTEM \
        --add-opens java.base/java.util=ALL-UNNAMED \
        --add-opens java.base/java.lang=ALL-UNNAMED \
        --add-opens java.base/java.net=ALL-UNNAMED \
        --add-opens java.base/java.util.concurrent=ALL-UNNAMED \
        -jar "$LAUNCHER_JAR" \
        -configuration "$JDTLS_PATH/$OS_CONFIG" \
        -data "$WORKSPACE_DIR" 2>> "$LOG_FILE"
else
    echo "Launching JDTLS without strace..." >> "$LOG_FILE"
    $JAVA_CMD $MEMORY_OPTS \
        -Declipse.application=org.eclipse.jdt.ls.core.id1 \
        -Dosgi.bundles.defaultStartLevel=4 \
        -Declipse.product=org.eclipse.jdt.ls.core.product \
        -Dlog.protocol=true \
        -Dlog.level=ALL \
        -Djava.util.logging.config.file=/tmp/java-debug-logging.properties \
        -XX:ErrorFile=/tmp/jdtls_crash_%p.log \
        -XX:+HeapDumpOnOutOfMemoryError \
        -javaagent:"$LOMBOK_PATH" \
        --add-modules=ALL-SYSTEM \
        --add-opens java.base/java.util=ALL-UNNAMED \
        --add-opens java.base/java.lang=ALL-UNNAMED \
        --add-opens java.base/java.net=ALL-UNNAMED \
        --add-opens java.base/java.util.concurrent=ALL-UNNAMED \
        -jar "$LAUNCHER_JAR" \
        -configuration "$JDTLS_PATH/$OS_CONFIG" \
        -data "$WORKSPACE_DIR" >> "$LOG_FILE" 2>&1
fi

echo "JDTLS launch completed. Check $LOG_FILE for details."
