import { create } from 'zustand';
import { supabase } from './supabase';

type ThemeStore = {
  theme: 'light' | 'dark';
  isLoading: boolean;
  toggleTheme: () => Promise<void>;
  initializeTheme: () => Promise<void>;
};

export const useTheme = create<ThemeStore>((set, get) => ({
  theme: 'light',
  isLoading: true,
  toggleTheme: async () => {
    const newTheme = get().theme === 'light' ? 'dark' : 'light';
    
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      // Update the theme in Supabase
      const { error } = await supabase
        .from('user_settings')
        .upsert({ 
          user_id: user.id,
          theme: newTheme
        });

      if (error) throw error;
      
      // Update local state
      set({ theme: newTheme });
      
      // Update document class
      document.documentElement.classList.toggle('dark', newTheme === 'dark');
    } catch (error) {
      console.error('Error saving theme preference:', error);
    }
  },
  initializeTheme: async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        set({ isLoading: false });
        return;
      }

      // Try to get user settings
      const { data: settings } = await supabase
        .from('user_settings')
        .select('theme')
        .eq('user_id', user.id)
        .single();

      if (settings) {
        set({ theme: settings.theme as 'light' | 'dark' });
        document.documentElement.classList.toggle('dark', settings.theme === 'dark');
      } else {
        // Create default settings if none exist
        await supabase
          .from('user_settings')
          .insert({ user_id: user.id, theme: 'light' });
      }
    } catch (error) {
      console.error('Error loading theme preference:', error);
    } finally {
      set({ isLoading: false });
    }
  }
}));