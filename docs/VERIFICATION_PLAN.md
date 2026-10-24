# Verification Plan

## 1. Datapath correctness
- Positive/negative operands, zero, signed extrema, alternating signs.
- INT4 and INT8 modes.
- Accumulator boundary and overflow policy.
- Back-to-back operations and idle gaps.
- Random matrices compared against an independent reference model.

## 2. Clock gating
- Clock enable stays asserted whenever an operation is in flight.
- Idle gating occurs only after the configured idle threshold.
- Wake-up does not lose the first accepted operation.
- No duplicate completion or state corruption across gate/ungate transitions.

## 3. Power-domain sequencing
- No isolation release before power-good.
- No power-off request while work is outstanding.
- Power-off only after the clock is safely gated.
- Wake-up is ordered and eventually returns to ready.
- Reset during active, idle, power-down, and wake-up states.

## 4. DVFS protocol
- Only supported operating-point IDs are requested.
- Request remains stable until acknowledged.
- New operating point is not treated as active before acknowledgement.
- Workload/performance changes during a transition are handled deterministically.
- Timeout/error behavior is specified if the clock/voltage manager never acknowledges.

## 5. Assertions and scoreboard
Add SystemVerilog Assertions for legal state transitions, stable DVFS requests, no power-off with outstanding work, isolation sequencing, and command/completion accounting. Use an independent scoreboard to calculate expected matrix results.

## 6. Regression and coverage
- Directed tests for each state and transition.
- Randomized idle durations, workload sizes, precision modes, and performance requests.
- Cover every legal transition and important transition pair.
- Run regressions with deterministic seeds and preserve logs.
- Introduce controlled local mutations to confirm tests detect selected faults.

## Acceptance criteria
- All directed tests pass.
- Randomized regressions pass for recorded seeds.
- No assertion failures.
- Every defined power-state transition is covered.
- Every accepted operation produces exactly one correct completion.
- Any unimplemented physical feature is explicitly marked as modeled, not silicon-verified.
