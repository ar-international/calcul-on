/*
  # Remove RLS and Simplify Schema

  1. Changes
    - Disable RLS on all tables
    - Drop existing policies
    - Keep foreign key constraints for data integrity
*/

-- Disable RLS on all tables
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE goals DISABLE ROW LEVEL SECURITY;
ALTER TABLE expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE budget_adjustments DISABLE ROW LEVEL SECURITY;
ALTER TABLE collaborators DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Allow profile creation during signup" ON profiles;
DROP POLICY IF EXISTS "Users can view own goals and shared goals" ON goals;
DROP POLICY IF EXISTS "Users can create goals" ON goals;
DROP POLICY IF EXISTS "Users can update own goals and admin shared goals" ON goals;
DROP POLICY IF EXISTS "Users can delete own goals and admin shared goals" ON goals;
DROP POLICY IF EXISTS "Users can view expenses for their goals" ON expenses;
DROP POLICY IF EXISTS "Users can manage expenses with proper permissions" ON expenses;
DROP POLICY IF EXISTS "Users can view budget adjustments" ON budget_adjustments;
DROP POLICY IF EXISTS "Users can manage budget adjustments with proper permissions" ON budget_adjustments;
DROP POLICY IF EXISTS "Users can view collaborators for their goals" ON collaborators;
DROP POLICY IF EXISTS "Users can manage collaborators with admin role" ON collaborators;