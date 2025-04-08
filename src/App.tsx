import React, { useState, useEffect } from 'react';
import { CircularProgressBar } from './components/CircularProgressBar';
import { ExpenseList } from './components/ExpenseList';
import { FloatingActionButton } from './components/FloatingActionButton';
import { AddExpenseDialog } from './components/AddExpenseDialog';
import { AddGoalDialog } from './components/AddGoalDialog';
import { BudgetAdjustmentDialog } from './components/BudgetAdjustmentDialog';
import { ShareGoalDialog } from './components/ShareGoalDialog';
import { LoginDialog } from './components/LoginDialog';
import { SignUpDialog } from './components/SignUpDialog';
import { DeleteConfirmDialog } from './components/DeleteConfirmDialog';
import { ThemeToggle } from './components/ThemeToggle';
import { Calculator, Plus, Target, Share2, PlusCircle, LogIn, Trash2, LogOut } from 'lucide-react';
import { supabase } from './lib/supabase';
import { Toaster } from 'sonner';
import type { Goal, Expense, BudgetAdjustment as BudgetAdjustmentType } from './types';
import { Button } from './components/ui/button';
import { formatCurrency } from './lib/utils';
import { useTheme } from './lib/theme';

function App() {
  const { theme, initializeTheme } = useTheme();
  const [goals, setGoals] = useState<Goal[]>([]);
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [adjustments, setAdjustments] = useState<BudgetAdjustmentType[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedGoal, setSelectedGoal] = useState<string | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [goalToDelete, setGoalToDelete] = useState<Goal | null>(null);
  
  const [addExpenseOpen, setAddExpenseOpen] = useState(false);
  const [addGoalOpen, setAddGoalOpen] = useState(false);
  const [adjustBudgetOpen, setAdjustBudgetOpen] = useState(false);
  const [shareGoalOpen, setShareGoalOpen] = useState(false);
  const [loginOpen, setLoginOpen] = useState(false);
  const [signUpOpen, setSignUpOpen] = useState(false);

  useEffect(() => {
    initializeTheme();
  }, [initializeTheme]);

  useEffect(() => {
    checkAuth();
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setIsAuthenticated(!!session);
      if (session) {
        fetchGoals();
        fetchExpenses();
        fetchAdjustments();
        initializeTheme();
      } else {
        // Clear data on logout
        setGoals([]);
        setExpenses([]);
        setAdjustments([]);
        setSelectedGoal(null);
      }
    });

    return () => subscription.unsubscribe();
  }, [initializeTheme]);

  async function checkAuth() {
    const { data: { session } } = await supabase.auth.getSession();
    setIsAuthenticated(!!session);
    if (session) {
      fetchGoals();
      fetchExpenses();
      fetchAdjustments();
    }
  }

  async function handleLogout() {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
    } catch (error) {
      console.error('Error logging out:', error);
    }
  }

  async function fetchGoals() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      // First get the collaborator goals
      const { data: collaboratorGoals } = await supabase
        .from('collaborators')
        .select('goal_id')
        .eq('user_id', user.id);

      // Get goals where user is owner or collaborator
      const { data, error } = await supabase
        .from('goals')
        .select('*')
        .or(`user_id.eq.${user.id},id.in.(${collaboratorGoals?.map(g => g.goal_id).join(',') || ''})`)
        .order('created_at', { ascending: false });
      
      if (error) {
        console.error('Error fetching goals:', error);
        return;
      }

      setGoals(data || []);
      if (data && data.length > 0 && !selectedGoal) {
        setSelectedGoal(data[0].id);
      }
      setLoading(false);
    } catch (error) {
      console.error('Error in fetchGoals:', error);
      setLoading(false);
    }
  }

  async function fetchExpenses() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      // First get the collaborator goals
      const { data: collaboratorGoals } = await supabase
        .from('collaborators')
        .select('goal_id')
        .eq('user_id', user.id);

      // Get all accessible goals
      const { data: accessibleGoals } = await supabase
        .from('goals')
        .select('id')
        .or(`user_id.eq.${user.id},id.in.(${collaboratorGoals?.map(g => g.goal_id).join(',') || ''})`);

      if (!accessibleGoals?.length) return;

      // Then get expenses for those goals
      const { data, error } = await supabase
        .from('expenses')
        .select('*')
        .in('goal_id', accessibleGoals.map(g => g.id))
        .order('date', { ascending: false });
      
      if (error) {
        console.error('Error fetching expenses:', error);
        return;
      }

      setExpenses(data || []);
    } catch (error) {
      console.error('Error in fetchExpenses:', error);
    }
  }

  async function fetchAdjustments() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      // Get all goals where the user is either the owner or a collaborator
      const { data: accessibleGoals } = await supabase
        .from('goals')
        .select('id')
        .or(
          `user_id.eq.${user.id},id.in.(${
            await supabase
              .from('collaborators')
              .select('goal_id')
              .eq('user_id', user.id)
              .then(({ data }) => (data || []).map(g => g.goal_id).join(',') || '')
          })`
        );

      if (!accessibleGoals?.length) return;

      // Get all adjustments for accessible goals
      const { data, error } = await supabase
        .from('budget_adjustments')
        .select('*')
        .in('goal_id', accessibleGoals.map(g => g.id))
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Error fetching adjustments:', error);
        return;
      }

      setAdjustments(data || []);
    } catch (error) {
      console.error('Error in fetchAdjustments:', error);
    }
  }

  async function handleDeleteGoal(goal: Goal) {
    setGoalToDelete(goal);
  }

  async function confirmDeleteGoal() {
    if (!goalToDelete) return;

    try {
      const { error } = await supabase
        .from('goals')
        .delete()
        .eq('id', goalToDelete.id);

      if (error) throw error;

      if (selectedGoal === goalToDelete.id) {
        const remainingGoals = goals.filter(g => g.id !== goalToDelete.id);
        setSelectedGoal(remainingGoals.length > 0 ? remainingGoals[0].id : null);
      }

      await fetchGoals();
      setGoalToDelete(null);
    } catch (error) {
      console.error('Error deleting goal:', error);
    }
  }

  const currentGoal = goals.find(g => g.id === selectedGoal);
  
  const goalExpenses = expenses.filter(e => e.goal_id === selectedGoal);
  const goalAdjustments = adjustments.filter(a => a.goal_id === selectedGoal);
  
  const totalSpent = goalExpenses.reduce((sum, expense) => sum + expense.amount, 0);
  const totalAdjustments = goalAdjustments.reduce((sum, adj) => sum + adj.amount, 0);
  const targetAmount = currentGoal?.target_amount || 0;
  
  const adjustedBudget = targetAmount + totalAdjustments;
  const progress = adjustedBudget > 0 ? (totalSpent / adjustedBudget) * 100 : 0;

  const isOverBudgetWarning = progress >= 90;

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-indigo-950 flex items-center justify-center">
        <Toaster position="top-right" />
        <div className="absolute top-4 right-4">
          <ThemeToggle />
        </div>
        <div className="text-center">
          <div className="flex items-center justify-center gap-3 mb-4">
            <Calculator className="h-8 w-8 text-indigo-600 dark:text-indigo-400" />
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white">CalculON</h1>
          </div>
          <p className="text-gray-600 dark:text-gray-300 mb-8">Smart financial goals tracking</p>
          <div className="space-y-4">
            <Button onClick={() => setLoginOpen(true)} className="flex items-center gap-2">
              <LogIn className="h-4 w-4" />
              Log In
            </Button>
            <div>
              <span className="text-gray-600 dark:text-gray-400">Don't have an account? </span>
              <button
                onClick={() => setSignUpOpen(true)}
                className="text-indigo-600 dark:text-indigo-400 hover:text-indigo-500 dark:hover:text-indigo-300 font-medium"
              >
                Sign up
              </button>
            </div>
          </div>
        </div>

        <LoginDialog
          open={loginOpen}
          onOpenChange={setLoginOpen}
          onSignUpClick={() => {
            setLoginOpen(false);
            setSignUpOpen(true);
          }}
        />

        <SignUpDialog
          open={signUpOpen}
          onOpenChange={setSignUpOpen}
        />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-indigo-950">
      <Toaster position="top-right" />
      <div className="container mx-auto px-4 py-8">
        <header className="mb-12">
          {/* User actions */}
          <div className="flex justify-end gap-2 mb-8">
            <ThemeToggle />
            <Button
              onClick={handleLogout}
              variant="outline"
              className="flex items-center gap-2"
            >
              <LogOut className="h-4 w-4" />
              Log Out
            </Button>
          </div>

          {/* Logo and title */}
          <div className="text-center">
            <div className="flex items-center justify-center gap-3 mb-2">
              <Calculator className="h-8 w-8 text-indigo-600 dark:text-indigo-400" />
              <h1 className="text-4xl font-bold text-gray-900 dark:text-white">CalculON</h1>
            </div>
            <p className="text-gray-600 dark:text-gray-300">Smart financial goals tracking</p>
            
            <div className="mt-6 flex justify-center gap-4">
              <Button
                onClick={() => setAddGoalOpen(true)}
                className="flex items-center gap-2"
              >
                <Target className="h-4 w-4" />
                New Goal
              </Button>
            </div>
          </div>
        </header>

        {loading ? (
          <div className="flex justify-center items-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 dark:border-indigo-400"></div>
          </div>
        ) : (
          <>
            {goals.length > 0 ? (
              <div className="grid grid-cols-1 gap-8">
                {/* Goals Overview */}
                <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-6 mb-8">
                  <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-6">Your Goals</h2>
                  <div className="grid gap-4">
                    {goals.map((goal) => {
                      const goalAdjustments = adjustments.filter(a => a.goal_id === goal.id);
                      const totalAdjustments = goalAdjustments.reduce((sum, adj) => sum + adj.amount, 0);
                      
                      return (
                        <div
                          key={goal.id}
                          className={`p-4 rounded-lg border transition-colors cursor-pointer ${
                            selectedGoal === goal.id
                              ? 'border-indigo-600 bg-indigo-50 dark:border-indigo-400 dark:bg-indigo-950'
                              : 'border-gray-200 dark:border-gray-700 hover:border-indigo-300 dark:hover:border-indigo-600'
                          }`}
                          onClick={() => setSelectedGoal(goal.id)}
                        >
                          <div className="flex items-center justify-between">
                            <div>
                              <h3 className="text-lg font-medium text-gray-900 dark:text-white">{goal.name}</h3>
                              <p className="text-sm text-gray-600 dark:text-gray-300">
                                Target: {formatCurrency(goal.target_amount)}
                              </p>
                              {totalAdjustments > 0 && (
                                <p className="text-sm text-green-600 dark:text-green-400">
                                  Adjustments: +{formatCurrency(totalAdjustments)}
                                </p>
                              )}
                              <p className="text-sm text-gray-600 dark:text-gray-300">
                                Deadline: {new Date(goal.deadline).toLocaleDateString()}
                              </p>
                            </div>
                            <div className="flex items-center gap-2">
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleDeleteGoal(goal);
                                }}
                                className="text-red-600 dark:text-red-400 hover:text-red-700 dark:hover:text-red-300"
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* Selected Goal Details */}
                {currentGoal && (
                  <>
                    <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-6 mb-8">
                      <div className="mb-6">
                        <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-4">
                          {currentGoal.name}
                        </h2>
                        <div className="flex flex-wrap gap-2">
                          <Button
                            onClick={() => setAdjustBudgetOpen(true)}
                            variant="outline"
                            className="flex items-center gap-2"
                          >
                            <PlusCircle className="h-4 w-4" />
                            Adjust Budget
                          </Button>
                          <Button
                            onClick={() => setShareGoalOpen(true)}
                            variant="outline"
                            className="flex items-center gap-2"
                          >
                            <Share2 className="h-4 w-4" />
                            Share Goal
                          </Button>
                        </div>
                      </div>

                      <div className="max-w-md mx-auto mb-8">
                        <CircularProgressBar
                          percentage={Math.min(progress, 100)}
                          spent={totalSpent}
                          budget={adjustedBudget}
                          expenses={goalExpenses}
                        />
                        {isOverBudgetWarning && (
                          <div className="mt-4 p-4 bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-200 rounded-lg text-center">
                            Warning: You've used {progress.toFixed(1)}% of your budget!
                          </div>
                        )}
                      </div>

                      <ExpenseList expenses={goalExpenses} />
                    </div>

                    <FloatingActionButton
                      icon={<Plus className="h-6 w-6" />}
                      onClick={() => setAddExpenseOpen(true)}
                    />
                  </>
                )}
              </div>
            ) : (
              <div className="text-center py-12">
                <h3 className="text-xl font-medium text-gray-900 dark:text-white mb-2">
                  No goals yet
                </h3>
                <p className="text-gray-600 dark:text-gray-300 mb-4">
                  Create your first financial goal to get started
                </p>
                <Button onClick={() => setAddGoalOpen(true)}>
                  Create Goal
                </Button>
              </div>
            )}
          </>
        )}
      </div>

      {currentGoal && (
        <>
          <AddExpenseDialog
            open={addExpenseOpen}
            onOpenChange={setAddExpenseOpen}
            goalId={currentGoal.id}
            onExpenseAdded={() => {
              fetchExpenses();
              fetchGoals();
            }}
          />
          <BudgetAdjustmentDialog
            open={adjustBudgetOpen}
            onOpenChange={setAdjustBudgetOpen}
            goalId={currentGoal.id}
            onAdjustmentAdded={() => {
              fetchAdjustments();
              fetchGoals();
            }}
          />
          <ShareGoalDialog
            open={shareGoalOpen}
            onOpenChange={setShareGoalOpen}
            goalId={currentGoal.id}
            onCollaboratorAdded={() => {
              fetchGoals();
            }}
          />
        </>
      )}

      <AddGoalDialog
        open={addGoalOpen}
        onOpenChange={setAddGoalOpen}
        onGoalAdded={() => {
          fetchGoals();
        }}
      />

      <DeleteConfirmDialog
        open={!!goalToDelete}
        onOpenChange={(open) => !open && setGoalToDelete(null)}
        onConfirm={confirmDeleteGoal}
        goalName={goalToDelete?.name || ''}
      />
    </div>
  );
}

export default App