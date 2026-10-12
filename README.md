# resqai

A new Flutter project.

## Incident report database

Incident reports are sent from the Flutter app to the backend's
`POST /incident-reports` endpoint and stored in the Neon PostgreSQL
`incident_reports` table. The backend creates the table when it starts.
This table uses a separate Neon database from the login tables.

Configure these backend environment variables in Railway (or in
`backend/.env` for local development):

- `DATABASE_URL`: the Neon PostgreSQL connection string.
- `INCIDENT_DATABASE_URL`: the connection string for the separate Neon
  incident-report database.
- `FIREBASE_SERVICE_ACCOUNT_JSON`: the Firebase service account JSON used by
  the backend to verify the signed-in user's ID token.

Keep these values on the backend; do not add them to Flutter code or commit
them. Incident photos are still uploaded to Firebase Storage, and their
download URLs are stored with the report in Neon.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.