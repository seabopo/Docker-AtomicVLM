#==================================================================================================================
# AtomicVLM - Docker Image
#
# Base image : .NET 10 SDK on Ubuntu 24.04 (Noble), which includes PowerShell.
# CLI tools  : MediaInfo (from MediaArea's apt repository).
#              FFmpeg (ffmpeg, ffprobe, from the Ubuntu archive).
#              AtomicParsley (compiled from its upstream release source during the build).
# Modules    : po.AtomicVLM
#              po.Toolkit       from the PowerShell Gallery.
#              po.MediaInfo     from the PowerShell Gallery.
#              po.FFMPEG        from the PowerShell Gallery.
#              po.AtomicParsley from the PowerShell Gallery.
#              po.MediaClasses  from the PowerShell Gallery.
#              po.TMDB          from the PowerShell Gallery.
# Licenses   : /usr/share/licenses/atomicvlm/ (see THIRD_PARTY_NOTICES.md).
#
# Build targets:
#   production : the default (last stage). Everything in the base stage, nothing else.
#                  docker build -t atomicvlm .
#   test       : the base stage plus the module folders in test-modules (see test-modules/README.md).
#                  docker build --target test -t atomicvlm:test .
#   dev        : a copy of the test stage, for additional development-only commands.
#                  docker build --target dev -t atomicvlm:dev .
#==================================================================================================================

#------------------------------------------------------------------------------------------------------------------
# Build stage: AtomicParsley
#
# Compiles AtomicParsley from the official release tag at https://github.com/wez/atomicparsley. Upstream only
# publishes a prebuilt Linux binary for x86-64, so compiling it here gives the same version on amd64 and arm64.
# The compiler and source stay in this stage; only the AtomicParsley executable and its license files are copied
# into the final image. Update THIRD_PARTY_NOTICES.md and SOURCE_OFFER.md when the version changes.
#------------------------------------------------------------------------------------------------------------------

FROM mcr.microsoft.com/dotnet/sdk:10.0-noble AS atomicparsley

ARG ATOMICPARSLEY_VERSION=20240608.083822.1ed9031

RUN apt-get update \
 && apt-get install -y --no-install-recommends cmake g++ make zlib1g-dev \
 && git clone --depth 1 --branch "${ATOMICPARSLEY_VERSION}" https://github.com/wez/atomicparsley.git /src \
 && cmake -S /src -B /build -DCMAKE_BUILD_TYPE=Release \
 && cmake --build /build --parallel

#------------------------------------------------------------------------------------------------------------------
# Base stage: everything shared by the production and test images
#------------------------------------------------------------------------------------------------------------------

FROM mcr.microsoft.com/dotnet/sdk:10.0-noble AS base

# MediaInfo versions from MediaArea's repository (https://mediaarea.net/en/Repos). Update THIRD_PARTY_NOTICES.md
# when these change.
ARG MEDIAAREA_REPO_VERSION=1.0-26
ARG MEDIAINFO_VERSION=26.05-1
ARG ZENLIB_VERSION=0.4.41-1

LABEL org.opencontainers.image.title="AtomicVLM" \
      org.opencontainers.image.description="PowerShell media tools with MediaInfo, FFmpeg and AtomicParsley." \
      org.opencontainers.image.source="https://github.com/seabopo/Docker-AtomicVLM" \
      org.opencontainers.image.licenses="MIT AND BSD-2-Clause AND Zlib AND curl AND GPL-2.0-or-later AND LGPL-2.1-or-later"

#------------------------------------------------------------------------------------------------------------------
# Command-line tools
#
# AtomicParsley is copied from the build stage into /usr/local/bin, with its upstream COPYING and CREDITS files in
# /usr/share/doc/atomicparsley/.
#
# MediaInfo comes from MediaArea's own apt repository, which publishes current releases for Ubuntu 24.04; the Ubuntu
# archive only has MediaInfo 24.01. The repo-mediaarea package installs MediaArea's signing key and apt source.
# The mediainfo, libmediainfo0v5 and libzen0v5 packages are pinned to the versions above.
#
# The executables are in /usr/bin and /usr/local/bin, which are already on the PATH, so each tool can be called
# by name (mediainfo, ffmpeg, ffprobe, AtomicParsley). The check at the end fails the build if any name
# the PowerShell modules call does not resolve.
#
# /usr/share/doc/<package>/copyright files are kept; the license notices rely on them.
#------------------------------------------------------------------------------------------------------------------

COPY --from=atomicparsley /build/AtomicParsley /usr/local/bin/AtomicParsley
COPY --from=atomicparsley /src/COPYING /src/CREDITS /usr/share/doc/atomicparsley/

RUN curl -fsSLo /tmp/repo-mediaarea.deb \
        "https://mediaarea.net/repo/deb/repo-mediaarea_${MEDIAAREA_REPO_VERSION}_all.deb" \
 && apt-get update \
 && apt-get install -y --no-install-recommends /tmp/repo-mediaarea.deb \
 && rm /tmp/repo-mediaarea.deb \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
        "mediainfo=${MEDIAINFO_VERSION}" \
        "libmediainfo0v5=${MEDIAINFO_VERSION}" \
        "libzen0v5=${ZENLIB_VERSION}" \
        ffmpeg \
 && rm -rf /var/lib/apt/lists/* \
 && for tool in mediainfo ffmpeg ffprobe AtomicParsley; do \
        command -v "$tool" || { echo "ERROR: '$tool' is not on the PATH." >&2; exit 1; }; \
    done \
 && mediainfo --version \
 && ffmpeg -hide_banner -version | head -n 1 \
 && AtomicParsley --version

#------------------------------------------------------------------------------------------------------------------
# PowerShell modules
#
# Installed for all users (/usr/local/share/powershell/Modules), which is on every user's PSModulePath.
# Importing po.MediaClasses afterwards loads po.Toolkit, po.AtomicParsley and po.MediaInfo as dependencies and
# confirms the modules load; po.FFMPEG and po.TMDB are imported to confirm they load too.
#
# po.TMDB calls the TMDB API, which needs an API key. No key is included in the image; each user supplies their own
# at runtime (see THIRD_PARTY_NOTICES.md for TMDB's terms of use).
#
# PowerShell does not auto-load classes the way it auto-loads functions, so po.MediaClasses must be imported
# explicitly before its classes ([MediaFile], [Movie], etc.) can be used. The all-users, all-hosts profile
# ($PROFILE.AllUsersAllHosts, under $PSHOME) imports it at the start of every PowerShell session for every user.
# Its path includes the PowerShell version and CPU architecture, so it is resolved at build time. Sessions started
# with -NoProfile skip the profile and must import the module themselves.
#------------------------------------------------------------------------------------------------------------------

RUN pwsh -NoLogo -NoProfile -Command " \
        \$ErrorActionPreference = 'Stop'; \
        Install-PSResource -Name po.Toolkit, po.AtomicParsley, po.MediaInfo, po.MediaClasses, po.FFMPEG, po.TMDB \
                           -Repository PSGallery -Scope AllUsers -TrustRepository; \
        Import-Module -Name po.Toolkit; \
        Import-Module -Name po.AtomicParsley; \
        Import-Module -Name po.MediaInfo; \
        Import-Module -Name po.MediaClasses; \
        Import-Module -Name po.FFMPEG; \
        Import-Module -Name po.TMDB; \
        Get-Module -Name po.* | Format-Table -Property Name, Version -AutoSize; \
        Add-Content -Path \$PROFILE.AllUsersAllHosts -Value 'Import-Module -Name po.MediaClasses'; \
        Write-Host ('All-users profile: {0}' -f \$PROFILE.AllUsersAllHosts) \
    "

#------------------------------------------------------------------------------------------------------------------
# AtomicVLM and media folders
#
# /AtomicVLM is the mount point for external storage, mapped at runtime (for example, -v /host/path:/AtomicVLM).
# /media is the mount point for media files (for example, -v /host/media:/media). Ubuntu's base image already has
# an empty /media folder; it is created here too so the Dockerfile documents it as an expected mount point.
# Docker would create both at mount time anyway. Anything the image put in these folders would be hidden by the
# mounts, so they are left empty.
#------------------------------------------------------------------------------------------------------------------

RUN mkdir -p /AtomicVLM /Media

#------------------------------------------------------------------------------------------------------------------
# Licenses and third-party notices
#------------------------------------------------------------------------------------------------------------------

COPY LICENSE \
     THIRD_PARTY_NOTICES.md \
     SOURCE_OFFER.md \
     MEDIAINFO_LICENSE \
     FFMPEG_LICENSE.md \
     ATOMICPARSLEY_LICENSE \
     /usr/share/licenses/atomicvlm/
COPY licenses/ /usr/share/licenses/atomicvlm/licenses/

#------------------------------------------------------------------------------------------------------------------
# Start command
#
# Starts the AtomicVLM services (po.AtomicVLM's Start-avlmAppServices), which run until the container stops. The
# function auto-loads po.AtomicVLM by name; the session's profile imports po.MediaClasses first. All targets
# inherit this command. To get a PowerShell prompt instead, add pwsh after the image name in docker run.
#------------------------------------------------------------------------------------------------------------------

CMD ["pwsh", "-NoLogo", "-Command", "Start-avlmAppServices"]

#------------------------------------------------------------------------------------------------------------------
# Test stage: base + test modules  (docker build --target test -t atomicvlm:test .)
#
# Copies each module folder in this repository's test-modules folder into the all-users module folder, where the
# PowerShell Gallery modules are installed, so they are available for auto-loading in every session. If a module
# folder with the same name already exists (for example, a module installed from the Gallery), it is deleted and
# replaced, so there is only ever one copy of each module.
#
# test-modules is bind-mounted read-only for this step only. It is not copied into the image; only the module
# folders inside it are. Files directly in test-modules (such as its README) are ignored. The folder may contain no
# modules. The build log lists every po.* module available afterwards.
#
# Only the test and dev targets run this step. The production target never reads test-modules, so test modules
# cannot end up in a production image.
#------------------------------------------------------------------------------------------------------------------

FROM base AS test

RUN --mount=type=bind,source=test-modules,target=/tmp/test-modules \
    modules=/usr/local/share/powershell/Modules \
 && for dir in /tmp/test-modules/*/; do \
        [ -d "$dir" ] || continue; \
        name=$(basename "$dir"); \
        if [ -e "$modules/$name" ]; then echo "Replacing module: $name"; else echo "Adding module: $name"; fi; \
        rm -rf "${modules:?}/$name"; \
        cp -R "$dir" "$modules/$name"; \
    done \
 && pwsh -NoLogo -NoProfile -Command " \
        Get-Module -ListAvailable -Name po.* | Sort-Object -Property Name, Version | \
            Format-Table -Property Name, Version, ModuleBase -AutoSize | Out-String -Width 250 \
    "

#------------------------------------------------------------------------------------------------------------------
# Dev stage: base + test modules + development commands  (docker build --target dev -t atomicvlm:dev .)
#
# Starts as a copy of the test stage: the same test-modules step (see the test stage above). Add development-only
# commands at the end of this stage; they are not included in the test or production images.
#------------------------------------------------------------------------------------------------------------------

FROM base AS dev

RUN --mount=type=bind,source=test-modules,target=/tmp/test-modules \
    modules=/usr/local/share/powershell/Modules \
 && for dir in /tmp/test-modules/*/; do \
        [ -d "$dir" ] || continue; \
        name=$(basename "$dir"); \
        if [ -e "$modules/$name" ]; then echo "Replacing module: $name"; else echo "Adding module: $name"; fi; \
        rm -rf "${modules:?}/$name"; \
        cp -R "$dir" "$modules/$name"; \
    done \
 && pwsh -NoLogo -NoProfile -Command " \
        Get-Module -ListAvailable -Name po.* | Sort-Object -Property Name, Version | \
            Format-Table -Property Name, Version, ModuleBase -AutoSize | Out-String -Width 250 \
    "

# Empty po.AtomicVLM module folder in the all-users module folder. 
# If test-modules already supplied a po.AtomicVLM folder, it is left as is.
RUN mkdir -p /usr/local/share/powershell/Modules/po.AtomicVLM

#------------------------------------------------------------------------------------------------------------------
# Production stage: base only  (docker build -t atomicvlm .)
#
# The last stage in the file, so it is what a plain "docker build" produces.
#------------------------------------------------------------------------------------------------------------------

FROM base AS production
