# Bug fix

Use this when the user reports a defect and wants it diagnosed and fixed.

Every shipped line traces to runtime evidence. A change that "might help" is a hypothesis, not a fix, and does not ship. When evidence refutes a hypothesis, revert what it motivated. Read `references/principles/fix-root-causes.md` before starting.

1. Reproduce the defect yourself on the relevant surface. Record the exact steps and result. Ask the user to reproduce only with a specific reason you cannot reach the target. If it won't reproduce directly, synthesize the trigger, tighten conditions, or instrument until it fires.
2. Binary-search the cause. Seed candidate hypotheses with the **how** skill over the affected subsystem, and the **why** skill for regression history. Rule hypotheses out with runtime evidence until one survives. When program state is unclear, add logging and read it as the code runs. Don't guess. If two fixes built on one premise have failed, read `references/principles/attack-the-premise.md`.
3. Plan the smallest change the evidence justifies. If it crosses a function boundary, run the **architect** skill first.
4. Verify the original reproduction now passes on the same surface. "Inconclusive" or wrong-surface is not a pass. Say so.
5. When the bug has a cheap local test path, follow `references/writing/tdd.md` and commit the failing test before the fix. Skip it when the test would be expensive or unclear, and say why.
6. Before commit, run the **deslop** skill, then the **no-comments** skill. Apply the usage budget's reviewer rule.

**Reply:** what was broken, root cause, fix, how you verified. Paste the failing-then-passing repro output verbatim.
