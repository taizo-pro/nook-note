#!/bin/bash

# NookNote - Self-Signed Certificate Creation Script
# This script creates a self-signed certificate for code signing NookNote
# for free distribution via GitHub Releases

set -e

# Configuration
CERT_NAME="NookNote Developer"
KEYCHAIN_NAME="nooknote-signing"
KEYCHAIN_PASSWORD="nooknote-temp-password"

echo "🔐 Creating self-signed certificate for NookNote code signing..."

# Check if certificate already exists
if security find-certificate -c "$CERT_NAME" >/dev/null 2>&1; then
    echo "✅ Certificate '$CERT_NAME' already exists"
    echo "To recreate, first run: security delete-certificate -c '$CERT_NAME'"
    exit 0
fi

# Create temporary keychain
echo "📂 Creating temporary keychain..."
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME" || true
security set-keychain-settings -lut 21600 "$KEYCHAIN_NAME"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"

# Add keychain to search list
security list-keychains -d user -s "$KEYCHAIN_NAME" $(security list-keychains -d user | sed s/\"//g)

# Create certificate request configuration
CERT_CONFIG=$(mktemp)
cat > "$CERT_CONFIG" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = California
L = San Francisco
O = NookNote
OU = Development
CN = $CERT_NAME
emailAddress = noreply@nooknote.app

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = codeSigning
EOF

# Generate private key and certificate
echo "🔑 Generating private key and certificate..."
TEMP_KEY=$(mktemp)
TEMP_CERT=$(mktemp)

openssl genrsa -out "$TEMP_KEY" 2048
openssl req -new -x509 -key "$TEMP_KEY" -out "$TEMP_CERT" -days 365 -config "$CERT_CONFIG"

# Convert to PKCS#12 format and import
echo "📥 Importing certificate to keychain..."
TEMP_P12=$(mktemp)
openssl pkcs12 -export -out "$TEMP_P12" -inkey "$TEMP_KEY" -in "$TEMP_CERT" -passout pass:

security import "$TEMP_P12" -k "$KEYCHAIN_NAME" -P "" -A

# Set certificate trust settings for code signing
echo "🛡️ Setting certificate trust settings..."
security add-trusted-cert -d -r trustRoot -k "$KEYCHAIN_NAME" "$TEMP_CERT"

# Clean up temporary files
rm -f "$CERT_CONFIG" "$TEMP_KEY" "$TEMP_CERT" "$TEMP_P12"

echo "✅ Self-signed certificate created successfully!"
echo ""
echo "Certificate Details:"
echo "  Name: $CERT_NAME"
echo "  Keychain: $KEYCHAIN_NAME"
echo "  Valid for: 365 days"
echo ""
echo "Usage:"
echo "  codesign --sign '$CERT_NAME' --keychain '$KEYCHAIN_NAME' YourApp.app"
echo ""
echo "⚠️  Note: Apps signed with self-signed certificates will show security warnings"
echo "   on first launch. Users need to right-click and select 'Open' to bypass."
echo ""
echo "🧹 To clean up later:"
echo "  security delete-keychain '$KEYCHAIN_NAME'"