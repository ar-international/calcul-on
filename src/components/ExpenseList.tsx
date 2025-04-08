import React, { useState } from 'react';
import type { Expense } from '../types';
import { format } from 'date-fns';
import {
  ArrowUpDown,
  DollarSign,
  Calendar,
  Tag,
  ChevronUp,
  ChevronDown
} from 'lucide-react';
import { CATEGORY_COLORS } from '../types';

interface ExpenseListProps {
  expenses: Expense[];
}

type SortField = 'date' | 'amount' | 'category';
type SortDirection = 'asc' | 'desc';

export function ExpenseList({ expenses }: ExpenseListProps) {
  const [sortField, setSortField] = useState<SortField>('date');
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc');

  const sortedExpenses = [...expenses].sort((a, b) => {
    const modifier = sortDirection === 'asc' ? 1 : -1;
    
    switch (sortField) {
      case 'date':
        return modifier * (new Date(a.date).getTime() - new Date(b.date).getTime());
      case 'amount':
        return modifier * (a.amount - b.amount);
      case 'category':
        return modifier * a.category.localeCompare(b.category);
      default:
        return 0;
    }
  });

  const handleSort = (field: SortField) => {
    if (field === sortField) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDirection('desc');
    }
  };

  const SortIcon = ({ field }: { field: SortField }) => {
    if (field !== sortField) return <ArrowUpDown className="h-4 w-4 text-gray-400" />;
    return sortDirection === 'asc' ? 
      <ChevronUp className="h-4 w-4 text-indigo-600" /> : 
      <ChevronDown className="h-4 w-4 text-indigo-600" />;
  };

  return (
    <div>
      <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-6">Recent Expenses</h2>
      
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-200">
              <th className="pb-3 text-left">
                <button
                  className="flex items-center text-sm font-medium text-gray-600 dark:text-white hover:text-gray-900"
                  onClick={() => handleSort('date')}
                >
                  <Calendar className="h-4 w-4 mr-1" />
                  Date
                  <SortIcon field="date" />
                </button>
              </th>
              <th className="pb-3 text-left">
                <button
                  className="flex items-center text-sm font-medium text-gray-600 dark:text-white hover:text-gray-900"
                  onClick={() => handleSort('category')}
                >
                  <Tag className="h-4 w-4 mr-1" />
                  Category
                  <SortIcon field="category" />
                </button>
              </th>
              <th className="pb-3 text-left">
                <button
                  className="flex items-center text-sm font-medium text-gray-600 dark:text-white hover:text-gray-900"
                  onClick={() => handleSort('amount')}
                >
                  <DollarSign className="h-4 w-4 mr-1" />
                  Amount
                  <SortIcon field="amount" />
                </button>
              </th>
            </tr>
          </thead>
          <tbody>
            {sortedExpenses.map((expense) => (
              <tr
                key={expense.id}
                className="border-b border-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              >
                <td className="py-4 text-sm text-gray-600 dark:text-white">
                  {format(new Date(expense.date), 'MMM d, yyyy')}
                </td>
                <td className="py-4">
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                    CATEGORY_COLORS[expense.category as keyof typeof CATEGORY_COLORS]?.bg || 'bg-gray-100'
                  } ${
                    CATEGORY_COLORS[expense.category as keyof typeof CATEGORY_COLORS]?.text || 'text-gray-800'
                  }`}>
                    {expense.category}
                  </span>
                </td>
                <td className="py-4 text-sm font-medium text-gray-900 dark:text-white">
                  {expense.amount.toLocaleString()}
                </td>
              </tr>
            ))}
            {sortedExpenses.length === 0 && (
              <tr>
                <td colSpan={3} className="py-8 text-center text-gray-500 dark:text-white">
                  No expenses recorded yet
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}