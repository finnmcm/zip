# Order Status Banner Component

## Overview

The Order Status Banner is a DoorDash-style banner component that appears at the top of the screen whenever a user has an order with status `in_queue` or `in_progress`. It provides real-time updates on order status and estimated delivery time.

## Features

- **Real-time Status Updates**: Shows current order status (in queue, in progress)
- **ETA Display**: Shows estimated delivery time with countdown
- **Interactive**: Tap to view order details (navigates to order tracking)
- **Dismissible**: Users can dismiss the banner if desired
- **Auto-refresh**: Updates every 30 seconds automatically
- **Smooth Animations**: Spring-based animations for appearance/disappearance
- **Northwestern Branding**: Uses Northwestern purple colors and styling

## Components

### 1. OrderStatusBanner
The main banner component that displays order information.

**Properties:**
- `order: Order` - The order to display
- `onTap: () -> Void` - Callback when banner is tapped
- `onDismiss: () -> Void` - Callback when dismiss button is pressed

**Features:**
- Status-specific icons (clock for queue, bicycle for in-progress)
- Status-specific colors (Northwestern purple for queue, accent for in-progress)
- Progress bar for in-progress orders
- ETA countdown with smart formatting

### 2. OrderStatusBannerContainer
A container component that conditionally shows the banner only when there's an active order.

**Properties:**
- `activeOrder: Order?` - The active order to display
- `onBannerTap: () -> Void` - Callback for banner tap
- `onBannerDismiss: () -> Void` - Callback for banner dismiss

### 3. OrderStatusViewModel
Manages the state and business logic for order status.

**Key Methods:**
- `loadActiveOrder(userId: String)` - Loads active order for a user
- `refreshOrderStatus(userId: String)` - Manually refreshes order status
- `dismissBanner()` - Hides the banner
- `handleBannerTap()` - Handles banner tap events

## Integration

### Adding to MainTabView

The banner is already integrated into `MainTabView` and will automatically appear when there are active orders:

```swift
.overlay(
    VStack {
        // Order status banner at the top
        OrderStatusBannerContainer(
            activeOrder: orderStatusViewModel.activeOrder,
            onBannerTap: {
                orderStatusViewModel.handleBannerTap()
            },
            onBannerDismiss: {
                orderStatusViewModel.dismissBanner()
            }
        )
        
        Spacer()
        
        // Other banner content...
    }
)
```

### Automatic Loading

The banner automatically loads active orders when:
- The app launches
- User authentication changes
- Every 30 seconds (if there's an active order)

## Usage Examples

### Basic Implementation

```swift
struct ContentView: View {
    @StateObject private var orderStatusViewModel = OrderStatusViewModel()
    
    var body: some View {
        VStack {
            // Your main content
        }
        .overlay(
            OrderStatusBannerContainer(
                activeOrder: orderStatusViewModel.activeOrder,
                onBannerTap: {
                    // Navigate to order details
                },
                onBannerDismiss: {
                    orderStatusViewModel.dismissBanner()
                }
            )
        )
    }
}
```

### Manual Order Loading

```swift
// Load active order for a user
await orderStatusViewModel.loadActiveOrder(userId: "user-123")

// Manually refresh
await orderStatusViewModel.refreshOrderStatus(userId: "user-123")
```

## Styling

### Colors
- **In Queue**: Northwestern Purple (`AppColors.northwesternPurple`)
- **In Progress**: Accent Color (`AppColors.accent`)
- **Text**: White with opacity variations
- **Background**: Linear gradient with status-specific colors

### Typography
- **Status Message**: Headline font, semibold weight
- **ETA**: Subheadline font, regular weight
- **Icons**: Title2 size for main icons, title3 for dismiss button

### Layout
- **Padding**: Uses `AppMetrics.spacing` and `AppMetrics.spacingLarge`
- **Corner Radius**: `AppMetrics.cornerRadiusLarge`
- **Shadow**: Subtle shadow for depth
- **Spacing**: Consistent spacing between elements

## Testing

### Demo View

A demo view is available in the Profile section (DEBUG builds only) that allows testing different order statuses:

1. Navigate to Profile → Order Banner Demo
2. Use the segmented control to switch between statuses
3. Use buttons to show/hide different order types
4. Test banner interactions and animations

### Mock Data

The `OrderStatusViewModel` includes mock data for development:

```swift
// Load mock in-progress order
orderStatusViewModel.loadMockActiveOrder()
```

## Future Enhancements

### Planned Features
- **Push Notifications**: Real-time updates via push notifications
- **Order Tracking**: Integration with order tracking view
- **Delivery Updates**: Real-time delivery status updates
- **ETA Refinement**: More accurate delivery time estimates
- **Order History**: Quick access to recent orders

### Customization Options
- **Banner Position**: Configurable top/bottom positioning
- **Auto-dismiss**: Automatic dismissal after certain time
- **Sound Effects**: Audio feedback for status changes
- **Haptic Feedback**: Tactile feedback for interactions

## Troubleshooting

### Common Issues

1. **Banner Not Showing**
   - Check if user is authenticated
   - Verify order status is `in_queue` or `in_progress`
   - Check console for error messages

2. **Banner Not Updating**
   - Verify refresh timer is running
   - Check network connectivity
   - Ensure Supabase service is configured

3. **Animation Issues**
   - Check if animations are disabled in system settings
   - Verify SwiftUI animation modifiers are correct

### Debug Information

Enable debug logging by checking the console for:
- ✅ Active order found messages
- ❌ Error messages
- 📱 Mock data loading messages
- 🎯 Banner interaction messages

## Dependencies

- **SwiftUI**: UI framework
- **Foundation**: Basic data types and utilities
- **AppColors**: Custom color definitions
- **AppMetrics**: Custom spacing and sizing constants
- **Order Model**: Order data structure
- **SupabaseService**: Backend service integration

## Performance Considerations

- **Auto-refresh**: Limited to 30-second intervals
- **Memory Management**: Proper cleanup of timers and observers
- **View Updates**: Efficient state management with @Published properties
- **Animation**: Smooth 60fps animations with spring physics
