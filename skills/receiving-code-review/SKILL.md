---
name: receiving-code-review
description: |
  Review reception protocol - requires technical verification before implementing
  suggestions. Prevents performative agreement and blind implementation.

trigger: |
  - Received code review feedback
  - About to implement reviewer suggestions
  - Feedback seems unclear or technically questionable

skip_when: |
  - Feedback is clear and obviously correct → implement directly
  - No feedback received → continue working
---

# Code Review Reception

## Overview

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

## The Response Pattern

**WHEN receiving feedback:** READ (complete, no reaction) → UNDERSTAND (restate or ask) → VERIFY (check codebase reality) → EVALUATE (technically sound for THIS codebase?) → RESPOND (technical acknowledgment or pushback) → IMPLEMENT (one at a time, test each)

## Forbidden Responses

**NEVER:**
- "You're absolutely right!"
- "Great point!" / "Excellent feedback!" (performative)
- "Let me implement that now" (before verification)

**INSTEAD:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if wrong
- Just start working (actions > words)

## Handling Unclear Feedback

**IF any item is unclear:** STOP - do not implement anything yet. ASK for clarification. Items may be related - partial understanding = wrong implementation.

**Example:** "Fix 1-6" - You understand 1,2,3,6, unclear on 4,5. STOP. "Understand 1,2,3,6. Need clarification on 4 and 5 before proceeding."

## Source-Specific Handling

### From your human partner
- **Trusted** - implement after understanding
- **Still ask** if scope unclear
- **No performative agreement**
- **Skip to action** or technical acknowledgment

### From External Reviewers

**BEFORE implementing:** (1) Technically correct for THIS codebase? (2) Breaks existing functionality? (3) Reason for current implementation? (4) Works on all platforms/versions? (5) Does reviewer understand full context?

- **If suggestion seems wrong:** Push back with technical reasoning
- **If can't easily verify:** "I can't verify this without [X]. Should I [investigate/ask/proceed]?"
- **If conflicts with prior decisions:** Stop and discuss first

## YAGNI Check for "Professional" Features

**IF reviewer suggests "implementing properly":** grep codebase for actual usage. Unused? "This endpoint isn't called. Remove it (YAGNI)?" Used? Then implement properly.

## Implementation Order

**FOR multi-item feedback:** (1) Clarify anything unclear FIRST (2) Implement: Blocking issues → Simple fixes → Complex fixes (3) Test each fix individually (4) Verify no regressions

## When To Push Back

Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (unused feature)
- Technically incorrect for this stack
- Legacy/compatibility reasons exist
- Conflicts with architectural decisions

**How to push back:**
- Use technical reasoning, not defensiveness
- Ask specific questions
- Reference working tests/code

## Acknowledging Correct Feedback

"Fixed. [Brief description]" | "Good catch - [issue]. Fixed in [location]." | [Just fix it and show in code]

**Why no thanks:** Actions speak. Just fix it. The code shows you heard the feedback.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Performative agreement | State requirement or just act |
| Blind implementation | Verify against codebase first |
| Batch without testing | One at a time, test each |
| Assuming reviewer is right | Check if breaks things |
| Avoiding pushback | Technical correctness > comfort |
| Partial implementation | Clarify all items first |

## The Bottom Line

**External feedback = suggestions to evaluate, not orders to follow.**

Verify. Question. Then implement.

No performative agreement. Technical rigor always.
