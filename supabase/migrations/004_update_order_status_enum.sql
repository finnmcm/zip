-- Migration to add new order status values to existing enum
-- This migration adds the new status values: in_queue, in_progress, disputed
-- while preserving existing values and dependencies

-- Add new enum values to the existing order_status type
ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'in_queue';
ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'in_progress';
ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'disputed';

-- The existing functions should work with the new enum values
-- Note: New enum values are added to the end of the enum list
