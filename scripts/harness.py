"""Local iOS feedback loop. Python standard library and Apple tools only."""
import argparse
import datetime
from html import escape
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from urllib.parse import quote
import uuid

ROOT = Path(__file__).resolve().parent.parent
RUNS = ROOT / '.harness' / 'runs'
IMAGE_SUFFIXES = ('.png', '.jpeg', '.jpg', '.heic')


class Failure(Exception):
    def __init__(self, message, code=1):
        super().__init__(message)
        self.code = code if code > 0 else 1


def execute(args, run, name, allow_failure=False):
    """Keep unabridged output and argv; no shell interpolation or pipe masking."""
    with (run / 'commands.jsonl').open('a') as commands:
        commands.write(json.dumps(args) + '\n')
    try:
        with (run / f'{name}.log').open('w') as log:
            process = subprocess.run(args, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
        output = (run / f'{name}.log').read_text(errors='replace')
    except OSError as error:
        raise Failure(f'Cannot run {args[0]}: {error}. Install/select prerequisites manually.', 2) from error
    if process.returncode and not allow_failure:
        raise Failure(f'{name} failed (exit {process.returncode}); see {run / (name + ".log")}', process.returncode)
    return process.returncode, output


def json_output(args, run, name):
    _, output = execute(args, run, name)
    try:
        return json.loads(output)
    except ValueError as error:
        raise Failure(f'{name} returned invalid JSON; see its raw log.') from error


def prerequisites(run, requested):
    metadata = {'developer_directory_override': os.environ.get('DEVELOPER_DIR'), 'python': sys.version, 'platform': sys.platform}
    _, directory = execute(['xcode-select', '-p'], run, 'developer-directory', True)
    metadata['developer_directory'] = os.environ.get('DEVELOPER_DIR') or directory.strip()
    (run / 'metadata.json').write_text(json.dumps(metadata, indent=2) + '\n')
    code, version = execute(['xcodebuild', '-version'], run, 'xcode-version', True)
    if code:
        raise Failure('Full Xcode is required. Complete Xcode setup and an iOS Simulator runtime, then set DEVELOPER_DIR to its Contents/Developer for this command. See xcode-version.log. Nothing was installed or changed.', code)
    execute(['xcrun', '--find', 'simctl'], run, 'simctl-location')
    execute(['xcrun', '--find', 'xcresulttool'], run, 'xcresulttool-location')
    execute(['xcodebuild', '-showsdks'], run, 'sdks')
    devices = json_output(['xcrun', 'simctl', 'list', 'devices', 'available', '--json'], run, 'devices')
    if not isinstance(devices, dict) or not isinstance(devices.get('devices'), dict):
        raise Failure('Unexpected simulator JSON structure; inspect devices.log.')
    candidates = []
    for runtime, items in devices['devices'].items():
        if '.iOS-' not in runtime:
            continue
        for device in items:
            if device.get('isAvailable') and device.get('name', '').startswith('iPhone'):
                candidates.append(dict(device, runtime=runtime))
    # Stable selection; no assumption that a particular model/runtime exists.
    candidates.sort(key=lambda d: (d.get('state') != 'Booted', d['runtime'], d['name'], d['udid']))
    selected = next((d for d in candidates if d['udid'] == requested), None) if requested else next(iter(candidates), None)
    if selected is None:
        raise Failure('No matching available iPhone simulator. Add an iOS runtime/device in Xcode, or pass --device with an available iPhone UDID. See devices.log.', 2)
    metadata.update(xcode=version.strip(), device=selected)
    (run / 'metadata.json').write_text(json.dumps(metadata, indent=2) + '\n')
    return selected


def build_args(action, run, device):
    return ['xcodebuild', action, '-project', str(ROOT / 'HarnessShell.xcodeproj'), '-scheme', 'HarnessShell', '-configuration', 'Debug', '-destination', f'platform=iOS Simulator,id={device["udid"]}', '-derivedDataPath', str(run / 'DerivedData'), '-resultBundlePath', str(run / ('Tests.xcresult' if action == 'test' else 'Build.xcresult')), 'CODE_SIGNING_ALLOWED=NO']


def named_screenshots(run):
    folder = run / 'attachments'
    try:
        manifest = json.loads((folder / 'manifest.json').read_text())
        if not isinstance(manifest, list):
            raise ValueError('expected a list of test attachments')
        images = {}
        seen = set()
        for test in manifest:
            for attachment in test['attachments']:
                exported = attachment['exportedFileName']
                if not isinstance(exported, str) or Path(exported).name != exported:
                    raise ValueError('invalid exportedFileName')
                source = folder / exported
                if source.suffix.lower() not in IMAGE_SUFFIXES:
                    continue
                suggested = attachment['suggestedHumanReadableName']
                # Xcode adds _<index>_<UUID>.<extension> to XCTAttachment.name.
                match = re.fullmatch(r'(.+)_\d+_[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\.[^.]+', suggested)
                if not match:
                    raise ValueError(f'cannot recover screenshot name from {suggested!r}')
                name = match[1]
                if name in ('.', '..') or any(c in '/\\' or ord(c) < 32 for c in name):
                    raise ValueError(f'unsafe screenshot name: {name!r}')
                if name.casefold() in seen:
                    raise Failure(f'Duplicate screenshot name: {name}. Give every capture a unique name, including its variant suffix.')
                seen.add(name.casefold())
                if not source.is_file():
                    raise ValueError(f'missing exported screenshot: {exported}')
                images[name] = source
    except (OSError, ValueError, KeyError, TypeError) as error:
        raise Failure(f'Cannot read screenshot names from attachments/manifest.json: {error}') from error
    destination = run / 'screenshots'
    destination.mkdir()
    paths = []
    for name, source in sorted(images.items()):
        target = destination / (name + source.suffix.lower())
        shutil.copyfile(source, target)
        paths.append(str(target.relative_to(run)))
    return paths


def design_comparison(run, summary):
    """Snapshot references so a copied run still has a working comparison page."""
    references = {}
    context = []
    for source in sorted((ROOT / 'docs/design-reference').glob('*')):
        if source.suffix.lower() not in IMAGE_SUFFIXES or not source.is_file():
            continue
        destination = run / 'design-reference' / source.name
        destination.parent.mkdir(exist_ok=True)
        shutil.copyfile(source, destination)
        relative = str(destination.relative_to(run))
        if source.stem == '00-flow-map':
            context.append(relative)
        else:
            if source.stem in references:
                raise Failure(f'Duplicate design reference name: {source.stem}')
            references[source.stem] = relative

    captures = {Path(path).stem: path for path in summary['screenshots']}
    groups = {}
    for name in captures:
        screen, separator, _ = name.partition('--')
        if separator:
            groups.setdefault(screen, []).append(name)
    coverage = []
    for name, reference in references.items():
        coverage.append({'name': name, 'reference': reference,
                         'screenshot': captures.get(name),
                         'variants': [captures[v] for v in groups.get(name, [])]})
    summary['design_coverage'] = coverage
    summary['design_context'] = context
    summary['unmatched_screenshots'] = [path for name, path in captures.items()
                                        if name.partition('--')[0] not in references]
    summary['comparison_page'] = 'design-comparison.html'

    def figure(path, label, missing):
        if path is None:
            return f'<div class="missing"><strong>{label}</strong><p>{missing}</p></div>'
        url = quote(path)
        name = escape(Path(path).name)
        return (f'<figure><figcaption>{label}: <a href="{url}">{name}</a></figcaption>'
                f'<a href="{url}"><img src="{url}" alt="{label}: {name}"></a></figure>')

    matched = sum(item['screenshot'] is not None for item in coverage)
    parts = ['<!doctype html><html lang="en"><meta charset="utf-8">',
             '<meta name="viewport" content="width=device-width, initial-scale=1">',
             '<title>Design comparison</title><style>',
             'body{font:16px/1.5 system-ui,sans-serif;color:#202124;background:#fff;margin:32px auto;padding:0 24px;max-width:1100px}',
             'a{color:#174ea6}section{border-top:1px solid #aaa;padding:24px 0}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}',
             'figure{margin:0;min-width:0}figcaption{overflow-wrap:anywhere;margin-bottom:12px}img{width:100%;max-width:390px;height:auto;border:1px solid #ccc}',
             '.missing{background:#f4f4f4;padding:16px}h2,h3{overflow-wrap:anywhere}li{margin:4px 0}',
             '@media(max-width:600px){body{padding:0 12px}.pair{gap:12px}}',
             '</style><h1>Design comparison</h1>',
             f'<p>{matched} of {len(coverage)} screen references have a main screenshot. '
             'Variants never satisfy main-screen coverage. This page does not establish visual approval or a passing test run.</p>',
             '<p>Reference on the left; built screen on the right. Open an image for full size. '
             'Check structure, actions, colour, type, shape, spacing and wording against the design manifest §12.</p>',
             '<p><a href="summary.txt">Run summary</a></p><ul>']
    for index, item in enumerate(coverage):
        status = 'matched' if item['screenshot'] else 'MISSING main screenshot'
        parts.append(f'<li><a href="#screen-{index}">{escape(item["name"])}</a>: {status}</li>')
    parts.append('</ul>')
    if context:
        parts.append('<p>Context only, excluded from screen coverage: ' + ', '.join(
            f'<a href="{quote(path)}">{escape(Path(path).name)}</a>' for path in context) + '.</p>')
    for index, item in enumerate(coverage):
        parts.append(f'<section id="screen-{index}"><h2>{escape(item["name"])}</h2><div class="pair">')
        parts.append(figure(item['reference'], 'Reference', 'No reference image.'))
        parts.append(figure(item['screenshot'], 'Built screen', 'Missing main screenshot.'))
        parts.append('</div>')
        for variant in item['variants']:
            parts.append(f'<h3>Variant: {escape(Path(variant).stem)}</h3><div class="pair">')
            parts.append(figure(item['reference'], 'Reference', 'No reference image.'))
            parts.append(figure(variant, 'Built variant', 'Missing variant.'))
            parts.append('</div>')
        parts.append('</section>')
    unmatched_groups = sorted({name.partition('--')[0] for name in captures} - references.keys())
    for screen in unmatched_groups:
        parts.append(f'<section><h2>{escape(screen)}: no design reference</h2>')
        for name in [screen] + groups.get(screen, []):
            if name not in captures:
                continue
            parts.append('<div class="pair">' + figure(None, 'Reference', 'No matching reference image.'))
            parts.append(figure(captures[name], 'Built variant' if '--' in name else 'Built screen', '') + '</div>')
        parts.append('</section>')
    parts.append('</html>')
    (run / summary['comparison_page']).write_text('\n'.join(parts) + '\n')


def test_ios(run, device, summary, require_all_screenshots=False):
    bundle = run / 'Tests.xcresult'
    args = build_args('test', run, device) + ['-parallel-testing-enabled', 'NO']
    code, _ = execute(args, run, 'test', True)
    summary['xcodebuild_exit'] = code
    # Extract diagnostics even after a failing test invocation.
    evidence_error = None
    try:
        counts = json_output(['xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', str(bundle)], run, 'test-summary')
        if not isinstance(counts, dict):
            raise Failure('Unexpected test-summary JSON structure; inspect test-summary.log.')
        summary['tests'] = counts
        execute(['xcrun', 'xcresulttool', 'export', 'attachments', '--path', str(bundle), '--output-path', str(run / 'attachments')], run, 'attachment-export')
        images = named_screenshots(run)
        summary['screenshots'] = images
        design_comparison(run, summary)
        total = counts.get('totalTestCount')
        passed = counts.get('passedTests')
        failed = counts.get('failedTests')
        skipped = counts.get('skippedTests')
        expected_failures = counts.get('expectedFailures')
        # Four meaningful tests are the initial baseline. Do not lower it to hide failures.
        if not all(isinstance(n, int) for n in (total, passed, failed, skipped, expected_failures)) or total < 4 or passed != total or failed or skipped or expected_failures or counts.get('result') != 'Passed':
            raise Failure(f'Test verification incomplete: total={total}, passed={passed}, failed={failed}, skipped={skipped}, expected failures={expected_failures}, result={counts.get("result")}; require at least 4, all passing.')
        if not images:
            raise Failure('No retained test screenshot was exported; inspect attachment-export.log and keepAlways attachment lifetime.')
        if require_all_screenshots:
            if not summary['design_coverage']:
                raise Failure('No screen reference images found in docs/design-reference; cannot require full screenshot coverage.')
            missing = [item['name'] for item in summary['design_coverage'] if not item['screenshot']]
            if missing:
                raise Failure('Missing main screenshots for design references: ' + ', '.join(missing))
    except Failure as error:
        evidence_error = str(error)
        summary['evidence_error'] = evidence_error
    if code:
        raise Failure(f'xcodebuild test failed (exit {code}); inspect test.log and retained result bundle.', code)
    if evidence_error:
        raise Failure(evidence_error)


def launch(run, device):
    execute(build_args('build', run, device), run, 'build')
    udid = device['udid']
    if device.get('state') != 'Booted':
        execute(['xcrun', 'simctl', 'boot', udid], run, 'boot')
    execute(['xcrun', 'simctl', 'bootstatus', udid, '-b'], run, 'bootstatus')
    execute(['xcrun', 'simctl', 'install', udid, str(run / 'DerivedData/Build/Products/Debug-iphonesimulator/HarnessShell.app')], run, 'install')
    execute(['xcrun', 'simctl', 'launch', '--terminate-running-process', udid, 'dev.local.tarotharness.HarnessShell'], run, 'launch')
    execute(['xcrun', 'simctl', 'io', udid, 'screenshot', str(run / 'launch.png')], run, 'launch-screenshot')


def inspect_evidence(which):
    if which:
        path = Path(which).resolve()
    else:
        choices = sorted(RUNS.glob('*/summary.json'))
        if not choices:
            raise Failure('No runs yet. Run doctor, build, launch, test or check first.', 2)
        path = choices[-1].parent
    if path.is_file():
        path = path.parent
    try:
        print((path / 'summary.txt').read_text())
    except OSError as error:
        raise Failure(f'Cannot inspect {path}: {error}', 2) from error


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['doctor', 'build', 'launch', 'test', 'check', 'evidence'])
    parser.add_argument('--device', help='Available iPhone simulator UDID; otherwise prefer a booted iPhone, then stable alphabetical order')
    parser.add_argument('--run', help='Run directory to inspect (evidence only; defaults to latest)')
    parser.add_argument('--require-all-screenshots', action='store_true', help='Fail test/check if any screen reference lacks its main screenshot')
    args = parser.parse_args()
    if args.run and args.command != 'evidence':
        parser.error('--run applies only to evidence')
    if args.require_all_screenshots and args.command not in ('test', 'check'):
        parser.error('--require-all-screenshots applies only to test/check')
    if args.command == 'evidence':
        try:
            inspect_evidence(args.run)
            return 0
        except Failure as error:
            print(error, file=sys.stderr)
            return error.code
    identity = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ') + '-' + args.command + '-' + uuid.uuid4().hex[:8]
    run = RUNS / identity
    run.mkdir(parents=True)
    summary = {'run': str(run), 'command': args.command, 'status': 'failed'}
    code = 1
    print(f'Evidence: {run}', flush=True)
    try:
        _, revision = execute(['git', 'rev-parse', 'HEAD'], run, 'revision', True)
        _, dirty = execute(['git', 'status', '--short'], run, 'worktree', True)
        summary.update(revision=revision.strip(), worktree=dirty.strip())
        if args.command == 'check':
            execute([sys.executable, '-m', 'unittest', 'discover', '-s', 'tests', '-v'], run, 'command-tests')
            execute([sys.executable, str(ROOT / 'scripts/design_rules.py')], run, 'design-rules')
        device = prerequisites(run, args.device)
        summary['device'] = device
        if args.command in ('test', 'check'):
            test_ios(run, device, summary, args.require_all_screenshots)
        elif args.command == 'build':
            execute(build_args('build', run, device), run, 'build')
        elif args.command == 'launch':
            launch(run, device)
        summary['status'] = 'passed'
        code = 0
    except Failure as error:
        summary['error'] = str(error)
        code = error.code
    except (OSError, ValueError, KeyError) as error:
        summary['error'] = f'Unexpected tool/output error: {error}'
    except KeyboardInterrupt:
        summary['error'] = 'Interrupted; run is incomplete.'
        code = 130
    summary['exit_code'] = code
    (run / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    lines = [f'{args.command}: {summary["status"]} (exit {code})', f'Run: {run}', f'HEAD: {summary.get("revision", "unknown")}']
    if 'device' in summary:
        lines.append(f'Device: {device["name"]} / {device["runtime"]} / {device["udid"]}')
    if 'tests' in summary:
        lines.append('Tests: ' + ', '.join(f'{key}={summary["tests"].get(key, "unknown")}' for key in ['totalTestCount', 'passedTests', 'failedTests', 'skippedTests', 'expectedFailures']))
    if 'screenshots' in summary:
        lines.append('Screenshots: ' + ', '.join(summary['screenshots']))
    if 'design_coverage' in summary:
        lines.append('Design comparison: ' + str(run / summary['comparison_page']))
        for item in summary['design_coverage']:
            match = 'MATCHED ' + item['screenshot'] if item['screenshot'] else 'MISSING main screenshot'
            lines.append(f'Reference {Path(item["reference"]).name}: {match}')
            if item['variants']:
                lines.append('  Variants (do not count as main): ' + ', '.join(item['variants']))
        if summary['design_context']:
            lines.append('Context only (excluded from screen coverage): ' + ', '.join(summary['design_context']))
        if summary['unmatched_screenshots']:
            lines.append('Screenshots without a reference: ' + ', '.join(summary['unmatched_screenshots']))
    if 'error' in summary:
        lines.append(summary['error'])
    lines.append('Raw logs, command arguments and metadata are in this run directory. A build/doctor/launch pass is not a test pass.')
    (run / 'summary.txt').write_text('\n'.join(lines) + '\n')
    print('\n'.join(lines))
    return code


if __name__ == '__main__':
    sys.exit(main())
