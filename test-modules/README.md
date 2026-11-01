# Test Modules

Put PowerShell module folders here to include them in the Docker image for testing, for example
unpublished modules or local builds of a module that hasn't been released to the PowerShell Gallery yet.

Test modules are only included in the **test** and **dev** images. Build them with the `test` or `dev`
target:

```
docker build --target test -t atomicvlm:test .
docker build --target dev  -t atomicvlm:dev .
```

A plain `docker build` produces the production image, which never reads this folder, so test modules
cannot end up in a production image.

When the test or dev image is built, each folder in `test-modules` is copied into the all-users module folder in
the container, `/usr/local/share/powershell/Modules/`, where the modules from the PowerShell Gallery are
installed. That folder is on every user's `PSModulePath`, so the modules auto-load like any installed
module. The build log lists every `po.*` module available after the copy, with its version and location.

The `test-modules` folder itself is not copied into the image, only the module folders inside it. Files
directly in `test-modules`, such as this README, are ignored. The folder can contain no modules.

## Folder layout

Copy the module folder itself (the folder containing the `.psd1` file), not its parent repository.
The folder name is the module name. Either of these layouts works:

```
test-modules/
  po.Example/                  <- module folder name must match the .psd1 name
    po.Example.psd1
    po.Example.psm1
    public/ ...

  po.Other/
    1.2.0/                     <- version folder name must match ModuleVersion in the .psd1
      po.Other.psd1
      po.Other.psm1
      ...
```

## Replacing modules installed from the PowerShell Gallery

If a folder here has the same name as a module the Dockerfile installs from the Gallery (for example
`po.Toolkit` or `po.MediaClasses`), the Gallery module's folder is deleted and replaced by yours. There is
only ever one copy of each module in the image, so your copy is always the one that loads, whatever its
version number. The build log shows `Replacing module: <name>` or `Adding module: <name>` for each folder.

## Dependencies

A test module's `RequiredModules` must be available in the image: either installed from the Gallery by
the Dockerfile, or added here as another test module.

## Licensing

Modules added here are copied into the test and dev images only. Don't distribute those images; if a module
should ship, install it in the Dockerfile's base stage and cover its license in `THIRD_PARTY_NOTICES.md`.
