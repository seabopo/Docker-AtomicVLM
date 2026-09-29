# Third-Party Notices: AtomicVLM Docker Image

The AtomicVLM Docker image **includes and redistributes** software from other projects. Each
component stays under its own license. This file lists every component in the image, the license
it is under, what that license requires when the software is redistributed, and where to find the
full license text.

The Docker build files in this repository (Copyright (c) 2026 seabopo) are licensed under the
[MIT License](LICENSE).

This product uses [MediaInfo](https://mediaarea.net/en/MediaInfo) library, Copyright (c) 2002-2026
[MediaArea.net SARL](mailto:info@mediaarea.net).

This software uses code of [FFmpeg](https://ffmpeg.org/) licensed under the GPLv2 or later, and its
source can be downloaded as described in [`SOURCE_OFFER.md`](SOURCE_OFFER.md). FFmpeg is a
trademark of Fabrice Bellard, originator of the FFmpeg project. This image and its maintainer are
not affiliated with the FFmpeg project and do not own FFmpeg.

This software is based in part on the work of the Independent JPEG Group.

This product uses the TMDB API but is not endorsed or certified by TMDB.

## Base image

The image is built on `mcr.microsoft.com/dotnet/sdk:10.0-noble` (Ubuntu 24.04 LTS) for amd64 and
arm64. It runs on Linux, and on macOS or Windows through Docker Desktop's Linux VM.

## Components

| Component | License | License text |
|-----------|---------|--------------|
| AtomicVLM PowerShell modules: po.AtomicVLM, po.Toolkit, po.MediaClasses, po.MediaInfo, po.AtomicParsley, po.FFMPEG | MIT | [below](#atomicvlm-powershell-modules) |
| .NET SDK 10 (base image) | MIT | https://github.com/dotnet/sdk/blob/main/LICENSE.TXT |
| PowerShell (included in the .NET SDK base image) | MIT | https://github.com/PowerShell/PowerShell/blob/master/LICENSE.txt |
| Ubuntu 24.04 packages (base image and apt dependencies) | Various, one per package | `/usr/share/doc/<package>/copyright` inside the image |
| MediaInfo CLI and MediaInfoLib (from MediaArea's apt repository) | BSD-2-Clause | [`MEDIAINFO_LICENSE`](MEDIAINFO_LICENSE) |
| ZenLib (MediaInfo dependency, from MediaArea's apt repository) | zlib | [below](#zenlib) |
| zlib (MediaInfo dependency) | zlib | [below](#zlib) |
| TinyXML-2 (bundled in MediaInfoLib) | zlib | [below](#tinyxml-2) |
| AES implementation by Brian Gladman (bundled in MediaInfoLib) | Gladman BSD-style | [below](#aes-brian-gladman) |
| libcurl (MediaInfo dependency) | curl (MIT-style) | [below](#libcurl) |
| libmms (MediaInfo dependency) | LGPL-2.1-or-later | [`licenses/LGPL-2.1.txt`](licenses/LGPL-2.1.txt) |
| AtomicParsley | GPL-2.0-or-later ([details](#atomicparsley)) | [`ATOMICPARSLEY_LICENSE`](ATOMICPARSLEY_LICENSE), [`licenses/GPL-2.0.txt`](licenses/GPL-2.0.txt) |
| FFmpeg (`ffmpeg`, `ffprobe` and libraries) | GPL-2.0-or-later ([details](#ffmpeg)) | [`FFMPEG_LICENSE.md`](FFMPEG_LICENSE.md), [`licenses/GPL-2.0.txt`](licenses/GPL-2.0.txt) |

The Qt and wxWidgets toolkits in MediaInfo's third-party list are only used by the MediaInfo
graphical interface. That interface is not installed in this image.

## What redistribution requires

Redistributing this image means meeting the conditions of every license above.

1. **Permissive licenses** (MIT, BSD-2-Clause, zlib, curl, and Brian Gladman's AES license) require that the copyright notices,
   license terms and disclaimers be kept with the distributed binaries. This file,
   `MEDIAINFO_LICENSE`, `FFMPEG_LICENSE.md`, `ATOMICPARSLEY_LICENSE`, the upstream license files that ship with each component, and the
   Ubuntu `copyright` files do that. Do not remove them from the image.
2. **Copyleft licenses** (GPL and LGPL: AtomicParsley, FFmpeg, libmms, and the LGPL libraries
   that Ubuntu's libcurl and FFmpeg packages depend on, such as GnuTLS) also require:
   - the full license text to accompany the binaries (see [`licenses/`](licenses/)), and
   - the complete corresponding source code to be made available to recipients (see
     [`SOURCE_OFFER.md`](SOURCE_OFFER.md)).

   No GPL or LGPL component has been changed: the Ubuntu packages are installed unmodified, and
   AtomicParsley is compiled from its unmodified upstream release source.

## License files inside the image

- `/usr/share/licenses/atomicvlm/` holds this file, `LICENSE`, `MEDIAINFO_LICENSE`,
  `FFMPEG_LICENSE.md`, `ATOMICPARSLEY_LICENSE`, `SOURCE_OFFER.md` and `licenses/`.
- `/usr/share/doc/<package>/copyright` holds the copyright and license file for every installed
  Ubuntu package. Common license texts they refer to are in `/usr/share/common-licenses/`.

---

## Installed packages

MediaInfo and its ZenLib library come from MediaArea's own apt repository
(https://mediaarea.net/en/Repos), pinned in the Dockerfile. Everything else comes from the Ubuntu
24.04 (Noble) archive. These are the versions installed when this file was written:

| Package | Source | Version | License |
|---------|--------|---------|---------|
| `mediainfo` | MediaArea | 26.05-1 | BSD-2-Clause |
| `libmediainfo0v5` | MediaArea | 26.05-1 | BSD-2-Clause; bundles TinyXML-2 (zlib) and Brian Gladman's AES code (Gladman BSD-style) |
| `libzen0v5` | MediaArea | 0.4.41-1 | zlib ([details](#zenlib)) |
| `repo-mediaarea` | MediaArea | 1.0-26 | MediaArea's apt signing key and repository configuration |
| `libcurl3t64-gnutls` | Ubuntu | 8.5.0-2ubuntu10.11 | curl, linked against GnuTLS (LGPL-2.1-or-later) |
| `libmms0` | Ubuntu | 0.6.4-3build1 | LGPL-2.1-or-later |
| `zlib1g` | Ubuntu | 1:1.3.dfsg-3.1ubuntu2.1 | zlib |
| `ffmpeg` and `libav*` / `libsw*` / `libpostproc` | Ubuntu | 7:6.1.1-3ubuntu5 | GPL-2.0-or-later (Ubuntu's FFmpeg is built with GPL components enabled, e.g. `libpostproc`) |

The `ffmpeg` package pulls in many codec libraries (x264, x265, libvpx, libaom, dav1d, Opus and
others), each with its own license. Every installed package's copyright holders and license are
in `/usr/share/doc/<package>/copyright`. To list the installed packages, run
`dpkg-query -W -f='${Package} ${Version}\n'`.

MediaArea's packages also install their copyright files in `/usr/share/doc/<package>/copyright`.
AtomicParsley is not installed from a package. It is compiled during the image build from the
upstream release tag `20240608.083822.1ed9031` and installed at `/usr/local/bin/AtomicParsley` (see
[AtomicParsley](#atomicparsley)).

If the pinned MediaInfo or AtomicParsley versions in the Dockerfile change, or FFmpeg is installed
from somewhere other than the Ubuntu archive, update this file to match.

---

## FFmpeg

This image **redistributes FFmpeg**. The `ffmpeg` package and its libraries are installed from the
Ubuntu 24.04 archive, unmodified.

### License

FFmpeg itself is licensed under the LGPL-2.1-or-later, but builds that enable its GPL components
are licensed under the GPL-2.0-or-later. Ubuntu's standard `ffmpeg` package is built with
`--enable-gpl`, so the FFmpeg in this image is GPL-2.0-or-later. (Ubuntu's optional
`libavcodec-extra` package is a GPL-3.0-or-later build; it is not installed in this image.) To
confirm the license of the installed binary, and to see the exact configure line it was built
with, run:

```
ffmpeg -hide_banner -L
ffmpeg -hide_banner -buildconf
```

- FFmpeg's license summary: [`FFMPEG_LICENSE.md`](FFMPEG_LICENSE.md), copied from the FFmpeg source
  tree. It covers the LGPL and GPL parts, the optional external libraries and how each affects the
  license, and the files under other terms.
- Full license texts: [`licenses/GPL-2.0.txt`](licenses/GPL-2.0.txt) and
  [`licenses/LGPL-2.1.txt`](licenses/LGPL-2.1.txt).
- Copyright holders and licenses of the Ubuntu FFmpeg packages and the codec libraries they depend
  on: `/usr/share/doc/<package>/copyright` inside the image (for example
  `/usr/share/doc/ffmpeg/copyright`).
- Legal information from the FFmpeg project: https://ffmpeg.org/legal.html.

### How this image meets FFmpeg's redistribution terms

FFmpeg's [License Compliance Checklist](https://ffmpeg.org/legal.html) is written mainly for
applications that link to an LGPL build. Because this image redistributes a GPL build as
unmodified, standalone programs, the parts of the checklist about LGPL-only builds, dynamic
linking and EULAs do not apply. The rest are handled as follows:

| Requirement | How it is met |
|-------------|---------------|
| Distribute the license with the binaries | `FFMPEG_LICENSE.md`, `licenses/`, and the Ubuntu `copyright` files ship in the image. |
| Make the corresponding source available | The Ubuntu `ffmpeg` source package of the installed version, plus the written offer in [`SOURCE_OFFER.md`](SOURCE_OFFER.md). |
| Document how FFmpeg was compiled and any changes | FFmpeg is not modified. The build configuration is in the Ubuntu source package (`debian/rules`) and is printed by `ffmpeg -buildconf`. |
| Attribute FFmpeg | The attribution at the top of this file. |
| Make clear that you do not own FFmpeg | The attribution at the top of this file. |
| Spell "FFmpeg" correctly and don't rename its files | FFmpeg's programs and libraries are installed under their Ubuntu package names. |
| Credit the Independent JPEG Group when distributing executables | "This software is based in part on the work of the Independent JPEG Group." (top of this file). FFmpeg's `LICENSE.md` requires this because some libjpeg-derived files are compiled into the binaries. |

The po.FFMPEG module's own `THIRD_PARTY_NOTICES.md` says that the module does not redistribute
FFmpeg. That is true of the module on its own. In this image, FFmpeg is redistributed alongside
the module, and this file covers that redistribution.

---

## AtomicParsley

This image **redistributes AtomicParsley**, version 20240608.083822.1ed9031. It is compiled during the image
build from the unmodified upstream release tag at https://github.com/wez/atomicparsley, using the
project's own CMake build in Release mode, and installed at `/usr/local/bin/AtomicParsley`.
AtomicParsley's upstream `COPYING` and `CREDITS` files are installed alongside it in
`/usr/share/doc/atomicparsley/`.

```
AtomicParsley is GPL software; you can freely distribute,
redistribute, modify & use under the terms of the GNU General
Public License; either version 2 or its successor.

AtomicParsley is distributed under the GPL "AS IS", without
any warranty; without the implied warranty of merchantability
or fitness for either an expressed or implied particular purpose.

Copyright (C) 2005-2007, puck_lock
Copyright (C) 2009-2012, Wez Furlong
Copyright (C) 2010-2012, Oleg Oshmyan
Copyright (C) 2009, 2011, Santino Fuentes
Copyright (C) 2011, John D Pell
Copyright (C) 2010, Edriss Mirzadeh
Copyright (C) 2009, Josh Aune
Copyright (C) 2014, Paul Foose
```

- Full list of copyright holders and contributors, and the GPL-2.0 text:
  [`ATOMICPARSLEY_LICENSE`](ATOMICPARSLEY_LICENSE) (AtomicParsley's `CREDITS` and `COPYING` files,
  unchanged). They are identical to the files in release `20240608.083822.1ed9031`.
- Source code: https://github.com/wez/atomicparsley/tree/20240608.083822.1ed9031 (see
  [`SOURCE_OFFER.md`](SOURCE_OFFER.md)).

### Code in AtomicParsley under other licenses

AtomicParsley's binary includes code under these additional terms:

- **UTF conversion functions from libxml2** (`src/iconv.cpp`), under an MIT-style license that
  requires this notice in all copies:

  ```
  Copyright (C) 1998-2003 Daniel Veillard.  All Rights Reserved.

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is fur-
  nished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FIT-
  NESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  DANIEL VEILLARD BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CON-
  NECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

  Except as contained in this notice, the name of Daniel Veillard shall not
  be used in advertising or otherwise to promote the sale, use or other deal-
  ings in this Software without prior written authorization from him.
  ```

  Original code for IsoLatin1 and UTF-16 by "Martin J. Duerst" <duerst@w3.org>.
- **SHA-1 implementation** (`src/sha1.cpp`): Copyright (C) 2000, 2001, 2003, 2004, 2005 Free Software
  Foundation, Inc., written by Scott G. Miller, under the GPL version 2 or later.
- **UUID generation** (`src/uuid.cpp`), derived from RFC 4122 code: Copyright (c) 1990-1993, 1996
  Open Software Foundation, Inc.; Copyright (c) 1989 Hewlett-Packard Company and Digital Equipment
  Corporation; Copyright (c) 1998 Microsoft. Its notice is required in source code copies, and
  is in the AtomicParsley source code (`src/uuid.cpp`).

### How this image meets AtomicParsley's redistribution terms

| GPL-2.0 requirement | How it is met |
|---------------------|---------------|
| Keep the copyright notices and warranty disclaimer with each copy | This section, `ATOMICPARSLEY_LICENSE`, and `/usr/share/doc/atomicparsley/COPYING` and `CREDITS` ship in the image. |
| Give recipients a copy of the GPL | [`licenses/GPL-2.0.txt`](licenses/GPL-2.0.txt), and the `COPYING` text in `ATOMICPARSLEY_LICENSE`. |
| Provide the complete corresponding source code | The upstream release tag `20240608.083822.1ed9031` the binary is built from, the build commands in this repository's `Dockerfile`, and the written offer in [`SOURCE_OFFER.md`](SOURCE_OFFER.md). |
| Mark any modifications | AtomicParsley is not modified; it is built from the release source as published. |

The po.AtomicParsley module's own `THIRD_PARTY_NOTICES.md` says that the module does not
redistribute AtomicParsley. That is true of the module on its own. In this image, AtomicParsley is
redistributed alongside the module, and this file covers that redistribution.

---

## MediaInfo / MediaInfoLib

See [`MEDIAINFO_LICENSE`](MEDIAINFO_LICENSE) for the full MediaInfo(Lib) license as published at
https://mediaarea.net/en/MediaInfo/License. That file also has the alternate binary attribution
clause, the third-party library list, and the contributor list. Source code:
https://github.com/MediaArea/MediaInfo and https://github.com/MediaArea/MediaInfoLib.

The MediaInfo packages in this image are MediaArea's own builds, installed unmodified from
MediaArea's apt repository. Their copyright files, including the bundled third-party code listed
below, are at `/usr/share/doc/mediainfo/copyright` and `/usr/share/doc/libmediainfo0v5/copyright`.

---

## ZenLib

```
Copyright (c) 2002-2025 MediaArea.net SARL. All rights reserved.

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
```

ZenLib (package `libzen0v5`, from MediaArea) also includes code from other authors, all under the
zlib license unless noted: 128-bit integer code by Jan Ringos, Base64 code by Markus Ewald, an HTTP
client by Eitan Michaelson (partly derived from RFC 2617, Copyright (C) The Internet Society), a
bundled copy of TinyXML by Lee Thomason, and a public-domain MD5 implementation. The full list, with
each license's text, is in `/usr/share/doc/libzen0v5/copyright` inside the image.

---

## zlib

```
(C) 1995-2026 Jean-loup Gailly and Mark Adler

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.

Jean-loup Gailly        Mark Adler
jloup@gzip.org          madler@alumni.caltech.edu
```

---

## TinyXML-2

TinyXML-2 is compiled into MediaInfoLib (package `libmediainfo0v5`).

```
Original code by Lee Thomason (www.grinninglizard.com)

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any
damages arising from the use of this software.

Permission is granted to anyone to use this software for any
purpose, including commercial applications, and to alter it and
redistribute it freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must
not claim that you wrote the original software. If you use this
software in a product, an acknowledgment in the product documentation
would be appreciated but is not required.

2. Altered source versions must be plainly marked as such, and
must not be misrepresented as being the original software.

3. This notice may not be removed or altered from any source
distribution.
```

---

## AES (Brian Gladman)

MediaInfoLib (package `libmediainfo0v5`) includes Brian Gladman's AES implementation
(`Source/ThirdParty/aes-gladman`). Its license requires binary distributions to include the
following notice in their documentation:

```
Copyright (c) 1998-2013, Brian Gladman, Worcester, UK. All rights reserved.

The redistribution and use of this software (with or without changes)
is allowed without the payment of fees or royalties provided that:

  source code distributions include the above copyright notice, this
  list of conditions and the following disclaimer;

  binary distributions include the above copyright notice, this list
  of conditions and the following disclaimer in their documentation.

This software is provided 'as is' with no explicit or implied warranties
in respect of its operation, including, but not limited to, correctness
and fitness for purpose.
```

---

## libcurl

```
COPYRIGHT AND PERMISSION NOTICE

Copyright (c) 1996 - 2026, Daniel Stenberg, <daniel@haxx.se>, and many
contributors, see the THANKS file.

All rights reserved.

Permission to use, copy, modify, and distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright
notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name of a copyright holder shall not
be used in advertising or otherwise to promote the sale, use or other dealings
in this Software without prior written authorization of the copyright holder.
```

---

## libmms

libmms is used by MediaInfoLib (installed from the Ubuntu archive) and is licensed under the
GNU Lesser General Public License, version 2.1 or later. Full license text:
[`licenses/LGPL-2.1.txt`](licenses/LGPL-2.1.txt). Source code:
https://sourceforge.net/projects/libmms/ and the Ubuntu `libmms` source package.

---

## AtomicVLM PowerShell modules

The following modules are included in the image. Each one is licensed under the MIT License
below, with the copyright year shown.

| Module | Copyright | Repository |
|--------|-----------|------------|
| po.AtomicVLM | Copyright (c) 2025 seabopo | https://github.com/seabopo/PowerShell-AtomicVLM |
| po.Toolkit | Copyright (c) 2024 seabopo | https://github.com/seabopo/PowerShell-Toolkit |
| po.MediaClasses | Copyright (c) 2025 seabopo | https://github.com/seabopo/PowerShell-MediaClasses |
| po.MediaInfo | Copyright (c) 2025 seabopo | https://github.com/seabopo/PowerShell-MediaInfo |
| po.AtomicParsley | Copyright (c) 2024 seabopo | https://github.com/seabopo/PowerShell-AtomicParsley |
| po.FFMPEG | Copyright (c) 2025 seabopo | https://github.com/seabopo/PowerShell-FFMPEG |

```
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Online data services (not included in the image)

AtomicVLM reads movie metadata from online services at runtime. No data from these services is
included in the image.

- **TMDB.** This product uses the TMDB API but is not endorsed or certified by TMDB. Use of the
  API is subject to TMDB's terms of use: https://www.themoviedb.org/api-terms-of-use. Each user
  supplies their own TMDB API key.
- **IMDb.** IMDb content is subject to IMDb's Conditions of Use:
  https://www.imdb.com/conditions.
