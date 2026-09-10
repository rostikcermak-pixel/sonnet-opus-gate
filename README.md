<!-- SPDX-License-Identifier: GPL-3.0-only -->

# sonnet-opus-gate

A Claude Code plugin: two lanes, two roles, one gate. Sonnet plans, builds and
self-verifies. A fresh-context Opus reviewer then reviews the real diff, fixes what it
finds, re-runs verification, and only then is the work done.

Inspired by [sol-advisor](https://github.com/DannyMac180/sol-advisor), adapted for Claude
Code subagents instead of Codex.

## What it does

**Planner/Builder lane** - your primary session, on Sonnet. Owns requirements gathering,
architecture, implementation, and self-verification (tests, build, lint). It must produce
concrete evidence - the command run plus its output or exit code - before declaring the
work done. "Should work" is not verification and does not open the gate.

**Reviewer/Fixer lane** - the `reviewer` subagent, pinned to Opus, full read-write tool
access, fresh context on every invocation. It is invoked only after the builder declares
completion and evidence exists. It reads the actual diff and the actual verification
output, hunts adversarially for correctness bugs, missed edge cases, security concerns,
silent failures, scope creep, and unverified claims - then fixes every issue directly in
the code, re-runs the relevant checks itself, and reports pass or fail with evidence,
plus a summary of every issue found and every fix made.

**The gate.** Nothing is done until the reviewer has reviewed, fixed if needed, and
re-verified. Any code change after a review voids that review; the gate runs again.

**Routing.** Anything that produces a diff goes through the gate, regardless of size.
Tasks with no diff - questions, code reading, searches - are handled inline with no
review. Only an explicit user instruction to skip the review bypasses the gate, and the
final report then says the change is unreviewed.

## What the review lane actually guarantees

**Context independence, not model independence.** Both lanes are Claude. The reviewer's
value is that it never sees the planning conversation, so it cannot inherit the
assumptions, reasoning, or rationalizations built up there. That is a real and useful
property - it catches the class of error where the builder convinced itself.

It is **not** a cross-model or cross-vendor check, and it is **not** bias-free review.
Shared model-level blind spots are not covered by this design. Do not present its verdict
as independent verification.

## Requirements

- Claude Code with subagent support (the Task/Agent tool and `agents/` definitions) -
  Claude Code 2.x or newer.
- Account access to both Sonnet and Opus. The reviewer agent is pinned to `model: opus`;
  without Opus access the gate cannot run as designed.
- The primary session should be set to Sonnet. A skill cannot change the primary session's
  model - that is your selection.
- POSIX `sh` for the install script.

## Install

### As a plugin (recommended)

Add this repository as a plugin marketplace and install the plugin:

```
/plugin marketplace add rostikcermak-pixel/sonnet-opus-gate
/plugin install sonnet-opus-gate
```

The skill and the `reviewer` agent ship with the plugin; no further setup is needed.

### Agent only, without the plugin

To install just the reviewer subagent into your Claude Code agents directory:

```
plugins/sonnet-opus-gate/scripts/install-agents.sh
```

It targets `$CLAUDE_CONFIG_DIR/agents` when `CLAUDE_CONFIG_DIR` is set, otherwise
`$HOME/.claude/agents`. It never overwrites a destination that differs from the template
unless you pass `--force`. Verify an existing install with:

```
plugins/sonnet-opus-gate/scripts/install-agents.sh --check
```

## Usage

With the plugin installed, invoke the orchestration skill at the start of a task:

```
Use the sonnet-opus-gate orchestration skill, then build and verify this feature.
```

The session then plans, builds, self-verifies, hands off to the Opus reviewer, and reports
the combined result.

## Acceptance criteria

A task delivered under this workflow satisfies all of the following:

1. The builder produced verification evidence: each check run, as command plus output or
   exit code. No unverified "should work" claims.
2. The reviewer was invoked in a fresh context, after completion was declared and evidence
   existed, and reviewed the actual diff rather than a summary of it.
3. The review named specifics. A pass with no specifics is a failed review.
4. Every issue the reviewer found was fixed in the code by the reviewer, not handed back
   as a recommendation - or explicitly reported as unfixable with the reason.
5. The reviewer re-ran the relevant verification after its fixes and reported `pass` with
   evidence.
6. The final report to the user lists every issue found and every fix made.
7. No code changed after the passing review. If it did, the gate ran again.

## Layout

```
.claude-plugin/marketplace.json
plugins/sonnet-opus-gate/
  .claude-plugin/plugin.json
  agents/reviewer.md                       Opus-pinned reviewer subagent
  skills/orchestration/SKILL.md            the two-lane flow, routing, review gate
  skills/orchestration/references/
    role-contracts.md                      duties and prompt/return contracts
    operations.md                          invocation, evidence rules, verdict handling
  scripts/install-agents.sh                agent-only install helper
```

## License

Licensed under GPL-3.0. See [LICENSE](LICENSE) for the full text.
