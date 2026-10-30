#==================================================================================================================
#==================================================================================================================
# Build - Test Image
#
# Builds the test image (the Dockerfile's "test" target) and tags it atomicvlm:test. Includes the module folders
# in test-modules (see test-modules/README.md). Can be run from any folder.
#
#   pwsh ./build/build-test.ps1
#==================================================================================================================
#==================================================================================================================

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Path $PSScriptRoot -Parent
$dockerfile  = Join-Path -Path $projectRoot -ChildPath 'Dockerfile'
$imageTag    = 'atomicvlm:test'

docker info --format '{{.ServerVersion}}' *> $null
if ( $LASTEXITCODE -ne 0 ) { throw 'Docker is not running. Start Docker and try again.' }

Write-Host $( 'Building {0} (target: test) from {1}' -f $imageTag, $projectRoot )

docker build --target test --tag $imageTag --file $dockerfile $projectRoot
if ( $LASTEXITCODE -ne 0 ) { throw $( 'Docker build failed for {0}.' -f $imageTag ) }

Write-Host $( 'Built {0}' -f $imageTag ) -ForegroundColor Green
