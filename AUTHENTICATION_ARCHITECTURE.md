# Authentication Architecture - Zip iOS App

## Overview

The authentication system has been refactored to have a clean separation of concerns between different layers of the app.

## Architecture Layers

### 1. **AuthenticationService** - Data Layer
**Responsibility**: Raw Supabase API calls and data operations

**What it does**:
- Manages Supabase client connection
- Handles raw authentication API calls
- Performs database operations
- Transforms data between Supabase and app models
- Throws raw authentication errors

**What it doesn't do**:
- UI validation
- Business logic
- State management
- User interaction handling

**Key Methods**:
```swift
func signUp(email: String, password: String, firstName: String, lastName: String, phoneNumber: String) async throws -> User
func signIn(email: String, password: String) async throws -> User
func signOut() async throws
func getCurrentUser() async throws -> User?
func resetPassword(email: String) async throws
func updateProfile(_ user: User) async throws -> User
```

### 2. **AuthViewModel** - Business Logic Layer
**Responsibility**: UI state management, validation, and business logic coordination

**What it does**:
- Manages authentication state (`@Published` properties)
- Handles form validation
- Coordinates between UI and service layer
- Manages loading states and error messages
- Handles user interactions
- Provides computed validation properties

**What it doesn't do**:
- Direct API calls
- Data transformation
- Raw error handling

**Key Properties**:
```swift
@Published var isAuthenticated: Bool
@Published var currentUser: User?
@Published var isLoading: Bool
@Published var errorMessage: String?
```

**Key Methods**:
```swift
func signUp() async
func login() async
func logout() async
func resetPassword() async
func updateProfile() async
```

### 3. **String+Validation** - Utility Layer
**Responsibility**: Reusable validation logic

**What it provides**:
- Email validation (general and Northwestern-specific)
- Password validation
- Phone number validation
- Name validation
- String utility methods

**Usage**:
```swift
email.isValidNorthwesternEmail
password.isValidPassword
phoneNumber.isValidPhoneNumber
firstName.isValidName
```

## Data Flow

```
UI (LoginView) → AuthViewModel → AuthenticationService → Supabase
                ↓
            State Updates ← Error Handling ← Response Processing
```

1. **User interacts** with LoginView
2. **AuthViewModel** validates input and manages state
3. **AuthenticationService** makes API calls to Supabase
4. **Response** flows back through the chain
5. **UI updates** based on AuthViewModel state changes

## Benefits of This Architecture

### ✅ **Separation of Concerns**
- Each layer has a single, clear responsibility
- Easy to test individual components
- Easy to modify one layer without affecting others

### ✅ **Reusability**
- Validation logic can be used across the app
- AuthenticationService can be used by other ViewModels
- String extensions are app-wide utilities

### ✅ **Maintainability**
- Clear where to make changes
- Easy to debug issues
- Consistent error handling

### ✅ **Testability**
- Mock AuthenticationService for ViewModel tests
- Test validation logic independently
- Test UI logic without network calls

### ✅ **Scalability**
- Easy to add new validation rules
- Easy to add new authentication methods
- Easy to switch authentication providers

## Error Handling

### **AuthenticationService Level**
- Throws raw `AuthError` types
- Handles network and database errors
- Provides technical error descriptions

### **AuthViewModel Level**
- Catches and processes errors
- Converts technical errors to user-friendly messages
- Manages error state for UI

### **UI Level**
- Displays error messages
- Handles error state styling
- Provides user feedback

## Example Usage

### **In a View**:
```swift
@ObservedObject var authViewModel: AuthViewModel

Button("Sign Up") {
    Task {
        await authViewModel.signUp()
    }
}
.disabled(!authViewModel.isValidSignUp)
```

### **In another ViewModel**:
```swift
private let authService = AuthenticationService()

func someFunction() async {
    if let user = try? await authService.getCurrentUser() {
        // Use user data
    }
}
```

### **Validation anywhere**:
```swift
if email.isValidNorthwesternEmail {
    // Proceed with Northwestern-specific logic
}
```

## Best Practices

1. **Never call AuthenticationService directly from Views**
2. **Always go through AuthViewModel for UI operations**
3. **Use String validation extensions for consistency**
4. **Keep AuthenticationService focused on data operations**
5. **Keep AuthViewModel focused on state management**
6. **Use proper error handling at each layer**

## Future Enhancements

- **Biometric Authentication**: Add Face ID/Touch ID support
- **Social Login**: Google, Apple Sign-In integration
- **Multi-factor Authentication**: SMS/Email verification
- **Session Management**: Token refresh, auto-logout
- **Offline Support**: Local authentication state caching
