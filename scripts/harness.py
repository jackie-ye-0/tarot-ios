"""Local iOS feedback loop. Python standard library and Apple tools only."""
import argparse
import datetime
import json
import os
from pathlib import Path
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parent.parent
RUNS = ROOT / '.harness' / 'runs'


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


def test_ios(run, device, summary):
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
        images = sorted(str(p.relative_to(run)) for p in (run / 'attachments').rglob('*') if p.suffix.lower() in ('.png', '.jpeg', '.jpg', '.heic'))
        summary['screenshots'] = images
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
    args = parser.parse_args()
    if args.run and args.command != 'evidence':
        parser.error('--run applies only to evidence')
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
        device = prerequisites(run, args.device)
        summary['device'] = device
        if args.command in ('test', 'check'):
            test_ios(run, device, summary)
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
    if 'error' in summary:
        lines.append(summary['error'])
    lines.append('Raw logs, command arguments and metadata are in this run directory. A build/doctor/launch pass is not a test pass.')
    (run / 'summary.txt').write_text('\n'.join(lines) + '\n')
    print('\n'.join(lines))
    return code


if __name__ == '__main__':
    sys.exit(main())
