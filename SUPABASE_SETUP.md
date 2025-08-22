# Supabase Integration Setup Guide

This guide will help you set up Supabase integration for the Zip iOS app.

## Prerequisites

- Supabase account and project
- iOS development environment (Xcode 14+)
- iOS 16+ deployment target

## Step 1: Supabase Project Setup

### 1.1 Create a new Supabase project
1. Go to [supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Choose your organization
5. Enter project details:
   - Name: `zip-ios-app`
   - Database Password: (generate a strong password)
   - Region: Choose closest to your users
6. Click "Create new project"

### 1.2 Get your project credentials
1. Go to Project Settings → API
2. Copy the following values:
   - Project URL
   - Anon (public) key
   - Service Role (secret) key (keep this secure)

## Step 2: Database Schema Setup

### 2.1 Create the database tables
Run the following SQL in your Supabase SQL Editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create products table
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    image_url TEXT,
    category VARCHAR(100) NOT NULL,
    in_stock BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    delivery_address TEXT,
    is_verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create cart_items table
CREATE TABLE cart_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create orders table
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    total_amount DECIMAL(10,2) NOT NULL,
    delivery_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    tax DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    delivery_address TEXT NOT NULL,
    payment_intent_id VARCHAR(255),
    estimated_delivery_time TIMESTAMP WITH TIME ZONE,
    actual_delivery_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create order_items table
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL,
    price_at_time DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_in_stock ON products(in_stock);
CREATE INDEX idx_cart_items_user_id ON cart_items(user_id);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
```

### 2.2 Set up Row Level Security (RLS)
```sql
-- Enable RLS on all tables
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Products: Read access for all authenticated users
CREATE POLICY "Products are viewable by everyone" ON products
    FOR SELECT USING (true);

-- Users: Users can only access their own data
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Cart items: Users can only access their own cart
CREATE POLICY "Users can view own cart" ON cart_items
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cart items" ON cart_items
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cart items" ON cart_items
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own cart items" ON cart_items
    FOR DELETE USING (auth.uid() = user_id);

-- Orders: Users can only access their own orders
CREATE POLICY "Users can view own orders" ON orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own orders" ON orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Order items: Users can only access items from their own orders
CREATE POLICY "Users can view own order items" ON order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );
```

## Step 3: iOS App Configuration

### 3.1 Update Configuration.swift
Replace the placeholder values in `Zip/Utilities/Configuration.swift`:

```swift
var supabaseURL: String {
    switch environment {
    case .development:
        return "https://your-project-ref.supabase.co"
    case .production:
        return "https://your-project-ref.supabase.co"
    case .testing:
        return "https://your-project-ref.supabase.co"
    }
}

var supabaseAnonKey: String {
    switch environment {
    case .development:
        return "your-anon-key-here"
    case .production:
        return "your-anon-key-here"
    case .testing:
        return "your-anon-key-here"
    }
}
```

### 3.2 Update Constants.swift
Replace the placeholder values in `Zip/Utilities/Constants.swift`:

```swift
enum SupabaseConfig {
    static let devURL = "https://your-project-ref.supabase.co"
    static let devAnonKey = "your-anon-key-here"
    
    static let prodURL = "https://your-project-ref.supabase.co"
    static let prodAnonKey = "your-anon-key-here"
}
```

## Step 4: Authentication Setup

### 4.1 Configure Authentication in Supabase
1. Go to Authentication → Settings
2. Configure the following:
   - Site URL: `https://your-domain.com`
   - Redirect URLs: Add your app's custom URL scheme
   - Email templates: Customize as needed

### 4.2 Set up Email Templates
1. Go to Authentication → Email Templates
2. Customize the following templates:
   - Confirm signup
   - Magic Link
   - Change email address
   - Reset password

### 4.3 Configure OAuth Providers (Optional)
1. Go to Authentication → Providers
2. Enable and configure:
   - Google (for @u.northwestern.edu emails)
   - Apple (for iOS app)

## Step 5: Storage Setup (for Product Images)

### 5.1 Create Storage Bucket
1. Go to Storage → Buckets
2. Create a new bucket called `product-images`
3. Set it to public

### 5.2 Set up Storage Policies
```sql
-- Allow public read access to product images
CREATE POLICY "Product images are publicly accessible" ON storage.objects
    FOR SELECT USING (bucket_id = 'product-images');

-- Allow authenticated users to upload product images
CREATE POLICY "Authenticated users can upload product images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'product-images' 
        AND auth.role() = 'authenticated'
    );
```

## Step 6: Edge Functions Setup (for Stripe Integration)

### 6.1 Create Edge Function for Stripe Webhooks
1. Go to Edge Functions
2. Create a new function called `stripe-webhook`
3. Use the template from the Stripe integration guide

### 6.2 Deploy Edge Functions
```bash
supabase functions deploy stripe-webhook
```

## Step 7: Testing

### 7.1 Test Database Connection
1. Build and run the app
2. Check the console for any connection errors
3. Verify that the `Configuration.shared.isConfigured` returns true

### 7.2 Test Authentication
1. Try to sign up with a test email
2. Verify email confirmation works
3. Test sign in functionality

### 7.3 Test Data Operations
1. Verify products are fetched from the database
2. Test cart operations
3. Test order creation

## Troubleshooting

### Common Issues

1. **"Supabase client is not configured" error**
   - Check that your URL and keys are correctly set in Configuration.swift
   - Verify the project is active in Supabase dashboard

2. **Authentication errors**
   - Check RLS policies are correctly configured
   - Verify email templates are set up
   - Check redirect URLs in authentication settings

3. **Database connection issues**
   - Verify your database is active
   - Check that RLS is properly configured
   - Ensure your API keys have the correct permissions

### Debug Mode
The app includes debug logging when running in development mode. Check the console for detailed error messages.

## Security Considerations

1. **Never commit API keys to version control**
   - Use environment variables or configuration files
   - Consider using a secrets management service

2. **Row Level Security (RLS)**
   - All tables have RLS enabled
   - Users can only access their own data
   - Products are publicly readable

3. **API Key Permissions**
   - Anon key: Limited permissions for public data
   - Service role key: Full access (keep secure)

## Next Steps

After completing this setup:

1. **Implement the actual Supabase functions** in `SupabaseService.swift`
2. **Add error handling** for network failures
3. **Implement offline support** with local caching
4. **Add push notifications** for order updates
5. **Set up monitoring** and analytics

## Support

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
- [Supabase Community](https://github.com/supabase/supabase/discussions)
