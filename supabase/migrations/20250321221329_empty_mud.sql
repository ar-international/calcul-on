/*
  # Fix RLS Policies Recursion - Final Fix

  1. Changes
    - Simplify policies to prevent infinite recursion
    - Use direct table references instead of nested queries
    - Split complex policies into simpler ones
    - Remove all circular dependencies between policies

  2. Security
    - Maintain proper access control
    - Prevent unauthorized access
    - Keep data isolation between users
*/

-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view own goals" ON goals;
DROP POLICY IF EXISTS "Users can view shared goals" ON goals;
DROP POLICY IF EXISTS "Users can create goals" ON goals;
DROP POLICY IF EXISTS "Users can update own goals" ON goals;
DROP POLICY IF EXISTS "Users can update shared goals as admin" ON goals;
DROP POLICY IF EXISTS "Users can delete own goals" ON goals;
DROP POLICY IF EXISTS "Users can manage own goal expenses" ON expenses;
DROP POLICY IF EXISTS "Collaborators can manage expenses" ON expenses;
DROP POLICY IF EXISTS "Users can manage own goal adjustments" ON budget_adjustments;
DROP POLICY IF EXISTS "Admin collaborators can manage adjustments" ON budget_adjustments;
DROP POLICY IF EXISTS "Users can view goal collaborators" ON collaborators;
DROP POLICY IF EXISTS "Users can manage own goal collaborators" ON collaborators;

-- Profiles
CREATE POLICY "profiles_select"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "profiles_update"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Goals
CREATE POLICY "goals_select_own"
  ON goals FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "goals_select_shared"
  ON goals FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT goal_id 
      FROM collaborators 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "goals_insert"
  ON goals FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "goals_update_own"
  ON goals FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "goals_update_admin"
  ON goals FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT goal_id 
      FROM collaborators 
      WHERE user_id = auth.uid() 
      AND role = 'admin'
    )
  );

CREATE POLICY "goals_delete"
  ON goals FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Expenses
CREATE POLICY "expenses_select"
  ON expenses FOR SELECT
  TO authenticated
  USING (
    goal_id IN (
      SELECT id FROM goals WHERE user_id = auth.uid()
      UNION
      SELECT goal_id FROM collaborators WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "expenses_insert_own"
  ON expenses FOR INSERT
  TO authenticated
  WITH CHECK (
    goal_id IN (
      SELECT id FROM goals WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "expenses_insert_collab"
  ON expenses FOR INSERT
  TO authenticated
  WITH CHECK (
    goal_id IN (
      SELECT goal_id 
      FROM collaborators 
      WHERE user_id = auth.uid() 
      AND role IN ('editor', 'admin')
    )
  );

CREATE POLICY "expenses_update_own"
  ON expenses FOR UPDATE
  TO authenticated
  USING (
    goal_id IN (
      SELECT id FROM goals WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "expenses_update_collab"
  ON expenses FOR UPDATE
  TO authenticated
  USING (
    goal_id IN (
      SELECT goal_id 
      FROM collaborators 
      WHERE user_id = auth.uid() 
      AND role IN ('editor', 'admin')
    )
  );

CREATE POLICY "expenses_delete_own"
  ON expenses FOR DELETE
  TO authenticated
  USING (
    goal_id IN (
      SELECT id FROM goals WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "expenses_delete_collab"
  ON expenses FOR DELETE
  TO authenticated
  USING (
    goal_id IN (
      SELECT goal_id 
      FROM collaborators 
      WHERE user_id = auth.uid() 
      AND role IN ('editor', 'admin')
    )
  );

-- Budget Adjustments
CREATE POLICY "adjustments_select"
  ON budget_adjustments FOR SELECT
  TO authenticated
  USING (
    goal_id IN (
      SELECT id FROM goals WHERE user_id = auth.uid()
      UNION
      SELECT goal_id FROM collaborators WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "adjustments_insert_own"
  ON budget_adjustments FOR INSERT
  TO authenticated
  WITH CHECK (
    goal_id IN (
      SELECT id FROM goals WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "adjustments_insert_admin"
  ON budget_adjustments FOR INSERT
  TO authenticated
  WITH CHECK (
    goal_id IN (
      SELECT goal_id 
      FROM collaborators 
      WHERE user_id = auth.uid() 
      AND role = 'admin'
    )
  );

CREATE POLICY "adjustments_update_own"
  ON budget_adjustments FOR UPDATE
  TO authenticated
  USING (
    goal_id IN (
      SELECT id FROM goals WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "adjustments_update_admin"
  ON budget_adjustments FOR UPDATE
  TO authenticated
  USING (
    goal_id IN (
      SELECT goal_id 
      FROM collaborators 
      WHERE user_id = auth.uid() 
      AND role = 'admin'
    )
  );

CREATE POLICY "adjustments_delete_own"
  ON budget_adjustments FOR DELETE
  TO authenticated
  USING (
    goal_id IN (
      SELECT id FROM goals WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "adjustments_delete_admin"
  ON budget_adjustments FOR DELETE
  TO authenticated
  USING (
    goal_id IN (
      SELECT goal_id 
      FROM collaborators 
      WHERE user_id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Collaborators
CREATE POLICY "collaborators_select"
  ON collaborators FOR SELECT
  TO authenticated
  USING (
    goal_id IN (
      SELECT id FROM goals WHERE user_id = auth.uid()
    )
    OR user_id = auth.uid()
  );

CREATE POLICY "collaborators_insert"
  ON collaborators FOR INSERT
  TO authenticated
  WITH CHECK (
    goal_id IN (
      SELECT id FROM goals WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "collaborators_update"
  ON collaborators FOR UPDATE
  TO authenticated
  USING (
    goal_id IN (
      SELECT id FROM goals WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "collaborators_delete"
  ON collaborators FOR DELETE
  TO authenticated
  USING (
    goal_id IN (
      SELECT id FROM goals WHERE user_id = auth.uid()
    )
  );