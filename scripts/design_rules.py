#!/usr/bin/env python3
"""Reject raw SwiftUI styling outside the design system. No packages required."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STYLING_TYPES = ('Color', 'UIColor', 'CGColor', 'Font', 'UIFont',
                 'RoundedRectangle', 'UnevenRoundedRectangle')
SYSTEM_VALUES = ('accentColor', 'black', 'blue', 'brown', 'clear', 'cyan', 'gray', 'green',
                 'indigo', 'mint', 'orange', 'pink', 'primary', 'purple', 'red', 'secondary',
                 'teal', 'white', 'yellow', 'largeTitle', 'title', 'title2', 'title3', 'headline',
                 'subheadline', 'body', 'callout', 'caption', 'caption2', 'footnote')
BANNED = re.compile(
    rf'\b(?:{"|".join(STYLING_TYPES)})\b'
    r'|\bcornerRadius\b'
    rf'|(?<![A-Za-z0-9_])\.(?:{"|".join(SYSTEM_VALUES)})\b'
)


def strip_non_code(source):
    result = list(source)

    def erase(start, end):
        for index in range(start, end):
            if result[index] != '\n':
                result[index] = ' '

    index = 0
    while index < len(source):
        if source.startswith('//', index):
            end = source.find('\n', index)
            end = len(source) if end == -1 else end
            erase(index, end)
            index = end
            continue
        if source.startswith('/*', index):
            end = index + 2
            depth = 1
            while end < len(source) and depth:
                if source.startswith('/*', end):
                    depth += 1
                    end += 2
                elif source.startswith('*/', end):
                    depth -= 1
                    end += 2
                else:
                    end += 1
            erase(index, end)
            index = end
            continue

        quote = index
        while quote < len(source) and source[quote] == '#':
            quote += 1
        delimiter = '"""' if source.startswith('"""', quote) else '"' if source.startswith('"', quote) else None
        if delimiter:
            hashes = source[index:quote]
            closing = delimiter + hashes
            end = quote + len(delimiter)
            while end < len(source):
                if source.startswith(closing, end):
                    end += len(closing)
                    break
                if not hashes and source[end] == '\\':
                    end += 2
                else:
                    end += 1
            erase(index, min(end, len(source)))
            index = end
            continue
        index += 1
    return ''.join(result)


def violations(source):
    source = strip_non_code(source)
    return [(source.count('\n', 0, match.start()) + 1, match[0]) for match in BANNED.finditer(source)]


def check(root=ROOT):
    return [f'{path.relative_to(root)}:{line}: use a Design role or component instead of {token}'
            for path in (root / 'HarnessShell').rglob('*.swift')
            if path.name != 'DesignSystem.swift'
            for line, token in violations(path.read_text())]


if __name__ == '__main__':
    problems = check()
    print('\n'.join(problems) if problems else 'Design roles: passed')
    raise SystemExit(bool(problems))
