# First Crack

A Flutter application built with MVC (Model-View-Controller) architecture following Splendid coding standards.

## Architecture

This project follows a strict MVC pattern for all screens:

### Route (Entry Point)
- Each screen has a `*_route.dart` file containing a `StatefulWidget`
- The route's `createState()` method returns the corresponding controller
- Routes are responsible only for defining the screen entry point

### Controller (Business Logic)
- Controllers extend `State<RouteWidget>` and handle all business logic
- Controllers manage state and call `setState()` to trigger UI updates
- All event handlers and data manipulation logic belongs in controllers

### View (Presentation)
- Views are `StatelessWidget` classes that handle only UI presentation
- Views receive the controller as a parameter for accessing state and methods
- Views should be "dumb" and purely declarative

## Getting Started

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the application:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
└── screens/
    └── home/
        ├── home_route.dart      # Route definition
        ├── home_controller.dart # Business logic and state
        └── home_view.dart       # UI presentation
```

## Development Guidelines

- Follow the MVC pattern for all new screens
- Use `setState()` for state management
- Extract reusable UI components into separate widget classes
- Use `Padding` widgets for spacing, not `SizedBox`
- Maintain 120-character line length
- Document all public classes and methods

For more detailed coding standards, refer to the project's analysis_options.yaml and linting configuration.