#==================================================================================================================
#==================================================================================================================
# Docker Login - GitHub Container Registry
#
# Logs docker in to ghcr.io so the private AtomicVLM images can be pulled (see run-test-ghcr.ps1). Uses a
# classic personal access token with the read:packages scope, read from the environment variable named below, and
# passes it to docker on stdin so it doesn't appear in the process list. Docker stores the credentials, so this only
# needs to be run once, or again when the token expires. The variable is set by _init_token.ps1 in this folder,
# which this script runs first. That file holds the token, so it is git-ignored; create it yourself with one line:
# $env:GHCR_TOKEN = '<token>'. Edit the variables below, then run this file.
#
# Create the token at https://github.com/settings/tokens (Tokens (classic) > Generate new token (classic)).
#==================================================================================================================
#==================================================================================================================

  # The registry to log in to, the GitHub user name that owns the token, and the environment variable that holds it.
    $Registry      = 'ghcr.io'
    $UserName      = 'seabopo'
    $TokenVariable = 'GHCR_TOKEN'

#==================================================================================================================
# Log in
#==================================================================================================================

    $ErrorActionPreference = 'Stop'

  # Check that Docker is running.
    docker info --format '{{.ServerVersion}}' *> $null
    if ( $LASTEXITCODE -ne 0 ) { throw 'Docker is not running. Start Docker and try again.' }

  # Run the git-ignored init file, which sets the token's environment variable for this session.
    $initPath = Join-Path -Path $PSScriptRoot -ChildPath '_init_token.ps1'
    if ( -not ( Test-Path -LiteralPath $initPath -PathType Leaf ) ) {
        throw $( 'Token init file not found: {0}. Create it and set $env:{1} to a personal access token with the read:packages scope.' -f $initPath, $TokenVariable )
    }
    . $initPath

    $token = [System.Environment]::GetEnvironmentVariable( $TokenVariable )
    if ( [string]::IsNullOrWhiteSpace( $token ) ) {
        throw $( 'Environment variable {0} is not set by {1}.' -f $TokenVariable, $initPath )
    }

    Write-Host $( 'Logging in to {0} as {1}' -f $Registry, $UserName )

    $token | docker login $Registry --username $UserName --password-stdin
    if ( $LASTEXITCODE -ne 0 ) { throw $( 'Docker login to {0} failed.' -f $Registry ) }

    Write-Host $( 'Logged in to {0}' -f $Registry ) -ForegroundColor Green
