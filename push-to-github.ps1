# Push this folder to GitHub.
# Usage:  pwsh -File .\push-to-github.ps1
#         pwsh -File .\push-to-github.ps1 -RepoName my-repo -Visibility private
param(
    [string]$RepoName = "alchemytable-cc",
    [ValidateSet("public", "private")][string]$Visibility = "public",
    [string]$GitUserName = "",
    [string]$GitUserEmail = ""
)

if (Test-Path variable:PSNativeCommandUseErrorActionPreference) { $PSNativeCommandUseErrorActionPreference = $false }
$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git not found. Install it first: https://git-scm.com/download/win"
}

# ---- git identity ----------------------------------------------------------
if (-not (git config --global user.name)) {
    if (-not $GitUserName) { $GitUserName = Read-Host "git user.name (your GitHub username or nickname)" }
    git config --global user.name $GitUserName
}
if (-not (git config --global user.email)) {
    if (-not $GitUserEmail) { $GitUserEmail = Read-Host "git user.email" }
    git config --global user.email $GitUserEmail
}

# ---- local repo ------------------------------------------------------------
if (-not (Test-Path (Join-Path $PWD ".git"))) {
    git init -b main *> $null
    if ($LASTEXITCODE -ne 0) { git init *> $null }   # older git without -b
}
git add .
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -m "Add CC:Tweaked alchemy table automation script" *> $null
    Write-Host "[ok] committed local changes"
} else {
    Write-Host "[skip] nothing new to commit"
}

# ---- remote ----------------------------------------------------------------
if (Get-Command gh -ErrorAction SilentlyContinue) {
    gh auth status *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "GitHub CLI is not logged in, starting 'gh auth login' ..."
        gh auth login
    }
    gh repo create $RepoName "--$Visibility" --source=. --remote=origin --push
    if ($LASTEXITCODE -ne 0) { throw "gh repo create failed (repo name taken? not logged in?)" }
    Write-Host "[ok] created and pushed: https://github.com/<your-name>/$RepoName"
} else {
    Write-Host "GitHub CLI (gh) not found - using plain git."
    Write-Host "Create an EMPTY repository on https://github.com/new first (do NOT add a README)."
    $user = Read-Host "GitHub username"
    $repo = Read-Host "Repository name"
    git remote remove origin *> $null
    git remote add origin "https://github.com/$user/$repo.git"
    git branch -M main
    Write-Host "When asked for a password, paste a Personal Access Token (classic, scope: repo)."
    git push -u origin main
    if ($LASTEXITCODE -ne 0) { throw "git push failed. Check the token / repository name." }
    Write-Host "[ok] pushed: https://github.com/$user/$repo"
}
