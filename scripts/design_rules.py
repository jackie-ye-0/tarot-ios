#!/usr/bin/env python3
"""Reject raw SwiftUI styling outside the design system. No packages required."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRIMITIVES = re.compile(
    r'\b(?:Color|UIColor|CGColor|Font|UIFont|RoundedRectangle|UnevenRoundedRectangle)\s*'
    r'(?:\(|\.\s*[A-Za-z_]\w*)'
    r'|\.(?:font|fontWeight|fontDesign|cornerRadius)\s*\('
    r'|\bcornerRadius\s*:'
    r'|\.(?:foregroundStyle|foregroundColor|background|fill|stroke|tint)\s*\(\s*\.'
    r'|\.(?:bold|italic)\s*\('
)


def violations(source):
    # Comments cannot create a violation. Preserve line numbers for actionable output.
    source = re.sub(r'/\*.*?\*/', lambda m: '\n' * m[0].count('\n'), source, flags=re.S)
    source = re.sub(r'//[^\n]*', '', source)
    return [(source.count('\n', 0, match.start()) + 1, match[0]) for match in PRIMITIVES.finditer(source)]


def check(root=ROOT):
    return [f'{path.relative_to(root)}:{line}: use a Design role or component instead of {token}'
            for path in (root / 'HarnessShell').rglob('*.swift')
            if path.name != 'DesignSystem.swift'
            for line, token in violations(path.read_text())]


if __name__ == '__main__':
    problems = check()
    print('\n'.join(problems) if problems else 'Design roles: passed')
    raise SystemExit(bool(problems))
