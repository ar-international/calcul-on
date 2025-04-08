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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from './ui/select';

const shareSchema = z.object({
  email: z.string().email('Invalid email address'),
  role: z.enum(['viewer', 'editor', 'admin'], {
    required_error: 'Please select a role',
  }),
});

type ShareFormData = z.infer<typeof shareSchema>;

interface ShareGoalDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  goalId: string;
  onCollaboratorAdded: () => void;
}

export function ShareGoalDialog({
  open,
  onOpenChange,
  goalId,
  onCollaboratorAdded,
}: ShareGoalDialogProps) {
  const form = useForm<ShareFormData>({
    resolver: zodResolver(shareSchema),
    defaultValues: {
      email: '',
      role: 'viewer',
    },
  });

  const onSubmit = async (data: ShareFormData) => {
    try {
      // First, get the user ID for the email
      const { data: profiles, error: profileError } = await supabase
        .from('profiles')
        .select('id')
        .eq('email', data.email)
        .single();

      if (profileError) {
        toast.error('User not found');
        return;
      }

      // Add collaborator
      const { error } = await supabase.from('collaborators').insert({
        goal_id: goalId,
        user_id: profiles.id,
        role: data.role,
      });

      if (error) {
        if (error.code === '23505') {
          toast.error('This user is already a collaborator');
        } else {
          throw error;
        }
        return;
      }

      toast.success('Collaborator added successfully');
      onCollaboratorAdded();
      onOpenChange(false);
      form.reset();
    } catch (error) {
      toast.error('Failed to add collaborator');
      console.error('Error adding collaborator:', error);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Share Goal</DialogTitle>
        </DialogHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="email"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Email Address</FormLabel>
                  <FormControl>
                    <Input
                      placeholder="Enter collaborator's email"
                      type="email"
                      {...field}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="role"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Role</FormLabel>
                  <Select
                    onValueChange={field.onChange}
                    defaultValue={field.value}
                  >
                    <FormControl>
                      <SelectTrigger>
                        <SelectValue placeholder="Select a role" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      <SelectItem value="viewer">Viewer</SelectItem>
                      <SelectItem value="editor">Editor</SelectItem>
                      <SelectItem value="admin">Admin</SelectItem>
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )}
            />
            <DialogFooter>
              <Button type="submit">Share Goal</Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}