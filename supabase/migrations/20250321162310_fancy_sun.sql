/*
  # Initial Schema Setup for Financial Goals App

  1. Tables
    - profiles
      - User profiles with email
    - goals
      - Financial goals with target amounts and deadlines
    - expenses
      - Expense entries linked to goals
    - budget_adjustments
      - Budget modifications with reasons
    - collaborators
      - Goal sharing with role-based access

  2. Security
    - RLS enabled on all tables
    - Policies for authenticated access
    - Cascade deletes for related records

  3. Constraints
    - Foreign key relationships
    - Check constraints for positive amounts
    - Unique constraints where needed
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users,
  email text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can view own profile'
  ) THEN
    CREATE POLICY "Users can view own profile"
      ON profiles
      FOR SELECT
      TO authenticated
      USING (auth.uid() = id);
  END IF;
END $$;

-- Create goals table
CREATE TABLE IF NOT EXISTS goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id),
  name text NOT NULL,
  target_amount numeric NOT NULL CHECK (target_amount > 0),
  current_amount numeric DEFAULT 0,
  deadline date NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'goals' AND policyname = 'Users can manage own goals'
  ) THEN
    CREATE POLICY "Users can manage own goals"
      ON goals
      FOR ALL
      TO authenticated
      USING (
        user_id = auth.uid() OR 
        EXISTS (
          SELECT 1 FROM collaborators 
          WHERE goal_id = goals.id 
          AND user_id = auth.uid()
        )
      );
  END IF;
END $$;

-- Create expenses table
CREATE TABLE IF NOT EXISTS expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id uuid NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  amount numeric NOT NULL CHECK (amount > 0),
  category text NOT NULL,
  date date DEFAULT CURRENT_DATE,
  notes text,
  created_at timestamptz DEFAULT now(),
  created_by uuid NOT NULL REFERENCES profiles(id)
);

ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'expenses' AND policyname = 'Users can manage expenses with proper permissions'
  ) THEN
    CREATE POLICY "Users can manage expenses with proper permissions"
      ON expenses
      FOR ALL
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
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'expenses' AND policyname = 'Users can view expenses for their goals'
  ) THEN
    CREATE POLICY "Users can view expenses for their goals"
      ON expenses
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM goals g
          LEFT JOIN collaborators c ON c.goal_id = g.id
          WHERE g.id = expenses.goal_id
          AND (g.user_id = auth.uid() OR c.user_id = auth.uid())
        )
      );
  END IF;
END $$;

-- Create budget_adjustments table
CREATE TABLE IF NOT EXISTS budget_adjustments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id uuid NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  amount numeric NOT NULL CHECK (amount > 0),
  reason text NOT NULL,
  created_at timestamptz DEFAULT now(),
  created_by uuid NOT NULL REFERENCES profiles(id)
);

ALTER TABLE budget_adjustments ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'budget_adjustments' AND policyname = 'Users can manage budget adjustments with proper permissions'
  ) THEN
    CREATE POLICY "Users can manage budget adjustments with proper permissions"
      ON budget_adjustments
      FOR ALL
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
  END IF;
END $$;

-- Create collaborators table
CREATE TABLE IF NOT EXISTS collaborators (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id uuid NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id),
  role text NOT NULL CHECK (role IN ('viewer', 'editor', 'admin')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(goal_id, user_id)
);

ALTER TABLE collaborators ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'collaborators' AND policyname = 'Users can manage collaborators with admin role'
  ) THEN
    CREATE POLICY "Users can manage collaborators with admin role"
      ON collaborators
      FOR ALL
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
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'collaborators' AND policyname = 'Users can view collaborators for their goals'
  ) THEN
    CREATE POLICY "Users can view collaborators for their goals"
      ON collaborators
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM goals g
          WHERE g.id = collaborators.goal_id
          AND g.user_id = auth.uid()
        )
      );
  END IF;
END $$;

-- Drop existing function and trigger if they exist
DROP TRIGGER IF EXISTS expense_rate_limit ON expenses;
DROP FUNCTION IF EXISTS check_expense_rate_limit();

-- Create function for expense rate limiting
CREATE OR REPLACE FUNCTION check_expense_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  recent_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO recent_count
  FROM expenses
  WHERE created_by = NEW.created_by
  AND created_at > NOW() - INTERVAL '1 minute';

  IF recent_count >= 5 THEN
    RAISE EXCEPTION 'Rate limit exceeded: Maximum 5 expenses per minute';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for expense rate limiting
CREATE TRIGGER expense_rate_limit
  BEFORE INSERT ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION check_expense_rate_limit();