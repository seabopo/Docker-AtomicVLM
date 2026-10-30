#==================================================================================================================
#==================================================================================================================
# Build - Production Image
#
# Builds the production image (the Dockerfile's default "production" target) and tags it atomicvlm:latest.
# Test modules are never included. Can be run from any folder.
#
#   pwsh ./build/build-production.ps1
#==================================================================================================================
#==================================================================================================================

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Path $PSScriptRoot -Parent
$dockerfile  = Join-Path -Path $projectRoot -ChildPath 'Dockerfile'
$imageTag    = 'atomicvlm:latest'

docker info --format '{{.ServerVersion}}' *> $null
if ( $LASTEXITCODE -ne 0 ) { throw 'Docker is not running. Start Docker and try again.' }

Write-Host $( 'Building {0} (target: production) from {1}' -f $imageTag, $projectRoot )

docker build --target production --tag $imageTag --file $dockerfile $projectRoot
if ( $LASTEXITCODE -ne 0 ) { throw $( 'Docker build failed for {0}.' -f $imageTag ) }

Write-Host $( 'Built {0}' -f $imageTag ) -ForegroundColor Green
