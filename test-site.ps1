$ErrorActionPreference = 'Stop'

$indexPath = Join-Path $PSScriptRoot 'index.html'
$prsPath = Join-Path $PSScriptRoot 'prs.html'
$cssPath = Join-Path $PSScriptRoot 'style.css'

foreach ($path in @($indexPath, $prsPath, $cssPath)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing site file: $path" }
}

$index = Get-Content -LiteralPath $indexPath -Raw -Encoding utf8
$prs = Get-Content -LiteralPath $prsPath -Raw -Encoding utf8
$css = Get-Content -LiteralPath $cssPath -Raw -Encoding utf8

if ($css -notmatch '^body\s*\{') { throw 'Stylesheet must begin with the body selector.' }

foreach ($page in @($index, $prs)) {
    if ($page -notmatch '<!doctype html>') { throw 'Page is not a complete HTML document.' }
    if ($page -notmatch '<meta name="viewport"') { throw 'Page is missing its viewport declaration.' }
    if ($page -notmatch '<link rel="stylesheet" href="style\.css">') { throw 'Page does not load the shared stylesheet.' }
    if ($page -notmatch '<a class="skip-link" href="#main">Skip to content</a>') { throw 'Page is missing its skip link.' }
    if ($page -notmatch '<main id="main">') { throw 'Page main content is not a skip-link target.' }
    if ($page -match 'target="_blank"') { throw 'New-tab links must not open without warning.' }
}

if ($index -notmatch 'href="prs\.html"[^>]*>View all merged PRs</a>') {
    throw 'Homepage does not link to the local PR archive.'
}
if ($index -match 'github\.com/search\?q=') { throw 'Homepage still links to GitHub search.' }

$entries = ([regex]::Matches($prs, 'class="pr-entry"')).Count
$problems = ([regex]::Matches($prs, '<strong>Problem:</strong>')).Count
$fixes = ([regex]::Matches($prs, '<strong>Fix:</strong>')).Count
$links = [regex]::Matches($prs, 'https://github\.com/[^"\s]+/pull/\d+') | ForEach-Object Value | Sort-Object -Unique

if ($entries -ne 31) { throw "Expected 31 PR entries, found $entries." }
if ($problems -ne $entries) { throw "Expected one problem summary per PR, found $problems." }
if ($fixes -ne $entries) { throw "Expected one fix summary per PR, found $fixes." }
if ($links.Count -ne $entries) { throw "Expected 31 unique PR links, found $($links.Count)." }
if ($prs -notmatch 'https://github\.com/triton-lang/triton/pull/11720') { throw 'Latest merged Triton PR is missing.' }
if ($index -match 'after diagonal extraction') { throw 'tinygrad summary describes the fix at the wrong stage.' }

'Site checks passed.'
