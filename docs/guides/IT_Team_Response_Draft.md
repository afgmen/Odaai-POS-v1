# Response to IT Team Questions - Odaai Multi-Layer Approval System

**From:** Jin (Product Team)  
**To:** IT Implementation Team  
**Date:** February 27, 2026  
**Re:** Implementation Questions - Multi-Layer Approval System

---

Hi team,

Thanks for your questions! We have clear answers for all of them. Here's what you need to know to get started:

## 1. Requirements & Priority

**Q: What are the specific functional requirements and the priority order?**

We have complete documentation ready for you:

- **PRD (English):** `multi-layer-approval-web-prd-EN.md`
- **QC Report (English):** `QC_Report_Consolidated_EN.md`

**Quality Status:**
- ✅ 62 code review items: PASS
- ✅ 31 runtime tests: PASS
- ✅ Design UAT: PASS
- **Total: 93/93 items verified**

**Priority:** All P0 (critical) items have already been fixed and verified. The system is production-ready from a quality perspective.

---

## 2. Workflow & User Experience

**Q: Where will users configure settings and where will approvers act?**

**Everything happens inside the Oda app** — no more email-based workflow.

**Settings Configuration:**
- Integrated into Oda Admin Settings menu
- Admins configure approval rules, thresholds, and approver lists directly in the app

**Approver Notifications:**
- Oda push notifications (primary)
- In-app notification center (secondary)
- Email is either optional reminders only or completely removed

**Approver Actions:**
- Done entirely inside the Oda app
- Implementation options:
  - WebView embedding of the current web app, OR
  - Native rebuild (your choice based on technical preference)

**Key takeaway:** Users never need to leave the Oda app ecosystem.

---

## 3. Handoff Process

**Q: Can we establish a standardized workflow instead of manual exports/imports?**

**Yes — we recommend a GitHub-based workflow:**

**Repository Setup:**
- Create a shared GitHub repository
- IT team gets full repository access with latest code always available

**Branch Strategy:**
- `main` → production-ready code
- `develop` → integration branch
- `feature/*` → individual features

**Code Review:**
- PR-based review process
- Automated CI/CD integration (optional but recommended)

**Design Handoff:**
- Figma link sharing
- Change notifications via Figma comments/version history
- No more manual exports

**Benefits:** Real-time access, version control, no manual file transfers, clear audit trail.

---

## 4. Hard-coded Data Management

**Q: How do we handle hard-coded values like emails?**

**This is already being addressed:**

**Current Status:**
- Mock data (emails, branches, approvers) is being migrated to `.env` / database configuration
- A developer task is in progress to remove all hard-coded values

**Solution:**
- Environment variables for deployment-specific config
- Admin Settings UI already exists for managing approvers, branches, and thresholds
- `.env.example` will be provided documenting all required configuration fields

**What you'll get:**
- Clean separation of code and configuration
- Easy deployment to multiple environments (dev/staging/production)
- No code changes needed for configuration updates

---

## Next Steps

1. Review the PRD and QC Report
2. Let us know your preference: WebView embedding or native rebuild
3. Confirm GitHub repository setup details (org, naming conventions)
4. Schedule a technical handoff session if needed

Feel free to reach out if you have any follow-up questions. We're ready to support the implementation.

Best,  
Jin  
Product Team
