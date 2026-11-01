#==================================================================================================================
#==================================================================================================================
# Run - Dev Image
#
# Starts a container from the dev image with a PowerShell session, and removes the container when the session
# ends. The po.AtomicVLM source folder is mapped over the image's empty po.AtomicVLM module folder, so the
# container loads the module straight from its source; the mapping is read-write, so changes on either side are
# visible on both. Edit the variables below, then run this file.
#==================================================================================================================
#==================================================================================================================
# exFAT volumes on macOS: set Docker Desktop's file sharing implementation to gRPC FUSE (Settings > General).
# With the default, VirtioFS, a container can't reopen or overwrite files it has just written on an exFAT volume.
# The reopen fails with ENOENT, and overwrites fail with "Input/output error" or "File exists". This breaks:
#   - Metadata updates (Update-avlmMovieFiles): AtomicParsley crashes (exit 139) during its in-place update.
#     The original file is left unchanged, and a "<name>-data-<pid>.m4v" temp file is left next to it.
#   - Thumbnails: ffmpeg can't overwrite an existing thumbnail (exit 251), so ThumbnailPath is left empty.
#   - Any other overwrite of an existing file, such as library.xml.
# APFS volumes work with either setting. gRPC FUSE is slower than VirtioFS and applies to all containers.
#==================================================================================================================
#==================================================================================================================

  # The image to run.
    $ImageTag = 'atomicvlm:dev'

  # The folder on this computer that is mapped to /AtomicVLM in the container.
    $AtomicVLMPath = '/Users/sean/AtomicVLM-Docker'

  # The movie and TV show folders on this computer, mapped to /media/movies and /media/tv in the container.
    $MoviesPath = '/Volumes/Mobile 4TB2/Media/Movies/! Tag'
    $TVPath     = '/Volumes/Media/TV Shows'

  # The web server port on this computer, mapped to the AtomicVLM web server's port in the container.
    $HostPort      = 80
    $ContainerPort = 80

  # The po.AtomicVLM module source folder on this computer, and where it is mapped in the container.
    $ModulePath          = '/Users/sean/Repos/@psModules/PowerShell-AtomicVLM/po.AtomicVLM'
    $ContainerModulePath = '/usr/local/share/powershell/Modules/po.AtomicVLM'

#==================================================================================================================
# Run the container
#==================================================================================================================

    $ErrorActionPreference = 'Stop'

  # Check that Docker is running and the image has been built.
    docker info --format '{{.ServerVersion}}' *> $null
    if ( $LASTEXITCODE -ne 0 ) { throw 'Docker is not running. Start Docker and try again.' }

    docker image inspect $ImageTag *> $null
    if ( $LASTEXITCODE -ne 0 ) { throw $( 'Image {0} not found. Build it first.' -f $ImageTag ) }

  # docker run creates missing host folders instead of failing, so check both exist to catch typos.
    if ( -not ( Test-Path -LiteralPath $AtomicVLMPath -PathType Container ) ) {
        throw $( 'AtomicVLM folder not found: {0}' -f $AtomicVLMPath )
    }
    if ( -not ( Test-Path -LiteralPath $MoviesPath -PathType Container ) ) {
        throw $( 'Movies folder not found: {0}' -f $MoviesPath )
    }
    if ( -not ( Test-Path -LiteralPath $TVPath -PathType Container ) ) {
        throw $( 'TV folder not found: {0}' -f $TVPath )
    }
    if ( -not ( Test-Path -LiteralPath ( Join-Path -Path $ModulePath -ChildPath 'po.AtomicVLM.psd1' ) -PathType Leaf ) ) {
        throw $( 'po.AtomicVLM module not found (no po.AtomicVLM.psd1) in: {0}' -f $ModulePath )
    }

  # Use an interactive terminal unless commands are piped in.
    $interactive = @( if ( [Console]::IsInputRedirected ) { '-i' } else { '-it' } )

    Write-Host $( 'Running {0}'            -f $ImageTag )
    Write-Host $( '  {0} -> /AtomicVLM'    -f $AtomicVLMPath )
    Write-Host $( '  {0} -> /media/movies' -f $MoviesPath )
    Write-Host $( '  {0} -> /media/tv'     -f $TVPath )
    Write-Host $( '  port {0} -> port {1}' -f $HostPort, $ContainerPort )
    Write-Host '  env AVLM_USE_ALPHA_METADATA_PROVIDERS=True'
    Write-Host $( '  {0} -> {1}' -f $ModulePath, $ContainerModulePath )

    docker run --rm @interactive `
        --volume "${AtomicVLMPath}:/AtomicVLM" `
        --volume "${MoviesPath}:/Media/Movies" `
        --volume "${TVPath}:/Media/TV" `
        --volume "${ModulePath}:${ContainerModulePath}" `
        --publish "${HostPort}:${ContainerPort}" `
        --env "AVLM_USE_ALPHA_METADATA_PROVIDERS=True" `
        $ImageTag
