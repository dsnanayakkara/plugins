# Refactoring

Use this for a behavior-preserving change to structure, names, or module boundaries. The structure changes. The behavior does not.

If the cleanup reveals a missing feature or a real bug, split it out and ship the structural change first against the pinned contract.

1. Pin the behavior contract before any structure moves. Run the **how** skill to learn the contract, then write a characterization test, snapshot, or equivalence check that captures current behavior. If the area has no coverage, write the pin first. Type check and lint are not a pin.
2. Name the structure the code is missing per `references/principles/model-the-domain.md`. Keep existing structure when it is already clear and local. The reshape must delete branches or invalid states, not add indirection.
3. Name the target shape as if built today (`references/principles/redesign-from-first-principles.md`). If it crosses a function boundary, run the **architect** skill.
4. Subtract before you add (`references/principles/subtract-before-you-add.md`). Remove dead code and redundant layers first. For an API change, migrate every caller and delete the old path in the same change (`references/principles/migrate-callers-then-delete-legacy-apis.md`). No compatibility shims.
5. Move in small steps, each keeping the pin green. Spot-check every rename against the actual files, including strings and docs.
6. Prove behavior is unchanged on the real artifact, not "it compiles". For larger reshapes, diff old and new outputs.
7. Confirm the change reduces reader load (`references/principles/minimize-reader-load.md`). If it doesn't, revert it.
8. Before commit, run the **deslop** skill, then the **no-comments** skill. Apply the usage budget's reviewer rule.

**Reply:** the structure that changed, the pin you held it against, the equivalence proof, and what shipped or got reverted.
