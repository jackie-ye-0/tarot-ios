import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('design_rules', Path(__file__).resolve().parents[1] / 'scripts/design_rules.py')
rules = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rules)


class DesignRoleTests(unittest.TestCase):
    def test_rejects_banned_styling_vocabulary(self):
        cases = {
            'typed shorthand': 'let raw: Color = .red; Text("x").foregroundStyle(raw)',
            'corner radius': 'let cornerRadius = 20',
            'system colour': 'let raw = .primary',
            'system text style': 'let raw = .body',
        }
        cases.update({f'type {name}': f'let raw: {name}' for name in rules.STYLING_TYPES})
        for name, source in cases.items():
            with self.subTest(name=name):
                self.assertTrue(rules.violations(source))

    def test_accepts_roles_and_ignores_comments_and_strings(self):
        source = '''
Text("Color.red, Font.body, and cornerRadius are prose")
let rawProse = #"UIColor.red and .headline"#
let multilineProse = """RoundedRectangle
.secondary"""
    .typeRole(Design.TypeRole.body)
    .foregroundStyle(Design.Palette.secondary)
// let raw: Color = .red
/* outer Font /* nested UIColor */ .body */
'''
        self.assertEqual(rules.violations(source), [])

    def test_preserves_line_numbers_after_stripping(self):
        self.assertEqual(rules.violations('"Color"\nlet raw: Color = .red'), [(2, 'Color'), (2, '.red')])
