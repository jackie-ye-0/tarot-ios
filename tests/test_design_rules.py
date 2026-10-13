import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('design_rules', Path(__file__).resolve().parents[1] / 'scripts/design_rules.py')
rules = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rules)


class DesignRoleTests(unittest.TestCase):
    def test_rejects_raw_primitives_and_modifiers(self):
        for source in ['Color(red: 1, green: 0, blue: 0)', 'UIColor(named: "Ink")',
                       'let raw = Color.red; Text("x").foregroundStyle(raw)',
                       'let raw = UIColor.red', 'let raw = Font.body',
                       '.font(.body)', '.fontWeight(.bold)', '.cornerRadius(20)',
                       'let shape = RoundedRectangle(cornerRadius: 20)', '.background(.red)',
                       '.foregroundStyle(.primary)', '.bold()']:
            with self.subTest(source=source):
                self.assertTrue(rules.violations(source))

    def test_accepts_roles_and_ignores_comments(self):
        self.assertEqual(rules.violations('Text("Hello").typeRole(.body).foregroundStyle(Design.Palette.ink)\n// .font(.body)\n/* Color(.red) */'), [])
