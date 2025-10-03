# Project Plan: Cognigy Backup System

## Overview
Build a GitHub Actions-based backup system for Cognigy projects using 1:1 repo mapping and orphan branch snapshots for storage efficiency. This repository serves as a **template** that can be used to create individual backup repositories for each Cognigy project.

---

## Architecture Decisions

### Repository Structure
- **This repo (cognigy-backup)**: GitHub template repository containing workflows, documentation, and setup automation
- **Per-project repos**: `cognigy-backup-{project-name}` (created from this template, one per Cognigy project)
- **No orchestrator**: Each project repo is self-contained and operates independently with its own schedule

### Template-Based Approach
- Users create new backup repos using GitHub's "Use this template" feature
- Initial setup is semi-automated via:
  - Setup workflow that creates a GitHub issue with instructions
  - Interactive setup script (run locally) to configure project details
  - Workflows start disabled and activate after configuration
- Documentation travels with each project repo for easy reference

### Storage Strategy
- **Orphan branches** for time-based snapshots (force-pushed, fixed history)
- **GitHub Releases** for monthly archives
- **No data in `main`** - only workflows/config

### Branch Tiers
```
main                    # Workflows + config only (no Cognigy data)
snapshot/hourly         # Last 6 half-hour snapshots (3 hours)
snapshot/daily          # Last 7 daily snapshots (1 week)
snapshot/weekly         # Last 4 weekly snapshots (1 month)
releases/               # 12 monthly GitHub Releases (1 year)
```

### Expected Storage per Project
- Hourly snapshots (6): ~30 MB
- Daily snapshots (7): ~35 MB
- Weekly snapshots (4): ~20 MB
- Monthly releases (12): ~60 MB
- **Total: ~145 MB per project (fixed, doesn't grow)**

---

## Phase 0: Template Repository Setup

### Goals
- Build the template infrastructure in THIS repository
- Create setup automation for easy project onboarding
- Test template creation and setup flow

### Tasks

#### 0.1: Template Structure Setup
- [ ] Create directory structure:
  ```
  /
  ├── .github/
  │   ├── workflows/
  │   │   ├── setup.yml              # Auto-runs on first push
  │   │   ├── backup.yml.disabled    # Activated after setup
  │   │   ├── promote.yml.disabled
  │   │   ├── cleanup.yml.disabled
  │   │   └── restore.yml.disabled
  │   └── ISSUE_TEMPLATE/
  │       └── setup-checklist.md     # Manual setup guide
  ├── docs/
  │   ├── PROJECT.md                 # This file
  │   ├── SETUP-GUIDE.md            # Step-by-step setup
  │   ├── RESTORE-GUIDE.md          # How to restore backups
  │   └── ARCHITECTURE.md           # Technical deep-dive
  ├── scripts/
  │   ├── setup-interactive.sh      # Local setup wizard
  │   └── validate-config.sh        # Test configuration
  ├── .gitignore
  ├── .template-config.yml          # Template metadata
  ├── config.json.example
  └── README.md                     # Template README
  ```

#### 0.2: Setup Workflow (`setup.yml`)
- [ ] Detect first-time setup (check if config.json exists)
- [ ] Create GitHub issue with setup instructions
- [ ] Issue includes:
  - Link to setup guide
  - GitHub secrets needed
  - Commands to run setup script
  - Checklist of steps
- [ ] Only runs once (detects `[skip-setup]` in commit message)

#### 0.3: Interactive Setup Script
- [ ] Prompt for project configuration:
  - Cognigy project name
  - Agent ID
  - Backup directory name
  - Any custom settings
- [ ] Generate `config.json` from inputs
- [ ] Rename `.disabled` workflows to `.yml` (activate them)
- [ ] Update project README with project-specific details
- [ ] Provide next steps (commit, push, add secrets)

#### 0.4: Documentation
- [ ] Write SETUP-GUIDE.md (step-by-step for new projects)
- [ ] Write RESTORE-GUIDE.md (how to use restore workflow)
- [ ] Write ARCHITECTURE.md (technical implementation details)
- [ ] Update main README.md (template usage instructions)

#### 0.5: Template Testing
- [ ] Mark this repo as GitHub template (Settings → Template repository)
- [ ] Create test repo from template
- [ ] Run through setup process end-to-end
- [ ] Verify workflows activate correctly
- [ ] Delete test repo after validation

---

## Phase 1: First Real Project Backup

### Goals
- Validate template works with a real Cognigy project
- Test backup workflow with actual data
- Verify storage efficiency and snapshot retention

### Tasks

#### 1.1: Project Repository Creation
- [ ] Use template to create first project repo: `cognigy-backup-{project-name}`
- [ ] Run setup workflow (auto-triggers on first push)
- [ ] Clone repo locally and run `./scripts/setup-interactive.sh`
- [ ] Commit configuration changes and push

#### 1.2: Secrets Configuration
- [ ] Add GitHub secrets via UI or CLI:
  ```bash
  gh secret set COGNIGY_BASE_URL -b "https://api.cognigy.ai"
  gh secret set COGNIGY_API_KEY -b "your-key"
  gh secret set COGNIGY_AGENT_ID -b "agent-id"
  ```
- [ ] Optional: Set repository variables for non-sensitive config
- [ ] Verify secrets are accessible in workflow runs

#### 1.3: Initial Backup Test
- [ ] Manually trigger backup workflow
- [ ] Verify Cognigy CLI authenticates successfully
- [ ] Confirm project data is cloned
- [ ] Check that orphan branch `snapshot/hourly` is created
- [ ] Review backup data structure

#### 1.4: Automated Schedule Testing
- [ ] Enable scheduled workflows (every 30 minutes)
- [ ] Monitor first 24 hours of automated backups
- [ ] Verify change detection works (only commits when changed)
- [ ] Check workflow logs for any errors

#### 1.5: Retention & Cleanup Testing
- [ ] Manually trigger promotion workflow (hourly → daily)
- [ ] Manually trigger cleanup workflow
- [ ] Verify old snapshots are pruned correctly
- [ ] Check GitHub storage usage
- [ ] Run for 1 week, validate full retention cycle

#### 1.6: Manual Snapshot Checkout
- [ ] Checkout `snapshot/hourly` branch
- [ ] Verify all project files are present
- [ ] Checkout older snapshots from daily/weekly tiers
- [ ] Confirm data integrity

---

## Phase 2: Restore Capability

### Goals
- Enable recovery from any snapshot tier
- Add safety checks to prevent accidental overwrites

### Tasks

#### 2.1: Restore Workflow (`restore.yml.disabled`)
- [ ] Manual trigger with inputs:
  - Snapshot tier (hourly/daily/weekly/monthly)
  - Specific commit SHA or "latest"
  - Dry-run mode (boolean)
  - Confirmation flag
- [ ] Checkout specified snapshot
- [ ] If dry-run: show what would be restored (use `cognigy diff`)
- [ ] If confirmed: run `cognigy restore` to push back to Cognigy
- [ ] Log restore operation with timestamp and user
- [ ] Send notification on completion

#### 2.2: GitHub Environment Protection
- [ ] Create GitHub Environment: "production-restore"
- [ ] Add required reviewers (manual approval needed)
- [ ] Update restore workflow to use environment
- [ ] Test approval flow

#### 2.3: Restore Testing
- [ ] Create test Cognigy project for restore testing
- [ ] Restore from 1-hour-old snapshot
- [ ] Restore from 1-day-old snapshot
- [ ] Restore from 1-week-old snapshot
- [ ] Verify data matches snapshot exactly

---

## Phase 3: Multi-Project Scaling

### Goals
- Use template to backup multiple Cognigy projects
- Document best practices for managing many backup repos

### Tasks

#### 3.1: Template Refinement
- [ ] Based on Phase 1 learnings, improve template
- [ ] Add common troubleshooting to docs
- [ ] Optimize workflow performance
- [ ] Add more validation/error handling

#### 3.2: Second Project Setup
- [ ] Create second backup repo from template
- [ ] Time the setup process (goal: < 5 minutes)
- [ ] Document any pain points
- [ ] Refine setup script based on feedback

#### 3.3: Third Project Setup
- [ ] Create third backup repo
- [ ] Validate consistency across all project repos
- [ ] Ensure template updates can be applied retroactively

#### 3.4: Management Utilities
- [ ] Create helper scripts in template:
  - `list-all-backups.sh` - Query GitHub API for all `cognigy-backup-*` repos
  - `backup-status.sh` - Show last backup time for all projects
  - `storage-report.sh` - Total storage usage across all projects
- [ ] Optional: Create simple web dashboard (GitHub Pages)

#### 3.5: Template Update Strategy
- [ ] Document how to update existing project repos when template changes
- [ ] Consider: GitHub Actions workflow to detect template updates
- [ ] Test applying template updates to existing repos

---

## Phase 4: Monitoring & Notifications

### Goals
- Visibility into backup health across all projects
- Automated alerts for failures

### Tasks

#### 4.1: Per-Project Logging
- [ ] Add structured logging to workflows (JSON format)
- [ ] Track metrics:
  - Last successful backup timestamp
  - Number of changes detected
  - Snapshot size
  - Workflow execution time
  - Error count
- [ ] Store logs as workflow artifacts

#### 4.2: Notification Integration (Optional)
- [ ] Add optional Slack/Discord webhook secret
- [ ] Notify on backup failure
- [ ] Optional: Daily summary of backup status
- [ ] Alert if no changes detected for >7 days (may indicate issue)

#### 4.3: Cross-Project Dashboard
- [ ] Create GitHub Pages site in template repo
- [ ] Use GitHub API to query all `cognigy-backup-*` repos
- [ ] Display dashboard showing:
  - All projects with last backup time
  - Health status (green/yellow/red)
  - Total storage usage
  - Recent failures
- [ ] Auto-update via GitHub Action

#### 4.4: Monitoring Best Practices
- [ ] Document how to set up GitHub storage alerts
- [ ] Create runbook for common failure scenarios
- [ ] Set up weekly review process

---

## Phase 5: Enhancements (Future)

### Nice-to-Haves
- [ ] Selective resource backup (flows only, skip endpoints, etc.)
- [ ] Compression for large projects (gzip JSON files before commit)
- [ ] Backup metadata tracking (who changed what, change summaries)
- [ ] Integration with Cognigy webhooks (backup on publish event)
- [ ] Cross-environment sync (copy prod backup to staging)
- [ ] Audit log of all restore operations
- [ ] Automated restore testing (periodically test restores in isolated environment)
- [ ] Backup comparison tool (web UI to diff any two snapshots)
- [ ] Custom retention policies per project (configurable tiers)

---

## Risk Mitigation

### Storage Overruns
- **Monitor**: Set up GitHub storage usage alerts
- **Fallback**: If approaching limit, reduce hourly snapshots from 6 to 3, daily from 7 to 4
- **Compression**: Enable gzip for JSON files if needed

### API Rate Limits
- **Throttle**: Add delays between API calls if needed
- **Retry logic**: Exponential backoff on 429 errors
- **Coordinate**: Stagger backup schedules if many projects hit same Cognigy instance

### Credential Exposure
- **Never commit**: Add `config.json` with real creds to `.gitignore`
- **Template safety**: Example files use placeholder values
- **Secrets rotation**: Document how to rotate API keys
- **Audit**: Regularly review who has access to secrets

### Accidental Restore
- **Require approval**: Use GitHub Environments with required reviewers
- **Dry-run first**: Always show diff before actual restore
- **Logging**: Track all restore operations with user attribution
- **Confirmation**: Multi-step confirmation in workflow

### Template Drift
- **Version control**: Tag template releases (v1.0, v1.1, etc.)
- **Update strategy**: Document how to pull template updates into existing repos
- **Breaking changes**: Clearly document in CHANGELOG.md

---

## Success Criteria

### Phase 0 (Template)
- ✅ Template repo structure complete
- ✅ Setup workflow creates helpful issue
- ✅ Interactive script configures project in < 2 minutes
- ✅ Test repo created successfully from template

### Phase 1 (First Project)
- ✅ One project backing up every 30 minutes for 1 week
- ✅ Storage usage < 200 MB
- ✅ All snapshot tiers functioning (hourly/daily/weekly)
- ✅ Successful manual snapshot checkout
- ✅ Change detection works (no redundant commits)

### Phase 2 (Restore)
- ✅ Successfully restore from 1-day-old snapshot
- ✅ Successfully restore from 1-week-old snapshot
- ✅ Successfully restore from 1-month-old release
- ✅ Approval workflow prevents unauthorized restores

### Phase 3 (Multi-Project)
- ✅ 3+ projects backing up independently
- ✅ New project onboarding < 5 minutes
- ✅ Template updates can be applied to existing repos
- ✅ Management utilities work across all repos

### Phase 4 (Production-Ready)
- ✅ Zero missed backups over 1 month across all projects
- ✅ Notifications working for failures (if enabled)
- ✅ Documentation complete and accurate
- ✅ Dashboard shows health of all projects

---

## Open Questions to Resolve Before Starting

### Phase 0 Questions (Template Setup)

1. **Repository settings:**
   - Keep this repo as `cognigy-backup`?
   - Private or public? (Recommend private)
   - Should we use `ben-elliot-nice` account or create an org?

2. **Setup workflow:**
   - Should workflows be `.disabled` or just have a manual approval step?
   - Should setup script support non-interactive mode (config file input)?
   - Do we need a "cleanup template files" step after setup?

3. **Documentation scope:**
   - How detailed should SETUP-GUIDE.md be? (screenshots, step-by-step, etc.)
   - Should we include video walkthrough?
   - Target audience: technical users or anyone?

### Phase 1 Questions (First Real Project)

4. **First project details:**
   - What Cognigy project name/ID to use for prototype?
   - What's the base URL? (e.g., `https://api-trial.cognigy.ai`, `https://api-app.cognigy.ai`)
   - Do you have an API key ready with appropriate permissions?

5. **Scope of first backup:**
   - Clone entire agent or just specific resources (flows only)?
   - Any resources to explicitly exclude?
   - Should we test with a small project first or go for full-size?

6. **Backup frequency:**
   - Start with every 30 minutes or hourly for testing?
   - When should we enable automated scheduling (immediately or after manual tests)?

### Phase 2+ Questions

7. **Restore philosophy:**
   - Should restore ALWAYS require manual approval?
   - Or allow automated restore for specific scenarios (e.g., staging environment)?
   - Should we create a separate "restore staging" Cognigy project for testing?

8. **Notifications:**
   - Should we implement Slack/Discord notifications in Phase 1 or wait until Phase 4?
   - What events should trigger notifications (failures only, or daily summaries too)?

9. **Multi-project strategy:**
   - How many Cognigy projects do you ultimately need to backup?
   - Should all projects use the same retention policy or allow customization?

---

## Timeline Estimate

- **Phase 0**: 3-4 hours (template structure, setup automation, docs, testing)
- **Phase 1**: 2-3 hours (create first project, test workflows, 1-week validation period)
- **Phase 2**: 1-2 hours (restore workflow, approval setup, testing)
- **Phase 3**: 2-3 hours (additional projects, management utilities)
- **Phase 4**: 2-3 hours (monitoring, notifications, dashboard)

**Total: ~10-15 hours of active work** (excluding multi-day validation periods)

---

## Next Steps

1. **Answer open questions above**
2. **Initialize repo**: Run `git init`, add remote, initial commit
3. **Start Phase 0.1**: Create template directory structure
4. **Build iteratively**: Complete Phase 0 fully before moving to Phase 1

---

## Template Repository Structure

### Final Structure (This Repo)
```
cognigy-backup/                        # Template repo
├── .github/
│   ├── workflows/
│   │   ├── setup.yml                  # Auto-creates setup issue (always active)
│   │   ├── backup.yml.disabled        # Renamed to .yml after setup
│   │   ├── promote.yml.disabled       # Tier promotion logic
│   │   ├── cleanup.yml.disabled       # Retention enforcement
│   │   └── restore.yml.disabled       # Manual restore workflow
│   └── ISSUE_TEMPLATE/
│       └── setup-checklist.md         # Manual setup guide template
├── docs/
│   ├── PROJECT.md                     # This file - overall plan
│   ├── SETUP-GUIDE.md                 # How to set up a new project repo
│   ├── RESTORE-GUIDE.md               # How to restore from backups
│   └── ARCHITECTURE.md                # Technical deep-dive
├── scripts/
│   ├── setup-interactive.sh           # Interactive project configuration
│   ├── validate-config.sh             # Test if configuration is valid
│   ├── list-all-backups.sh            # Find all backup repos (optional)
│   └── backup-status.sh               # Check status across projects (optional)
├── .gitignore                         # Ignore config.json, etc.
├── .template-config.yml               # Template metadata
├── config.json.example                # Example configuration
└── README.md                          # Template usage instructions
```

### Project Repo Structure (After Template Use)
```
cognigy-backup-{project-name}/         # Created from template
├── .github/
│   └── workflows/
│       ├── setup.yml                  # Ran once, can be deleted
│       ├── backup.yml                 # Active (renamed from .disabled)
│       ├── promote.yml                # Active
│       ├── cleanup.yml                # Active
│       └── restore.yml                # Active
├── docs/                              # Copied from template
│   ├── PROJECT.md
│   ├── SETUP-GUIDE.md
│   ├── RESTORE-GUIDE.md
│   └── ARCHITECTURE.md
├── scripts/                           # Copied from template
│   ├── setup-interactive.sh
│   └── validate-config.sh
├── config.json                        # Generated by setup script
├── .gitignore
└── README.md                          # Generated by setup script (project-specific)
```

### Snapshot Branch Structure
```
snapshot/hourly                        # Orphan branch with backup data
├── agent/                             # From cognigy clone
│   ├── flows/
│   │   ├── main-flow.json
│   │   └── fallback-flow.json
│   ├── endpoints/
│   │   ├── webchat.json
│   │   └── voice.json
│   ├── lexicons/
│   │   └── custom-terms.json
│   └── config.json                    # Cognigy CLI config
└── .backup-metadata.json              # Timestamp, commit SHA, etc.
```

---

## Technical Reference

### Cognigy CLI Commands Used

```bash
# Initialize CLI configuration
cognigy init

# Clone entire agent
cognigy clone -y

# Clone specific resource types
cognigy clone --type flows
cognigy clone --type endpoints
cognigy clone --type lexicons

# Restore (push) back to Cognigy
cognigy restore -y

# Diff local vs remote
cognigy diff flow <flowName>

# Execute API commands
cognigy execute <command> -d '<json_payload>'
```

### Environment Variables (for CLI)
```bash
CAI_BASEURL         # Cognigy API base URL
CAI_APIKEY          # Cognigy API key
CAI_AGENT           # Agent/project ID
CAI_AGENTDIR        # Local directory for backups (e.g., "agent")
```

### Storage Optimization Strategy

#### Orphan Branch Creation
```bash
# Create new orphan commit (no parent history)
git checkout --orphan temp-snapshot
git add -A
git commit -m "Snapshot: $(date -Iseconds)"

# Force-push to snapshot branch (creates or overwrites)
git push -f origin temp-snapshot:snapshot/hourly

# Clean up temp branch
git checkout main
git branch -D temp-snapshot
```

#### Branch Pruning (Keep Last N Commits)
```bash
# Example: Keep only last 6 commits on snapshot/hourly
git checkout snapshot/hourly

# Count commits
COMMIT_COUNT=$(git rev-list --count HEAD)

if [[ $COMMIT_COUNT -gt 6 ]]; then
  # Get the 6th commit hash from HEAD
  CUTOFF_COMMIT=$(git rev-parse HEAD~6)

  # Create new branch from cutoff point
  git checkout -b temp-pruned $CUTOFF_COMMIT

  # Cherry-pick recent commits
  for commit in $(git rev-list --reverse HEAD~6..HEAD); do
    git cherry-pick $commit
  done

  # Replace old branch
  git branch -f snapshot/hourly temp-pruned
  git checkout snapshot/hourly
  git branch -D temp-pruned

  # Force push
  git push -f origin snapshot/hourly
fi
```

**Simpler approach** (recommended):
```bash
# Just keep the last N commits by recreating branch
git checkout snapshot/hourly

# Get list of last 6 commit messages and contents
COMMITS=$(git rev-list HEAD | head -n 6)

# Create new orphan branch
git checkout --orphan temp-new-hourly

# For each commit, apply changes (simplified: just keep latest state)
# In practice, we force-push new snapshot each time, maintaining natural limit
```

**Actual implementation** (simplest):
Each backup creates a NEW orphan commit and force-pushes to the branch. Over time, only the pushed commits remain accessible. Cleanup workflow periodically removes unreachable commits using:

```bash
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

#### GitHub Release Management
```bash
# Create monthly release from weekly snapshot
gh release create "monthly-$(date +%Y-%m)" \
  --title "Monthly Backup - $(date +%Y-%m)" \
  --notes "Automated monthly snapshot created from weekly backup" \
  --target snapshot/weekly

# List all releases
gh release list --limit 100

# Delete releases older than 12 months
CUTOFF_DATE=$(date -d "12 months ago" +%Y-%m)
gh release list --limit 100 | \
  awk '{print $1}' | \
  while read tag; do
    if [[ "$tag" < "monthly-$CUTOFF_DATE" ]]; then
      gh release delete "$tag" -y
    fi
  done
```

### Workflow Scheduling (Cron Syntax)

```yaml
on:
  schedule:
    # Every 30 minutes
    - cron: '*/30 * * * *'

    # Every 6 hours (0:00, 6:00, 12:00, 18:00)
    - cron: '0 */6 * * *'

    # Every Sunday at midnight
    - cron: '0 0 * * 0'

    # First day of every month at midnight
    - cron: '0 0 1 * *'

    # Daily at 2 AM
    - cron: '0 2 * * *'
```

---

## Cognigy API Reference

### Authentication
- Uses API Key in header: `X-API-Key: <your-api-key>`
- Base URLs vary by environment:
  - Trial: `https://api-trial.cognigy.ai`
  - Production: `https://api-app.cognigy.ai` (or custom domain)

### Key Endpoints (via `cognigy execute`)
```bash
# List all agents (if available)
cognigy execute listAgents

# Get agent details
cognigy execute readAgent -d '{"agentId": "xxx"}'

# List flows in agent
cognigy execute listFlows -d '{"agentId": "xxx"}'

# Get flow details
cognigy execute readFlow -d '{"flowId": "xxx"}'
```

### Rate Limits
- Varies by Cognigy environment/plan
- Typical: 100-1000 requests per minute
- CLI handles throttling internally (verify in testing)
- Monitor for 429 errors and implement backoff if needed

---

## Security Considerations

### Secrets Management
- **Never commit** real API keys or credentials
- Use GitHub Secrets for all sensitive data:
  - `COGNIGY_BASE_URL`
  - `COGNIGY_API_KEY`
  - `COGNIGY_AGENT_ID`
  - Optional: `SLACK_WEBHOOK_URL`
- Template includes only example/placeholder values
- `.gitignore` prevents accidental commit of `config.json`

### Branch Protection Rules
- Protect `main` branch:
  - Require PR reviews for changes to workflows
  - Prevent force push to `main`
  - Prevent deletion
- Allow force push to `snapshot/*` branches (required for cleanup)
- Consider: Restrict who can trigger restore workflow

### Access Control
- Keep backup repos private (contains business logic)
- Limit who can:
  - Trigger restore workflows (use GitHub Environments)
  - Modify GitHub Actions workflows
  - Access GitHub Secrets
  - Create repos from template

### Audit Trail
- GitHub Actions logs all workflow runs (retention: 90 days default)
- Consider archiving logs for compliance:
  - Export workflow run logs to external storage
  - Track all restore operations separately
- Restore workflow logs include user attribution

---

## Troubleshooting Guide

### Common Issues

**1. Cognigy CLI Authentication Fails**
```
Error: Unauthorized (401)
```
**Solutions:**
- Verify `COGNIGY_API_KEY` is correct and not expired
- Check `COGNIGY_BASE_URL` matches your environment
- Ensure API key has necessary permissions
- Test manually: `curl -H "X-API-Key: $KEY" $BASE_URL/agents`

**2. Git Push Fails (Protected Branch)**
```
Error: refusing to update checked out branch: refs/heads/main
```
**Solutions:**
- Verify branch protection settings allow force-push for `snapshot/*`
- Check GitHub Actions has `contents: write` permission
- Ensure workflow uses correct authentication (GITHUB_TOKEN)

**3. Snapshot Branch Has No History**
```
Error: couldn't find remote ref snapshot/hourly
```
**Solutions:**
- Normal on first run - branch doesn't exist yet
- Subsequent runs will create/update it
- Check workflow logs for actual errors
- Verify backup workflow completed successfully

**4. Storage Usage Growing Unexpectedly**
```
Repository size: 2 GB (expected: 150 MB)
```
**Solutions:**
- Run `git gc --prune=now --aggressive` locally and push
- Verify cleanup workflow is running on schedule
- Check if old commits are being orphaned properly
- Look for large binary files that shouldn't be committed
- Consider enabling git LFS for large assets

**5. Rate Limit Errors from Cognigy API**
```
Error: Too Many Requests (429)
```
**Solutions:**
- Reduce backup frequency (hourly instead of 30 min)
- Add delays between API calls in workflow
- Contact Cognigy support for rate limit increase
- Stagger backup schedules if multiple projects

**6. Workflow Permissions Error**
```
Error: Resource not accessible by integration
```
**Solutions:**
- Check workflow has required permissions:
  ```yaml
  permissions:
    contents: write
    issues: write
  ```
- Verify repository settings allow GitHub Actions to create PRs/issues

**7. Setup Script Fails**
```
Error: config.json already exists
```
**Solutions:**
- Backup existing config if needed
- Delete config.json and re-run setup
- Or manually edit config.json

### Debug Commands

```bash
# Check branch history and structure
git log --oneline --graph --all

# See all branches including remote
git branch -a

# Check repo size and object count
git count-objects -vH

# List all GitHub releases
gh release list --limit 100

# Verify orphan branch has no parents
git log --oneline snapshot/hourly --max-count=10

# Check storage usage via API
gh api repos/{owner}/{repo} | jq '.size'

# List workflow runs
gh run list --limit 20

# View specific workflow run logs
gh run view <run-id> --log

# Validate GitHub secrets are set
gh secret list

# Test Cognigy CLI authentication
cognigy execute listAgents
```

---

## Future Enhancements Ideas

### Advanced Features
- **Incremental backups**: Only export resources that changed (requires custom logic)
- **Parallel backups**: Backup multiple resources simultaneously
- **Backup verification**: Automatically test restore in isolated environment
- **Change detection webhooks**: Trigger backup when Cognigy publishes changes
- **Multi-region redundancy**: Mirror backups to secondary GitHub org/account
- **Smart scheduling**: Adjust backup frequency based on change rate

### Integration Opportunities
- **Cognigy Snapshots**: Use native Cognigy snapshots as backup source
- **CI/CD integration**: Deploy from specific backup version
- **Backup comparison tool**: Web UI to diff any two snapshots
- **Automated rollback**: On detection of issue, auto-restore last good backup
- **Backup catalog**: Searchable index of all backups with metadata
- **Slack bot**: Query backup status, trigger restores via Slack

### Reporting & Analytics
- **Backup health dashboard**: Real-time status of all projects
- **Storage trend analysis**: Predict when storage limits will be reached
- **Change frequency heatmap**: Visualize when projects are most active
- **Backup/restore audit report**: Compliance documentation
- **Version comparison**: Visual diff between any two snapshots
- **Resource-level tracking**: Track changes per flow/endpoint/lexicon

---

## Contributing

### Adding a New Project to Backup

1. Navigate to this template repository
2. Click "Use this template" → "Create a new repository"
3. Name it: `cognigy-backup-{project-name}`
4. Clone the new repository locally
5. Run setup script: `./scripts/setup-interactive.sh`
6. Commit and push configuration
7. Add GitHub Secrets in repository settings
8. Enable workflows in Actions tab
9. Trigger initial backup manually to verify
10. Monitor first 24 hours of automated backups

### Modifying Workflows

1. Test changes in a fork or separate test project first
2. Create PR with description of changes
3. Verify workflows pass in PR checks
4. Update documentation if behavior changes
5. Merge only after review
6. Consider: How to roll out changes to existing project repos

### Updating Existing Project Repos with Template Changes

When the template is updated, existing project repos won't automatically get changes. Options:

**Option 1: Manual update**
1. Check out both template and project repo
2. Copy changed files from template to project
3. Commit and push

**Option 2: Git remote tracking**
```bash
# In project repo
git remote add template https://github.com/{org}/cognigy-backup
git fetch template
git merge template/main --allow-unrelated-histories
# Resolve conflicts, commit
```

**Option 3: Automated (future enhancement)**
- Create workflow that detects template updates
- Auto-creates PR in project repos with changes

### Reporting Issues

Include in issue report:
- Project name (if applicable)
- Workflow run URL
- Error message (full logs if possible)
- Expected vs actual behavior
- Steps to reproduce
- Environment info (Cognigy version, etc.)

---

## License & Ownership

- **Owner**: CSA Team
- **Maintainer**: [Your name/team]
- **Access**: Private repositories, team access only
- **Data retention**: Follow company data retention policies
- **License**: Internal use only

---

## Glossary

- **Orphan branch**: Git branch with no parent commits (detached history)
- **Force push**: Overwrite remote branch history (required for cleanup)
- **Snapshot tier**: Category of backup (hourly/daily/weekly/monthly)
- **Promotion**: Moving snapshot from one tier to another (e.g., hourly → daily)
- **Pruning**: Deleting old snapshots per retention policy
- **Template repository**: GitHub feature to create boilerplate repos
- **Cognigy Agent**: Virtual agent project in Cognigy.AI
- **Flow**: Conversational workflow in Cognigy
- **Endpoint**: Deployment channel for Cognigy agent (webchat, voice, etc.)
- **Lexicon**: Custom terminology/entity definitions in Cognigy
- **GitHub Environment**: Protected deployment target requiring approval

---

## Changelog

### v1.0.0 (Planned)
- Initial template structure
- Basic backup workflow (hourly snapshots)
- Tier promotion workflow (daily/weekly/monthly)
- Cleanup workflow (retention enforcement)
- Restore workflow with approval
- Setup automation
- Complete documentation

### Future Versions
- v1.1.0: Notifications and monitoring
- v1.2.0: Dashboard and cross-project management
- v2.0.0: Advanced features (compression, selective backup, etc.)

---

_Last updated: 2025-10-03_
_Version: 1.0.0-draft_
