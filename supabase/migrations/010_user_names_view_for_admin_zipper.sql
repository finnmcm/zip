-- Migration: Create view for admin/zipper to access user names
-- Date: 2025-10-08
-- Description: Creates a view that exposes only first_name and last_name from users table,
--              with RLS policy allowing admin and zipper roles to read all user names

-- Create a security definer function to check if current user is admin or zipper
-- This bypasses RLS to prevent infinite recursion
CREATE OR REPLACE FUNCTION is_admin_or_zipper()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if the current authenticated user has admin or zipper role
  RETURN EXISTS (
    SELECT 1 
    FROM users 
    WHERE users.id = auth.uid()::text 
    AND users.role IN ('admin'::user_role, 'zipper'::user_role)
  );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION is_admin_or_zipper() TO authenticated;

-- Create a view that exposes only id, first_name, and last_name
CREATE OR REPLACE VIEW user_names AS
SELECT 
    id,
    first_name,
    last_name
FROM users;

-- Enable RLS on the view
ALTER VIEW user_names SET (security_barrier = true);
ALTER VIEW user_names SET (security_invoker = true);

-- Grant usage to authenticated users
GRANT SELECT ON user_names TO authenticated;

-- Create RLS policy for the underlying users table that allows 
-- admins and zippers to access first_name and last_name via the view
CREATE POLICY "Allow admins and zippers to view all user names"
ON users
FOR SELECT
TO authenticated
USING (
  -- Use the security definer function to avoid infinite recursion
  is_admin_or_zipper()
);

-- Add helpful comments
COMMENT ON FUNCTION is_admin_or_zipper IS 'Security definer function that checks if the authenticated user has admin or zipper role. Bypasses RLS to prevent infinite recursion.';
COMMENT ON VIEW user_names IS 'View exposing only user IDs and names for admin/zipper access. Use this view instead of querying users table directly when only names are needed.';

