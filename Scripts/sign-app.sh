#!/bin/bash

# NookNote App Signing Script
# Creates self-signed certificate and signs the app for distribution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."
RELEASE_DIR="$PROJECT_DIR/build/Release"
APP_NAME="NookNote"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
CERT_NAME="NookNote Developer"
KEYCHAIN_NAME="nooknote-signing"

echo "🔐 Signing NookNote App"
echo "======================="

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: App bundle not found at $APP_BUNDLE"
    echo "   Run './Scripts/build-app.sh' first"
    exit 1
fi

# Function to create self-signed certificate
create_self_signed_cert() {
    echo "📜 Creating self-signed certificate..."
    
    # Create temporary keychain for signing
    security create-keychain -p "nooknote" "$KEYCHAIN_NAME.keychain" 2>/dev/null || true
    security default-keychain -s "$KEYCHAIN_NAME.keychain"
    security unlock-keychain -p "nooknote" "$KEYCHAIN_NAME.keychain"
    
    # Set keychain timeout to 1 hour
    security set-keychain-settings -t 3600 "$KEYCHAIN_NAME.keychain"
    
    # Create certificate request
    cat > /tmp/cert.conf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = $CERT_NAME
O = NookNote
C = US

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = codeSigning
EOF
    
    # Generate private key and certificate
    openssl genrsa -out /tmp/private.key 2048
    openssl req -new -key /tmp/private.key -out /tmp/cert.csr -config /tmp/cert.conf
    openssl x509 -req -days 365 -in /tmp/cert.csr -signkey /tmp/private.key -out /tmp/cert.crt -extensions v3_req -extfile /tmp/cert.conf
    
    # Convert to PKCS#12 format
    openssl pkcs12 -export -out /tmp/cert.p12 -inkey /tmp/private.key -in /tmp/cert.crt -passout pass:nooknote
    
    # Import certificate to keychain
    security import /tmp/cert.p12 -k "$KEYCHAIN_NAME.keychain" -P nooknote -T /usr/bin/codesign -T /usr/bin/security
    
    # Set the certificate to be trusted for code signing
    security set-key-partition-list -S apple-tool:,apple: -s -k nooknote "$KEYCHAIN_NAME.keychain" 2>/dev/null || true
    
    # Clean up temporary files
    rm -f /tmp/cert.conf /tmp/private.key /tmp/cert.csr /tmp/cert.crt /tmp/cert.p12
    
    echo "✅ Self-signed certificate created: $CERT_NAME"
}

# Function to sign the app
sign_app() {
    echo "✍️  Signing app bundle..."
    
    # Sign all frameworks and libraries first
    find "$APP_BUNDLE" -name "*.framework" -o -name "*.dylib" | while read -r item; do
        echo "   Signing: $(basename "$item")"
        codesign --force --verify --verbose --sign "$CERT_NAME" "$item" 2>/dev/null || echo "     Warning: Failed to sign $item"
    done
    
    # Sign the main executable
    echo "   Signing main executable..."
    codesign --force --verify --verbose --sign "$CERT_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    
    # Sign the app bundle
    echo "   Signing app bundle..."
    codesign --force --verify --verbose --sign "$CERT_NAME" "$APP_BUNDLE"
    
    echo "✅ App signed successfully"
}

# Function to verify signature
verify_signature() {
    echo "🔍 Verifying signature..."
    
    if codesign --verify --verbose=2 "$APP_BUNDLE" 2>/dev/null; then
        echo "✅ Signature verification passed"
        
        # Display signature info
        echo ""
        echo "📋 Signature Details:"
        codesign -dv "$APP_BUNDLE" 2>&1 | grep -E "(Identifier|Authority|Signed Time|Info.plist)" || true
        
    else
        echo "❌ Signature verification failed"
        return 1
    fi
}

# Function for ad-hoc signing (fallback)
adhoc_sign() {
    echo "🔧 Performing ad-hoc signing..."
    
    # Ad-hoc sign (no certificate required)
    codesign --force --deep --sign - "$APP_BUNDLE"
    
    echo "✅ Ad-hoc signing completed"
    echo "⚠️  Note: Ad-hoc signed apps will show security warnings on first launch"
}

# Main signing process
echo "📱 App to sign: $APP_BUNDLE"
echo ""

# Check if we can create certificates (requires openssl)
if command -v openssl &> /dev/null; then
    echo "🔐 Method: Self-signed certificate"
    create_self_signed_cert
    
    if sign_app && verify_signature; then
        echo ""
        echo "🎉 App signing completed successfully!"
        echo ""
        echo "Distribution notes:"
        echo "• App is signed with self-signed certificate"
        echo "• Users will see 'Developer cannot be verified' warning"
        echo "• Users must right-click and select 'Open' on first launch"
        echo "• Consider getting Apple Developer account for trusted distribution"
    else
        echo ""
        echo "⚠️  Self-signed certificate signing failed, falling back to ad-hoc..."
        adhoc_sign
    fi
else
    echo "🔧 Method: Ad-hoc signing (openssl not available)"
    adhoc_sign
fi

echo ""
echo "📍 Signed app location: $APP_BUNDLE"
echo ""
echo "Next steps:"
echo "1. Test the signed app: open '$APP_BUNDLE'"
echo "2. Create DMG: ./Scripts/create-dmg.sh"
echo "3. Upload to GitHub Releases"

# Clean up keychain
if security list-keychains | grep -q "$KEYCHAIN_NAME"; then
    security delete-keychain "$KEYCHAIN_NAME.keychain" 2>/dev/null || true
fi