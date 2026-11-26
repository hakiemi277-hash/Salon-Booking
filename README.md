# SALON BOOKING

Flutter Android app starter for salon/beauty appointments, cake orders, and item rentals.

## Current prototype
- Home screen with 20 editable sample salon entries.
- Expandable salon-specific service categories with horizontal image galleries.
- Separate **BALLAN QABSO** flow for beauty services and cake orders.
- Separate **KIRAYSO** section for SAD RENTAL, TAASH, TOOBKA MEHERKA, and SUBEECIYAD.
- Cake request form: size, tiers, design/color details, cake text, delivery date/time, and location.
- GitHub Actions workflow builds a release APK on pushes to the main branch.

## Build APK
Open the **Actions** tab and select **Build Salon Booking APK**. Download the `salon-booking-release-apk` artifact when the workflow completes successfully.

## Important
This is an initial UI prototype. Salon edits are currently local demo state only. Authentication, persistent database storage, real booking submission, admin approval, image uploads, and rental inventory/availability still need backend implementation before production use.
