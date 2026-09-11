# Issue tracker: GitHub

Issues and PRDs for this repo live in GitHub Issues for `jackie-ye-0/tarot-ios`. Use the ordinary `gh` CLI; Firstmate is not required. Run inside this clone and confirm the target with `git remote -v`, or pass `--repo jackie-ye-0/tarot-ios` to issue/PR commands.

These are consumer conventions, not permission to start automation or publish work. Follow [repository guidance](../../AGENTS.md), [scope and decisions](../decisions.md) and [workflow](../workflow.md) for authorisation. Consult [harness principles](../harness.md) for harness improvements.

## Conventions

Replace placeholders below with actual issue numbers or local file paths. Write multiline bodies to a file and use `--body-file`; preserve existing content when editing an issue body.

- Create: `gh issue create --title "..." --body-file <body-file>`.
- Read with comments and labels: `gh issue view <number> --json number,title,body,labels,comments`. Use `--jq` when filtering structured output, or `gh issue view <number> --comments` for readable conversation.
- List: `gh issue list --state open --json number,title,body,labels,comments`, with appropriate `--label` and `--state` filters. Use `--limit` or paginated API reads when the default page would omit relevant issues.
- Comment: `gh issue comment <number> --body-file <comment-file>`.
- Apply/remove labels: `gh issue edit <number> --add-label "..."` / `gh issue edit <number> --remove-label "..."`. Use the mapping in [triage labels](triage-labels.md).
- Close: post any explanation with the comment command, then `gh issue close <number>`.

## Pull requests as a triage surface

**PRs as a request surface: no.** External PRs are not included in the issue triage queue. This does not change the repository's direct-PR delivery workflow.

GitHub shares issue and PR numbers. If a bare reference could be either, resolve it with `gh pr view <number>` and fall back to `gh issue view <number>` when it is not a PR.

## When a skill says "publish to the issue tracker"

Create a GitHub issue, within the current task's authorisation.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`; fetch labels with structured output as above when needed.

## Wayfinding operations

Used when `/wayfinder` is explicitly run within an authorised task. The map is one issue with child issues as tickets. These conventions do not create a map, tickets, labels or an automation schedule during setup.

- **Map:** an issue labelled `wayfinder:map`, holding Notes / Decisions-so-far / Fog. Create with `gh issue create --title "..." --body-file <map-file> --label wayfinder:map`.
- **Child ticket:** create an issue with a `wayfinder:<type>` label (`research`, `prototype`, `grilling` or `task`), then link it using `gh issue edit <map-number> --add-sub-issue <child-number>`. If native sub-issues are unavailable, add the child to a task list in the map body and put `Part of #<map-number>` at the top of the child body. Assign the ticket to the driving developer when claimed.
- **Blocking:** use native issue dependencies: `gh issue edit <child-number> --add-blocked-by <blocker-number>`. The API equivalent is `gh api --method POST repos/jackie-ye-0/tarot-ios/issues/<child-number>/dependencies/blocked_by -F issue_id=<blocker-database-id>`; obtain the database ID with `gh api repos/jackie-ye-0/tarot-ios/issues/<blocker-number> --jq .id`. It is not the issue number or node ID. If dependencies are unavailable, put `Blocked by: #<number>, #<number>` at the top of the child body. A ticket is unblocked when every blocker is closed.
- **Frontier:** enumerate the map's open children using native sub-issues or its task list, retaining map order. Exclude assigned tickets and those with open blockers. Native issue responses expose `issue_dependencies_summary.blocked_by` (open blockers); for fallback text, read each referenced blocker's state. First remaining ticket in map order wins. Do not treat all open repository issues as children of the map.
- **Claim:** `gh issue edit <number> --add-assignee @me`, before beginning ticket work, as the session's first write.
- **Resolve:** `gh issue comment <number> --body-file <answer-file>`, then `gh issue close <number>`, then append a brief answer summary and link to the map's Decisions-so-far using `gh issue edit <map-number> --body-file <updated-map-file>`.

The Wayfinder label names are separate from the five triage roles. Missing labels or unsupported tracker features require an authorised follow-up or the documented fallback; configuring conventions does not authorise creating remote labels.
