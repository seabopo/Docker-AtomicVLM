#==================================================================================================================
#==================================================================================================================
# Test - MediaFile
#
# For each media file listed in a CSV file, creates a MediaFile object (po.MediaClasses) inside the AtomicVLM
# image and confirms it is populated by both command-line tools:
#   - Tags     : read by AtomicParsley (po.AtomicParsley)
#   - Encoding : read by MediaInfo     (po.MediaInfo)
#
# The MediaFile object for each file is written as JSON next to the original file, with the same name and a
# .json extension (for example, "Movie (2019).m4v" -> "Movie (2019).json"). Existing JSON files are overwritten.
#
# CSV format: a header row with a "Path" column, then one media file path per row. Paths are paths inside the
# container (for example, under /media). Blank rows are ignored. See tests/test-files.csv.
#
# Run from the root of this repository, after building the image (docker build -t atomicvlm .). The media folder
# is mounted read-write so the JSON files can be written; the tests folder is mounted read-only:
#
#   docker run --rm \
#       -v "/Users/sean/Repos/@psModules/sample-media:/media" \
#       -v "$PWD/tests:/tests:ro" \
#       atomicvlm pwsh -NoLogo -NoProfile -File /tests/Test-MediaFile.ps1
#
# Pass -CsvPath to use a different CSV file (a path inside the container). Exits 0 if every check passes for
# every file, 1 otherwise.
#==================================================================================================================
#==================================================================================================================

param (
    [String] $CsvPath = '/tests/test-files.csv'
)

$ErrorActionPreference = 'Stop'

Import-Module -Name po.MediaClasses

$failures = [System.Collections.Generic.List[String]]::new()

function Test-Check {
    param ( [String] $File, [String] $Name, [Bool] $Passed, [String] $Detail )
    if ( $Passed ) { Write-Host $( '  PASS  {0}  {1}' -f $Name, $Detail ) -ForegroundColor Green }
    else           { Write-Host $( '  FAIL  {0}  {1}' -f $Name, $Detail ) -ForegroundColor Red; $failures.Add($( '{0}: {1}' -f $File, $Name.Trim() )) }
}

#==================================================================================================================
# Load the list of test files
#==================================================================================================================

    if ( -not ( Test-Path -LiteralPath $CsvPath ) ) {
        Write-Host $( 'CSV file not found: {0}' -f $CsvPath ) -ForegroundColor Red
        exit 1
    }

    $testFiles = @( Import-Csv -LiteralPath $CsvPath | Where-Object { -not [String]::IsNullOrWhiteSpace($_.Path) } )

    if ( $testFiles.Count -eq 0 ) {
        Write-Host $( 'No test files found in {0}. The CSV needs a "Path" column.' -f $CsvPath ) -ForegroundColor Red
        exit 1
    }

#==================================================================================================================
# Check that the command-line tools are available
#==================================================================================================================

    Write-Host ''
    Write-Host 'Command-line tools:'

    Test-Check -File '(tools)' -Name 'AtomicParsley on PATH   ' -Passed ( [bool](Get-Command -Name AtomicParsley -ErrorAction Ignore) ) `
               -Detail $( (Get-Command -Name AtomicParsley -ErrorAction Ignore).Source )
    Test-Check -File '(tools)' -Name 'MediaInfo on PATH       ' -Passed ( [bool](Get-Command -Name mediainfo -ErrorAction Ignore) ) `
               -Detail $( (Get-Command -Name mediainfo -ErrorAction Ignore).Source )

#==================================================================================================================
# Build and check a MediaFile object for each test file
#==================================================================================================================

    foreach ( $testFile in $testFiles ) {

        $mp = $testFile.Path.Trim()

        Write-Msg -h -ps -bb -m $( ' Test Media File: {0}' -f (Split-Path -Path $mp -Leaf) )

        if ( -not ( Test-Path -LiteralPath $mp ) ) {
            Test-Check -File $mp -Name 'File exists             ' -Passed $false -Detail $mp
            continue
        }

        $e = [MediaFile]::new($mp)
        $r = Read-AtomicParsleyAtoms -File $($mp)
        if ( $r.success ) { $e.SetTags($r.value) } else { Write-Msg -e -il 2 -m $r.message }
        $r = Get-MediaInfoSummary -File $($mp)
        if ( $r.success ) { $e.SetEncoding($r.value) } else { Write-Msg -e -il 2 -m $r.message }
        Write-Msg -a -o $e

      # Write the MediaFile object as JSON next to the original file.
        $jsonPath = [System.IO.Path]::ChangeExtension($mp, '.json')
        $jsonError = $null
        try {
            $e | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $jsonPath -Encoding utf8
        }
        catch {
            $jsonError = $_.Exception.Message
        }

        Write-Host ''
        Write-Host 'Results:'
        Test-Check -File $mp -Name 'File exists             ' -Passed $true -Detail $mp
        Test-Check -File $mp -Name 'Tags set (AtomicParsley)' -Passed ( $null -ne $e.Tags -and $e.Tags.Count -gt 0 ) `
                   -Detail $( 'Title: {0}' -f $e.Tags.Title )
        Test-Check -File $mp -Name 'Encoding set (MediaInfo)' -Passed ( -not [String]::IsNullOrWhiteSpace($e.Encoding.Video.ResolutionTag) ) `
                   -Detail $( 'ProfileTag: {0}' -f $e.Encoding.ProfileTag )
        Test-Check -File $mp -Name 'JSON written            ' -Passed ( $null -eq $jsonError -and ( Test-Path -LiteralPath $jsonPath ) ) `
                   -Detail $( $jsonError ?? $jsonPath )
    }

#==================================================================================================================
# Summary
#==================================================================================================================

    Write-Host ''
    if ( $failures.Count -eq 0 ) {
        Write-Host $( 'All MediaFile checks passed for {0} file(s).' -f $testFiles.Count ) -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host $( '{0} MediaFile check(s) failed:' -f $failures.Count ) -ForegroundColor Red
        $failures | ForEach-Object { Write-Host $( '  - {0}' -f $_ ) -ForegroundColor Red }
        exit 1
    }
