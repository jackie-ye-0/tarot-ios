# Local workflow and harness evolution

## Working loop

Start a standalone Codex session from the repository root. Ask it to read repository guidance and state the approved scope. Run `./scripts/harness doctor`; fix missing prerequisites through the machine owner. Use `DEVELOPER_DIR` per command when needed. Make a bounded change, run the relevant command tests and `./scripts/harness check`, inspect the latest summary and exported screenshot, and report what actually executed. If tools are absent, report the failed prerequisite and precisely which iOS checks remain unverified.

For internal tooling/fixture changes, review the diff and make a coherent commit. Push/open a PR only when the task authorises it. Product changes are outside initial scope and require a human decision and review of the configured delivery gate. Repository prose and file-existence checks are not enforcement. No remote ruleset or CI gate has been verified here.

## Improve from observed friction

1. Capture a concrete failure or repeated slowdown in `docs/friction.md`: scenario, command, run path, expected/actual behaviour and impact. Use synthetic examples and remove private information.
2. Classify what was missing: **knowledge** (an agent could not find a fact), **tool** (a repetitive/error-prone operation), or **check** (a repeatable invariant failed silently). A larger design question belongs to a human decision.
3. Make the smallest fix: add a pointer or improve an existing explanation for knowledge; improve the existing command/diagnostic for tooling; add a behaviour check for a repeatable defect. Avoid creating parallel instructions or another wrapper by default.
4. Replay the original scenario, using a fresh Codex session if discovery or guidance was the problem. Record actual results and inspect the diff for weakened checks.
5. Rewrite or prune obsolete guidance and redundant checks. Close the friction entry with the evidence and remaining limitation.

Small, reversible changes inside approved scope can accompany a task. New dependencies/services, weaker checks, security/privacy changes, cost, product behaviour or significant architecture require a human decision. Explain options and consequences rather than silently expanding scope. This workflow is a review practice, not proof that instructions enforce themselves.

## Future AI testing boundary

Once AI product features are approved, fixed synthetic responses can drive repeatable app tests for rendering, navigation, empty/error states and retry behaviour. Store only invented prompts/context and fixed outputs; inject those through a narrow response boundary established at that time. These tests should run offline without credentials, network access, provider selection or spend. No such integration is implemented now.

Semantic evaluation answers a different question: whether generated readings are relevant, coherent, appropriately cautious and aligned with the user's context and intended tone. It needs an agreed synthetic/example dataset and rubric, plus a separate privacy/cost/provider decision before any live calls. Passing deterministic UI tests does not establish reading quality or safety. Keep those evidence sets separate.
