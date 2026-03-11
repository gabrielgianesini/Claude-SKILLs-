---
name: brainstorming
description: |
  Socratic design refinement - transforms rough ideas into validated designs through
  structured questioning, alternative exploration, and incremental validation.

trigger: |
  - New feature or product idea (requirements unclear)
  - User says "plan", "design", or "architect" something
  - Multiple approaches seem possible
  - Design hasn't been validated by user

skip_when: |
  - Design already complete and validated → proceed to planning
  - Have detailed plan ready to execute → proceed to execution
  - Just need task breakdown from existing design → proceed to task generation
---

# Brainstorming Ideas Into Designs

## Overview

Transform rough ideas into fully-formed designs through structured questioning and alternative exploration.

**Core principle:** Research first, ask targeted questions to fill gaps, explore alternatives, present design incrementally for validation.

## Quick Reference

| Phase | Key Activities | Tool Usage | Output |
|-------|---------------|------------|--------|
| **Prep: Autonomous Recon** | Inspect repo/docs/commits, form initial model | Native tools (ls, cat, git log, etc.) | Draft understanding to confirm |
| **1. Understanding** | Share findings, ask only for missing context | AskUserQuestion for real decisions | Purpose, constraints, criteria (confirmed) |
| **2. Exploration** | Propose 2-3 approaches | AskUserQuestion for approach selection | Architecture options with trade-offs |
| **3. Design Presentation** | Present in 200-300 word sections | Open-ended questions | Complete design with validation |
| **4. Design Documentation** | Write design document | Writing skill | Design doc in docs/plans/ |
| **5. Worktree Setup** | Set up isolated workspace | Worktree setup | Ready development environment |
| **6. Planning Handoff** | Create implementation plan | Planning skill | Detailed task breakdown |

## The Process

Copy this checklist to track progress:

```
Brainstorming Progress:
- [ ] Prep: Autonomous Recon (repo/docs/commits reviewed, initial model shared)
- [ ] Phase 1: Understanding (purpose, constraints, criteria gathered)
- [ ] Phase 2: Exploration (2-3 approaches proposed and evaluated)
- [ ] Phase 3: Design Presentation (design validated in sections)
- [ ] Phase 4: Design Documentation (design written to docs/plans/)
- [ ] Phase 5: Worktree Setup (if implementing)
- [ ] Phase 6: Planning Handoff (if implementing)
```

### Prep: Autonomous Recon

**MANDATORY evidence (paste ALL):** `ls -la`, `git log --oneline -10`, `head -50 README.md`, `find . -name "*test*" | wc -l`, check package.json/requirements.txt/go.mod.

**Only after ALL evidence pasted:** Form your model and share findings. **Skip any = not following skill.**

### Question Budget

**Maximum 3 questions per phase.** More = insufficient research.

Question count:
- Phase 1: ___/3
- Phase 2: ___/3
- Phase 3: ___/3

Hit limit? Do research instead of asking.

### Phase 1: Understanding
- Share your synthesized understanding first, then invite corrections or additions.
- Ask one focused question at a time, only for gaps you cannot close yourself.
- **Use AskUserQuestion tool** only when you need the human to make a decision among real alternatives.
- Gather: Purpose, constraints, success criteria (confirmed or amended by your partner)

### Phase Lock Rules

**CRITICAL:** Once you enter a phase, you CANNOT skip ahead.

- Asked a question? → WAIT for answer before solutions
- Proposed approaches? → WAIT for selection before design
- Started design? → COMPLETE before documentation

**WAIT means WAIT. No assumptions.**

### Phase 2: Exploration
- Propose 2-3 different approaches
- For each: Core architecture, trade-offs, complexity assessment, and your recommendation
- **Use AskUserQuestion tool** to present approaches when you truly need a judgement call
- Lead with the option you prefer and explain why; invite disagreement if your partner sees it differently

### Phase 3: Design Presentation
- Present in coherent sections; use ~200-300 words when introducing new material, shorter summaries once alignment is obvious
- Cover: Architecture, components, data flow, error handling, testing
- Check in at natural breakpoints rather than after every paragraph

**Design Acceptance Gate:**

Design is NOT approved until human EXPLICITLY says one of:
- "Approved" / "Looks good" / "Proceed"
- "Let's implement that" / "Ship it"
- "Yes" (in response to "Shall I proceed?")

**No explicit approval = keep refining**

### Phase 4: Design Documentation
After validating the design, write it to a permanent document:
- **File location:** `docs/plans/YYYY-MM-DD-<topic>-design.md`
- **Content:** Capture the design as discussed and validated in Phase 3
- Commit the design document to git before proceeding

### Phase 5: Worktree Setup (for implementation)
When design is approved and implementation will follow, set up an isolated workspace.

### Phase 6: Planning Handoff
Ask: "Ready to create the implementation plan?"
When confirmed, create detailed plan.

## Key Principles

| Principle | Application |
|-----------|-------------|
| **One question at a time** | Phase 1: Single targeted question only for gaps you can't close yourself |
| **Structured choices** | Use AskUserQuestion tool for 2-4 options with trade-offs |
| **YAGNI ruthlessly** | Remove unnecessary features from all designs |
| **Explore alternatives** | Always propose 2-3 approaches before settling |
| **Incremental validation** | Present design in sections, validate each |
| **Flexible progression** | Go backward when needed - flexibility > rigidity |
| **Own the initiative** | Recommend priorities and next steps |
