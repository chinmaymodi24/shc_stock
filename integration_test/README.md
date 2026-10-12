# Integration tests

Drive the real app against a real backend. They are separate from `test/`
(which runs in milliseconds with fakes) because they need a device.

## What is covered

`app_flow_test.dart` — sign in → add a sale (server-issued number, client and
item pickers, GST block) → it shows in the list → open its bill.

## Run on the Android emulator

```bash
# 1. backend running on :4000 (the emulator reaches it through `adb reverse`)
node backend/scripts/e2eFixture.js setup        # ZZ-E2E user, client, product
flutter test integration_test/app_flow_test.dart -d emulator-5554
node backend/scripts/e2eFixture.js teardown     # removes every ZZ-E2E row
```

Custom credentials: `--dart-define=E2E_EMAIL=… --dart-define=E2E_PASSWORD=…`.

## Run in a browser

```bash
chromedriver --port=4444
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_flow_test.dart -d chrome
```

A desktop-sized window exercises the web forms; a phone-sized one the mobile
forms. `test_driver/integration_test.dart` is the standard two-line driver.

## Rules

* Test data is always named `ZZ-E2E…` and `teardown` deletes only that.
* Never point it at a database that holds real data you cannot restore — take
  `npm run backup:db` first.
