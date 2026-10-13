#!/usr/bin/env python3
"""Regenerate lib/l10n/fragment_strings.dart from the fragment JSON files.

Usage:  python3 lib/l10n/fragments/gen_fragment_strings.py
        (run from the package root ~/workspace/namat_khata)

Why this script exists: fragment keys are merged into the ARB files by
Agent A / the orchestrator at release time. Until then, module UI code
reads its strings through the generated FragmentStrings bridge so the
project compiles with zero hardcoded UI strings. After the merge the
bridge keeps working unchanged (it is self-contained).

The previously generated tables (customers/dashboard/khata) no longer
have their source fragment JSONs on disk, so this script treats the
existing generated Dart file as the source of truth for those keys and
merges in every fragments/*_{en,ur}.json it finds.
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]  # package root
FRAG_DIR = ROOT / "lib" / "l10n" / "fragments"
OUT = ROOT / "lib" / "l10n" / "fragment_strings.dart"

MAP_RE = re.compile(r"^  '((?:[^'\\]|\\.)*)': '((?:[^'\\]|\\.)*)',$")
PLACEHOLDER_RE = re.compile(r"\{(\w+)\}")


def unescape(s: str) -> str:
    return s.replace("\\'", "'").replace("\\\\", "\\")


def escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")


def parse_existing_maps(text: str):
    """Extract the _fragmentEn / _fragmentUr maps from the generated file."""
    maps = {}
    current = None
    for line in text.splitlines():
        if line.startswith("const Map<String, String> _fragmentEn = {"):
            current = "en"
            maps[current] = {}
            continue
        if line.startswith("const Map<String, String> _fragmentUr = {"):
            current = "ur"
            maps[current] = {}
            continue
        if line == "};":
            current = None
            continue
        if current is not None:
            m = MAP_RE.match(line)
            if m:
                maps[current][unescape(m.group(1))] = unescape(m.group(2))
    return maps.get("en", {}), maps.get("ur", {})


def load_fragments():
    en, ur = {}, {}
    for path in sorted(FRAG_DIR.glob("*_en.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        for k, v in data.items():
            if not k.startswith("@") and isinstance(v, str):
                en[k] = v
    for path in sorted(FRAG_DIR.glob("*_ur.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        for k, v in data.items():
            if not k.startswith("@") and isinstance(v, str):
                ur[k] = v
    return en, ur


def emit_map(name: str, mapping: dict) -> str:
    lines = [f"const Map<String, String> {name} = {{"]
    for key in sorted(mapping):
        lines.append(f"  '{escape(key)}': '{escape(mapping[key])}',")
    lines.append("};")
    return "\n".join(lines)


def main() -> int:
    existing_en, existing_ur = ({}, {})
    if OUT.exists():
        existing_en, existing_ur = parse_existing_maps(
            OUT.read_text(encoding="utf-8")
        )
    frag_en, frag_ur = load_fragments()

    merged_en = {**existing_en, **frag_en}
    merged_ur = {**existing_ur, **frag_ur}

    # Parity check: every en key must exist in ur and vice versa.
    problems = []
    for k in merged_en:
        if k not in merged_ur:
            problems.append(f"missing ur for key: {k}")
    for k in merged_ur:
        if k not in merged_en:
            problems.append(f"missing en for key: {k}")
    if problems:
        print("FRAGMENT PARITY ERRORS:", file=sys.stderr)
        for p in problems:
            print("  " + p, file=sys.stderr)
        return 1

    keys = sorted(merged_en)
    parts = []
    parts.append(
        "// GENERATED — do not edit by hand.\n"
        "// Built from lib/l10n/fragments/*_{en,ur}.json (plus the previously\n"
        "// generated tables, whose source fragments were consumed earlier).\n"
        "// Regenerate: python3 lib/l10n/fragments/gen_fragment_strings.py\n"
        "//\n"
        "// Why this file exists: fragment keys are merged into the ARB files\n"
        "// by Agent A / the orchestrator at release time. Until then, module UI\n"
        "// code reads its strings through this bridge so the project compiles\n"
        "// with zero hardcoded UI strings. After the merge this file keeps\n"
        "// working unchanged (it is self-contained).\n"
        "import 'package:flutter/widgets.dart';\n"
    )
    parts.append(emit_map("_fragmentEn", merged_en))
    parts.append("")
    parts.append(emit_map("_fragmentUr", merged_ur))
    parts.append("")
    parts.append(
        "/// Localised strings for the wave-2 modules (Agents C/D/E/F).\n"
        "///\n"
        "/// Usage: `final t = FragmentStrings.of(context); Text(t.reports_title)`\n"
        "/// Falls back to English, then to the key itself — never throws.\n"
        "class FragmentStrings {\n"
        "  final Map<String, String> _map;\n"
        "  const FragmentStrings._(this._map);\n"
        "\n"
        "  /// Picks the fragment table matching the ambient locale.\n"
        "  static FragmentStrings of(BuildContext context) {\n"
        "    final code = Localizations.localeOf(context).languageCode;\n"
        "    return FragmentStrings._(code == 'ur' ? _fragmentUr : _fragmentEn);\n"
        "  }\n"
        "\n"
        "  String _t(String key) => _map[key] ?? _fragmentEn[key] ?? key;\n"
        "\n"
        "  String _f(String key, Map<String, Object?> params) {\n"
        "    var s = _t(key);\n"
        "    params.forEach((k, v) => s = s.replaceAll('{$k}', '${v ?? ''}'));\n"
        "    return s;\n"
        "  }\n"
    )
    for key in keys:
        phs = sorted(set(PLACEHOLDER_RE.findall(merged_en[key])))
        if not phs:
            parts.append(f"  String get {key} => _t('{key}');")
        else:
            params = ", ".join(f"required Object {p}" for p in phs)
            fwd = ", ".join(f"'{p}': {p}" for p in phs)
            parts.append(
                f"  String {key}({{{params}}}) => _f('{key}', {{{fwd}}});"
            )
    parts.append("}")
    parts.append("")
    OUT.write_text("\n".join(parts), encoding="utf-8")
    print(f"wrote {OUT} ({len(keys)} keys)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
