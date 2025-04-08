/*
  # Re-enable RLS and Fix Access Policies

  1. Changes
    - Re-enable RLS on all tables
    - Create proper policies for data access
    - Ensure users can only see their own data and shared goals

  2. Security
    - Strict access control based on user ID
    - Proper handling of shared resources
    - Maintain data isolation between users
*/

-- Re-enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaborators ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Goals policies
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
  );

CREATE POLICY "Users can delete own goals"
  ON goals FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Expenses policies
CREATE POLICY "Users can view expenses for their goals"
  ON expenses FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM goals g
      LEFT JOIN collaborators c ON c.goal_id = g.id
      WHERE g.id = expenses.goal_id
      AND (g.user_id = auth.uid() OR c.user_id = auth.uid())
    )
  );

CREATE POLICY "Users can manage expenses with proper permissions"
  ON expenses FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM goals g
      LEFT JOIN collaborators c ON c.goal_id = g.id
      WHERE g.id = expenses.goal_id
      AND (
        g.user_id = auth.uid() OR
        (c.user_id = auth.uid() AND c.role IN ('editor', 'admin'))
      )
    )
  );

-- Budget adjustments policies
CREATE POLICY "Users can view budget adjustments"
  ON budget_adjustments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM goals g
      LEFT JOIN collaborators c ON c.goal_id = g.id
      WHERE g.id = budget_adjustments.goal_id
      AND (g.user_id = auth.uid() OR c.user_id = auth.uid())
    )
  );

CREATE POLICY "Users can manage budget adjustments with proper permissions"
  ON budget_adjustments FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM goals g
      LEFT JOIN collaborators c ON c.goal_id = g.id
      WHERE g.id = budget_adjustments.goal_id
      AND (
        g.user_id = auth.uid() OR
        (c.user_id = auth.uid() AND c.role = 'admin')
      )
    )
  );

-- Collaborators policies
CREATE POLICY "Users can view collaborators for their goals"
  ON collaborators FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM goals g
      WHERE g.id = collaborators.goal_id
      AND (
        g.user_id = auth.uid() OR
        user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can manage collaborators as owner or admin"
  ON collaborators FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM goals g
      LEFT JOIN collaborators c ON c.goal_id = g.id
      WHERE g.id = collaborators.goal_id
      AND (
        g.user_id = auth.uid() OR
        (c.user_id = auth.uid() AND c.role = 'admin')
      )
    )
  );