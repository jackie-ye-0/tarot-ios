# Harness engineering reference

The harness is the environment supporting AI coding: repository guidance, development tools, checks and feedback. It is separate from any future AI inside the tarot product. This reference supports later harness improvements; the linked project documents remain authoritative for local procedures and policy.

## Source

OpenAI, Ryan Lopopolo, [Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering/). Published 11 February 2026; reviewed 10 September 2026.

## Article principles and caveats

- Humans define intent, acceptance and outcomes; protect scarce attention.
- Diagnose missing environmental capabilities; build enabling blocks iteratively.
- Give agents direct UI, log, metric and trace access, with isolated runtimes per change.
- Keep knowledge versioned in the repository; use a short AGENTS map and progressively reveal detail.
- Track plans, progress, decisions, debt and quality; mechanically check documentation and garden stale content.
- Prefer predictable technology and inspectable abstractions.
- Enforce architecture, dependency direction and data validation at boundaries; make linter errors explain repairs. Preserve essential invariants while allowing local implementation freedom.
- Apply agents across tests, documentation, tools, evaluations, review and delivery, beyond application code.
- Earn autonomy through end-to-end reproduction, verification, review, feedback and recovery.
- Encode recurring feedback as rules; clean up incrementally.
- Throughput and merge trade-offs depend on context. Zero handwritten code, the specific web stack/layers and permissive merges were experiment choices, not requirements here.
- Evidence comes from one deployed experiment, not universal proof; durability over years and effects of evolving models remain unknown.

## What good means here

A useful harness lets standalone Codex discover the approved task boundary, run the technical fixture, diagnose failures and produce inspectable evidence. Firstmate is optional; repository commands must remain usable without a supervisor or shared daemon.

The current foundation is native Swift/SwiftUI, Apple tools and shell/Python, with synthetic data and local ignored output. Product features remain unapproved. Existing approval rules still apply: internal work uses direct PRs under `no-mistakes-prod-only`, yolo off; pushing requires task authorisation and merging requires approval. This reference grants no additional autonomy or permission to weaken checks.

## Using this reference later

Start from the concrete difficulty and consult these existing owners before proposing a bounded improvement:

- [README commands](../README.md#commands): prerequisites, invocation and evidence access.
- [Architecture](architecture.md): fixture, runner and evidence boundaries. Separate run directories do not establish isolated simulator runtimes per change.
- [Workflow](workflow.md): improvement process, replay and human decision boundaries.
- [Friction](friction.md): observed problems and their resolutions.
- [Decisions](decisions.md): approved scope, technology choices and unresolved product questions.
- [Verification](verification.md): observed results and limitations, rather than assumed capabilities.

Use those owners to assess the gap and record any authorised change. Article ideas are reference material, not a backlog or installed capabilities: no documentation automation, quality scorecard, new planning convention or cleanup schedule is introduced here. Follow the existing verification loop; documentation review and actual runtime evidence answer different questions.
