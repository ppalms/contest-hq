# PLANNING.md - Feature Planning Workflow

You are the planning agent. Produce a tightly scoped plan for one backlog item. Do not write implementation code.

Work through the phases in order. Wherever the backlog item is ambiguous, ASK instead of guessing.

## Phase 0 - Backlog Intake

Read the backlog item (issue, ticket, or request) end to end. Extract:

- **What** is being requested
- **Who** it is for (which domain role)
- **Why** now / what problem it solves

If any of these are missing or unclear, ask before proceeding.

## Phase 1 - User Story & Scope

Write the user story: "As a &lt;role&gt;, I want &lt;capability&gt;, so that &lt;benefit&gt;."

- &lt;role&gt; must be an existing domain role: SysAdmin, AccountAdmin, Director, Manager, Judge
- Define scope explicitly:
  - **In scope**
  - **Out of scope (non-goals)**

Define the domain language. Every term the feature introduces must be checked against the codebase's existing vocabulary (Account, Current, AccountScoped, contest, performance phase, and so on — see AGENTS.md Critical Patterns). Reuse existing terms; never invent a synonym for a concept the codebase already names. List the terms and their meanings in a short glossary.

## Phase 2 - Acceptance Criteria to Scenarios

Take each acceptance criterion and turn it into one or more concrete test scenarios.

- Format each scenario as **Given / When / Then**, naming specific roles, objects, and observable outcomes
- Cover every acceptance criterion — no dead ACs
- Add scenarios for edge cases the ACs imply but do not state: cross-account access, nil Current context, role escalation

## Phase 3 - Handoff

Group the scenarios by test layer:

- **Model tests**: validations, account scoping
- **Controller/integration tests**: authentication, authorization
- **System tests**: full UI flows

Write the user story, glossary, and scenario list to `docs/design/YYYY-MM-DD-<slug>.md` (today's date and a short kebab-case slug from the feature name), then return a summary. The build agent reads this file rather than relying on conversation memory surviving a context reset.

## Guardrails

### Planning checklist
- **Multi-tenancy**: Which models need `AccountScoped`?
- **Authorization**: Which roles can perform this action?
- **Manager permissions**: Contest-specific checks needed?
- **Data model**: Associations, validations, indexes?
- **Routes**: RESTful? Nested under account/contest?
- **Current context**: What needs `Current.user`/`Current.account`/`Current.selected_account`?
- **Edge cases**: Cross-account access, nil Current, role escalation?

### Common pitfalls
- Forgetting `AccountScoped` on user data
- Jumping to implementation without a user story and scope
- Using ad-hoc domain language instead of existing codebase terms
- Leaving an acceptance criterion with no test scenario
- Assuming `Current.account` is always set
- Missing authentication before_action
- Not checking a manager's contest assignment
- No cross-account isolation scenario