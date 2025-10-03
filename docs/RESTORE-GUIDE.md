# Cognigy Backup Restore Guide

How to restore your Cognigy project from any backup snapshot.

---

## ⚠️ Important Warnings

**Before restoring:**

1. **Restoring OVERWRITES your current Cognigy project** with the snapshot state
2. **Any changes made after the snapshot will be LOST**
3. **Always use dry-run mode first** to preview what will change
4. **Consider restoring to a test/staging project first** before production
5. **Backup current state** before restoring if you might need to revert

---

## Quick Restore Methods

### Method 1: GitHub Actions (Recommended)

Easiest method with built-in safety checks.

[Jump to full instructions](#method-1-restore-via-github-actions)

### Method 2: Local Command Line

For advanced users or custom restore scenarios.

[Jump to full instructions](#method-2-restore-locally)

---

## Method 1: Restore via GitHub Actions

### Step 1: Navigate to Restore Workflow

1. Go to your backup repository on GitHub
2. Click **Actions** tab
3. Select **"Restore Backup"** workflow from left sidebar
4. Click **"Run workflow"** dropdown (top right)

### Step 2: Configure Restore Parameters

**Select Snapshot Tier:**
- `hourly` - Last 3 hours (every 30 min)
- `daily` - Last 7 days (every 6 hours)
- `weekly` - Last 4 weeks (every Sunday)
- `monthly` - Last 12 months (GitHub Releases)

**Snapshot Commit SHA** (optional):
- Leave blank for latest snapshot in tier
- Or enter specific commit SHA to restore exact version

**Dry Run:**
- ✅ **Enabled (recommended)** - Shows what would change, doesn't actually restore
- ❌ Disabled - Actually restores to Cognigy

**Branch:**
- Select `main` (default)

### Step 3: Run Dry-Run First

1. Enable "Dry Run" checkbox
2. Click **"Run workflow"**
3. Wait for workflow to complete
4. Review workflow logs to see what would be restored

**Look for:**
- List of flows that would be updated
- List of endpoints that would be changed
- Any resources that would be deleted
- Summary of changes

### Step 4: Approve and Restore (If Using Environments)

If you set up GitHub Environment protection:

1. Disable "Dry Run" checkbox
2. Click **"Run workflow"**
3. Workflow will pause and wait for approval
4. Go to workflow run page
5. Click **"Review deployments"**
6. Review changes summary
7. Click **"Approve and deploy"** or **"Reject"**

If you're NOT using environment protection, workflow will restore immediately.

### Step 5: Verify Restore

1. Log into Cognigy.AI
2. Open your project
3. Verify flows, endpoints, and other resources match expected state
4. Test basic functionality

---

## Method 2: Restore Locally

### Prerequisites

- Git installed
- Cognigy CLI installed: `npm install -g @cognigy/cognigy-cli`
- Valid Cognigy API key

### Step 1: Clone Backup Repository

```bash
git clone git@github.com:{your-username}/cognigy-backup-{project-name}.git
cd cognigy-backup-{project-name}
```

### Step 2: List Available Snapshots

```bash
# Fetch all branches
git fetch origin

# List snapshot tiers
git branch -r | grep snapshot

# View commits in specific tier
git log origin/snapshot/hourly --oneline
git log origin/snapshot/daily --oneline
```

### Step 3: Checkout Desired Snapshot

```bash
# Checkout latest from specific tier
git checkout snapshot/hourly

# OR checkout specific commit
git checkout <commit-sha>
```

### Step 4: Configure Cognigy CLI

Create `config.json` if not present:

```json
{
  "baseUrl": "https://api-app.cognigy.ai",
  "apiKey": "your-api-key",
  "agent": "your-agent-id",
  "agentDir": "agent"
}
```

**Or use environment variables:**

```bash
export CAI_BASEURL="https://api-app.cognigy.ai"
export CAI_APIKEY="your-api-key"
export CAI_AGENT="your-agent-id"
export CAI_AGENTDIR="agent"
```

### Step 5: Preview Changes (Dry Run)

```bash
# Compare local snapshot vs current Cognigy state
cognigy diff flow MainFlow
cognigy diff endpoint WebchatEndpoint

# Repeat for all resources you want to check
```

### Step 6: Restore to Cognigy

```bash
# Restore everything
cognigy restore -y

# OR restore specific resource types
cognigy push flows MainFlow
cognigy push endpoints WebchatEndpoint
```

### Step 7: Verify

Log into Cognigy.AI and verify the restore was successful.

---

## Restore Scenarios

### Scenario 1: "I just deleted a flow by accident!"

**Quick Recovery:**

1. **Actions** → **Restore Backup**
2. Select tier: `hourly`
3. Leave commit blank (uses latest)
4. Enable dry-run
5. Run workflow → review changes
6. Disable dry-run → run workflow → approve

**Time to restore:** ~5 minutes

### Scenario 2: "I need to go back to last week's version"

**Restore from daily tier:**

1. **Actions** → **Restore Backup**
2. Select tier: `daily`
3. Find commit from desired date:
   ```bash
   git log origin/snapshot/daily --oneline
   # Pick commit from desired date
   ```
4. Enter commit SHA in workflow input
5. Run dry-run first
6. Approve and restore

### Scenario 3: "I want to copy a flow from an old backup"

**Selective restore:**

1. Checkout snapshot locally:
   ```bash
   git checkout snapshot/weekly
   ```

2. Extract specific flow:
   ```bash
   cp agent/flows/SpecificFlow.json /tmp/
   ```

3. Return to current state:
   ```bash
   git checkout main
   ```

4. Manually import flow JSON into Cognigy.AI

### Scenario 4: "I need the version from exactly 2 weeks ago"

**Restore specific date:**

1. Find commits around that date:
   ```bash
   git log origin/snapshot/daily --since="2 weeks ago" --until="13 days ago" --oneline
   ```

2. Pick closest commit SHA

3. Use GitHub Actions restore workflow with that SHA

Or restore monthly release if available:

```bash
gh release list
gh release download monthly-2024-01
# Extract and restore
```

### Scenario 5: "I want to test restore without affecting production"

**Restore to staging project:**

1. Create test Cognigy agent/project

2. Clone backup repo locally

3. Checkout desired snapshot

4. Update config to point to staging:
   ```bash
   export CAI_AGENT="staging-agent-id"
   ```

5. Restore:
   ```bash
   cognigy restore -y
   ```

6. Test in staging

7. If successful, repeat for production agent ID

---

## Understanding Snapshots

### What's in a Snapshot?

Each snapshot branch contains:

```
agent/
├── flows/
│   ├── MainFlow.json
│   └── FallbackFlow.json
├── endpoints/
│   ├── WebchatEndpoint.json
│   └── VoiceEndpoint.json
├── lexicons/
│   └── CustomTerms.json
└── config.json
```

### Snapshot Metadata

Each commit message includes:
- Timestamp: `Snapshot: 2024-10-03T14:30:00Z`
- Tier: `hourly`, `daily`, `weekly`, or `monthly`

View metadata:
```bash
git log snapshot/hourly --pretty=format:"%H %s %ci"
```

### Finding the Right Snapshot

**By time:**
```bash
# Snapshots from last hour
git log snapshot/hourly --since="1 hour ago"

# Snapshots from specific day
git log snapshot/daily --since="2024-10-01" --until="2024-10-02"
```

**By content:**
```bash
# Search for when a file changed
git log -p snapshot/daily -- agent/flows/MainFlow.json

# Find snapshots containing specific text
git log -S "search term" snapshot/daily
```

---

## Restore Workflow Reference

### Workflow Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `tier` | Yes | `hourly` | Snapshot tier to restore from |
| `commit_sha` | No | (latest) | Specific commit SHA to restore |
| `dry_run` | No | `true` | Preview changes without restoring |

### Workflow Behavior

1. **Checkout**: Checks out specified snapshot commit
2. **Validate**: Verifies snapshot contains valid Cognigy data
3. **Diff** (if dry-run): Shows what would change
4. **Restore** (if not dry-run): Pushes snapshot to Cognigy
5. **Notify**: Logs restore operation

### Workflow Permissions

Required GitHub Secrets:
- `COGNIGY_BASE_URL`
- `COGNIGY_API_KEY`
- `COGNIGY_AGENT_ID`

---

## Safety Best Practices

### Before Every Restore

1. ✅ **Create a manual snapshot in Cognigy.AI** as additional backup
2. ✅ **Run dry-run first** to preview changes
3. ✅ **Notify team members** that restore is happening
4. ✅ **Document why you're restoring** (for audit trail)
5. ✅ **Test in staging first** if possible

### After Restore

1. ✅ **Verify all flows work** as expected
2. ✅ **Test critical user journeys**
3. ✅ **Check integrations** (APIs, databases, etc.)
4. ✅ **Monitor for errors** in production
5. ✅ **Document what was restored** and why

---

## Troubleshooting Restore Issues

### Restore Fails with "Resource not found"

**Cause**: Resource exists in snapshot but not in current Cognigy project

**Solution**:
- Cognigy CLI can only UPDATE existing resources, not CREATE new ones
- Manually create placeholder resources in Cognigy first
- Then re-run restore

### Restore Completes but Changes Not Visible

**Cause**: Cached data in Cognigy UI

**Solution**:
- Hard refresh browser (Ctrl+Shift+R or Cmd+Shift+R)
- Log out and back into Cognigy.AI
- Clear browser cache

### Workflow Fails with Permission Error

**Cause**: API key lacks permissions

**Solution**:
- Verify API key in Cognigy.AI has admin/write permissions
- Regenerate API key
- Update GitHub secret: `gh secret set COGNIGY_API_KEY -b "new-key"`

### Partial Restore (Some Resources Failed)

**Cause**: Network issues or API rate limits

**Solution**:
- Check workflow logs for specific errors
- Re-run restore workflow
- If persists, restore manually using CLI

---

## FAQ

**Q: Can I restore to a different Cognigy project?**

A: Yes! Change the `COGNIGY_AGENT_ID` secret or environment variable to point to a different project.

**Q: Will restore affect my production users?**

A: Yes - restore overwrites the live project. Consider:
- Restoring during off-peak hours
- Using maintenance mode in Cognigy
- Restoring to staging first

**Q: How do I know what changed in a snapshot?**

A: Use `git diff`:
```bash
git diff snapshot/daily~1 snapshot/daily -- agent/
```

Or compare any two commits:
```bash
git diff <old-commit> <new-commit>
```

**Q: Can I restore just one flow?**

A: Yes - use selective restore:
```bash
cognigy push flow SpecificFlowName
```

**Q: What if I restore the wrong snapshot?**

A: Immediately restore the most recent snapshot:
1. **Actions** → **Restore Backup**
2. Select `hourly` tier
3. Leave commit blank (latest)
4. Disable dry-run
5. Run workflow

---

## Restore Checklist

Use this before every restore:

```
Restore Pre-Flight Checklist:
[ ] Identified correct snapshot tier and commit
[ ] Ran dry-run to preview changes
[ ] Created manual backup in Cognigy.AI
[ ] Notified team members
[ ] Scheduled restore during low-traffic time
[ ] Have rollback plan ready

Restore Execution:
[ ] Disabled dry-run
[ ] Approved workflow (if using environments)
[ ] Monitored workflow logs
[ ] Workflow completed successfully

Post-Restore Verification:
[ ] Logged into Cognigy.AI
[ ] Verified flows present and correct
[ ] Tested critical user journeys
[ ] Checked integrations working
[ ] No errors in Cognigy logs
[ ] Documented restore in team wiki/log
```

---

## Getting Help

If you encounter issues:

1. Check [troubleshooting section](#troubleshooting-restore-issues)
2. Review workflow logs in Actions tab
3. Test restore locally with Cognigy CLI
4. Consult [Cognigy CLI docs](https://www.npmjs.com/package/@cognigy/cognigy-cli)
5. Contact Cognigy support if API issues persist

---

_Need to set up backups? See [SETUP-GUIDE.md](SETUP-GUIDE.md)_
