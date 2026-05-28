# Renumber TODO.md ranked handoff entries sequentially
# Run from workspace root: pwsh .agents/skills/reorder-todo/scripts/reorder-todo.ps1

$todoPath = Join-Path $PSScriptRoot "..\..\..\..\TODO.md"
$content = Get-Content -Path $todoPath -Raw
# Detect original line ending style to preserve it
$lineEnding = if ($content -match "`r`n") { "`r`n" } else { "`n" }
$lines = $content -split "`r?`n"

$inRankedSection = $false
$newLines = @()
$counter = 1

foreach ($line in $lines) {
    if ($line -match "^## Ranked handoffs") {
        $inRankedSection = $true
        $newLines += $line
        continue
    }

    if ($inRankedSection) {
        if ($line -match "^\d+\.\s") {
            # Renumber this line
            $rest = $line -replace "^\d+\.\s*", ""
            if ($rest -ne "") {
                $newLines += "$counter. $rest"
                $counter++
            } else {
                $newLines += $line
            }
            continue
        }
        # Blank lines, notes, or other non-numbered lines — exit section if next header
        if ($line -match "^## ") {
            $inRankedSection = $false
        }
        $newLines += $line
        continue
    }

    $newLines += $line
}

$newContent = $newLines -join $lineEnding
Set-Content -Path $todoPath -Value $newContent -NoNewline
Write-Host "Done. Renumbered $($counter-1) entries."
