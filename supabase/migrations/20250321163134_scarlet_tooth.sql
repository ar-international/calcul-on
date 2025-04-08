/*
  # Fix Goals Table RLS Policy

  1. Changes
    - Drop existing policy for goals table
    - Create new policy with fixed conditions to prevent recursion
    - Separate policies for different operations (SELECT, INSERT, UPDATE, DELETE)

  2. Security
    - Maintain same level of access control
    - Prevent infinite recursion in policy evaluation
*/

-- Drop existing policy
DROP POLICY IF EXISTS "Users can manage own goals" ON goals;

-- Create separate policies for different operations
CREATE POLICY "Users can view own goals and shared goals"
  ON goals FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    id IN (
      SELECT goal_id 
      FROM collaborators 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create goals"
  ON goals FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own goals and admin shared goals"
  ON goals FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid() OR
    id IN (
      SELECT goal_id 
      FROM collaborators 
      WHERE user_id = auth.uid() 
      AND role = 'admin'
    )
  )
  WITH CHECK (
    user_id = auth.uid() OR
    id IN (
      SELECT goal_id 
      FROM collaborators 
      WHERE user_id = auth.uid() 
      AND role = 'admin'
    )
  );

CREATE POLICY "Users can delete own goals and admin shared goals"
  ON goals FOR DELETE
  TO authenticated
  USING (
    user_id = auth.uid() OR
    id IN (
      SELECT goal_id 
      FROM collaborators 
      WHERE user_id = auth.uid() 
      AND role = 'admin'
    )
  );