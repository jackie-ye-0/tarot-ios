# Learning notes

- **Harness:** the repeatable feedback loop around coding, not an AI model or application framework. Here it is repository guidance, a command wrapper, tests and inspectable evidence.
- **Project, target, scheme:** the Xcode project holds build settings; each target produces an app or test bundle; the shared `HarnessShell` scheme says what to build and test. The static files are in `HarnessShell.xcodeproj/`.
- **State and behaviour:** `@State` in `ContentView.swift` refreshes the screen when the counter changes. The counter has no storage, so relaunch resets it. Unit tests exercise the value directly; UI tests exercise the running app.
- **Exit status:** zero means a command completed successfully; non-zero means failure. `scripts/harness.py` preserves Xcode's failure status and additionally fails incomplete evidence. A successful build is not a successful test run.
- **Result bundle:** Apple's `.xcresult` contains test outcomes and attachments. Successful tests normally discard attachments unless their lifetime is `.keepAlways`; the UI fixture opts in explicitly.
- **Portability:** code, commands and guidance travel with Git. Xcode/runtimes are machine prerequisites, and generated output is machine-local. Per-command tool selection avoids changing the rest of the Mac.
- **Deterministic tests versus AI evaluations:** a fixed invented response can test how an app behaves repeatedly. It cannot judge whether a newly generated reading is helpful. See `docs/workflow.md` before future AI integration.
- **Guidance versus enforcement:** `AGENTS.md` tells an agent how to work. Only observed execution and reviewed results establish what it did; a pointer file or a green build alone cannot prove compliance.
