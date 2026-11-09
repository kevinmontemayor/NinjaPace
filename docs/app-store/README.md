# App Store launch preparation

Status: **preparation in progress; not submitted or upload-ready**. Audited November 5, 2026.

## Confirmed launch decisions

- Free app.
- iPhone and companion Apple Watch on the App Store; Mac companion on the Mac App Store.
- TestFlight testing before public release.
- No commits, App Store records, uploads, invitations, or submissions made by this preparation pass.

## Proposed records

| Record | Bundle ID (existing) | Proposed internal SKU |
|---|---|---|
| NinjaPace — iOS + companion watchOS | `com.github.kevinmontemayor.NinjaPace` | `NINJAPACE-IOS-001` |
| NinjaPace Relay — macOS | `com.github.kevinmontemayor.NinjaPaceMac` | `NINJAPACE-MAC-001` |

Watch bundle ID: `com.github.kevinmontemayor.NinjaPace.watchkitapp`. It accompanies the iOS record. SKUs above are proposals, not registered values. Check for existing records before creating anything. Apple treats SKUs as immutable internal identifiers. [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/).

Separate records preserve the existing distinct bundle IDs. Universal purchase would require a deliberate identifier/distribution decision; do not change IDs merely for branding. [Adding platforms](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-platforms/).

## TestFlight release track

These are proposed testing groups and gates, not Xcode configurations:

1. **Internal QA** — signed Release archives, installation/update smoke tests, physical iPhone + Watch workout lifecycle, Mac sandbox networking, privacy permissions, and data persistence.
2. **External Beta** — a small invited cohort after internal QA and Beta App Review; gather crashes, usability feedback, and battery/background behavior. Apple requires an internal group before an external group, and the first external build is reviewed. [External testing](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/).
3. **Release Candidate** — freeze the candidate, capture final screenshots, verify metadata against that build, and retest critical workflows. Increment the build number for subsequent uploads.
4. **App Review → manual release** — recommended to coordinate the two listings and verify companion download links before going public.

Current project version/build: **1.0 (1)**. Existing App Store Connect build history has not been checked. Do not assume build 1 is unused.

## Local build audit

- [x] Unsigned Release build: NinjaPace, including embedded Watch app — passed.
- [x] Unsigned Release build: NinjaPaceMac — passed.
- [x] Fixed preview references to DEBUG-only helpers in `MonthlyChallengeBadgeView.swift` and `MacRelayTheme.swift`.
- [ ] Signed archives, Organizer validation, and processing in App Store Connect.
- [ ] Physical-device Release smoke tests; the builds above are compilation evidence only.

Build logs from this pass: `/tmp/ninjapace-store-audit-ios.log` and `/tmp/ninjapace-store-audit-mac.log`. Temporary files are not permanent release records.

## Before upload

- [ ] Privacy audit and required-reason API manifests: no `PrivacyInfo.xcprivacy` found; UserDefaults is used. Audit all targets and dependencies, add accurate declarations, inspect the archive privacy report.
- [ ] Audit HealthKit capabilities: iPhone/Watch currently request `health-records`. Verify actual clinical-record use and remove that entitlement if unnecessary. Review background modes as well.
- [ ] Review purpose strings to explain workout history recovery and live tracking accurately; current iPhone read string only mentions streaming. Motion wording should reflect actual motion use.
- [ ] Review global `NSAllowsArbitraryLoads`; scope networking exceptions to the local relay requirements where possible.
- [ ] Confirm support for iPad: the iOS Release target currently includes device families 1 and 2. Retain and test iPad/capture its screenshots, or explicitly decide to narrow support before submission.
- [ ] Confirm minimum supported OS versions (currently 26.0) and test supported versions.
- [ ] Verify app icons, artwork and sound rights, app/brand name availability, copyright owner, and App Store category.
- [ ] Publish support and privacy-policy pages; provide support/review contact information.
- [ ] Complete privacy labels, age-rating questionnaire, encryption/export compliance, availability, trader status where applicable, and account agreements using accurate owner responses.
- [ ] Decide whether the iOS app should also be available on Apple silicon Macs alongside the native Mac companion.
- [ ] Finish and visually approve the [screenshot set](screenshots/README.md).

Privacy answers must reflect actual data flows and third-party code, including optional LAN relay/OBS use. Do not claim that reinstall restores every setting: recovery depends on accessible HealthKit workouts and available metadata. [Apple privacy guidance](https://developer.apple.com/app-store/app-privacy-details/).

## Critical beta checks

Use test devices and documented backups, never delete the owner's app as a casual test.

- Start/pause/resume/end from Watch; duplicate-save handling; phone disconnected/reconnected; background workout and permission denial.
- Restore eligible HealthKit history; run restoration again without duplicates; edit a goal; verify completed-goal totals, awards, trends and footer agree. Validate upgrade persistence and controlled reinstall recovery on a test device.
- Local alerts with permission granted/denied, schedule edits, and completed goals; celebration audio toggles and reduced motion.
- Mac sandbox relay discovery, local-network permission, locked addresses, reconnect, HUD customization and OBS browser source; no Mac required for ordinary fitness use.
- Small phone, Duo folded/expanded, iPad if retained, Watch sizes, Dynamic Type and VoiceOver.

See [English store copy](metadata-en-US.md) for draft descriptions and review notes. Owner inputs still needed: public support/privacy URLs, review contact, copyright owner, territories, and iPad decision.
