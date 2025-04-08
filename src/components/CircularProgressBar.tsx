import React from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer } from 'recharts';
import { CATEGORY_COLORS } from '../types';
import type { Expense } from '../types';

interface CircularProgressBarProps {
  percentage: number;
  spent: number;
  budget: number;
  expenses: Expense[];
}

export function CircularProgressBar({ percentage, spent, budget, expenses }: CircularProgressBarProps) {
  // Group expenses by category
  const expensesByCategory = expenses.reduce((acc, expense) => {
    acc[expense.category] = (acc[expense.category] || 0) + expense.amount;
    return acc;
  }, {} as Record<string, number>);

  // Convert to data format for chart
  const data = Object.entries(expensesByCategory).map(([category, amount]) => ({
    category,
    value: amount
  }));

  // If no expenses, show empty state
  if (data.length === 0) {
    data.push({ category: 'Empty', value: 100 });
  }

  const isOverBudget = percentage > 100;

  return (
    <div>
      {/* Chart Container */}
      <div className="relative w-full" style={{ height: '300px' }}>
        <div className="absolute inset-0">
          <ResponsiveContainer width="100%" height="100%">
            <PieChart>
              <Pie
                data={data}
                cx="50%"
                cy="50%"
                startAngle={90}
                endAngle={-270}
                innerRadius="60%"
                outerRadius="80%"
                dataKey="value"
                cornerRadius={0}
              >
                {data.map((entry, index) => (
                  <Cell
                    key={`cell-${index}`}
                    fill={CATEGORY_COLORS[entry.category as keyof typeof CATEGORY_COLORS]?.chart || '#6b7280'}
                  />
                ))}
              </Pie>
            </PieChart>
          </ResponsiveContainer>
        </div>
        
        {/* Centered Text */}
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
          <div className="text-center">
            <div className="text-4xl font-bold text-gray-900 dark:text-white leading-none mb-2">
              {percentage.toFixed(1)}%
            </div>
            <div className="text-sm text-gray-600 dark:text-gray-300 whitespace-nowrap">
              {spent.toLocaleString()} / {budget.toLocaleString()}
            </div>
            {isOverBudget && (
              <div className="text-red-500 text-sm mt-2 font-medium">Over Budget!</div>
            )}
          </div>
        </div>
      </div>

      {/* Category Legend - Below the chart */}
      <div className="mt-4 grid grid-cols-2 gap-2">
        {Object.entries(expensesByCategory).map(([category, amount]) => (
          <div key={category} className="flex items-center gap-2">
            <div 
              className="w-3 h-3 rounded-full flex-shrink-0"
              style={{ backgroundColor: CATEGORY_COLORS[category as keyof typeof CATEGORY_COLORS]?.chart || '#6b7280' }}
            />
            <span className="text-sm text-gray-600 dark:text-gray-300">
              {category}: {amount.toLocaleString()}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}