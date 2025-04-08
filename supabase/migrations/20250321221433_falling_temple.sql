/*
  # Simplify RLS Policies to Fix Infinite Recursion

  1. Changes
    - Remove circular dependencies in policies
    - Simplify policy conditions
    - Use direct table references where possible
    - Split complex policies into simpler ones

  2. Security
    - Maintain proper access control
    - Keep data isolation between users
    - Preserve collaboration features
*/

-- Drop all existing policies
DROP POLICY IF EXISTS "profiles_select" ON profiles;
DROP POLICY IF EXISTS "profiles_update" ON profiles;
DROP POLICY IF EXISTS "goals_select_own" ON goals;
DROP POLICY IF EXISTS "goals_select_shared" ON goals;
DROP POLICY IF EXISTS "goals_insert" ON goals;
DROP POLICY IF EXISTS "goals_update_own" ON goals;
DROP POLICY IF EXISTS "goals_update_admin" ON goals;
DROP POLICY IF EXISTS "goals_delete" ON goals;
DROP POLICY IF EXISTS "expenses_select" ON expenses;
DROP POLICY IF EXISTS "expenses_insert_own" ON expenses;
DROP POLICY IF EXISTS "expenses_insert_collab" ON expenses;
DROP POLICY IF EXISTS "expenses_update_own" ON expenses;
DROP POLICY IF EXISTS "expenses_update_collab" ON expenses;
DROP POLICY IF EXISTS "expenses_delete_own" ON expenses;
DROP POLICY IF EXISTS "expenses_delete_collab" ON expenses;
DROP POLICY IF EXISTS "adjustments_select" ON budget_adjustments;
DROP POLICY IF EXISTS "adjustments_insert_own" ON budget_adjustments;
DROP POLICY IF EXISTS "adjustments_insert_admin" ON budget_adjustments;
DROP POLICY IF EXISTS "adjustments_update_own" ON budget_adjustments;
DROP POLICY IF EXISTS "adjustments_update_admin" ON budget_adjustments;
DROP POLICY IF EXISTS "adjustments_delete_own" ON budget_adjustments;
DROP POLICY IF EXISTS "adjustments_delete_admin" ON budget_adjustments;
DROP POLICY IF EXISTS "collaborators_select" ON collaborators;
DROP POLICY IF EXISTS "collaborators_insert" ON collaborators;
DROP POLICY IF EXISTS "collaborators_update" ON collaborators;
DROP POLICY IF EXISTS "collaborators_delete" ON collaborators;

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
CREATE POLICY "goals_select"
  ON goals FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM collaborators
      WHERE collaborators.goal_id = goals.id
      AND collaborators.user_id = auth.uid()
    )
  );

CREATE POLICY "goals_insert"
  ON goals FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "goals_update"
  ON goals FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM collaborators
      WHERE collaborators.goal_id = goals.id
      AND collaborators.user_id = auth.uid()
      AND collaborators.role = 'admin'
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
    EXISTS (
      SELECT 1 FROM goals
      WHERE goals.id = expenses.goal_id
      AND (
        goals.user_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM collaborators
          WHERE collaborators.goal_id = goals.id
          AND collaborators.user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "expenses_insert"
  ON expenses FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM goals
      WHERE goals.id = goal_id
      AND (
        goals.user_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM collaborators
          WHERE collaborators.goal_id = goals.id
          AND collaborators.user_id = auth.uid()
          AND collaborators.role IN ('editor', 'admin')
        )
      )
    )
  );

CREATE POLICY "expenses_update"
  ON expenses FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM goals
      WHERE goals.id = expenses.goal_id
      AND (
        goals.user_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM collaborators
          WHERE collaborators.goal_id = goals.id
          AND collaborators.user_id = auth.uid()
          AND collaborators.role IN ('editor', 'admin')
        )
      )
    )
  );

CREATE POLICY "expenses_delete"
  ON expenses FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM goals
      WHERE goals.id = expenses.goal_id
      AND (
        goals.user_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM collaborators
          WHERE collaborators.goal_id = goals.id
          AND collaborators.user_id = auth.uid()
          AND collaborators.role IN ('editor', 'admin')
        )
      )
    )
  );

-- Budget Adjustments
CREATE POLICY "adjustments_select"
  ON budget_adjustments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM goals
      WHERE goals.id = budget_adjustments.goal_id
      AND (
        goals.user_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM collaborators
          WHERE collaborators.goal_id = goals.id
          AND collaborators.user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "adjustments_insert"
  ON budget_adjustments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM goals
      WHERE goals.id = goal_id
      AND (
        goals.user_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM collaborators
          WHERE collaborators.goal_id = goals.id
          AND collaborators.user_id = auth.uid()
          AND collaborators.role = 'admin'
        )
      )
    )
  );

CREATE POLICY "adjustments_update"
  ON budget_adjustments FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM goals
      WHERE goals.id = budget_adjustments.goal_id
      AND (
        goals.user_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM collaborators
          WHERE collaborators.goal_id = goals.id
          AND collaborators.user_id = auth.uid()
          AND collaborators.role = 'admin'
        )
      )
    )
  );

CREATE POLICY "adjustments_delete"
  ON budget_adjustments FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM goals
      WHERE goals.id = budget_adjustments.goal_id
      AND (
        goals.user_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM collaborators
          WHERE collaborators.goal_id = goals.id
          AND collaborators.user_id = auth.uid()
          AND collaborators.role = 'admin'
        )
      )
    )
  );

-- Collaborators
CREATE POLICY "collaborators_select"
  ON collaborators FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM goals
      WHERE goals.id = collaborators.goal_id
      AND goals.user_id = auth.uid()
    )
    OR user_id = auth.uid()
  );

CREATE POLICY "collaborators_insert"
  ON collaborators FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM goals
      WHERE goals.id = goal_id
      AND goals.user_id = auth.uid()
    )
  );

CREATE POLICY "collaborators_update"
  ON collaborators FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM goals
      WHERE goals.id = collaborators.goal_id
      AND goals.user_id = auth.uid()
    )
  );

CREATE POLICY "collaborators_delete"
  ON collaborators FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM goals
      WHERE goals.id = collaborators.goal_id
      AND goals.user_id = auth.uid()
    )
  );