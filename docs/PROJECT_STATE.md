\# Questionable Decisions — Project State



Last Updated: 2026-09-02



\## Current Development Area



Detour



\## Current Framework Phase



Detour — Phase 6: Start Detour



\## Current Task



Actual GPS tracking for an active Detour.



\## Master Framework



The authoritative roadmap is `MASTER\_FRAMEWORK.md`.



Detour sequence:



1\. Navigation \& Structure

2\. Detour Home Screen

3\. Route Calculation

4\. Detour Recommendations

5\. Build Actual Detour

6\. Start Detour

7\. Proximity Notifications

8\. Background Location

9\. Navigation

10\. Saved Integration

11\. Booking.com Integration

12\. Road Trip Itinerary

13\. Notification Personality

14\. Safety

15\. Backend Architecture

16\. Analytics

17\. Help Documentation

18\. Testing

19\. Release



\## Current Position



We have moved into the actual GPS/location-tracking portion of Detour.



The immediate goal is to implement and verify Detour GPS tracking without unnecessarily changing existing functionality.



\## Existing Project Rules



\### Decision Paralysis



LOCKED.



Do not change Decision Paralysis functionality, selection logic, behavior, or interaction.



\### Nearby



Nearby functionality must be preserved.



Nearby is the spontaneous/default discovery experience.



\### Crawl



Crawl is the planned experience.



Existing Crawl functionality must be preserved unless a change is explicitly required by the framework.



\### Detour



Detour is the en-route experience.



Build according to the master framework in order.



\### Dining Unhinged / Sanity



Dining Unhinged/Sanity remains the editorial source of truth.



Do not create a duplicate restaurant database inside the app.



\### Shared Infrastructure



Detour and Crawl should share infrastructure wherever practical.



Avoid creating duplicate systems for:



\- Location

\- Routes

\- Venues

\- Proximity

\- Notifications

\- Saved venues

\- Navigation

\- Sanity/API access



\### API Credentials



Google API credentials must not be hardcoded into application source.



Credentials must remain in appropriate local, Git-ignored secret configuration.



Existing working Google Maps, Google Places, and Google Routes functionality must be preserved.



\## Recent Completed Work



\### Crawl



\- Manual Crawl venue selection implemented.

\- Selected stops remain reorderable.

\- Existing Crawl stop limits preserved.

\- Decision Paralysis remained unchanged.

\- Crawl background location monitoring implemented.

\- Crawl background 500 m proximity notifications implemented.

\- Android background-location permissions added.

\- iOS background-location configuration added.

\- Existing foreground Crawl behavior preserved.



\### Copyright



\- CIPO copyright registration completed.

\- Questionable Decisions registration number: 1249281.

\- Copyright source-code notice added to first-party Dart files.

\- Copyright change committed.



\## Current Analyzer State



`flutter analyze` currently reports 12 existing issues:



\- 10 `avoid\_print` infos in `lib/core/network/api\_logger.dart`

\- 1 `use\_build\_context\_synchronously` info in `lib/screens/nearby\_screen.dart`

\- 1 unused-field warning in `lib/screens/saved\_screen.dart`



There are 0 analyzer errors.



These issues are not part of the current Detour GPS task and should not be changed unless specifically required.



\## Next Step



Audit the existing Detour location/GPS implementation against Detour Phase 6 of the master framework.



Determine:



1\. What GPS/location functionality already exists.

2\. What Phase 6 requires.

3\. What is missing.

4\. Which existing shared infrastructure can be reused.

5\. The smallest safe implementation required for the next framework item.



Do not redesign unrelated functionality.



\## Working Principle



Complete the current framework phase before moving to the next phase.



Additional ideas discovered during development belong in Future Ideas rather than the active build.

