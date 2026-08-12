# Public task families

- `functional_timing_understanding`: explain functionality, state, latency, and
  clock/reset semantics from graph evidence.
- `hierarchy_dependency_analysis`: recover modules, instances, and dependencies.
- `hierarchical_rtl_generation`: generate synthesizable RTL while preserving
  project hierarchy, interfaces, and reusable modules.
- `reuse_integration`: reuse the IP through wrappers and adapters.
- `fault_localization_repair`: localize failure and propose a constrained patch.
- `verification_generation`: generate self-checking tests or assertions.
- `tool_result_analysis`: state what tool evidence proves and does not prove.
- `interface_modification`: enumerate cross-module interface changes.
- `hierarchical_integration`: construct a project-level DesignGraph plan.
- `cross_module_repair`: repair a protocol failure with complete regression.

Task candidates contain prompts and oracle contracts but no released gold answer.
They are not training-approved until the recorded quality fields are satisfied.
