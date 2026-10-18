# Export and delete all data (#22)

Status: implementation complete; iOS validation is in progress after rebasing onto the Morning reminder implementation. The normal scheme is restored. Independent comparison is pending firstmate's fresh-session review.

Non-simulator checks on 19 October 2026 (Sydney): all 34 command tests passed; all app/unit/UI Swift sources parsed successfully; the design-role guard and `git diff --check` passed. The earlier iOS run was deliberately interrupted after the source changed, and the later queued run was cancelled before acquiring the simulator under firstmate's hold. Neither run establishes full iOS verification. The earlier run did pass the three new engine/deletion tests before interruption; those results will be superseded by the final full check.

## Behaviour and boundaries

Settings' Good to know group ends with Export my readings and the destructive Delete all my data row. Export produces one UTF-8 `Daybreak-readings.txt` from the saved History snapshots, independent of hidden areas. It includes each daily date and recorded timestamp, card identity, orientation, picked position, original interpretation, keywords, colour, object, hour, all area scores and lines; each question reading includes timestamp, ID, area, question, all three cards/orientations/positions, original sections, connecting passage, reflection, optional response and notes. Old daily snapshots without a timestamp say “Time not recorded”. An empty archive exports a readable empty-state sentence.

The native share sheet receives a local file URL. Copy reads that same file as text. No account, network request, remote metadata lookup, dependency or service is added. The temporary export is removed on dismissal, before another export or deletion, and on launch after interruption. The user controls any destination chosen in the system share sheet.

Delete requires a native confirmation that states its irreversible scope and that copies already saved elsewhere remain. All eight current SwiftData model types are deleted in one save; a failure rolls back the context and leaves Settings and data intact. Success clears session readings, question and spread state, status and area preferences, clears the in-memory installation seed, removes pending and delivered local notifications, and returns to Welcome. The identity remains absent until a new start or app launch, both of which create a fresh seed. The deletion does not remove exports outside the app or phone backups.

The integrated Morning reminder preference is included in the same deletion transaction. The existing notification boundary cancels pending and delivered notifications and clears its Debug fixture. Deletion is unavailable while an asynchronous reminder operation is busy, preventing that operation from restoring data after the wipe. A regression verifies that a failed deletion preserves the scheduled reminder, successful deletion cancels it, a foreground refresh cannot restore it, and a fresh first draw can offer the invitation again.

## Verification map

- Engine export checks cover every daily field, all areas, original reading passages, Unicode and multi-line notes, all positions/orientations, deterministic output, old dates and an empty archive.
- A persisted deletion regression populates every current model, forces a failure after all deletions are staged, checks rollback, retries successfully, checks zero rows of every type, reopens the disk store and checks zero rows again. Session assertions check the empty in-memory state and a fresh replacement seed.
- Real-app UI tests export three daily draws and three area readings through the native Copy activity and retain the resulting text. They check hidden-area inclusion, cancellation preserving data, confirmed deletion returning to Welcome, relaunch retaining Welcome, empty History and default preferences, and drawing again after reset.
- Error injection covers failed export/retry and failed delete/retry at ordinary and largest app text sizes. These flags are parsed only in Debug test mode.
- Existing Settings captures retain `11-settings` and its bottom and largest-text variants; this change adds data-action, share-sheet, confirmation and error variants. Returned Welcome uses `01-welcome--after-delete` and its largest-text variant. The existing font-loading and lexical design guard remain unchanged.

## Design comparison

Compare `11-settings` and all data-action variants against `docs/design-reference/11-settings.jpg` and manifest §11h. The integrated morning-reminder section remains between About you and Good to know, as in the reference. Relationship status reflects the synthetic fixture rather than the reference's selected value. Native confirmation/error alerts and the share sheet have no reference images and use system styling, as recorded in the manifest. Welcome is reused without visual changes.

Final run, inspected images, accessibility results, accepted differences and independent findings will be recorded after validation.
