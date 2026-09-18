# Zlatograd Tracker — iOS

GPS tracker application for Zlatograd Bike n'Run.

Current source snapshot: **v2.5.0**.

The exact Flutter source package is stored under `source/`.
GitHub Actions uses a macOS runner to generate the iOS shell, apply the required permissions/background-location settings and perform an unsigned iOS build.

## Build output

Open **Actions → iOS unsigned build** and download the generated artifact from a successful run.

The generated IPA is **unsigned**. It proves that the project compiles, but installation on a physical iPhone still requires Apple code signing.

## iOS features

- background GPS location mode
- precise-location request
- QR camera permission
- `zlatograd://` deep links
- offline SQLite queue
- battery/network status
- SOS
