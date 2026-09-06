# Microsoft Store submission checklist

Canonical owner of Store submission gates. Use a fresh copy per release; unchecked
boxes here are requirements, not a report of failed historical work. Record exact
version, commit, hashes, dates and external evidence under docs/diagnostics or in
release reports. Past results live in [Store release history](../../docs/diagnostics/store-release-history.md).

## Identity and build

- [ ] Verify the reserved product and exact identity against Partner Center.
- [ ] Keep final identity values in gitignored packaging/msix/StoreIdentity.json;
      do not invent values or commit that file.
- [ ] Keep runtime/installer AppVersion and CHANGELOG aligned.
- [ ] Complete the clean build and applicable [Development gates](../../docs/DEVELOPMENT.md).
- [ ] Build using the [Store identity procedure](../msix/README.md).
- [ ] Confirm metadata purpose is Microsoft Store submission, signed is false,
      and identity, version, x64 architecture and artifact hashes match.
- [ ] Run packaged runtime tests and WACK for the final payload; review XML/HTML
      results. Resolve applicable failures; document any recurring runtime/tool
      warnings with matching evidence in [certification notes](CertificationNotes.md).
- [ ] Retain package/runtime/helper hashes and build metadata for this release.

## Listing and submission

- [ ] Keep product free unless monetization is intentionally changed; select
      PC/Desktop and x64, and complete the age-rating questionnaire.
- [ ] Declare and justify runFullTrust using [certification notes](CertificationNotes.md).
- [ ] Recheck every [English listing](StoreListing.en-US.md) field against the
      release and live form, including the unofficial/desktop-app dependency.
- [ ] Use the generated StoreLogo300x300.png and the current actual Quick Start
      screenshot from [Store materials](README.md); remove obsolete listing images.
- [ ] Verify the public privacy URL resolves; use the repository for support/site.
- [ ] Upload the final non-_Dev MSIX; exclude local certificates, identity JSON
      and development logs. Confirm package validation succeeds.
- [ ] Submit and record the submission ID, exact package hash, date and observed
      Partner Center status. Validated upload is not certification/publication.

## After certification

- [ ] Confirm public availability and the delivered package version.
- [ ] Install the public build on a clean Windows user profile.
- [ ] Verify first launch, tray/configuration, optional startup, picker matrix,
      cross-channel singleton and clean uninstall.
- [ ] Exercise an actual Store update: record old/new package versions, process
      replacement and return of exactly one tray runtime. A no-update check or
      manually tested activation fallback does not satisfy this gate.
- [ ] Keep README Store URL and public listing consistent with the product.

## Recorded status boundary

The archive records 1.0.3 publication and the 2026-09-02 submission of 1.0.6
(Submission 3) as In certification. It records a public-identity no-update check
and a separately exercised activation fallback. Clean-profile public installation
and an actual delivered upgrade were not marked complete in those records.
Recheck live state for a new release; this checklist does not assert today's
publication or certification status.
