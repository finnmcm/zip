## MVP Delivery Plan – Zip iOS

### Scope (MVP)
- Authentication: Email-based login with `@u.northwestern.edu` validation (local session storage).
- Shopping: Product list, product details, add to cart.
- Cart: View/edit quantities, persistent with UserDefaults.
- Checkout: Review order, mock payment (Stripe stub), confirmation screen.
- UI: Minimalist, Northwestern branding, accessible.

### Architectural Baseline
- iOS 16+, SwiftUI-first, MVVM.
- UserDefaults for local persistence (cart, session user, products cache).
- Services layer with protocols + simple stub implementations (Supabase, Stripe, Auth).

### Milestones & Steps

1) Project Setup
- [ ] Create directories per repo rules: `Models/`, `Views/`, `ViewModels/`, `Services/`, `Utilities/`.
- [ ] Add `Constants` (colors, spacing, typography), `Color` hex initializer.
- [ ] Configure `ZipApp` with UserDefaults persistence for models.

2) Data Models (UserDefaults)
- [ ] `Product`: id, name, price, imageURL, category, inStock.
- [ ] `CartItem`: id, productId, productName, unitPrice, quantity.
- [ ] `User`: id, email, createdAt.
- [ ] `Order`: id, total, createdAt, status (string for MVP).

3) Services (Stubs for MVP)
- [ ] `AuthenticationService`: validate NU email, store session locally.
- [ ] `SupabaseService`: `fetchProducts()` returns mock data for now.
- [ ] `StripeService`: `processPayment()` stub returning success.

4) ViewModels
- [ ] `AuthViewModel`: login/logout state, NU email validator.
- [ ] `ShoppingViewModel`: load products, search/filter hooks.
- [ ] `CartViewModel`: add/remove/update quantities, compute totals.
- [ ] `CheckoutViewModel`: confirm order, clear cart on success.

5) Views – Authentication
- [ ] `LoginView`: email field, NU validation, continue button.

6) Views – Shopping
- [ ] `ProductCard`: aesthetic minimalist card.
- [ ] `ProductListView`: grid list, add to cart.
- [ ] `ProductDetailView`: large image, description, add to cart.

7) Views – Cart & Checkout
- [ ] `CartItemRow` with stepper.
- [ ] `CartView` shows items, subtotal/fees/total.
- [ ] `CheckoutView` + `PaymentSheet` + `OrderConfirmationView`.

8) Root Navigation
- [ ] `ContentView`: conditional routing (Login vs Main tabs).
- [ ] `TabView`: Shop, Cart, Profile placeholder.

9) UX Polish
- [ ] Apply Northwestern purple, spacing, rounded corners, SF Symbols.
- [ ] Loading and error states; empty states for cart/products.

10) QA & Readiness
- [ ] Build and run; resolve compiler issues.
- [ ] Light manual tests for core flows.
- [ ] Prepare TODOs for Supabase/Stripe real integrations.

### Non-Goals (MVP)
- Push notifications, order tracking beyond confirmation.

### Payments (Updated)
- Create PaymentIntent via Supabase Edge Function `create-payment-intent` using `STRIPE_SECRET_KEY`.
- Initialize Stripe in `ZipApp` with `Configuration.stripePublishableKey`.
- Use `StripeService.processPayment(amount:tip:description:)` to present PaymentSheet and confirm payment.

### Risks & Mitigations
- Missing SDKs: Use stubs to avoid build failures.
- UserDefaults modeling pitfalls: Keep models simple (primitive fields), avoid complex relationships for MVP.
- Auth edge cases: Basic validation only; revisit later.


