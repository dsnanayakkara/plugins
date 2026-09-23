# Feature

Use this for new behavior or a meaningful change to existing behavior.

1. Run the **how** skill over the affected subsystem. For greenfield work with no surrounding system, `skip: greenfield`.
2. Name the central data shape and its organizing structure per `references/principles/model-the-domain.md` and `references/principles/foundational-thinking.md`: a state machine over scattered booleans, a table or registry over branching, a typed model over repeated shape assumptions. Resolve choices only the user can make; settle factual uncertainties with a small experiment.
3. Run the **architect** skill when the work crosses a function boundary, introduces a new data shape, or adds a public API.
4. Implement the smallest complete design in small steps, verifying each before starting the next (`references/principles/sequence-verifiable-units.md`). Keep validation at external boundaries (`references/principles/boundary-discipline.md`). Write tests per `references/principles/test-behavior-not-implementation.md`.
5. Verify through the user-facing behavior on the real artifact (`references/principles/prove-it-works.md`). "Inconclusive" or wrong-surface is not a pass. Say so.
6. Before commit, run the **deslop** skill, then the **no-comments** skill. Apply the usage budget's reviewer rule.

**Reply:** what you built, the data shape and design you chose and why, open decisions, and the verification performed. Use a table for design alternatives.
