-- Migration: Add RLS policy for cart_items table
-- Date: 2025-10-08
-- Description: Allows users with 'admin' or 'zipper' roles to read all cart_items

-- Note: This migration depends on the is_admin_or_zipper() function from migration 010
-- Make sure migration 010 is applied first

-- Enable RLS on cart_items table if not already enabled
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

-- Create policy to allow admins and zippers to read all cart items
-- Uses the security definer function to avoid potential RLS recursion issues
CREATE POLICY "Allow admins and zippers to read all cart items"
ON cart_items
FOR SELECT
TO authenticated
USING (
  -- Use the security definer function from migration 010
  is_admin_or_zipper()
);

-- Add comment to document the policy
COMMENT ON POLICY "Allow admins and zippers to read all cart items" ON cart_items 
IS 'Grants SELECT access to all cart_items for users with admin or zipper role. Uses is_admin_or_zipper() function to avoid RLS recursion.';

