-- Migration: Add store_credit column to users table
-- Date: 2024-12-19
-- Description: Adds a store_credit column to track user's available store credit

-- Add store_credit column to users table
ALTER TABLE users 
ADD COLUMN store_credit DECIMAL(10,2) NOT NULL DEFAULT 0.00;

-- Add comment to document the column
COMMENT ON COLUMN users.store_credit IS 'User''s available store credit balance in dollars';

-- Create index on store_credit for efficient queries
CREATE INDEX idx_users_store_credit ON users(store_credit);

-- Update existing users to have 0 store credit (if any exist)
UPDATE users SET store_credit = 0.00 WHERE store_credit IS NULL;
