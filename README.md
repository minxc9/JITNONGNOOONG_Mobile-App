# JITNONGNOOONG Mobile App

Flutter mobile client for the MharRuengSang food delivery system.

## Overview

This app connects to the existing backend and provides mobile flows for:

- Customer
- Restaurant
- Rider
- Admin

Main features include:

- Login with OTP verification
- Restaurant browsing and search
- Cart and checkout
- Customer order tracking with simulated rider map tracking
- Restaurant order and menu management
- Rider delivery management
- Admin dashboard and account/promotions management

## Requirements

Before running the app, make sure you have:

- Flutter SDK installed
- Dart SDK installed
- Android Studio or VS Code with Flutter extension
- An Android emulator or Android device
- The backend API running on port `8080`

Check Flutter installation:

```bash
flutter doctor
```

## Project Location

Current local path:
example

```bash
/Users/mn/Downloads/JITNONGNOOONG-Mobile-App-main-3
```

## Install Dependencies

From the project folder, run:

```bash
flutter pub get
```

## Backend Requirement

The app uses this API base URL in [lib/services/api_service.dart](/Users/mn/Downloads/JITNONGNOOONG-Mobile-App-main-3/lib/services/api_service.dart):

```dart
static const String baseUrl = "http://127.0.0.1:8080/api/v1";
```

So the backend must be running locally at:

```text
http://127.0.0.1:8080
```

If you run the app on a real Android device, `127.0.0.1` points to the device itself, not your computer. In that case, change the base URL to your computer's local IP address, for example:

```dart
static const String baseUrl = "http://192.168.x.x:8080/api/v1";
```

## Run the App

List available devices:

```bash
flutter devices
```

Run the app:

```bash
flutter run
```

Run on Chrome:

```bash
flutter run -d chrome
```

Run on a specific Android emulator:

```bash
flutter run -d emulator-5554
```

## Demo Login Accounts

Use the quick demo login chips on the login screen, or enter the credentials manually.

### Customer

- Email: `customer@foodexpress.com`
- Password: `customer123`

### Restaurant

- Email: `restaurant@foodexpress.com`
- Password: `restaurant123`

### Rider

- Email: `rider@foodexpress.com`
- Password: `rider123`

### Admin

- Email: `admin@foodexpress.com`
- Password: `admin123`

After login, enter any 6-digit OTP on the OTP screen if your backend is using the provided mock OTP behavior.

## Main App Workflows

### Customer

1. Login as customer
2. Browse or search restaurants
3. Open a restaurant
4. Add menu items to cart
5. Enter delivery address and place order
6. Open `My Orders`
7. View order details and live tracking

### Restaurant

1. Login as restaurant
2. Open dashboard
3. View orders
4. Update order status
5. Manage menu items
6. Manage categories and promotions

### Rider

1. Login as rider
2. View available orders
3. Accept an order
4. Open delivery details
5. View customer contact and map buttons
6. Confirm delivery

### Admin

1. Login as admin
2. Open admin dashboard
3. Review overview stats
4. Manage accounts
5. Manage promotions

## Useful Commands

Format code:

```bash
dart format lib test
```

Analyze project:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

## Troubleshooting

### App cannot connect to backend

Check:

- backend is running on port `8080`
- API base URL is correct
- emulator/device can access the backend host

### Android device cannot reach localhost backend

Use your computer's LAN IP instead of `127.0.0.1`.

### Login succeeds on web but not mobile

Check:

- backend data matches the demo account
- mobile app base URL points to the same backend as the website
- role-specific backend routes return valid data

### Flutter build problems

Try:

```bash
flutter clean
flutter pub get
flutter analyze
```

## Repository

GitHub repository:

[https://github.com/minxc9/JITNONGNOOONG_Mobile-App](https://github.com/minxc9/JITNONGNOOONG_Mobile-App)
