-- Migration: Fix UUID/text type mismatch in is_admin_or_zipper() function
-- Date: 2025-10-09
-- Description: Fixes the type mismatch error "operator does not exist: uuid = text"
--              by ensuring proper type casting in the is_admin_or_zipper() function

-- Recreate the is_admin_or_zipper function with proper type casting
CREATE OR REPLACE FUNCTION is_admin_or_zipper()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if the current authenticated user has admin or zipper role
  -- Cast both sides to text to ensure type compatibility
  RETURN EXISTS (
    SELECT 1 
    FROM users 
    WHERE users.id::text = auth.uid()::text 
    AND users.role IN ('admin'::user_role, 'zipper'::user_role)
  );
END;
$$;

-- Update comment to reflect the fix
COMMENT ON FUNCTION is_admin_or_zipper IS 'Security definer function that checks if the authenticated user has admin or zipper role. Bypasses RLS to prevent infinite recursion. Updated to fix UUID/text comparison.';

