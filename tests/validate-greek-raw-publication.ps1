param(
    [Parameter(Mandatory)]
    [string]$RepositoryCommit
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$report = @(Import-Csv -LiteralPath (Join-Path $root 'greek/raw-url-report.csv'))

if ($report.Count -ne 218) { throw "expected 218 Raw URL rows, found $($report.Count)" }
if (($report | Where-Object { $_.repository_commit -ne $RepositoryCommit }).Count) { throw 'Raw report does not cite the pushed asset commit' }
if (($report | Where-Object { $_.http_method -ne 'HEAD' }).Count) { throw 'Raw report must use HEAD checks' }
if (($report | Where-Object { $_.http_status -ne '200' }).Count) { throw 'not every Raw URL returned HTTP 200' }
if (($report | Where-Object { $_.content_type -notmatch '^image/webp(?:;|$)' }).Count) { throw 'not every Raw URL returned image/webp' }
if (($report | Where-Object { $_.check_status -ne 'verified' }).Count) { throw 'not every Raw URL is marked verified' }
if (($report | Where-Object { [string]::IsNullOrWhiteSpace($_.checked_at_kst) }).Count) { throw 'Raw URL checks require a KST timestamp' }

Write-Output "PASS: Greek Raw publication contract is complete for $RepositoryCommit."
