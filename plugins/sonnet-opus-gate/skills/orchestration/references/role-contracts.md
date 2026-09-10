<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Role contracts

Two roles. Each has a fixed set of duties and a fixed output shape.

## Planner/Builder (Sonnet, this session)

Owns: requirements gathering, architecture, implementation, self-verification.

Does not own: the final sign-off. It cannot clear its own gate.

### Handoff prompt contract

The reviewer's context is empty. Everything it needs goes in the prompt, in these five
parts:

**1. TASK** - the user's original request, verbatim. Not your restatement of it. If the
requirements were refined in conversation, include the refinements as a short list of
agreed points, marked as such.

**2. DIFF** - how to see the change. A command (`git diff`, `git diff <base>..HEAD`,
`git status` for untracked files) or an explicit list of changed paths. The reviewer
reads the code itself; do not paste a summary of what the diff does.

**3. VERIFICATION** - each check you ran, as command plus result:

~~~text
$ pytest tests/ -q
34 passed in 2.1s          (exit 0)
$ ruff check .
All checks passed!         (exit 0)
~~~

Include failures and skipped checks too, with the reason. An empty or absent
verification section means the gate is not ready to open.

**4. ASSUMPTIONS** - every judgment call you made that the code does not state: an
ambiguity you resolved one way, a default you picked, a case you decided was out of
scope. These are the highest-yield review targets, so understating them defeats the
lane.

**5. SCOPE** - what was explicitly in scope, and what you deliberately left out.

## Reviewer/Fixer (Opus, fresh context, read-write)

Owns: adversarial review of the diff, direct fixes, re-verification, final summary.

Does not own: the architecture, or the decision to widen the task. It fixes defects in
what was built; it does not rebuild it to its own taste.

### Review duties

Read the actual diff and the actual verification output. Hunt for:

- correctness bugs
- missed edge cases (empty, null, boundary, concurrent, error paths)
- security concerns
- silent failures - swallowed errors, ignored return values, bare excepts
- scope creep beyond the stated task
- unverified claims - anything the Planner asserted without a command backing it

No rubber-stamping. "Looks good overall" without named specifics is a failed review, not
a pass. If the diff is genuinely clean, say what you checked and what you found sound.

### Fix duties

For every issue: state what is wrong and why it matters, then fix it in the code
directly. Do not hand the issue back as a report. Keep each fix minimal and inside the
stated task.

### Re-verification duties

After fixing, re-run the relevant checks yourself. Report each as command plus output or
exit code, and state pass or fail plainly. A fix you did not re-verify is an unverified
claim of exactly the kind you are here to catch.

### Return shape

~~~text
ISSUES FOUND
1. <what is wrong, where, why it matters>
...
(or: none, with what was checked)

FIXES MADE
1. <file:line - what changed>
...
(or: none)

RE-VERIFICATION
$ <command>
<output>                   (exit N)
...
RESULT: pass | fail
~~~

RESULT is `fail` if any check fails after your fixes, or if you found an issue you could
not fix. Say which.
