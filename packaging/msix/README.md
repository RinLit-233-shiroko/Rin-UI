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

## Gallery Icons

The Gallery icon source lives at `examples/assets/icons/app/gallery.png`.
Regenerate the native ICO/ICNS files and all MSIX package variants with:

```powershell
./.venv/Scripts/python.exe scripts/generate_gallery_icons.py
```

Microsoft Store listing images live in `examples/assets/icons/store/listing/`.
MSIX package assets live in `examples/assets/icons/store/package/`.

## Signing

The signing certificate subject must exactly match the manifest `Publisher`.
The current test certificate uses `CN=RinLit` and is only for local testing.
Do not publish that certificate or its password.

For GitHub Actions, configure:

- `MSIX_CERTIFICATE_BASE64`: base64-encoded PFX file
- `MSIX_CERTIFICATE_PASSWORD`: PFX password

The build workflow also publishes `RinUI-Gallery-Signing.cer` beside the MSIX
when the certificate secret is present. Users who install the self-signed
package outside the Microsoft Store may need to trust this public certificate.

When `MSIX_CERTIFICATE_BASE64` is not configured, GitHub Actions creates an
unsigned MSIX package and continues the release workflow. Such a package is
intended for layout testing or local installation with developer settings; it
cannot be treated as a production-signed package. Configure both certificate
secrets before publishing a package intended for regular users.

## Microsoft Store publishing

`.github/workflows/store-publish.yml` submits the MSIX from a published GitHub
Release to the existing Partner Center application. It runs automatically when
a Release is published and can also be started manually with a release tag.
Create these GitHub Actions secrets from the Partner Center Azure AD app:

- `AZURE_AD_APPLICATION_CLIENT_ID`: the Entra app registration client ID
- `AZURE_AD_APPLICATION_SECRET`: the Entra app registration client secret
- `AZURE_AD_TENANT_ID`: the Entra tenant ID
- `SELLER_ID`: the Partner Center seller ID

Also create the repository variable `STORE_PRODUCT_ID` containing the Microsoft
Store product ID. The workflow uses the Microsoft documented
`microsoft/microsoft-store-apppublisher@v1.1` action and runs `msstore
reconfigure` followed by `msstore publish`.

The workflow is protected by the repository variable `ENABLE_STORE_PUBLISH`.
Leave it unset or set it to `false` while testing Tag based GitHub Releases.
Set it to `true` only when each published Release should also be submitted to
the Microsoft Store.

Microsoft currently documents GitHub Actions publishing for free products.
The submission may still require certification and approval before the update
becomes visible to users.

The app registration must be added in Partner Center with the documented
administrator role for Store submissions.


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
