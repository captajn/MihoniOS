#!/usr/bin/env python3
"""Convert moko-resources strings.xml -> iOS Localizable.xcstrings (en+vi only)"""
import xml.etree.ElementTree as ET
import json
import os
from pathlib import Path

def parse_strings_xml(path):
    """Parse strings.xml and return dict of key→value"""
    strings = {}
    tree = ET.parse(path)
    root = tree.getroot()
    for elem in root.findall("string"):
        name = elem.get("name")
        if name is None:
            continue
        if elem.get("translatable") == "false":
            continue
        text = ET.tostring(elem, encoding="unicode", method="text")
        if text is None:
            text = elem.text or ""
        text = text.strip()
        if text:
            strings[name] = text
    return strings

def build_xcstrings(base_strings, vi_strings):
    """Build Localizable.xcstrings JSON with en+vi only"""
    result = {
        "sourceLanguage": "vi",
        "version": "1.0",
        "strings": {}
    }
    
    all_keys = set(base_strings.keys()) | set(vi_strings.keys())
    
    for key in sorted(all_keys):
        entry = {"extractionState": "manual"}
        localizations = {}
        
        # English (base)
        if key in base_strings:
            localizations["en"] = {
                "stringUnit": {
                    "state": "translated",
                    "value": base_strings[key]
                }
            }
        
        # Vietnamese
        if key in vi_strings:
            localizations["vi"] = {
                "stringUnit": {
                    "state": "translated",
                    "value": vi_strings[key]
                }
            }
        
        if localizations:
            entry["localizations"] = localizations
        result["strings"][key] = entry
    
    return result

def main():
    base_dir = Path(__file__).parent.parent.parent / "i18n" / "src" / "commonMain" / "moko-resources"
    output = Path(__file__).parent.parent / "Resources" / "Localizable.xcstrings"
    
    # Parse base (English)
    base_strings = parse_strings_xml(base_dir / "base" / "strings.xml")
    print(f"Base (en): {len(base_strings)} strings")
    
    # Parse Vietnamese
    vi_strings = parse_strings_xml(base_dir / "vi" / "strings.xml")
    print(f"Vietnamese (vi): {len(vi_strings)} strings")
    
    # Build xcstrings
    xcstrings = build_xcstrings(base_strings, vi_strings)
    
    # Ensure output directory exists
    output.parent.mkdir(parents=True, exist_ok=True)
    
    # Write JSON
    with open(output, "w", encoding="utf-8") as f:
        json.dump(xcstrings, f, ensure_ascii=False, indent=2)
    
    print(f"\nOutput: {output}")
    print(f"Total keys: {len(xcstrings['strings'])}")

if __name__ == "__main__":
    main()
