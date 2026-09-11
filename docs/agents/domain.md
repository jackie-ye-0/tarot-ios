# Domain docs

This repository uses a single-context layout. These rules tell engineering skills how to consume domain documentation when it exists; they do not define a tarot product domain.

## Before exploring, read these

- Root `CONTEXT.md`, for resolved domain terms.
- Relevant ADRs in root `docs/adr/`, for architectural decisions affecting the area of work.

If either is absent, proceed silently. Do not flag the absence or suggest creating it upfront. `/domain-modeling` creates these documents lazily when terms or decisions are actually resolved within approved work.

Keep [scope and decisions](../decisions.md) as the existing owner of approved scope and unresolved product choices. Follow [harness principles](../harness.md) and its linked owners for harness improvements. Do not duplicate or migrate those documents into a speculative domain glossary or ADR set.

## File structure

The intended lazy paths are:

```text
CONTEXT.md
docs/adr/
```

This configuration does not create those files or directories. No root `CONTEXT-MAP.md` or per-context hierarchy is needed for this repository.

## Use the glossary's vocabulary

When naming a domain concept in an issue, proposal, hypothesis or test, use the term defined in `CONTEXT.md`. Avoid synonyms that the glossary explicitly excludes.

If an existing glossary lacks a concept you need, reconsider whether you are inventing language the project does not use. If there is a real gap, note it for `/domain-modeling` within the approved task; do not invent domain knowledge to fill it.

## Flag ADR conflicts

If a proposal contradicts an existing ADR, identify the ADR and explain the conflict and why reconsideration may be warranted. Do not silently override the decision. Continue to respect the repository's existing decision and approval boundaries.
