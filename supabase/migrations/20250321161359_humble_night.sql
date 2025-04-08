/*
  # Initial Schema for Personal Finance App

  1. New Tables
    - `profiles`
      - `id` (uuid, primary key, references auth.users)
      - `email` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `goals`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references profiles)
      - `name` (text)
      - `target_amount` (numeric)
      - `current_amount` (numeric)
      - `deadline` (date)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `expenses`
      - `id` (uuid, primary key)
      - `goal_id` (uuid, references goals)
      - `amount` (numeric)
      - `category` (text)
      - `date` (date)
      - `notes` (text)
      - `created_at` (timestamp)
      - `created_by` (uuid, references profiles)
    
    - `budget_adjustments`
      - `id` (uuid, primary key)
      - `goal_id` (uuid, references goals)
      - `amount` (numeric)
      - `reason` (text)
      - `created_at` (timestamp)
      - `created_by` (uuid, references profiles)
    
    - `collaborators`
      - `id` (uuid, primary key)
      - `goal_id` (uuid, references goals)
      - `user_id` (uuid, references profiles)
      - `role` (text)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
    - Implement role-based access control
*/

-- Create tables
CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users,
  email text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles NOT NULL,
  name text NOT NULL,
  target_amount numeric NOT NULL CHECK (target_amount > 0),
  current_amount numeric DEFAULT 0,
  deadline date NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id uuid REFERENCES goals ON DELETE CASCADE NOT NULL,
  amount numeric NOT NULL CHECK (amount > 0),
  category text NOT NULL,
  date date DEFAULT CURRENT_DATE,
  notes text,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES profiles NOT NULL
);

CREATE TABLE budget_adjustments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id uuid REFERENCES goals ON DELETE CASCADE NOT NULL,
  amount numeric NOT NULL CHECK (amount > 0),
  reason text NOT NULL,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES profiles NOT NULL
);

CREATE TABLE collaborators (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id uuid REFERENCES goals ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES profiles NOT NULL,
  role text NOT NULL CHECK (role IN ('viewer', 'editor', 'admin')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(goal_id, user_id)
);

-- Enable Row Level Security
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

-- Goals policies
CREATE POLICY "Users can manage own goals"
  ON goals FOR ALL
  TO authenticated
  USING (
    auth.uid() = user_id OR 
    EXISTS (
      SELECT 1 FROM collaborators 
      WHERE goal_id = goals.id 
      AND user_id = auth.uid()
    )
  );

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
      AND g.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage collaborators with admin role"
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

-- Create functions for rate limiting
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

CREATE TRIGGER expense_rate_limit
  BEFORE INSERT ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION check_expense_rate_limit();