-- Migration: Add is_fixed column to vtiger_cvcolumnlist
-- Date: 2025-11-28
-- Purpose: Support fixed columns feature in list view

ALTER TABLE vtiger_cvcolumnlist 
ADD COLUMN is_fixed TINYINT(1) DEFAULT 0 
COMMENT 'Whether column is fixed during horizontal scroll (max 3 columns can be fixed)';

-- Add index for better query performance
CREATE INDEX idx_cvid_fixed ON vtiger_cvcolumnlist(cvid, is_fixed);
