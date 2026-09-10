<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Operations

## Invoking the reviewer

Use the Task/Agent tool with `subagent_type: sonnet-opus-gate:reviewer` and the five-part
prompt from
[role-contracts.md](role-contracts.md). Run it in the foreground: the gate result is what
you need next, so there is nothing useful to do while it runs.

Each invocation starts a fresh context. That is the property the lane depends on, so
never continue an earlier reviewer to save it re-reading the diff - a continued reviewer
carries its previous conclusions, and after a fix those conclusions are stale.

## Confirming the lanes

The reviewer's model is pinned to Opus in `agents/reviewer.md`. If the agent is missing
or its `model:` field is not `opus`, the gate is not in place: say so and stop rather
than reviewing in this session. A skill cannot switch the primary session's model, so
the Sonnet side is the user's selection, not something to assert as verified.

The plugin namespace is required: a plugin's agents are registered as
`<plugin-name>:<agent-name>`, so a bare `reviewer` fails with "Agent type 'reviewer' not
found". The bare name applies only to a copy installed straight into an agents directory
by the install script.

Check the installed agent with:

~~~sh
scripts/install-agents.sh --check
~~~

## Evidence rules

An evidence line is a command and its result. These do not count:

- "tests pass" with no command
- a command with no output and no exit code
- output from before the last code change
- a check you decided to skip, unless the skip and its reason are stated

If verification cannot run at all (no test suite, no build), say that explicitly in the
handoff. The reviewer then knows the diff is unverified rather than assuming otherwise.

## After the reviewer returns

1. Read the reviewer's actual fixes with `git diff`. Its summary is a claim like any
   other.
2. If `RESULT: fail`, the gate is closed. Fix it in this session and invoke a fresh
   reviewer.
3. If anything changes in the code afterwards - your fix, a user request, a rebase - the
   prior pass is void. Re-run the gate.

## Concurrent edits

The reviewer has write access to the same working tree. Do not edit files while a
reviewer invocation is running; wait for it to return, then read the tree fresh before
touching anything.
