#!/bin/bash
set -e

echo "🔧 Cognigy Backup Setup"
echo "======================="
echo ""

# Check if already configured
if [ -f "config.json" ]; then
    echo "⚠️  config.json already exists!"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 1
    fi
fi

echo "This script will configure your Cognigy backup repository."
echo ""

# Project Configuration
echo "📋 Project Configuration"
echo "------------------------"
read -p "Cognigy Project Name (e.g., 'Customer Support Bot'): " PROJECT_NAME
read -p "Backup Directory Name (default: agent): " AGENT_DIR
AGENT_DIR=${AGENT_DIR:-agent}

echo ""
echo "📦 Retention Policy Configuration"
echo "----------------------------------"
echo "Configure how many snapshots to keep in each tier."
echo ""

# Hourly/Recent snapshots
read -p "Hourly snapshots to keep (default: 8, ~2 days at 6h intervals): " HOURLY_COUNT
HOURLY_COUNT=${HOURLY_COUNT:-8}

# Daily snapshots
read -p "Daily snapshots to keep (default: 7, last week): " DAILY_COUNT
DAILY_COUNT=${DAILY_COUNT:-7}

# Weekly snapshots
read -p "Weekly snapshots to keep (default: 4, last month): " WEEKLY_COUNT
WEEKLY_COUNT=${WEEKLY_COUNT:-4}

# Monthly archives
read -p "Monthly archives to keep (default: 12, last year): " MONTHLY_COUNT
MONTHLY_COUNT=${MONTHLY_COUNT:-12}

echo ""
echo "🔧 Backup Configuration"
echo "-----------------------"
echo "What should be backed up?"
echo "1) agent (entire project - recommended)"
echo "2) flows (only flows)"
echo "3) endpoints (only endpoints)"
echo "4) lexicons (only lexicons)"
read -p "Select option (1-4, default: 1): " CLONE_OPTION
CLONE_OPTION=${CLONE_OPTION:-1}

case "$CLONE_OPTION" in
    1) CLONE_TYPE="agent" ;;
    2) CLONE_TYPE="flows" ;;
    3) CLONE_TYPE="endpoints" ;;
    4) CLONE_TYPE="lexicons" ;;
    *) CLONE_TYPE="agent" ;;
esac

# Generate config.json
echo ""
echo "📝 Generating config.json..."

cat > config.json <<EOF
{
  "projectName": "$PROJECT_NAME",
  "agentDir": "$AGENT_DIR",

  "retention": {
    "hourly": {
      "enabled": true,
      "count": $HOURLY_COUNT,
      "description": "Short-term snapshots (every 6 hours by default)"
    },
    "daily": {
      "enabled": true,
      "count": $DAILY_COUNT,
      "description": "Medium-term snapshots (one per day)"
    },
    "weekly": {
      "enabled": true,
      "count": $WEEKLY_COUNT,
      "description": "Long-term snapshots (one per week)"
    },
    "monthly": {
      "enabled": true,
      "count": $MONTHLY_COUNT,
      "description": "Archive snapshots (GitHub Releases, one per month)"
    }
  },

  "backup": {
    "cloneType": "$CLONE_TYPE",
    "excludeResources": []
  },

  "notifications": {
    "enabled": false,
    "webhookUrl": "",
    "notifyOnFailure": true,
    "notifyOnSuccess": false,
    "dailySummary": false
  }
}
EOF

echo "✅ Created config.json"
echo ""

# Activate workflows
echo "📝 Activating workflows..."
WORKFLOWS_DIR=".github/workflows"

if [ ! -d "$WORKFLOWS_DIR" ]; then
    echo "::error::Workflows directory not found: $WORKFLOWS_DIR"
    exit 1
fi

for file in "$WORKFLOWS_DIR"/*.disabled; do
    if [ -f "$file" ]; then
        newname="${file%.disabled}"
        mv "$file" "$newname"
        echo "  ✓ Activated $(basename $newname)"
    fi
done

echo ""

# Update README
echo "📝 Updating README..."

cat > README.md <<EOF
# Cognigy Backup: $PROJECT_NAME

Automated backup for Cognigy project: **$PROJECT_NAME**

## 📊 Backup Configuration

- **Backup Frequency**: Every 6 hours (0:00, 6:00, 12:00, 18:00 UTC)
- **Backup Type**: $CLONE_TYPE
- **Storage Location**: GitHub branches + releases

## 📦 Retention Policy

| Tier | Count | Frequency | Coverage |
|------|-------|-----------|----------|
| Hourly | $HOURLY_COUNT snapshots | Every 6 hours | ~$(($HOURLY_COUNT * 6 / 24)) days |
| Daily | $DAILY_COUNT snapshots | Once per day | $DAILY_COUNT days |
| Weekly | $WEEKLY_COUNT snapshots | Once per week | $WEEKLY_COUNT weeks |
| Monthly | $MONTHLY_COUNT archives | Once per month | $MONTHLY_COUNT months |

**Total estimated storage**: ~150 MB (fixed, doesn't grow)

## 🌿 Snapshot Branches

- \`snapshot/hourly\` - Most recent snapshot (updated every 6 hours)
- \`snapshot/daily/YYYYMMDD\` - Daily snapshots
- \`snapshot/weekly/YYYY-Wxx\` - Weekly snapshots
- Releases: \`monthly-YYYY-MM\` - Monthly archives

## 🔄 How to Restore

### Via GitHub Actions (Recommended)

1. Go to **Actions** → **Restore Backup**
2. Click **Run workflow**
3. Select tier (hourly/daily/weekly/monthly)
4. Enable **dry run** to preview changes
5. Run workflow
6. If dry run looks good, disable dry run and run again

### Via Command Line

\`\`\`bash
# Checkout snapshot
git fetch origin snapshot/hourly
git checkout snapshot/hourly

# Restore to Cognigy
export CAI_BASEURL="your-base-url"
export CAI_APIKEY="your-api-key"
export CAI_AGENT="your-agent-id"
cognigy restore -y
\`\`\`

## 📚 Documentation

- [Setup Guide](docs/SETUP-GUIDE.md) - Complete setup instructions
- [Restore Guide](docs/RESTORE-GUIDE.md) - How to restore backups
- [Architecture](docs/ARCHITECTURE.md) - Technical details
- [Project Plan](docs/PROJECT.md) - Overall project documentation

## 🔒 GitHub Secrets Required

Make sure these secrets are configured in **Settings → Secrets → Actions**:

- \`COGNIGY_BASE_URL\` - Your Cognigy API endpoint
- \`COGNIGY_API_KEY\` - Your Cognigy API key
- \`COGNIGY_AGENT_ID\` - Your Cognigy agent/project ID

## ⚙️ Customization

### Change Backup Frequency

Edit \`.github/workflows/backup.yml\` and modify the cron schedule:

\`\`\`yaml
on:
  schedule:
    - cron: '0 * * * *'  # Change to hourly
    # or
    - cron: '*/30 * * * *'  # Change to every 30 min
\`\`\`

### Change Retention Policy

Edit \`config.json\` and adjust the count values, then commit and push.

## 🆘 Troubleshooting

**Backup failing with 401 Unauthorized?**
- Verify \`COGNIGY_API_KEY\` secret is correct
- Check API key hasn't expired

**No snapshots created?**
- Check Actions tab for workflow runs
- Verify project has changes since last backup
- Check workflow logs for errors

**Storage growing unexpectedly?**
- Verify cleanup workflow is running daily
- Check retention policy in \`config.json\`

## 📞 Support

- [Setup Guide](docs/SETUP-GUIDE.md) - Troubleshooting section
- [Architecture Docs](docs/ARCHITECTURE.md) - Debug commands
- [Cognigy CLI Docs](https://www.npmjs.com/package/@cognigy/cognigy-cli)

---

_Automated backups powered by [Cognigy CLI](https://www.npmjs.com/package/@cognigy/cognigy-cli) + GitHub Actions_

_Last configured: $(date)_
EOF

echo "✅ Updated README.md"
echo ""

echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Review the generated config.json"
echo "2. Commit changes: git add . && git commit -m 'Configure backup [skip-setup]'"
echo "3. Push to GitHub: git push"
echo "4. Add GitHub Secrets:"
echo "   - COGNIGY_BASE_URL"
echo "   - COGNIGY_API_KEY"
echo "   - COGNIGY_AGENT_ID"
echo "5. Go to Actions tab and manually trigger first backup"
echo ""
echo "📚 See docs/SETUP-GUIDE.md for detailed instructions"
echo ""
