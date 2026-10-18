#!/usr/bin/env python3
"""Preflight asset/reference sanity check (NOT an iOS compiler or device test)."""
import json
import plistlib
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
project = (root / 'ThreeOneOSFive.xcodeproj/project.pbxproj').read_text()
required = [
    'ThreeOneOSFive/App.swift',
    'ThreeOneOSFive/ContentView.swift',
    'ThreeOneOSFive/helpers/DevHaiPlatform.swift',
    'ThreeOneOSFive/views/DevHaiShell.swift',
    'ThreeOneOSFive/views/DevHaiAdminPanel.swift',
    '.github/workflows/build-ipa.yml',
    'ThreeOneOSFive.xcodeproj/xcshareddata/xcschemes/3105.xcscheme',
    'ThreeOneOSFive/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png',
    'LICENSE', 'THIRD_PARTY_NOTICES.md', 'README_ORIGINAL.md', 'README.vi.md',
]
errors = []
for path in required:
    if not (root / path).is_file():
        errors.append('Missing file: ' + path)
for name in ['DevHaiPlatform.swift', 'DevHaiShell.swift', 'DevHaiAdminPanel.swift']:
    if project.count(name) < 3:
        errors.append('Xcode reference or compile phase missing: ' + name)
with (root / 'ThreeOneOSFive/Info.plist').open('rb') as stream:
    info = plistlib.load(stream)
if info['CFBundleDisplayName'] != 'DEVHAI':
    errors.append('Display name mismatch')
icons = root / 'ThreeOneOSFive/Assets.xcassets/AppIcon.appiconset'
with (icons / 'Contents.json').open() as stream:
    contents = json.load(stream)
if not any((icons / i['filename']).is_file() for i in contents['images']):
    errors.append('Missing app icon image')
admin = (root / 'ThreeOneOSFive/views/DevHaiAdminPanel.swift').read_text()
if len([line for line in admin.splitlines() if line.strip().startswith('case ') and 'return ' not in line]) < 2:
    errors.append('Admin module enumeration missing')
if errors:
    print('\n'.join(errors), file=sys.stderr)
    raise SystemExit(1)
print('Preflight OK: required sources, references, asset catalog, documents, and Info.plist')
print('Note: Full compile requires macOS + Xcode and valid Apple signing for device tests.')
