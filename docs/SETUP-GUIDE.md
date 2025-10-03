# Cognigy Backup Setup Guide

Complete step-by-step guide to set up automated backups for your Cognigy project.

---

## Prerequisites

Before you begin, you'll need:

1. **Cognigy Account** with API access
2. **GitHub Account** with permission to create repositories
3. **Git** installed locally
4. **Cognigy API Key** with appropriate permissions
5. **Cognigy Agent ID** (found in Cognigy.AI URL or project settings)

---

## Step 1: Create Backup Repository from Template

### 1.1 Use Template

1. Navigate to the [cognigy-backup template](https://github.com/ben-elliot-nice/cognigy-backup)
2. Click **"Use this template"** button (top right)
3. Click **"Create a new repository"**

### 1.2 Configure New Repository

- **Owner**: Your GitHub username or organization
- **Repository name**: `cognigy-backup-{project-name}`
  - Example: `cognigy-backup-customer-support`
- **Description**: Optional - "Automated backup for [Project Name] Cognigy project"
- **Visibility**: **Private** (recommended - contains business logic)
- Click **"Create repository"**

---

## Step 2: Clone and Configure Locally

### 2.1 Clone Repository

```bash
git clone git@github.com:{your-username}/cognigy-backup-{project-name}.git
cd cognigy-backup-{project-name}
```

### 2.2 Run Setup Script

```bash
chmod +x scripts/setup-interactive.sh
./scripts/setup-interactive.sh
```

The script will prompt you for:

**Project Configuration:**
- **Cognigy Project Name**: Descriptive name for documentation
- **Agent ID**: Your Cognigy agent/project ID
- **Backup Directory**: Default is `agent` (recommended)

**Retention Policy** (or accept defaults):
- Hourly snapshots: count and interval
- Daily snapshots: count and interval
- Weekly snapshots: count
- Monthly archives: count

### 2.3 Review Generated Files

The script creates/modifies:
- `config.json` - Your project configuration
- `README.md` - Project-specific documentation
- `.github/workflows/*.yml` - Activated workflows (renamed from `.disabled`)

### 2.4 Commit Configuration

```bash
git add -f config.json  # Force add (it's in .gitignore)
git add .
git commit -m "Configure backup for {project-name} [skip-setup]"
git push
```

**Important Notes:**
- The `-f` flag is required because `config.json` is in `.gitignore`
- The `[skip-setup]` tag prevents the setup workflow from running again
- The committed config.json does NOT contain credentials (only retention settings)

---

## Step 3: Configure GitHub Secrets

### Option A: Via GitHub Web UI

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Add each secret:

| Secret Name | Value | Example |
|-------------|-------|---------|
| `COGNIGY_BASE_URL` | Your Cognigy API endpoint | `https://api-app.cognigy.ai` |
| `COGNIGY_API_KEY` | Your Cognigy API key | `apikey-xxx-yyy-zzz` |
| `COGNIGY_AGENT_ID` | Your Cognigy agent/project ID | `507f1f77bcf86cd799439011` |

### Option B: Via GitHub CLI

```bash
# Install gh CLI if needed: https://cli.github.com/

# Set secrets
gh secret set COGNIGY_BASE_URL -b "https://api-app.cognigy.ai"
gh secret set COGNIGY_API_KEY -b "your-api-key-here"
gh secret set COGNIGY_AGENT_ID -b "your-agent-id-here"

# Verify secrets are set
gh secret list
```

### Finding Your Values

**COGNIGY_BASE_URL:**
- Trial: `https://api-trial.cognigy.ai`
- Production: `https://api-app.cognigy.ai`
- Custom: Check your Cognigy instance URL

**COGNIGY_API_KEY:**
1. Log into Cognigy.AI
2. Go to **User Menu** → **My Profile** → **API Keys**
3. Create new API key or copy existing one

**COGNIGY_AGENT_ID:**
1. Open your Cognigy project
2. Look at the URL: `https://app.cognigy.ai/agent/{agent-id}/...`
3. Or go to **Project Settings** → copy the ID

---

## Step 4: Enable and Test Workflows

### 4.1 Enable Workflows

1. Go to **Actions** tab in your repository
2. You'll see a message about workflows in this repository
3. Click **"I understand my workflows, go ahead and enable them"**

### 4.2 Trigger First Backup Manually

1. Click **Actions** tab
2. Select **"Backup to Snapshot"** workflow
3. Click **"Run workflow"** dropdown
4. Select `main` branch
5. Click **"Run workflow"** button

### 4.3 Monitor First Backup

1. Click on the running workflow
2. Watch the job progress
3. Verify it completes successfully (green checkmark)
4. Check workflow logs for any errors

### 4.4 Verify Snapshot Created

```bash
# Fetch latest branches
git fetch origin

# List snapshot branches
git branch -r | grep snapshot

# You should see:
# origin/snapshot/hourly
```

### 4.5 Inspect Snapshot Contents

```bash
# Checkout snapshot branch
git checkout snapshot/hourly

# View backup contents
ls agent/

# Return to main
git checkout main
```

---

## Step 5: Enable Scheduled Backups

The backup workflow is already configured to run on schedule (default: every 30 minutes).

**No action needed** - backups will run automatically!

### Schedule Overview

Based on your `config.json`:

```yaml
# Backup workflow (default)
schedule:
  - cron: '*/30 * * * *'  # Every 30 minutes

# Promotion workflow (default)
schedule:
  - cron: '0 */6 * * *'   # Every 6 hours (for daily snapshots)
  - cron: '0 0 * * 0'     # Every Sunday (for weekly snapshots)
  - cron: '0 0 1 * *'     # First of month (for monthly releases)

# Cleanup workflow (default)
schedule:
  - cron: '0 2 * * *'     # Daily at 2 AM
```

### Customize Schedule (Optional)

Edit `.github/workflows/backup.yml`:

```yaml
on:
  schedule:
    - cron: '0 * * * *'  # Change to hourly instead of every 30 min
```

[Cron syntax reference](https://crontab.guru/)

---

## Step 6: Verify Automated Backups

### Monitor for 24 Hours

1. Check **Actions** tab periodically
2. Verify backups are running on schedule
3. Confirm no failures

### Check Snapshot History

```bash
git fetch origin
git checkout snapshot/hourly
git log --oneline

# You should see multiple commits with timestamps
```

---

## Optional: Configure GitHub Environment for Restore Approval

If you want to require manual approval before restoring backups:

### 6.1 Create Environment

1. Go to **Settings** → **Environments**
2. Click **"New environment"**
3. Name it: `production-restore`

### 6.2 Add Protection Rules

1. Check **"Required reviewers"**
2. Add yourself and/or team members
3. Save protection rules

### 6.3 Update Restore Workflow

Edit `.github/workflows/restore.yml`:

```yaml
jobs:
  restore:
    runs-on: ubuntu-latest
    environment: production-restore  # Add this line
```

Now all restore operations will require approval!

---

## Optional: Enable Notifications

### Slack/Discord Webhooks

1. Create webhook URL in Slack/Discord
2. Add as GitHub Secret:
   ```bash
   gh secret set SLACK_WEBHOOK_URL -b "https://hooks.slack.com/services/..."
   ```

3. Update `config.json`:
   ```json
   {
     "notifications": {
       "enabled": true,
       "webhookUrl": "",  # Loaded from secret in workflow
       "notifyOnFailure": true
     }
   }
   ```

4. Uncomment notification steps in workflows

---

## Verification Checklist

Before considering setup complete:

- [ ] Repository created from template
- [ ] Setup script run successfully
- [ ] `config.json` configured with your project details
- [ ] All three GitHub secrets added (BASE_URL, API_KEY, AGENT_ID)
- [ ] Workflows enabled in Actions tab
- [ ] First manual backup succeeded
- [ ] `snapshot/hourly` branch exists
- [ ] Snapshot contains your Cognigy project data
- [ ] Scheduled backups running automatically
- [ ] No errors in workflow runs for 24 hours

---

## Troubleshooting

### Setup Script Fails

**Error: Permission denied**
```bash
chmod +x scripts/setup-interactive.sh
```

**Error: config.json already exists**
```bash
# Backup existing if needed
cp config.json config.json.backup
rm config.json
./scripts/setup-interactive.sh
```

### Workflow Fails with 401 Unauthorized

**Cause**: Invalid or expired API key

**Solution**:
1. Generate new API key in Cognigy.AI
2. Update secret: `gh secret set COGNIGY_API_KEY -b "new-key"`
3. Re-run workflow

### No Changes Detected

**Cause**: Cognigy project hasn't changed since last backup

**Solution**: This is normal! Workflow will log "No changes detected" and skip creating a snapshot.

### Snapshot Branch Not Created

**Cause**: Workflow might have failed

**Solution**:
1. Check workflow logs in Actions tab
2. Verify secrets are set: `gh secret list`
3. Test Cognigy CLI locally:
   ```bash
   npm install -g @cognigy/cognigy-cli
   export CAI_BASEURL="your-base-url"
   export CAI_APIKEY="your-api-key"
   export CAI_AGENT="your-agent-id"
   cognigy clone -y
   ```

---

## Next Steps

- Read [RESTORE-GUIDE.md](RESTORE-GUIDE.md) to learn how to restore backups
- Review [ARCHITECTURE.md](ARCHITECTURE.md) for technical details
- Set up backups for additional Cognigy projects by repeating this process

---

## Getting Help

- Check [troubleshooting section](#troubleshooting) above
- Review workflow logs in Actions tab
- Consult [Cognigy CLI documentation](https://www.npmjs.com/package/@cognigy/cognigy-cli)
- Open an issue in this repository

---

_Setup complete? Great! Your Cognigy project is now automatically backed up._
