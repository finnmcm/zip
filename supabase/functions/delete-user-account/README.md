# Delete User Account Edge Function

This Edge Function handles the complete deletion of a user account, including:

- User data from database tables (orders, order_items, fcm_tokens, users)
- User from Supabase Auth system

## Security

This function uses the `SUPABASE_SERVICE_ROLE_KEY` to perform admin operations, which is only available server-side and never exposed to the client.

## Deployment

To deploy this function to your Supabase project:

```bash
# From the project root directory
supabase functions deploy delete-user-account
```

## Usage

The function is called from the iOS app's `AuthenticationService.deleteAccount()` method:

```swift
let response: DeleteAccountResponse = try await supabase.functions.invoke(
    "delete-user-account"
)
```

Note: The Authorization header is automatically included by the Supabase Swift client when the user is authenticated.

## Function Flow

1. **Authentication**: Verifies the user's JWT token
2. **Database Cleanup**: Deletes user data in correct order:
   - Order items (references orders)
   - Orders
   - FCM tokens
   - User record
3. **Auth Deletion**: Removes user from Supabase Auth system
4. **Response**: Returns success/failure status

## Error Handling

The function includes comprehensive error handling and logging for:
- Invalid or missing authorization
- Database deletion failures
- Auth system deletion failures
- Network issues

## Environment Variables Required

- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key for admin operations

These are automatically available in the Supabase Edge Functions environment.
