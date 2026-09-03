# QUESTIONABLE DECISIONS — PROJECT STATE

## Current Phase

**V1: Nearing Completion**

Current working checkpoint:

`V1: Nearing Completion`

This document is the living project framework for Questionable Decisions. It records the current release state, the rules for moving forward, and the publishing process.

---

# PUBLISHING FRAMEWORK

## 1. V1 FREEZE

V1 feature development is considered complete.

From this point forward:

- Do not add new features to V1.
- Do not redesign working features.
- Do not change underlying functionality unless required to fix a release-blocking issue.
- Do not expand scope because of new ideas discovered during testing.
- New ideas belong in the Future Ideas backlog.

The goal is now to prepare the existing V1 build for release.

---

## 2. CURRENT V1 BASELINE

The current V1 baseline includes:

- Nearby
- Crawl
- Detour
- Saved
- Help
- Final navigation structure
- Dining Unhinged integration
- Location services
- Google Maps / navigation integration
- Persistent saved decisions
- Tutorial/help content
- Detour planning and active-trip functionality
- Crawl planning and execution functionality

Working functionality must be preserved while preparing the release.

---

# 3. REPOSITORY AUDIT

Before release cleanup:

- Review the repository structure.
- Confirm all intended source files are present.
- Confirm obsolete files are identified.
- Confirm temporary/debug files are identified.
- Confirm generated build artifacts are not part of the release source.
- Confirm Git status.
- Confirm the correct branch and release checkpoint.
- Confirm the V1 baseline before making cleanup changes.

Do not delete or restructure files merely because they appear unnecessary. Verify their role first.

---

# 4. SECURITY & SECRETS

Before publication:

- Audit all API keys and credentials.
- Confirm secrets are stored outside committed source code.
- Confirm local secret configuration is Git-ignored.
- Confirm no credentials are hardcoded in Flutter source.
- Confirm no credentials are committed to GitHub.
- Confirm release configuration uses the intended secret mechanism.
- Rotate any credential that may have been exposed.

The existing working Maps and Routes functionality must be preserved while secrets are secured.

---

# 5. CODE CLEANUP

Cleanup is limited to release readiness.

Allowed:

- Removing confirmed dead code.
- Removing temporary debugging code where safe.
- Removing obsolete files after verification.
- Fixing release-blocking analyzer errors/warnings.
- Making small release-safety corrections.

Not allowed:

- Feature refactoring for its own sake.
- Architecture changes without a release requirement.
- UI redesign.
- Behaviour changes.
- Reworking functioning systems simply to make them “cleaner.”

Every cleanup change must preserve existing behaviour.

---

# 6. RELEASE CONFIGURATION

Confirm:

- Application name
- Package/bundle identifiers
- App version
- Build number
- App icon
- Splash/startup configuration
- Android release configuration
- iOS release configuration
- Required permissions
- Location permission disclosures
- Notification permissions
- Production API configuration
- Production secret configuration

---

# 7. QUALITY GATE

Before calling the build a Release Candidate:

### Static checks

- Run `flutter analyze`.
- Resolve release-blocking errors.
- Review warnings.
- Existing non-blocking informational issues do not automatically require unrelated refactoring.

### Build checks

- Build Android release configuration.
- Build iOS release configuration.
- Confirm both builds complete successfully.

### Functional checks

Verify:

- Nearby works.
- Crawl works.
- Detour works.
- Saved works.
- Help works.
- Navigation works.
- Location permissions work.
- Review links work.
- Save/remove functionality works.
- Detour planning works.
- Detour start/stop functionality works.
- Crawl planning works.
- Crawl start/navigation works.
- App survives normal navigation between sections.

---

# 8. REAL-DEVICE RELEASE TESTING

Test on actual devices.

### Android

- Fresh install
- Upgrade install
- Location permission
- Location denied
- GPS unavailable
- Nearby
- Crawl
- Detour
- Saved
- Navigation
- Notifications
- App backgrounding
- App restart

### iOS

Repeat the equivalent release tests on a real iPhone.

Do not treat emulator/simulator success as sufficient release validation.

---

# 9. RELEASE CANDIDATE

A build becomes the **Release Candidate** only after:

- Repository audit is complete.
- Secrets audit is complete.
- Release configuration is complete.
- Static analysis is reviewed.
- Android release build succeeds.
- iOS release build succeeds.
- Real-device testing passes.
- No known release-blocking defects remain.

The Release Candidate is frozen.

No new features are added after the RC is created.

---

# 10. PUBLICATION

After the Release Candidate is approved:

### Store preparation

- Google Play listing
- Apple App Store listing
- App description
- Screenshots
- App icon
- Promotional/marketing copy
- Privacy policy
- Terms where required
- Location disclosure
- Notification disclosure
- Any required third-party/affiliate disclosure

### Submission

- Submit Android build.
- Submit iOS build.
- Complete store metadata.
- Complete required compliance questionnaires.
- Respond to any store review issues.

---

# 11. POST-SUBMISSION RULE

Once submitted:

Do not start another feature cycle.

Only address:

- Store rejection issues
- Release-blocking bugs
- Security issues
- Compliance issues
- Critical production failures

Everything else goes into the post-V1 backlog.

---

# 12. FUTURE IDEAS

Any new feature or enhancement discovered during release preparation goes here instead of into the active V1 build.

Examples include:

- New monetization ideas
- Advanced personalization
- Additional filtering
- New integrations
- Expanded itinerary features
- Social/shared Crawls
- Advanced analytics
- Future Detour enhancements
- Future Nearby enhancements
- Future Crawl enhancements

Future Ideas do not change the V1 release scope.

---

# 13. CORE PROJECT RULES

These rules remain in force:

1. Do not move to the next phase until the current phase works.
2. Preserve working functionality.
3. Do not redesign features unless explicitly requested.
4. New ideas go into Future Ideas.
5. Detour and Crawl share infrastructure wherever practical.
6. The Dining Unhinged website remains the editorial source of truth.
7. Questionable Decisions is the decision-making layer.
8. Do not duplicate the Dining Unhinged database inside the app.
9. Keep credentials out of committed source code.
10. Release preparation is not a new feature-development cycle.

---

# 14. CURRENT NEXT STEP

**Next phase: Repository Audit**

The project is no longer in feature-building mode.

The next work should be release preparation, performed one controlled step at a time.
