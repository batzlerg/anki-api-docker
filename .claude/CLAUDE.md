# COMPLIANCE ENFORCEMENT TRIGGER

**⚠️ STOP: This repo is deferred for compliance enforcement.**

Before taking ANY action in this repository, you MUST:

1. **STOP immediately** - Do not proceed with user's request yet
2. **Execute compliance remediation** for this repo following Phase 5 process
3. **Update the execution log** with your actions
4. **ONLY THEN proceed** with the user's original request

## Required Reading

Read these documents IN ORDER before proceeding:

1. **Workflow Guardrails (conventions):**
   `~/.claude/docs/WorkflowGuardrails.md`

2. **Compliance Audit (execution process):**
   `~/.claude/docs/ComplianceAudit-2026-01-14.md`

3. **Execution Log (track progress):**
   `~/.claude/docs/COMPLIANCE_AUDIT_LOG.md`

## What Compliance Means

This repo must be brought to compliance, which requires:

- [ ] `CLAUDE.md` at root (replace this trigger file with proper instructions)
- [ ] `docs/PRD.md` exists (product requirements document)
- [ ] `docs/ARCHITECTURE.md` exists (technical documentation)
- [ ] `specs/` directory exists (for delta documents)
- [ ] `specs/archive/` subdirectory exists (for completed specs)
- [ ] `tmp/` in `.gitignore` (for ephemeral files)
- [ ] All specs use `NNN-Name.md` format (if any exist)
- [ ] No `knowledge/` directory (migrate to `docs/` if exists)

## Compliance Process (Phase 5)

Follow the process defined in the audit document:

1. Ensure repo has clean git state (commit or stash any changes)
2. Create branch: `refactor/compliance-structure`
3. Migrate `knowledge/` to `docs/` (if exists)
4. Create `docs/PRD.md`, `docs/ARCHITECTURE.md` placeholders
5. Create `specs/` and `specs/archive/` directories
6. Rename existing specs to `NNN-` format (if any)
7. Update `.gitignore` with `tmp/`
8. Replace this CLAUDE.md with proper repo-specific instructions
9. Commit with message: `refactor(compliance): apply workflow guardrails structure`
10. Log the completion in `~/.claude/docs/COMPLIANCE_AUDIT_LOG.md`
11. Merge to main and delete branch

## Commit Message Format

```
refactor(compliance): apply workflow guardrails structure

Part of Phase 5 deferred compliance enforcement.
See ~/.claude/docs/ComplianceAudit-2026-01-14.md

Generated with [Claude Code](https://claude.ai/code)
```

---

**This is a one-time enforcement trigger.** After compliance is complete, this file will be replaced with proper repository-specific AI instructions.
