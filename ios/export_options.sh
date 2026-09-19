#!/bin/bash
# ios/export_options.sh
# Usage: ./export_options.sh

cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>ad-hoc</string>
	<key>teamID</key>
	<string></string>
	<key>uploadBitcode</key>
	<false/>
	<key>uploadSymbols</key>
	<true/>
	<key>compileBitcode</key>
	<false/>
	<key>destination</key>
	<string>generic/platform=iOS</string>
	<key>signingStyle</key>
	<string>automatic</string>
</dict>
</plist>
EOF
