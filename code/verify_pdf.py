#!/usr/bin/env python3
"""Verify a PDF contains embedded images. Run before sending."""
import sys, os, re

path = sys.argv[1] if len(sys.argv) > 1 else 'digital-twin-landscape-survey.pdf'
if not os.path.exists(path):
    print(f'❌ File not found: {path}')
    sys.exit(1)

sz = os.path.getsize(path) / 1024
with open(path, 'rb') as f:
    content = f.read()

xobjs = len(re.findall(rb'/Type\s*/XObject', content))
imgs = len(re.findall(rb'/Subtype\s*/Image', content))
widths = [int(w.split()[-1]) for w in re.findall(rb'/Width\s+\d+', content)]
heights = [int(h.split()[-1]) for h in re.findall(rb'/Height\s+\d+', content)]

print(f'File: {path}')
print(f'Size: {sz:.0f} KB')
print(f'Embedded objects: {xobjs} XObjects, {imgs} Images')
if widths:
    print(f'Image dimensions: {list(zip(widths, heights))}')

# Check minimum thresholds
issues = []
if sz < 300: issues.append(f'File too small ({sz:.0f} KB < 300 KB)')
if imgs < 3: issues.append(f'Only {imgs} images found (expected 3+)')
for w in widths:
    if w < 500: issues.append(f'Small image width {w}px (expected ~2000px)')

if issues:
    print(f'❌ Issues: {\", \".join(issues)}')
    sys.exit(1)
else:
    print('✅ PDF verified OK')
