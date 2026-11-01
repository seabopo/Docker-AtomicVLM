#==================================================================================================================
#==================================================================================================================
# Run - Production Image
#
# Starts a container from the production image with a PowerShell session, and removes the container when the
# session ends. Edit the variables below, then run this file.
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
    $ImageTag = 'atomicvlm:latest'

  # The folder on this computer that is mapped to /AtomicVLM in the container.
    $AtomicVLMPath = '/Volumes/Media/AtomicVLM'

  # The movie and TV show folders on this computer, mapped to /media/movies and /media/tv in the container.
    $MoviesPath = '/Volumes/Media/Movies'
    $TVPath     = '/Volumes/Media/TV Shows'

  # The web server port on this computer, mapped to the AtomicVLM web server's port in the container.
    $HostPort      = 80
    $ContainerPort = 80

#==================================================================================================================
# Run the container
#==================================================================================================================

    $ErrorActionPreference = 'Stop'

  # Check that Docker is running and the image has been built.
    docker info --format '{{.ServerVersion}}' *> $null
    if ( $LASTEXITCODE -ne 0 ) { throw 'Docker is not running. Start Docker and try again.' }

    docker image inspect $ImageTag *> $null
    if ( $LASTEXITCODE -ne 0 ) { throw $( 'Image {0} not found. Build it first.' -f $ImageTag ) }

  # docker run creates a missing host folder instead of failing, so check it exists to catch typos.
    if ( -not ( Test-Path -LiteralPath $AtomicVLMPath -PathType Container ) ) {
        throw $( 'AtomicVLM folder not found: {0}' -f $AtomicVLMPath )
    }
    if ( -not ( Test-Path -LiteralPath $MoviesPath -PathType Container ) ) {
        throw $( 'Movies folder not found: {0}' -f $MoviesPath )
    }
    if ( -not ( Test-Path -LiteralPath $TVPath -PathType Container ) ) {
        throw $( 'TV folder not found: {0}' -f $TVPath )
    }

  # Use an interactive terminal unless commands are piped in.
    $interactive = @( if ( [Console]::IsInputRedirected ) { '-i' } else { '-it' } )

    Write-Host $( 'Running {0}' -f $ImageTag )
    Write-Host $( '  {0} -> /AtomicVLM' -f $AtomicVLMPath )
    Write-Host $( '  {0} -> /media/movies' -f $MoviesPath )
    Write-Host $( '  {0} -> /media/tv' -f $TVPath )
    Write-Host $( '  port {0} -> port {1}' -f $HostPort, $ContainerPort )

    docker run --rm @interactive `
        --volume "${AtomicVLMPath}:/AtomicVLM" `
        --volume "${MoviesPath}:/media/movies" `
        --volume "${TVPath}:/media/tv" `
        --publish "${HostPort}:${ContainerPort}" `
        $ImageTag
