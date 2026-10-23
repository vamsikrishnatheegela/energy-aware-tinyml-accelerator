# RTL-to-GDSII implementation plan

## Stage gates
1. **RTL lint/elaboration:** no syntax/elaboration errors; hierarchy and parameters checked.
2. **Functional simulation:** self-checking tests pass; add random and corner-case tests.
3. **Synthesis:** inspect inferred hardware and warnings; confirm signed arithmetic and no latches.
4. **Floorplan:** select PDK/platform, die/core area, utilization, pin placement, and power strategy.
5. **Placement and optimization:** inspect congestion and timing.
6. **Clock-tree synthesis:** required once the design has a real clocked implementation and flow setup.
7. **Routing:** global and detailed routing, DRC-aware repair, antenna handling where supported.
8. **Extraction and STA:** use extracted parasitics and appropriate process/voltage/temperature corners.
9. **Physical verification:** DRC and LVS with the appropriate PDK decks; also density, antenna, ERC and other checks as required by the platform.
10. **GDSII export:** inspect the final layout and preserve exact source/configuration/report provenance.

## Open-source tool options
- RTL simulation: Icarus Verilog or Verilator
- Synthesis: Yosys
- Physical design: OpenROAD / OpenROAD-flow-scripts
- Static timing analysis: OpenSTA
- Layout viewing and checks: KLayout, Magic, Netgen (capabilities depend on setup and PDK)

Choose one supported platform and follow its documented configuration exactly. Do not copy a platform name or library path from a different installation. PDK files and rule decks have their own licenses and redistribution conditions.

## Is GDSII signoff-ready?
No—not merely because a GDSII file was generated. Signoff depends on the intended foundry/platform, qualified rule decks, extraction models, timing corners, and all required checks passing. Open-source tools can produce a valuable educational RTL-to-GDSII result, but label it accurately unless the target's actual signoff criteria are met and documented.
