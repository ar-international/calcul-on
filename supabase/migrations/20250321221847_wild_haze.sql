/*
  # Remove RLS and Simplify Security Model

  1. Changes
    - Disable RLS on all tables
    - Drop all existing policies
    - Keep foreign key constraints for data integrity
    - Rely on table relationships for data access
*/

-- Disable RLS on all tables
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE goals DISABLE ROW LEVEL SECURITY;
ALTER TABLE expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE budget_adjustments DISABLE ROW LEVEL SECURITY;
ALTER TABLE collaborators DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "profiles_select" ON profiles;
DROP POLICY IF EXISTS "profiles_update" ON profiles;
DROP POLICY IF EXISTS "goals_select" ON goals;
DROP POLICY IF EXISTS "goals_insert" ON goals;
DROP POLICY IF EXISTS "goals_update" ON goals;
DROP POLICY IF EXISTS "goals_delete" ON goals;
DROP POLICY IF EXISTS "expenses_select" ON expenses;
DROP POLICY IF EXISTS "expenses_insert" ON expenses;
DROP POLICY IF EXISTS "expenses_update" ON expenses;
DROP POLICY IF EXISTS "expenses_delete" ON expenses;
DROP POLICY IF EXISTS "adjustments_select" ON budget_adjustments;
DROP POLICY IF EXISTS "adjustments_insert" ON budget_adjustments;
DROP POLICY IF EXISTS "adjustments_update" ON budget_adjustments;
DROP POLICY IF EXISTS "adjustments_delete" ON budget_adjustments;
DROP POLICY IF EXISTS "collaborators_select" ON collaborators;
DROP POLICY IF EXISTS "collaborators_insert" ON collaborators;
DROP POLICY IF EXISTS "collaborators_update" ON collaborators;
DROP POLICY IF EXISTS "collaborators_delete" ON collaborators;

-- Drop any other policies that might exist
DO $$ 
DECLARE 
  r RECORD;
BEGIN
  FOR r IN (
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'public'
  ) LOOP
    EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON ' || r.tablename;
  END LOOP;
END $$;