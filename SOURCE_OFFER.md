# Source Code Availability (GPL / LGPL)

The AtomicVLM Docker image contains unmodified software licensed under the GNU General Public
License (GPL) and the GNU Lesser General Public License (LGPL): Ubuntu packages, and AtomicParsley
compiled from its upstream release source. These licenses give you the
right to get the complete corresponding source code for those binaries.

| Component | License | Source |
|-----------|---------|--------|
| AtomicParsley | GPL-2.0-or-later | Release tag `20240608.083822.1ed9031` at https://github.com/wez/atomicparsley (source archive: https://github.com/wez/atomicparsley/archive/refs/tags/20240608.083822.1ed9031.tar.gz). The build commands are in this repository's `Dockerfile`. |
| FFmpeg | GPL-2.0-or-later | Ubuntu source package `ffmpeg` (`apt-get source ffmpeg`, or https://launchpad.net/ubuntu/+source/ffmpeg). The build configuration is in the package's `debian/rules` and is printed by `ffmpeg -buildconf`. |
| libmms | LGPL-2.1-or-later | Ubuntu source package `libmms` (https://launchpad.net/ubuntu/+source/libmms) |
| Other GPL/LGPL Ubuntu packages (e.g. GnuTLS and FFmpeg's codec libraries) | See `/usr/share/doc/<package>/copyright` | `apt-get source <package>`, or https://launchpad.net/ubuntu/+source/<source-package> |

The installed version of each Ubuntu package is shown by
`dpkg-query -W -f='${Package} ${Version}\n'` inside the image. The Ubuntu source package with the
same version is its corresponding source. AtomicParsley is not an Ubuntu package; its version is
printed by `AtomicParsley --version` and set by `ATOMICPARSLEY_VERSION` in the `Dockerfile`.

## Written offer

For at least three years after the last date on which a given image version was distributed, the
maintainer of this image will give anyone who asks a complete machine-readable copy of the
corresponding source code for every GPL- and LGPL-licensed component in that image version. It
will be provided on a medium customarily used for software interchange, for a charge no more than
the cost of physically performing the source distribution.

To request source code, open an issue at https://github.com/seabopo/Docker-AtomicVLM/issues and
include the image tag or digest.
