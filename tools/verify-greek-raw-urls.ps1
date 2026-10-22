param(
    [Parameter(Mandatory)]
    [string]$RepositoryCommit,
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path (Split-Path -Parent $PSCommandPath) 'greek/raw-url-report.csv'
}
$pending = @(Import-Csv -LiteralPath $ReportPath)
if ($pending.Count -ne 218) { throw "Expected 218 Raw URL rows, found $($pending.Count)" }

$checkedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK')
$results = foreach ($row in $pending) {
    try {
        $response = Invoke-WebRequest -Uri $row.raw_url -Method Head -MaximumRedirection 5 -TimeoutSec 30
        [PSCustomObject]@{
            asset_code = $row.asset_code
            repository = $row.repository
            branch = $row.branch
            repository_commit = $RepositoryCommit
            path = $row.path
            raw_url = $row.raw_url
            http_method = 'HEAD'
            http_status = [string]$response.StatusCode
            content_type = [string]$response.Headers['Content-Type']
            checked_at_kst = $checkedAt
            check_status = if ($response.StatusCode -eq 200 -and $response.Headers['Content-Type'] -match '^image/webp(?:;|$)') { 'verified' } else { 'failed' }
            notes = ''
        }
    } catch {
        [PSCustomObject]@{
            asset_code = $row.asset_code
            repository = $row.repository
            branch = $row.branch
            repository_commit = $RepositoryCommit
            path = $row.path
            raw_url = $row.raw_url
            http_method = 'HEAD'
            http_status = ''
            content_type = ''
            checked_at_kst = $checkedAt
            check_status = 'failed'
            notes = $_.Exception.Message.Replace("`r", ' ').Replace("`n", ' ')
        }
    }
}

$failed = @($results | Where-Object { $_.check_status -ne 'verified' })
if ($failed.Count) {
    $summary = $failed | Select-Object -First 5 | ForEach-Object { "$($_.asset_code): status=$($_.http_status) type=$($_.content_type) $($_.notes)" }
    throw "Raw verification failed for $($failed.Count) row(s): $($summary -join '; ')"
}

$results | Export-Csv -LiteralPath $ReportPath -NoTypeInformation -Encoding utf8BOM
Write-Output "RAW_URLS_VERIFIED: rows=$($results.Count) commit=$RepositoryCommit checked_at_kst=$checkedAt"
