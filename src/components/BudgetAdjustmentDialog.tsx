import React from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { toast } from 'sonner';
import { supabase } from '../lib/supabase';

import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from './ui/dialog';
import { Button } from './ui/button';
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from './ui/form';
import { Input } from './ui/input';
import { Textarea } from './ui/textarea';

const adjustmentSchema = z.object({
  amount: z.string().refine(
    (val) => {
      const num = parseFloat(val);
      return !isNaN(num) && num > 0;
    },
    { message: 'Amount must be a positive number' }
  ),
  reason: z.string().min(1, 'Please provide a reason for the adjustment'),
});

type AdjustmentFormData = z.infer<typeof adjustmentSchema>;

interface BudgetAdjustmentDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  goalId: string;
  onAdjustmentAdded: () => void;
}

export function BudgetAdjustmentDialog({
  open,
  onOpenChange,
  goalId,
  onAdjustmentAdded,
}: BudgetAdjustmentDialogProps) {
  const form = useForm<AdjustmentFormData>({
    resolver: zodResolver(adjustmentSchema),
    defaultValues: {
      amount: '',
      reason: '',
    },
  });

  const onSubmit = async (data: AdjustmentFormData) => {
    try {
      const { data: userData, error: userError } = await supabase.auth.getUser();
      if (userError) throw userError;

      const { error } = await supabase.from('budget_adjustments').insert({
        goal_id: goalId,
        amount: parseFloat(data.amount),
        reason: data.reason,
        created_by: userData.user.id,
      });

      if (error) throw error;

      toast.success('Budget adjustment added successfully');
      onAdjustmentAdded();
      onOpenChange(false);
      form.reset();
    } catch (error) {
      toast.error('Failed to add budget adjustment');
      console.error('Error adding budget adjustment:', error);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Adjust Budget</DialogTitle>
        </DialogHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="amount"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Amount to Add</FormLabel>
                  <FormControl>
                    <Input
                      placeholder="0.00"
                      type="number"
                      step="0.01"
                      {...field}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="reason"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Reason for Adjustment</FormLabel>
                  <FormControl>
                    <Textarea
                      placeholder="Explain why you're adjusting the budget..."
                      {...field}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <DialogFooter>
              <Button type="submit">Add Adjustment</Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}