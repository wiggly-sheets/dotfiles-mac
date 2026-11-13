---
description: Run code review on files or recent changes
---

Delegate to the `reviewer` agent to perform a code review.

**Scope:** $ARGUMENTS

If no arguments provided, collect staged changes with `git diff --cached` and pass the diff to the reviewer.
If argument is "recent", collect changes since the last commit with `git diff HEAD~1` and pass the diff to the reviewer.
Otherwise, pass the specified file(s) or directory. The reviewer can read those files directly.

The reviewer agent will:
- Load the code-review skill
- Apply the 4 Review Layers (Correctness, Security, Performance, Style)
- Classify findings by severity (Critical, Major, Minor, Nitpick)
- Only report findings with >=80% confidence
- Include positive observations
- Provide Philosophy Compliance checklist results

Return the complete review findings to the user.
