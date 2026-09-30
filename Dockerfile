#==================================================================================================================
# AtomicVLM - Docker Image
#
# Base image : .NET 10 SDK on Ubuntu 24.04 (Noble), which includes PowerShell.
# CLI tools  : MediaInfo (from MediaArea's apt repository), FFmpeg (ffmpeg, ffprobe, from the Ubuntu archive) and
#              AtomicParsley (compiled from its upstream release source during the build).
# Modules    : po.Toolkit, po.MediaInfo, po.FFMPEG, po.AtomicParsley, po.MediaClasses and po.TMDB, from the PowerShell
#              Gallery.
# Licenses   : /usr/share/licenses/atomicvlm/ (see THIRD_PARTY_NOTICES.md).
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
# Final image
#------------------------------------------------------------------------------------------------------------------

FROM mcr.microsoft.com/dotnet/sdk:10.0-noble

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
        Install-PSResource -Name po.Toolkit, po.MediaInfo, po.FFMPEG, po.AtomicParsley, po.MediaClasses, po.TMDB \
                           -Repository PSGallery -Scope AllUsers -TrustRepository; \
        Import-Module -Name po.FFMPEG, po.MediaClasses; \
        Import-Module -Name po.TMDB; \
        Get-Module -Name po.* | Format-Table -Property Name, Version -AutoSize; \
        Add-Content -Path \$PROFILE.AllUsersAllHosts -Value 'Import-Module -Name po.MediaClasses'; \
        Write-Host ('All-users profile: {0}' -f \$PROFILE.AllUsersAllHosts) \
    "

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

CMD ["pwsh"]
