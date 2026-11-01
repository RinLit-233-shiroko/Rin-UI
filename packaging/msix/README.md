# RinUI MSIX Packaging

This directory is the home for the reusable MSIX packaging workflow. The
current reference implementation is Gallery-specific and lives in:

- `packaging/msix/package_msix.ps1`
- `packaging/msix/gallery.spec`
- `examples/AppxManifest.xml`

## Local Build

```powershell
uv sync
uv pip install pyinstaller

./packaging/msix/package_msix.ps1 `
  -Version 0.4.4.5 `
  -CertificatePath scripts/RinUI-Gallery-Test.pfx `
  -CertificatePassword 123456
```

Use `-SkipSign` to produce an unsigned package for layout testing:

```powershell
./packaging/msix/package_msix.ps1 -Version 0.4.4.5 -SkipSign
```

Use `-SkipPyInstaller -SourceDirectory <path>` to test only manifest staging,
MakeAppx, and signing against an existing PyInstaller output.

## Signing

The signing certificate subject must exactly match the manifest `Publisher`.
The current test certificate uses `CN=RinLit` and is only for local testing.
Do not publish that certificate or its password.

For GitHub Actions, configure:

- `MSIX_CERTIFICATE_BASE64`: base64-encoded PFX file
- `MSIX_CERTIFICATE_PASSWORD`: PFX password

Release builds reject unsigned MSIX output. Pull-request and manual layout
tests may intentionally use `-SkipSign`.

## Manifest Inputs

Before publishing an application, replace the Gallery values in
`examples/AppxManifest.xml`:

- `Identity Name`
- `Publisher`
- `PublisherDisplayName`
- `Application Id`
- `Executable`
- Logo paths
- Minimum Windows version

The package version is injected by `package_msix.ps1`; keep the source manifest
version aligned with the library version as a harmless default.

## Future Template

When the Gallery-specific assumptions are parameterized, this directory should
contain:

- `AppxManifest.template.xml`
- `app.spec.template`
- `build.ps1`
- `assets/`

The template should be published as a separate GitHub Release asset, for
example `RinUI-MSIX-Template-vX.Y.Z.zip`. Do not put the PFX or build outputs in
that archive.
