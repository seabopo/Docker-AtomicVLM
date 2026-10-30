#==================================================================================================================
#==================================================================================================================
# Build - Dev Image
#
# Builds the dev image (the Dockerfile's "dev" target) and tags it atomicvlm:dev. Includes the module folders in
# test-modules (see test-modules/README.md) and the dev stage's development-only commands. Can be run from any
# folder.
#
#   pwsh ./build/build-dev.ps1
#==================================================================================================================
#==================================================================================================================

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Path $PSScriptRoot -Parent
$dockerfile  = Join-Path -Path $projectRoot -ChildPath 'Dockerfile'
$imageTag    = 'atomicvlm:dev'

docker info --format '{{.ServerVersion}}' *> $null
if ( $LASTEXITCODE -ne 0 ) { throw 'Docker is not running. Start Docker and try again.' }

Write-Host $( 'Building {0} (target: dev) from {1}' -f $imageTag, $projectRoot )

docker build --target dev --tag $imageTag --file $dockerfile $projectRoot
if ( $LASTEXITCODE -ne 0 ) { throw $( 'Docker build failed for {0}.' -f $imageTag ) }

Write-Host $( 'Built {0}' -f $imageTag ) -ForegroundColor Green
