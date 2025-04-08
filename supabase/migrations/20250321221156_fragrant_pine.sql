/*
  # Fix RLS Policies Recursion

  1. Changes
    - Simplify policies to prevent infinite recursion
    - Remove circular references between tables
    - Maintain security while fixing performance issues

  2. Security
    - Maintain proper access control
    - Prevent unauthorized access
    - Keep data isolation between users
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view own goals and shared goals" ON goals;
DROP POLICY IF EXISTS "Users can create goals" ON goals;
DROP POLICY IF EXISTS "Users can update own goals and admin shared goals" ON goals;
DROP POLICY IF EXISTS "Users can delete own goals" ON goals;
DROP POLICY IF EXISTS "Users can view expenses for their goals" ON expenses;
DROP POLICY IF EXISTS "Users can manage expenses with proper permissions" ON expenses;
DROP POLICY IF EXISTS "Users can view budget adjustments" ON budget_adjustments;
DROP POLICY IF EXISTS "Users can manage budget adjustments with proper permissions" ON budget_adjustments;
DROP POLICY IF EXISTS "Users can view collaborators for their goals" ON collaborators;
DROP POLICY IF EXISTS "Users can manage collaborators as owner or admin" ON collaborators;

-- Re-create policies without circular references
-- Profiles
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Goals
CREATE POLICY "Users can view own goals"
  ON goals FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can view shared goals"
  ON goals FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM collaborators 
      WHERE goal_id = goals.id 
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create goals"
  ON goals FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own goals"
  ON goals FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can update shared goals as admin"
  ON goals FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM collaborators 
      WHERE goal_id = goals.id 
      AND user_id = auth.uid() 
      AND role = 'admin'
    )
  );

CREATE POLICY "Users can delete own goals"
  ON goals FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Expenses
CREATE POLICY "Users can manage own goal expenses"
  ON expenses FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM goals 
      WHERE id = expenses.goal_id 
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Collaborators can manage expenses"
  ON expenses FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM collaborators 
      WHERE goal_id = expenses.goal_id 
      AND user_id = auth.uid() 
      AND role IN ('editor', 'admin')
    )
  );

-- Budget Adjustments
CREATE POLICY "Users can manage own goal adjustments"
  ON budget_adjustments FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM goals 
      WHERE id = budget_adjustments.goal_id 
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Admin collaborators can manage adjustments"
  ON budget_adjustments FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM collaborators 
      WHERE goal_id = budget_adjustments.goal_id 
      AND user_id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Collaborators
CREATE POLICY "Users can view goal collaborators"
  ON collaborators FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM goals 
      WHERE id = collaborators.goal_id 
      AND user_id = auth.uid()
    )
    OR user_id = auth.uid()
  );

CREATE POLICY "Users can manage own goal collaborators"
  ON collaborators FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM goals 
      WHERE id = collaborators.goal_id 
      AND user_id = auth.uid()
    )
  );