export interface Profile {
  id: string;
  email: string;
  created_at: string;
  updated_at: string;
}

export interface Goal {
  id: string;
  user_id: string;
  name: string;
  target_amount: number;
  current_amount: number;
  deadline: string;
  created_at: string;
  updated_at: string;
}

export interface Expense {
  id: string;
  goal_id: string;
  amount: number;
  category: string;
  date: string;
  notes?: string;
  created_at: string;
  created_by: string;
}

export interface BudgetAdjustment {
  id: string;
  goal_id: string;
  amount: number;
  reason: string;
  created_at: string;
  created_by: string;
}

export interface Collaborator {
  id: string;
  goal_id: string;
  user_id: string;
  role: 'viewer' | 'editor' | 'admin';
  created_at: string;
}

export const DEFAULT_CATEGORIES = [
  'ING',
  'Revolut',
  'ING Blik',
  'Other'
] as const;

export type ExpenseCategory = typeof DEFAULT_CATEGORIES[number] | string;

export const CATEGORY_COLORS = {
  'ING': { bg: 'bg-orange-100', text: 'text-orange-800', chart: '#f97316' },
  'Revolut': { bg: 'bg-blue-100', text: 'text-blue-800', chart: '#3b82f6' },
  'ING Blik': { bg: 'bg-purple-100', text: 'text-purple-800', chart: '#9333ea' },
  'Other': { bg: 'bg-gray-100', text: 'text-gray-800', chart: '#6b7280' }
} as const;