# Project documents

Keep research, product requirements and harness guidance here so they travel with the repository and their history is tracked in Git.

## Research

- [User psychology and journeys](research/user-psychology-and-journeys.md): research prepared on 12 September 2026 covering audience evidence, motivations, category-specific journeys and reasons to return. Includes hypotheses to validate, not approved product requirements.
- [Market opportunity assessment](research/market-opportunity.md): fortune-telling iOS market research prepared on 9 September 2026. Imported unchanged from the original research document. Its linked companion documents, `competitor-audit.md` and `demand-demographics.md`, have not yet been imported; those relative links will not resolve until they are added alongside it.

Add future research to `docs/research/`, using descriptive, lower-case hyphenated filenames. Include the research date and sources; findings are evidence and hypotheses, not approved product requirements.

## Product requirements

- [PRD folder](prds/README.md): home for product requirements documents.
- [Divination app V1 PRD](prds/prd-divination-app-v1.md): user-supplied requirements, imported unchanged on 17 September 2026 for reference; implementation is not approved.
- [Tarot V1 mock design](prds/assets/tarot-v1-final.html): accompanying user-supplied HTML mock-up, imported unchanged on 17 September 2026.
- [Quiet reflection proposal](prds/quiet-reflection-proposal.md): draft audience hypothesis and two-screen visual concept; implementation is not approved.

## Design

- [Design manifest](design.md): colours, type, shapes, components, flow and wording rules adopted on 11 October 2026. Follow it for any design or UI work. It supersedes the PRD's §10 where they differ; it does not approve implementation.
- [Design reference images](design-reference/README.md): a picture of each of the eleven screens, exported from the design canvas, for comparing built screens against.

## Harness guidance

- [Decisions and scope](decisions.md)
- [Architecture](architecture.md)
- [Workflow](workflow.md)
- [Verification](verification.md)
- [Foundation slice verification](foundation-verification.md): issue #7 behaviour, design evidence and scope differences.
- [Ritual motion verification](ritual-motion-verification.md): issue #10 motion, test coverage and design evidence.
- [Today verification](today-verification.md): issue #9 acceptance checks, screenshot comparison and audit evidence.
- [Card face verification](card-faces-verification.md): issue #12 full-deck identity, rendering evidence and design comparison.
- [Ask foundation verification](ask-verification.md): issue #13 behaviour, design evidence and scope differences.
- [Harness principles](harness.md)

Add a link here when adding a document. Keep each document's status clear and record approved scope changes in [decisions](decisions.md).
