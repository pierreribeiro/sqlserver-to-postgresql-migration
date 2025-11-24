# Setup Guide - Environment Configuration

## 📋 Overview

This guide helps you set up the development environment for the SQL Server → PostgreSQL migration project.

**Estimated Time:** 15-30 minutes
**Last Updated:** 2025-11-24

---

## ✅ Prerequisites Checklist

Before starting, verify you have:

- [ ] PostgreSQL 16+ installed
- [ ] Python 3.10+ installed
- [ ] Git installed
- [ ] psql CLI accessible
- [ ] Internet connection (for package downloads)

---

## 🐍 Python Automation Setup

### 1. Verify Python Version

```bash
python3 --version
# Required: Python 3.10 or higher
```

### 2. Create Virtual Environment

```bash
# Navigate to project root
cd sqlserver-to-postgresql-migration

# Create virtual environment
python3 -m venv .venv

# Activate virtual environment
# Linux/Mac:
source .venv/bin/activate

# Windows:
.venv\Scripts\activate

# Verify activation (should show .venv path)
which python
```

### 3. Install Automation Dependencies

```bash
# Install all required packages
pip install -r scripts/automation/requirements.txt

# Verify installation
pip list | grep -E "sqlparse|click|pandas|rich"
```

**Expected Output:**
```
click            8.1.7
pandas           2.1.0
rich             13.6.0
sqlparse         0.4.3
```

### 4. Test Python Setup

```bash
# Quick test
python -c "import sqlparse, click, pandas, rich; print('✅ All packages installed')"
```

---

## 🔧 GitHub CLI Setup (Optional but Recommended)

The GitHub CLI (`gh`) enables automation for issues, PRs, and releases.

**Status:** Optional (but useful for GitHub integration)

### Installation Methods

#### Linux (Debian/Ubuntu)

```bash
# Option 1: Official Repository
type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y

# Option 2: Snap (simpler)
sudo snap install gh
```

#### macOS

```bash
# Using Homebrew
brew install gh

# Using MacPorts
sudo port install gh
```

#### Windows

```powershell
# Using Winget
winget install --id GitHub.cli

# Using Scoop
scoop install gh

# Using Chocolatey
choco install gh
```

### Verify Installation

```bash
gh --version
# Expected: gh version 2.x.x or higher
```

### Authenticate with GitHub

```bash
# Interactive authentication
gh auth login

# Follow the prompts:
# 1. Select: GitHub.com
# 2. Select: HTTPS
# 3. Select: Login with a web browser
# 4. Copy the one-time code and press Enter
# 5. Paste code in browser and authorize
```

### Test GitHub CLI

```bash
# Test authentication
gh auth status

# Test issue listing (from project directory)
gh issue list

# Test PR listing
gh pr list
```

---

## 🗄️ PostgreSQL Setup Verification

### 1. Verify PostgreSQL Installation

```bash
# Check PostgreSQL version
psql --version
# Required: PostgreSQL 16 or higher

# Check if server is running
pg_isready
```

### 2. Test Database Connection

```bash
# Connect to your database
psql -U your_username -d perseus_dev

# Or if using default:
psql -d postgres

# Once connected, verify version:
SELECT version();
```

### 3. Verify Required Extensions

```sql
-- Check if plpgsql is available
SELECT * FROM pg_available_extensions
WHERE name = 'plpgsql';

-- Create test function to verify
CREATE OR REPLACE FUNCTION test_setup()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN 'PostgreSQL setup OK';
END;
$$;

-- Test it
SELECT test_setup();
-- Expected: "PostgreSQL setup OK"

-- Clean up
DROP FUNCTION test_setup();
```

---

## 📦 Project Structure Validation

### Verify Directory Structure

```bash
# Run from project root
ls -la procedures/original/
ls -la procedures/aws-sct-converted/
ls -la procedures/corrected/
ls -la procedures/analysis/
ls -la scripts/automation/
ls -la tests/unit/
ls -la tracking/

# Check for key files
ls -la docs/PROJECT-PLAN.md
ls -la templates/postgresql-procedure-template.sql
ls -la tracking/priority-matrix.csv
ls -la scripts/automation/requirements.txt
ls -la scripts/automation/automation-config.json
```

---

## 🧪 Complete Setup Test

### Run Full Environment Check

```bash
#!/bin/bash
# Save as: scripts/validation/check-setup.sh

echo "🔍 Checking environment setup..."

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    echo "✅ Python $PYTHON_VERSION"
else
    echo "❌ Python not found"
fi

# Check Virtual Environment
if [[ "$VIRTUAL_ENV" != "" ]]; then
    echo "✅ Virtual environment activated"
else
    echo "⚠️  Virtual environment not activated"
fi

# Check Python packages
if python3 -c "import sqlparse" 2>/dev/null; then
    echo "✅ Python automation packages installed"
else
    echo "❌ Python automation packages missing"
fi

# Check PostgreSQL
if command -v psql &> /dev/null; then
    PSQL_VERSION=$(psql --version | awk '{print $3}')
    echo "✅ PostgreSQL $PSQL_VERSION"
else
    echo "❌ PostgreSQL not found"
fi

# Check GitHub CLI
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -n1 | awk '{print $3}')
    echo "✅ GitHub CLI $GH_VERSION"
else
    echo "⚠️  GitHub CLI not installed (optional)"
fi

# Check Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    echo "✅ Git $GIT_VERSION"
else
    echo "❌ Git not found"
fi

echo ""
echo "🎯 Setup validation complete!"
```

### Run the Check

```bash
# Make script executable
chmod +x scripts/validation/check-setup.sh

# Run validation
./scripts/validation/check-setup.sh
```

**Expected Output:**
```
🔍 Checking environment setup...
✅ Python 3.11.14
✅ Virtual environment activated
✅ Python automation packages installed
✅ PostgreSQL 16.x
✅ GitHub CLI 2.x.x
✅ Git 2.x.x

🎯 Setup validation complete!
```

---

## 🔧 Troubleshooting

### Python Issues

**Problem:** `python3: command not found`
```bash
# Linux/Ubuntu
sudo apt update && sudo apt install python3 python3-pip python3-venv

# macOS
brew install python3

# Verify
python3 --version
```

**Problem:** `pip install` fails
```bash
# Upgrade pip
python3 -m pip install --upgrade pip

# Retry installation
pip install -r scripts/automation/requirements.txt
```

**Problem:** Permission denied
```bash
# Don't use sudo! Use virtual environment instead
python3 -m venv .venv
source .venv/bin/activate
pip install -r scripts/automation/requirements.txt
```

### PostgreSQL Issues

**Problem:** `psql: command not found`
```bash
# Add PostgreSQL to PATH
export PATH=/usr/lib/postgresql/16/bin:$PATH

# Or install PostgreSQL client
sudo apt install postgresql-client-16
```

**Problem:** Connection refused
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Start if stopped
sudo systemctl start postgresql

# Enable auto-start
sudo systemctl enable postgresql
```

### GitHub CLI Issues

**Problem:** `gh: command not found` (Linux)
```bash
# If installed via snap, add to PATH
export PATH=/snap/bin:$PATH

# Or use full path
/snap/bin/gh --version
```

**Problem:** Authentication fails
```bash
# Logout and retry
gh auth logout
gh auth login

# Check status
gh auth status
```

---

## 📝 Configuration Files

### Create logs directory

```bash
mkdir -p logs
touch logs/.gitkeep
```

### Verify Configuration Files

```bash
# Check automation config
cat scripts/automation/automation-config.json | jq .

# Check requirements
cat scripts/automation/requirements.txt
```

---

## 🎯 Next Steps

After completing setup:

1. **Verify Everything Works**
   ```bash
   ./scripts/validation/check-setup.sh
   ```

2. **Read the Project Plan**
   ```bash
   cat docs/PROJECT-PLAN.md
   ```

3. **Review Priority Matrix**
   ```bash
   cat tracking/priority-matrix.csv
   ```

4. **Start with Analysis Phase**
   - Select a procedure from priority matrix
   - Use automation scripts (when implemented)
   - Follow the template in `templates/`

---

## 📚 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/16/)
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [Python Virtual Environments](https://docs.python.org/3/tutorial/venv.html)
- [Project Plan](PROJECT-PLAN.md)

---

## ✅ Setup Complete Checklist

Mark each item when complete:

- [ ] Python 3.10+ installed and verified
- [ ] Virtual environment created and activated
- [ ] All Python packages installed successfully
- [ ] PostgreSQL 16+ accessible via psql
- [ ] Can connect to Perseus database
- [ ] GitHub CLI installed (optional)
- [ ] GitHub CLI authenticated (if installed)
- [ ] Git configured with username/email
- [ ] All project directories present
- [ ] Configuration files created
- [ ] Setup validation script runs without errors

**Once all items are checked, you're ready to begin Sprint 1! 🚀**

---

**Maintained by:** Pierre Ribeiro (DBA/DBRE)
**Last Updated:** 2025-11-24
**Version:** 1.0
