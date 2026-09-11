# Triage labels

The engineering skills use five canonical roles. Map them to these approved GitHub label strings:

| Canonical role | Label in this tracker | Meaning |
| --- | --- | --- |
| `needs-triage` | `needs-triage` | Maintainer needs to evaluate this issue |
| `needs-info` | `needs-info` | Waiting on the reporter for more information |
| `ready-for-agent` | `ready-for-agent` | Fully specified, ready for an autonomous agent |
| `ready-for-human` | `ready-for-human` | Requires human implementation |
| `wontfix` | `wontfix` | Will not be actioned |

When a skill mentions a role, use its corresponding label string. Edit the tracker column if the repository's vocabulary changes.

This mapping neither creates GitHub labels nor starts triage. A readiness label does not override the task's authorisation, [scope and decisions](../decisions.md) or [workflow](../workflow.md).
