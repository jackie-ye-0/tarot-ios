# Independent standalone Codex acceptance

Status: **executed once successfully**; see `verification.md` for observed evidence and limits. The protocol below remains the repeatable acceptance scenario. Full Xcode and an available iPhone simulator are required. Coordinate scheduling with whoever owns the Mac; no supervisor software is required to run it.

## Prepare an isolated fixture

Use a committed harness revision. Make a disposable copy inside `.harness/acceptance/` (or a separate directory you own) containing only tracked files; initialise a new Git repository there and commit the baseline. Record the source branch/head and fixture head. Do not copy `.harness/`, chat history, credentials or supervisor files. Use a checkout path containing spaces to exercise portability.

In this disposable copy only, change `SmokeCounter.increment()` from `count += 1` to `count += 2` and commit this deliberate defect. Do not weaken the tests. Run `./scripts/harness test` from the copy with the selected `DEVELOPER_DIR`/device, and record its non-zero exit status and evidence path. Confirm the test bundle reports assertion failures, rather than compilation or prerequisite failures. This is the real deliberately failing iOS fixture. It is not satisfied by fake-tool unit tests.

## Launch a new Codex session

Start directly in the disposable repository root using the installed Codex client. Do not resume any session or pass a supervisor brief, earlier conversation, repository rules pasted into the prompt, or a proposed patch. Record client version, source/fixture revisions, working directory, relevant global instructions/settings and toolchain selection. Global instructions may affect behaviour; disclose them rather than claiming perfect isolation. If recording a transcript, retain it locally and redact sensitive settings before sharing.

Use only this bounded task prompt:

> The technical shell's counter should increase by exactly one per tap and reset when the app relaunches. It currently increases by two. Fix this technical fixture using this repository's guidance, verify it and report the evidence. Keep the change within the technical shell; do not add product features.

The session should discover `AGENTS.md`, read the relevant linked guidance, diagnose the existing behaviour, make the smallest repair, run the documented checks and inspect the passing-test screenshot. Do not remind it where the command lives during the exercise. If it cannot proceed, preserve its diagnosis and record the failure honestly.

## Review separately

A reviewer must inspect the actual session transcript/tool activity, diff and retained result bundle. Verify:

- Guidance was discovered and used; file presence alone is insufficient.
- The original failing invocation had real assertion failures and returned non-zero.
- The repair restores one-per-tap behaviour without changing tests, lowering the runner's minimum count or adding product logic/dependencies.
- `./scripts/harness check` then returns zero with actual test counts, selected toolchain/device metadata, raw logs, exported passing-test attachments and visually inspected screenshot.
- A separate reviewer reruns the documented check against the repaired fixture and records its result.

Record run paths and exit codes, client/version, source and repaired heads, transcript path, reviewer observations and remaining limitations in `docs/verification.md` in the main repository. Keep any personal absolute paths/transcript contents out of tracked files. The disposable defect/repair must not be merged back as a product change. This demonstrates one observed Codex workflow, not guaranteed future agent compliance. Other clients and remote enforcement remain unverified.
