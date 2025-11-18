# GitHub Setup Guide for SAML Julia Package

This guide walks you through pushing this local Git repository to GitHub.

## Prerequisites

- GitHub account (create at https://github.com/signup)
- Git installed locally (already done)
- SSH key configured (optional but recommended) or personal access token

## Step 1: Create a GitHub Repository

1. Go to https://github.com/new
2. Enter repository name: `SAML.jl`
3. Description: "SAML 2.0 Service Provider implementation for Julia"
4. Choose visibility: **Public** (recommended for open-source)
5. Do **NOT** initialize with README, .gitignore, or license (we already have these)
6. Click "Create repository"

## Step 2: Configure Remote and Push

After creating the repository on GitHub, you'll see instructions like:

```bash
git remote add origin https://github.com/YOUR_USERNAME/SAML.jl.git
git branch -M main
git push -u origin main
```

However, GitHub now uses `main` as the default branch. Let's do this:

```bash
cd "c:\Users\K\Projects\SAMLClient"

# Add the remote repository
git remote add origin https://github.com/YOUR_USERNAME/SAML.jl.git

# Rename branch from master to main
git branch -M main

# Push to GitHub
git push -u origin main
```

Replace `YOUR_USERNAME` with your actual GitHub username.

### Using SSH (Recommended)

If you have SSH keys configured:

```bash
git remote add origin git@github.com:YOUR_USERNAME/SAML.jl.git
git branch -M main
git push -u origin main
```

### Using Personal Access Token

If using HTTPS and two-factor authentication:

```bash
# When prompted for password, use your personal access token instead
git push -u origin main
```

Create a personal access token at: https://github.com/settings/tokens

## Step 3: Verify the Push

1. Go to https://github.com/YOUR_USERNAME/SAML.jl
2. Verify all files are present
3. Check that the initial commit appears in the commit history

## Step 4: Add Important Files

### Enable GitHub Pages (Optional)

1. Go to Settings → Pages
2. Choose branch: `main`
3. Choose folder: `/docs` (if using documentation)
4. Save

### Add Topics (Optional)

1. Go to main repository page
2. Click "Add topics" (top right, below repository name)
3. Add relevant topics:
   - `julia`
   - `saml`
   - `saml2`
   - `sso`
   - `authentication`
   - `identity-provider`

### Setup Branch Protection (Optional)

1. Go to Settings → Branches
2. Click "Add rule"
3. Branch name pattern: `main`
4. Enable:
   - Require pull request reviews
   - Require status checks to pass before merging
   - Require branches to be up to date

## Step 5: Update Documentation

Update the following files to reflect your GitHub username:

### .github/README.md

Update these lines:
```markdown
[![Tests](https://github.com/YOUR_USERNAME/SAML.jl/workflows/Tests/badge.svg)](https://github.com/YOUR_USERNAME/SAML.jl/actions)
```

### docs/DEPLOYMENT.md

If needed, add repository-specific URLs:
```
For issues: https://github.com/YOUR_USERNAME/SAML.jl/issues
For documentation: https://YOUR_USERNAME.github.io/SAML.jl/
```

## Step 6: Configure GitHub Actions

The `.github/workflows/tests.yml` file is already configured. GitHub Actions will:

1. Run tests on push and pull requests
2. Test on multiple Julia versions
3. Test on multiple operating systems

Verify it's working:
1. Go to your repository
2. Click on "Actions" tab
3. You should see the initial commit triggering a workflow

## Next Steps

### Collaborators

To add collaborators:
1. Go to Settings → Collaborators and teams
2. Click "Add people"
3. Enter their GitHub username

### Issue Templates

Create issue templates in `.github/ISSUE_TEMPLATE/`:

```
.github/
├── ISSUE_TEMPLATE/
│   ├── bug_report.md
│   ├── feature_request.md
│   └── question.md
```

### Pull Request Template

Create `.github/pull_request_template.md`:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change

## Testing
How was this tested?

## Checklist
- [ ] Tests pass
- [ ] Documentation updated
- [ ] Commits are clean
```

## Pushing Updates

When you make changes locally:

```bash
# Make changes to files

# Stage changes
git add .

# Commit
git commit -m "Clear commit message"

# Push to GitHub
git push origin main
```

## Common Commands

### View remote configuration
```bash
git remote -v
```

### Update local repo from GitHub
```bash
git pull origin main
```

### Create a new branch for features
```bash
git checkout -b feature/my-feature
git push -u origin feature/my-feature
```

## Troubleshooting

### Authentication Issues

**Error**: `fatal: Authentication failed`

**Solution**: 
- Use HTTPS with personal access token, or
- Setup SSH keys at https://github.com/settings/keys, or
- Use GitHub CLI: `gh auth login`

### Remote Already Exists

**Error**: `fatal: remote origin already exists`

**Solution**:
```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/SAML.jl.git
```

### Push to Wrong Branch

**Error**: Want to push to `main` but accidentally on `master`

**Solution**:
```bash
git branch -M main
git push -u origin main
```

## Release Workflow

When you're ready to release version 1.0.0:

```bash
# Update Project.toml version
# Update CHANGELOG.md

# Commit
git add .
git commit -m "Release v1.0.0"

# Create tag
git tag v1.0.0

# Push
git push origin main
git push origin v1.0.0

# Create GitHub Release at:
# https://github.com/YOUR_USERNAME/SAML.jl/releases/new
```

## Registering with Julia Registry

Once your package is on GitHub, you can register it with the Julia General Registry:

1. Go to https://github.com/JuliaRegistries/General
2. Follow instructions to open a PR for registration
3. Once approved, users can install with:
   ```julia
   using Pkg
   Pkg.add("SAML")
   ```

## Getting Help

- GitHub Docs: https://docs.github.com
- Git Docs: https://git-scm.com/doc
- Julia Package Guide: https://pkgdocs.julialang.org

---

## Quick Summary

```bash
# 1. Create repository on GitHub at https://github.com/new

# 2. Push local repository
cd "c:\Users\K\Projects\SAMLClient"
git remote add origin https://github.com/YOUR_USERNAME/SAML.jl.git
git branch -M main
git push -u origin main

# 3. Verify at https://github.com/YOUR_USERNAME/SAML.jl

# Done! Your code is now on GitHub!
```

Replace `YOUR_USERNAME` with your actual GitHub username.
