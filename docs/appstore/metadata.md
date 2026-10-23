# App Store Connect — Metadata (English, U.S.)

Copy each block into the matching field in App Store Connect. Character limits are noted next to each field. Every block is within its limit.

---

## Screenshots

| App Store Connect slot | Folder | Size | Count |
|---|---|---|---|
| iPhone 6.9" Display | `iphone-6.9/` | 1320 × 2868 | 8 |
| iPhone 6.5" Display | `iphone-6.5/` | 1284 × 2778 | 8 |
| iPad 12.9" / 13" Display | `ipad-13/` | 2064 × 2752 | 7 |

Upload in file order (01 → 08). They tell the app's story in that order. The PNGs have no alpha channel, so App Store Connect accepts them as they are.

---

## App Information

**Name** (30)
```
Workout Tracker: Sets & Reps
```
> If that name is taken, try: `Lift Log – Workout Tracker` or `RepBook: Gym Workout Log`

**Subtitle** (30)
```
Simple gym log with templates
```

**Primary Category:** Health & Fitness
**Secondary Category:** Sports *(optional)*

**Content Rights:** Does not contain, show, or access third-party content.

**Age Rating:** Answer **None / No** to every question → **4+**

---

## Pricing and Availability

- **Price:** Free
- **Availability:** All countries/regions

---

## Version Information (1.0)

**Promotional Text** (170)
```
Build your workout once, start it in one tap and log every set in seconds. Your weights carry over automatically, so you always know what to lift next.
```

**Description** (4000)
```
Workout Tracker is the fastest way to log your gym sessions — no notebook, no spreadsheets, no guessing what you lifted last time.

Create your routines once, start them with a single tap and check off every set as you go. When you finish a set, the app remembers the weight and reps you actually lifted and uses them as the defaults for next time. Your plan grows with you automatically.

BUILD YOUR TEMPLATES
• Create workouts like Push Day, Pull Day, Leg Day or Full Body
• Add exercises, choose an icon and set default weight and reps for every set
• Drag to reorder exercises and sets in seconds

START IN ONE TAP
• Pick a template and your session is ready with every set pre-filled
• Run more than one workout on the same day

LOG EVERY SET
• Adjust weight and reps with quick +/– controls
• Tap to mark a set as done and see your progress for each exercise
• Defaults update automatically as you get stronger

SEE YOUR PROGRESS
• Charts for total reps and sets across 1, 3 or 6 months, or all time
• A per-exercise breakdown for every workout
• Session-by-session history so you can spot trends at a glance

YOUR COMPLETE HISTORY
• Every workout grouped by day, with start time and completed sets
• Open any past session to review exactly what you did

MADE FOR YOU
• Light, Dark or Automatic appearance
• Available in English, Türkçe, Español and Русский
• Works great on iPhone and iPad

PRIVATE BY DESIGN
Your workouts stay on your device. No account, no sign-up, no ads and no tracking.

Download Workout Tracker and make every rep count.
```

**Keywords** (100, comma-separated, no spaces after commas)
```
gym,lifting,strength,weightlifting,log,journal,routine,planner,bodybuilding,progress,fitness,coach
```
> Words already in the Name and Subtitle (workout, tracker, sets, reps, templates) are indexed anyway, so they are left out of Keywords.

**Support URL** (required)
```
https://github.com/sedatbilece/workout-tracker
```
> Any page where users can reach you works. A GitHub repo is fine if it is public; otherwise use a simple page with a contact email.

**Marketing URL** (optional): leave empty or use the same link.

**Version:** `1.0`

**Copyright**
```
2026 Sedat Bilece
```

**What's New:** not shown for the first release.

---

## App Review Information

**Sign-In Required:** No

**Notes**
```
No account or sign-in is needed. To try the main flow: open the Templates tab, create a template with a few exercises, go back to Today, tap + and pick the template, then mark sets as done. Completed sessions appear under Statistics → History, and progress charts under Statistics → Statistics → Workouts. All data is stored locally on the device.
```

**Contact Information:** your name, phone and email.

---

## App Privacy

- **Privacy Policy URL** (required)
  ```
  https://github.com/sedatbilece/workout-tracker/blob/main/PRIVACY.md
  ```
- **Data Collection:** select **"No, we do not collect data from this app."**
  - The app has no network calls, analytics or accounts. SwiftData stores everything on device.
  - The profile photo is picked with the system photo picker and saved only on the device. That does not count as collection.

---

## Export Compliance (on each build upload)

- **Does your app use encryption?** → **No** (it uses none beyond what the OS provides).
- Tip: add `ITSAppUsesNonExemptEncryption = NO` to Info.plist to skip this question on future uploads.

---

## Before you submit

- The **Calculations** tab and **Settings → "Coming Soon"** in Profile are placeholder screens. App Review often rejects apps with visible "coming soon" content (Guideline 2.1 — App Completeness). Hide them for 1.0 or ship the features.
- English count labels read "5 exercise" / "4 set". Fix the plural forms in `Localizable.xcstrings` before taking final screenshots.
