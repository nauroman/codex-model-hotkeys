# ReasonKey 1.0.9 release evidence

Prepared 2026-09-05 (local time), with the final F19 Extra High correction.

- Clean direct build and embedded validation passed; setup SHA-256:
  `44c609c8adeaa73780fb88d3eeea4805616a06cdb094e69204113ceb8ade1935`.
- Runtime SHA-256:
  `c82900c7e603f31475b5100e9be9cdea8a576e8132c09c1696f08519d3950aad`.
- Store 1.0.9.0 x64 package built and unpacked successfully, with the
  manifest-adjusted runtime validation passing. Unsigned Store package SHA-256:
  `48c46285b23e493d0b7cff272ba0326a3935f66f945a84f98659fbc2eba8ba9b`.
- Exact public identity was verified in Partner Center. Submission 4 ID:
  `1152921505701821011`. Package upload showed Validated.
- Real-window Codex tests on the rebuilt runtime confirmed Light at 20:44:32,
  High at 20:44:39, Extra High at 20:44:45, and Medium at 20:44:51.
  Original Medium was restored. Earlier Chat and open-picker evidence, and
  direct installation/replacement checks, are recorded in the
  [Astra report](astra-validation-20260905.md).
- A fresh Chat rerun was interrupted by active user input. The Chat logic was
  unchanged from the earlier verified build; this is not a new complete matrix.
- The actual 1.0.9 Store-preview Quick Start was captured, visually reviewed,
  and uploaded with the updated caption and listing. Screenshot SHA-256:
  `c99e2ecd3047a75e4c39d48dc7f6ab6c400d7f518d9846863d47dce3fdc985af`.
- The originally running public Store runtime was restored after preview/testing.
- Local WACK requires elevation and was not run in this non-admin session.
  Legacy picker, clean-profile Store install/uninstall, and delivered Store
  update/restart gates remain unverified for this release. Partner Center
  certification/publication is distinct from package upload validation.

## Remote publication

- GitHub release [v1.0.9](https://github.com/nauroman/codex-model-hotkeys/releases/tag/v1.0.9)
  published from commit `c7ca2f0f87a831fffa8ee702f1c3404989a84a2b` and marked
  latest. The uploaded setup's GitHub digest matches the hash above.
- Both GitHub Actions runs for the release commit completed successfully:
  `34009912404` and `34009913706`.
- The public privacy-policy URL returned HTTP 200.
- Store Submission 4 was submitted at approximately 20:50 local time on
  2026-09-05 (2026-09-06 UTC). Partner Center confirmed **Update in certification**,
  Submission complete and Pre-processing in progress. Publishing will start
  automatically after certification. This is not yet public delivery of 1.0.9.
- Updated listing description, release notes, the replacement screenshot and
  its 1.0.9 caption were saved before submission. Certification instructions
  were updated for Astra and independent Chat, with the local WACK limitation
  explicitly stated.
