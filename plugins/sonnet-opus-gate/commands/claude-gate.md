---
description: "Run a task through the two-lane gate: build and self-verify on Sonnet, then a fresh-context Opus reviewer reviews, fixes and re-verifies before anything is done."
argument-hint: "<the task to build>"
---
<!-- SPDX-License-Identifier: GPL-3.0-only -->

Use the sonnet-opus-gate `orchestration` skill for this task. Follow it in full: its
routing rules, its evidence requirements, and its review gate.

The task:

$ARGUMENTS

Work the Planner/Builder lane yourself - requirements, architecture, implementation, and
self-verification with real command output. Then hand off to the `reviewer` subagent per
the skill's handoff contract, and report only after that lane returns `RESULT: pass`.

If the task produces no diff, handle it inline and say that no review was needed.
