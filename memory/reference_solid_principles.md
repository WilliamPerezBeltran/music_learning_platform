---
name: reference-solid-principles
description: SOLID principles guide for Phoenix/Elixir — where to apply them, correct/incorrect examples, recommended structure
metadata:
  type: reference
---

SOLID principles documentation lives at `docs/software_good_practice/solid_principles/solid_principles.md`.

Apply to: Contexts, Domain Services, Policies, Queries, Commands, Workers, external integrations, LiveViews, Controllers.
Do NOT apply blindly to Schemas or simple data structures.

**S — SRP**: one module, one reason to change. Don't mix create/notify/audit/index in the same Context.

**O — OCP**: open for extension, closed for modification. Use Protocols/Behaviours instead of growing `case` blocks.

**L — LSP**: all Behaviour implementations must honour the same contract — fully substitutable.

**I — ISP**: small, specific Behaviours (`StorageBehaviour`, `NotificationBehaviour`) rather than one fat interface.

**D — DIP**: high-level modules depend on abstractions (`EmailProvider`), not concrete adapters (`Mailgun`). Wire via `config`.

**Checklist before writing a module:**
1. Single responsibility? → SRP
2. Extendable without modification? → OCP
3. Implementations substitutable? → LSP
4. Interface small and specific? → ISP
5. Depends on abstraction, not implementation? → DIP
