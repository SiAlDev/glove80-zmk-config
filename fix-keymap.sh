#!/bin/bash

# Fix keymap syntax issues caused by third-party editors
# Run this after saving from https://nickcoutsos.github.io/keymap-editor/

echo "🔧 Fixing keymap syntax issues from editor..."

KEYMAP_FILE="config/glove80.keymap"

if [ ! -f "$KEYMAP_FILE" ]; then
    echo "❌ Error: $KEYMAP_FILE not found!"
    exit 1
fi

# Create backup
cp "$KEYMAP_FILE" "$KEYMAP_FILE.backup"
echo "📋 Backup created: $KEYMAP_FILE.backup"

# Fix common keymap editor syntax issues
echo "🔍 Applying syntax fixes..."

# Remove standalone # characters
sed -i '' 's/^#$//' "$KEYMAP_FILE" 2>/dev/null || sed -i 's/^#$//' "$KEYMAP_FILE"

# Fix malformed endif statements
sed -i '' 's/^endif {$/#endif/' "$KEYMAP_FILE" 2>/dev/null || sed -i 's/^endif {$/#endif/' "$KEYMAP_FILE"

# Remove stray forward slashes
sed -i '' 's/^    \/$//g' "$KEYMAP_FILE" 2>/dev/null || sed -i 's/^    \/$//g' "$KEYMAP_FILE"
sed -i '' 's/^\/$//' "$KEYMAP_FILE" 2>/dev/null || sed -i 's/^\/$//' "$KEYMAP_FILE"

# Fix broken device tree root nodes
sed -i '' 's/endif {$/\/ {/' "$KEYMAP_FILE" 2>/dev/null || sed -i 's/endif {$/\/ {/' "$KEYMAP_FILE"

# Comprehensive fix for the specific pattern from keymap editor
echo "🔧 Applying comprehensive pattern fixes..."

# Use awk to fix the complex pattern: #ifndef -> #define -> # -> endif { -> / -> content
awk '
BEGIN { in_fix_block = 0 }
/^#ifndef LAYER_Lower/ { 
    print; 
    in_fix_block = 1; 
    next 
}
in_fix_block && /^#define LAYER_Lower/ { 
    print; 
    next 
}
in_fix_block && /^#$/ { 
    # Skip standalone #
    next 
}
in_fix_block && /^endif \{/ { 
    print "#endif"
    print ""
    print "/ {"
    in_fix_block = 0
    next 
}
in_fix_block && /^    \/$/ { 
    # Skip stray /
    next 
}
{ print }
' "$KEYMAP_FILE" > "$KEYMAP_FILE.tmp" && mv "$KEYMAP_FILE.tmp" "$KEYMAP_FILE"

# Ensure proper #ifndef/#endif pairing
if grep -q "#ifndef LAYER_Lower" "$KEYMAP_FILE"; then
    if ! grep -q "#endif" "$KEYMAP_FILE"; then
        echo "🔧 Adding missing #endif for #ifndef LAYER_Lower"
        # Use awk for more reliable insertion
        awk '
        /^#ifndef LAYER_Lower/ { print; getline; print; print "#endif"; next }
        { print }
        ' "$KEYMAP_FILE" > "$KEYMAP_FILE.tmp" && mv "$KEYMAP_FILE.tmp" "$KEYMAP_FILE"
    fi
fi

echo "✅ Syntax fixes applied"

# Validate the fixed syntax
if command -v cpp >/dev/null 2>&1; then
    if cpp -E "$KEYMAP_FILE" > /dev/null 2>&1; then
        echo "✅ Keymap syntax is now valid!"
    else
        echo "⚠️  Warning: Some syntax issues may remain. Check the file manually."
        echo "💡 Common issues to look for:"
        echo "   - Unterminated #ifndef/#ifdef statements"
        echo "   - Malformed device tree syntax (/ { ... };)"
        echo "   - Stray characters or incomplete lines"
    fi
else
    echo "ℹ️  cpp not available for validation, but fixes have been applied"
fi

echo "🎯 Done! You can now commit and push your changes."
echo "💡 To revert changes if needed: mv $KEYMAP_FILE.backup $KEYMAP_FILE"
