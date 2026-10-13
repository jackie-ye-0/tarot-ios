"""Black-box command contract tests using fake Apple executables, never iOS evidence."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
FAKE = r'''#!PYTHON
import json, os, pathlib, sys
args = sys.argv[1:]
tool = pathlib.Path(sys.argv[0]).name
case = os.environ.get('FAKE_CASE', '')
if tool == 'xcode-select':
    print('/Example Xcode.app/Contents/Developer')
elif tool == 'xcodebuild':
    if args == ['-version']:
        print('Full Xcode required' if case == 'missing-xcode' else 'Xcode FAKE\nBuild version TEST')
        sys.exit(72 if case == 'missing-xcode' else 0)
    if args and args[0] in ('test', 'build'):
        if '-resultBundlePath' in args:
            pathlib.Path(args[args.index('-resultBundlePath')+1]).mkdir()
        sys.exit(65 if case in ('failed-tests', 'failed-build') else 0)
elif args[:2] == ['simctl', 'list']:
    devices = [] if case == 'no-device' else [
        {'name':'iPhone Fake', 'udid':'PHONE', 'isAvailable':True, 'state':'Shutdown'},
        {'name':'iPhone Booted', 'udid':'BOOTED', 'isAvailable':True, 'state':'Booted'},
        {'name':'iPhone Missing', 'udid':'MISSING', 'isAvailable':False, 'state':'Shutdown'},
        {'name':'iPad Fake', 'udid':'IPAD', 'isAvailable':True, 'state':'Booted'}]
    print(json.dumps({'devices':{'com.apple.CoreSimulator.SimRuntime.iOS-26-0':devices}}))
elif args[:4] == ['xcresulttool', 'get', 'test-results', 'summary']:
    if case == 'bad-json':
        print('not JSON'); sys.exit()
    if case == 'wrong-shape':
        print('[]'); sys.exit()
    if case == 'missing-counts':
        print(json.dumps({'totalTestCount':4, 'passedTests':4})); sys.exit()
    total = 0 if case == 'zero-tests' else 3 if case == 'too-few-tests' else 4
    failed = 1 if case == 'failed-tests' else 0
    skipped = 1 if case == 'skipped-tests' else 0
    print(json.dumps({'totalTestCount':total, 'passedTests':total-failed-skipped, 'failedTests':failed, 'skippedTests':skipped, 'expectedFailures':1 if case == 'expected-failure' else 0, 'result':'Failed' if case in ('failed-tests', 'failed-result') else 'Passed'}))
elif args[:3] == ['xcresulttool', 'export', 'attachments']:
    if case == 'export-fails': sys.exit(74)
    folder = pathlib.Path(args[args.index('--output-path')+1]); folder.mkdir()
    names = json.loads(os.environ.get('FAKE_CAPTURES', '["04 today"]'))
    if case in ('no-screenshot', 'unlisted-screenshot'): names = []
    manifest = []
    for index, name in enumerate(names):
        extension = '.jpg' if index % 2 else '.png'
        exported = f'random-identifier-{index}{extension}'
        (folder/exported).write_bytes(f'FAKE: not iOS evidence {index}'.encode())
        suggested = f'{name}_0_D00CD600-EDD1-4CE5-BFDD-8DA4566EF078{extension}'
        manifest.append({'testIdentifier':f'FakeTests/test{index}()', 'attachments':[
            {'exportedFileName':exported, 'suggestedHumanReadableName':suggested,
             'isAssociatedWithFailure':False, 'configurationName':'Fake',
             'deviceName':'iPhone Fake', 'deviceId':'PHONE'}]})
    if case == 'missing-export': (folder/manifest[0]['attachments'][0]['exportedFileName']).unlink()
    if case == 'unknown-name': manifest[0]['attachments'][0]['suggestedHumanReadableName'] = 'unknown.png'
    if case == 'unsafe-export': manifest[0]['attachments'][0]['exportedFileName'] = '../outside.png'
    if case == 'wrong-manifest-shape': manifest = {}
    if case == 'unlisted-screenshot': (folder/'unlisted.png').write_bytes(b'FAKE')
    if case != 'missing-manifest':
        (folder/'manifest.json').write_text('not JSON' if case == 'bad-manifest' else json.dumps(manifest))
'''


class HarnessCommandTests(unittest.TestCase):
    def setUp(self):
        scratch = ROOT / '.harness' / 'command-tests'
        scratch.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='checkout with spaces ', dir=scratch)
        self.root = Path(self.temp.name).resolve()
        shutil.copytree(ROOT / 'scripts', self.root / 'scripts')
        self.references = self.root / 'docs/design-reference'
        self.references.mkdir(parents=True)
        for name in ('00-flow-map.png', '04 today.jpg', '05-ask.jpg'):
            (self.references / name).write_bytes(b'FAKE: design reference')
        self.bin = self.root / 'fake tools'
        self.bin.mkdir()
        for name in ['xcodebuild', 'xcode-select', 'xcrun']:
            path = self.bin / name
            path.write_text(FAKE.replace('PYTHON', sys.executable, 1))
            path.chmod(0o755)
        self.env = dict(os.environ, PATH=str(self.bin)+os.pathsep+os.environ['PATH'])
        self.env.pop('DEVELOPER_DIR', None)

    def tearDown(self):
        self.temp.cleanup()

    def invoke(self, command='test', case='', extra=()):
        env = dict(self.env, FAKE_CASE=case)
        result = subprocess.run([str(self.root/'scripts/harness'), command, *extra], cwd=self.root, env=env, capture_output=True, text=True)
        summaries = sorted(self.root.glob('.harness/runs/*/summary.json'))
        summary = json.loads(summaries[-1].read_text()) if summaries else None
        return result, summary

    def test_passing_counts_evidence_and_space_paths(self):
        result, summary = self.invoke()
        self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
        self.assertEqual(summary['tests']['passedTests'], 4)
        self.assertTrue(summary['screenshots'])
        run = Path(summary['run'])
        self.assertTrue((run/'test.log').exists())
        self.assertEqual(json.loads((run/'metadata.json').read_text())['device']['udid'], 'BOOTED')
        commands = [json.loads(line) for line in (run/'commands.jsonl').read_text().splitlines()]
        build = next(c for c in commands if c[:2] == ['xcodebuild', 'test'])
        self.assertEqual(build[build.index('-project')+1], str(self.root/'HarnessShell.xcodeproj'))

    def test_named_screenshots_comparison_and_missing_coverage(self):
        self.env['FAKE_CAPTURES'] = json.dumps(['04 today', '04 today--largest-text', '04 today--reduce-motion', 'Technical shell'])
        result, summary = self.invoke()
        self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
        self.assertEqual(summary['screenshots'], ['screenshots/04 today.png', 'screenshots/04 today--largest-text.jpg',
                                                 'screenshots/04 today--reduce-motion.png', 'screenshots/Technical shell.jpg'])
        self.assertEqual([row['name'] for row in summary['design_coverage']], ['04 today', '05-ask'])
        matched, missing = summary['design_coverage']
        self.assertEqual(matched['screenshot'], 'screenshots/04 today.png')
        self.assertEqual(len(matched['variants']), 2)
        self.assertIsNone(missing['screenshot'])
        run = Path(summary['run'])
        self.assertEqual((run / summary['screenshots'][0]).read_bytes(), b'FAKE: not iOS evidence 0')
        self.assertEqual((run / matched['reference']).read_bytes(), b'FAKE: design reference')
        page = (run / summary['comparison_page']).read_text()
        self.assertIn('href="design-reference/04%20today.jpg"', page)
        self.assertIn('src="screenshots/04%20today.png"', page)
        self.assertLess(page.index('Reference: <a'), page.index('Built screen: <a'))
        self.assertIn('04 today--largest-text.jpg', page)
        self.assertIn('04 today--reduce-motion.png', page)
        self.assertIn('Technical shell: no design reference', page)
        self.assertIn('Context only, excluded from screen coverage', page)
        evidence, _ = self.invoke('evidence', extra=('--run', str(run)))
        self.assertIn('Reference 04 today.jpg: MATCHED screenshots/04 today.png', evidence.stdout)
        self.assertIn('Reference 05-ask.jpg: MISSING main screenshot', evidence.stdout)
        self.assertIn(str(run / 'design-comparison.html'), evidence.stdout)

    def test_variants_never_satisfy_main_coverage(self):
        self.env['FAKE_CAPTURES'] = json.dumps(['04 today--largest-text', '04 today--reduce-motion', '05-ask'])
        result, summary = self.invoke(extra=('--require-all-screenshots',))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Missing main screenshots for design references: 04 today', summary['error'])
        self.assertIsNone(summary['design_coverage'][0]['screenshot'])
        self.assertEqual(len(summary['design_coverage'][0]['variants']), 2)
        self.assertTrue((Path(summary['run']) / summary['comparison_page']).exists())

    def test_strict_coverage_passes_only_with_all_main_screenshots(self):
        missing, summary = self.invoke(extra=('--require-all-screenshots',))
        self.assertNotEqual(missing.returncode, 0)
        self.assertIn('05-ask', summary['error'])
        self.env['FAKE_CAPTURES'] = json.dumps(['04 today', '05-ask', '04 today--largest-text'])
        complete, summary = self.invoke(extra=('--require-all-screenshots',))
        self.assertEqual(complete.returncode, 0, complete.stdout+complete.stderr)

    def test_duplicate_names_fail_across_tests_and_image_extensions(self):
        for names in (['04 today', '04 today'], ['04 today--largest-text'] * 2, ['04 today', '04 TODAY']):
            with self.subTest(names=names):
                self.env['FAKE_CAPTURES'] = json.dumps(names)
                result, summary = self.invoke()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('Duplicate screenshot name: ' + names[1], summary['error'])

    def test_names_are_html_escaped_and_urls_encoded(self):
        name = '04 today & <quoted> #?'
        (self.references / (name + '.jpg')).write_bytes(b'FAKE')
        self.env['FAKE_CAPTURES'] = json.dumps([name])
        result, summary = self.invoke()
        self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
        page = (Path(summary['run']) / summary['comparison_page']).read_text()
        self.assertIn('04 today &amp; &lt;quoted&gt; #?.png', page)
        self.assertIn('screenshots/04%20today%20%26%20%3Cquoted%3E%20%23%3F.png', page)
        self.assertNotIn('<quoted>', page)

    def test_malformed_or_missing_attachment_metadata_fails_closed(self):
        for case in ('missing-manifest', 'bad-manifest', 'wrong-manifest-shape', 'unknown-name', 'missing-export', 'unsafe-export'):
            with self.subTest(case=case):
                result, summary = self.invoke(case=case)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('attachments/manifest.json', summary['error'])

    def test_unsafe_screenshot_names_are_rejected(self):
        for name in ('../outside', 'screen/child', 'screen\\child', 'screen\nchild'):
            with self.subTest(name=name):
                self.env['FAKE_CAPTURES'] = json.dumps([name])
                result, summary = self.invoke()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('screenshot name', summary['error'])

    def test_strict_coverage_rejects_absent_references(self):
        shutil.rmtree(self.references)
        result, summary = self.invoke(extra=('--require-all-screenshots',))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('No screen reference images', summary['error'])

    def test_strict_option_only_applies_to_test_and_check(self):
        result, _ = self.invoke('doctor', extra=('--require-all-screenshots',))
        self.assertEqual(result.returncode, 2)
        self.assertIn('applies only to test/check', result.stderr)

    def test_check_runs_contracts_and_enforces_strict_coverage(self):
        (self.root / 'tests').mkdir()
        result, summary = self.invoke('check', extra=('--require-all-screenshots',))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('05-ask', summary['error'])
        self.assertTrue((Path(summary['run']) / 'command-tests.log').exists())
        self.assertTrue((Path(summary['run']) / 'design-rules.log').exists())

    def test_check_rejects_design_rule_violation(self):
        (self.root / 'tests').mkdir()
        source = self.root / 'HarnessShell/Bad.swift'
        source.parent.mkdir()
        source.write_text('let raw = Color.red\n')
        result, summary = self.invoke('check')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('design-rules failed', summary['error'])
        self.assertIn('HarnessShell/Bad.swift:1', (Path(summary['run']) / 'design-rules.log').read_text())

    def test_xcode_failure_status_survives_export(self):
        result, summary = self.invoke(case='failed-tests')
        self.assertEqual(result.returncode, 65)
        self.assertEqual(summary['status'], 'failed')
        self.assertEqual(summary['tests']['failedTests'], 1)

    def test_zero_tests_rejected(self):
        result, summary = self.invoke(case='zero-tests')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('total=0', summary['error'])

    def test_fewer_than_four_tests_rejected(self):
        result, summary = self.invoke(case='too-few-tests')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('total=3', summary['error'])

    def test_skipped_tests_rejected(self):
        result, _ = self.invoke(case='skipped-tests')
        self.assertNotEqual(result.returncode, 0)

    def test_missing_screenshot_rejected(self):
        for case in ('no-screenshot', 'unlisted-screenshot'):
            with self.subTest(case=case):
                result, summary = self.invoke(case=case)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('screenshot', summary['error'])

    def test_export_failure_rejected(self):
        result, summary = self.invoke(case='export-fails')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('attachment-export', summary['error'])

    def test_invalid_result_json_rejected(self):
        result, summary = self.invoke(case='bad-json')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('invalid JSON', summary['error'])

    def test_unknown_summary_schema_fails_closed(self):
        for case in ('wrong-shape', 'missing-counts'):
            with self.subTest(case=case):
                result, summary = self.invoke(case=case)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(summary['status'], 'failed')
                self.assertIn('error', summary)

    def test_failed_result_or_expected_failure_rejected(self):
        for case in ('expected-failure', 'failed-result'):
            with self.subTest(case=case):
                result, summary = self.invoke(case=case)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(summary['status'], 'failed')

    def test_missing_xcode_has_actionable_message(self):
        result, summary = self.invoke('doctor', 'missing-xcode')
        self.assertEqual(result.returncode, 72)
        self.assertIn('DEVELOPER_DIR', summary['error'])

    def test_missing_runtime_or_unknown_device(self):
        for case, extra in [('no-device', ()), ('', ('--device', 'MISSING'))]:
            with self.subTest(case=case):
                result, summary = self.invoke('doctor', case, extra)
                self.assertEqual(result.returncode, 2)
                self.assertIn('available iPhone', summary['error'])

    def test_explicit_destination(self):
        result, summary = self.invoke('build', extra=('--device', 'PHONE'))
        self.assertEqual(result.returncode, 0)
        self.assertEqual(summary['device']['udid'], 'PHONE')

    def test_build_failure_propagates(self):
        result, _ = self.invoke('build', 'failed-build')
        self.assertEqual(result.returncode, 65)

    def test_launch_boots_installs_then_launches_selected_device(self):
        result, summary = self.invoke('launch', extra=('--device', 'PHONE'))
        self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
        commands = [json.loads(line) for line in (Path(summary['run'])/'commands.jsonl').read_text().splitlines()]
        sim = [c[1:3] for c in commands if c[0] == 'xcrun']
        for action in ['boot', 'bootstatus', 'install', 'launch']:
            self.assertIn(['simctl', action], sim)
        self.assertLess(sim.index(['simctl', 'install']), sim.index(['simctl', 'launch']))

    def test_run_identity_and_evidence_inspection(self):
        first, one = self.invoke('doctor')
        second, two = self.invoke('doctor')
        self.assertEqual(first.returncode, 0)
        self.assertEqual(second.returncode, 0)
        self.assertNotEqual(one['run'], two['run'])
        result, _ = self.invoke('evidence', extra=('--run', one['run']))
        self.assertEqual(result.returncode, 0)
        self.assertIn(one['run'], result.stdout)

    def test_no_evidence_is_actionable(self):
        result, _ = self.invoke('evidence')
        self.assertEqual(result.returncode, 2)
        self.assertIn('No runs yet', result.stderr)


if __name__ == '__main__':
    unittest.main()
