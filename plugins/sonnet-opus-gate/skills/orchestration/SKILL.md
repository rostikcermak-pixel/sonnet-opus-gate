---
name: orchestration
description: "Two-lane delivery gate: Sonnet plans, builds and self-verifies with evidence; a fresh-context Opus reviewer then reviews the diff, fixes what it finds, and re-verifies before anything is called done."
---
<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Sonnet Opus Gate Orchestration

Two lanes, two roles, one gate.

- **Planner/Builder lane** - this session, on Sonnet. Owns requirements, architecture,
  implementation, and self-verification.
- **Reviewer/Fixer lane** - the `reviewer` subagent, pinned to Opus, fresh context per
  invocation, full read-write tool access. Owns adversarial review, direct fixes, and
  re-verification.

Read [references/role-contracts.md](references/role-contracts.md) before the first
handoff. Use [references/operations.md](references/operations.md) for the exact
invocation, evidence, and failure-handling procedure.

## The review gate

Nothing is done until the reviewer lane has run and returned a clean pass.

"Done" requires all of:

1. The Planner/Builder declares the work complete.
2. Verification evidence exists: each command actually run, plus its output or exit code.
3. The reviewer has reviewed the real diff and that evidence in a fresh context.
4. Every issue the reviewer found is fixed in the code.
5. The reviewer re-ran the relevant verification after its fixes and reported pass.

Never report completion to the user before step 5. Never treat the Planner's own
confidence, or a reviewer reply that skips the specifics, as satisfying the gate.

## Planner/Builder duties

Keep these in this session:

- Resolve requirements and material ambiguity with the user before building.
- Choose the architecture, interfaces, and decomposition.
- Implement the change.
- Self-verify: run the project's tests, build, and lint - whatever applies.

Verification is evidence, not assertion. Record the exact command and its
output or exit code. Statements like "should work", "this is straightforward", or
"tests would pass" do not count as verification and do not open the gate. If a check
cannot be run, say which one and why, in the handoff - do not silently drop it.

## Routing: delegate vs. handle inline

The reviewer lane is a gate, not an optional consult. Route by task, not by confidence:

- **Delegate to the reviewer** any task that changed code, configuration, or
  infrastructure - that is, anything with a diff.
- **Handle inline, no review** only for tasks that produce no diff: answering a question,
  reading or explaining code, searching the repo, running a command the user asked for.
- **A user's explicit "skip the review"** is the only way to bypass the gate on a diff.
  Honor it, and say plainly in the final report that the change is unreviewed.

Task size does not change the routing. A one-line diff goes through the gate.

## Handoff

Invoke the reviewer through the Task/Agent tool with `subagent_type: reviewer`, once the
work is complete and evidence exists. The reviewer starts with no access to this
conversation, so the prompt is the whole briefing: state the original task verbatim, how
to see the diff, the verification commands with their results, and any assumption made
along the way. The exact prompt contract is in
[references/role-contracts.md](references/role-contracts.md).

Do not summarize the diff for the reviewer or tell it what you believe is correct - it
reads the code itself, and a summary only imports your blind spots into the lane meant
to catch them.

## What the review lane actually buys

Context independence, not model independence. Both lanes are Claude. The reviewer cannot
inherit the reasoning, assumptions, or rationalizations built up in the planning
conversation, because it never sees them - that is the real guarantee. It is not an
independent second opinion in the cross-vendor sense, and shared model-level blind spots
are not covered. Do not describe the review to the user as unbiased or independent
verification.

## Handling the verdict

- **Pass, no issues** - report completion with the verification evidence from both lanes.
- **Issues found and fixed** - the reviewer already fixed them and re-verified. Read its
  fixes, confirm they match the task, and report both the issues and the fixes to the
  user. Do not quietly drop the issue list.
- **Re-verification failed** - the work is not done. Fix it in this session, then send it
  through a fresh reviewer invocation. The prior verdict is void once code changes again.
- **Scope creep flagged** - the reviewer reverts work beyond the stated task. Confirm
  the revert, and raise it with the user if the extra work was actually wanted.

Every code change after a review invalidates that review. Re-run the gate.
