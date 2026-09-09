---
name: ddd-squad-coordination
description: How the ddd-engineer build squad coordinates — the artifact-type-to-writer routing table, using ListAgents/SendMessage to align lanes without collisions, and the rule that coordinating never authorizes doing another writer's work. Reference knowledge preloaded by the collaborative writers, the pattern-evaluator, and the implementer; not a user-facing action.
user-invocable: false
---

# DDD squad coordination

You are on the **collaborative side** of the ddd-engineer pipeline (a writer, the `ddd-pattern-evaluator`, or the `ddd-implementer` coordinator), so you carry `ListAgents` and `SendMessage` and may coordinate directly with the rest of the build squad — not only through the coordinator. This skill is the shared protocol for that. (The five adversaries and the arbiter have none of these tools and stay independent; never expect to reach them.)

## Who owns what — the routing table

Message the writer that owns the artifact type your work touches:

| Artifact type | Owner |
| --- | --- |
| Aggregate roots + entities (the invariant-holding domain core) | `ddd-aggregate-writer` |
| Value objects (immutable, self-validating) | `ddd-value-object-writer` |
| Domain-event classes + their handlers/subscribers/projections | `ddd-event-handler-writer` |
| Factories (complex construction) | `ddd-factory-writer` |
| Repositories (persistence for aggregate roots) | `ddd-repository-writer` |
| Application/domain services (use-case orchestration) | `ddd-service-writer` |
| HTTP/entry-point controllers | `ddd-controller-writer` |
| Glue/wiring (DI, routes, module exports, bindings) | `ddd-wiring-writer` |
| Cross-lane decision, re-planning, or a gap with no clear owner | `ddd-implementer` (the coordinator) |

## How to coordinate

1. **Discover.** `ListAgents` shows which squad agents are currently addressable. A sibling that isn't running yet can't be messaged — fall back to flagging a gap in your returned result and let the coordinator sequence it.
2. **Reach the right one.** `SendMessage` the owner from the table above when your lane meets theirs — a shared type, a detail they need from you (or you from them), or a file you might both edit. Keep messages concrete: name the artifact, the boundary, and what you need agreed.
3. **Escalate cross-lane calls to the coordinator.** When a decision spans lanes or needs the plan changed, message `ddd-implementer` rather than negotiating a large change peer-to-peer.

## Coordination is not authorization

Coordinating aligns boundaries and avoids collisions — it **never** lets you do another writer's work or edit outside your own artifact type. If the right outcome is a change another lane owns, that is a **gap you flag**, not something you take on because you happened to message its owner. Two writers editing the same file is the failure this protocol exists to prevent; when in doubt about ownership, ask via `SendMessage` before writing, or flag it.

## For the pattern-evaluator

You review one artifact and return a verdict. You may `SendMessage` the writer that produced it to clarify intent before you rule, or to point at a fix direction — but your verdict still goes to `ddd-implementer`, which owns the retry decision and records it in the manifest. Messaging a writer is coordination, not a substitute for the verdict and not a way to drive the fix yourself.
