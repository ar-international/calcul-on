import React from 'react';

interface FloatingActionButtonProps {
  icon: React.ReactNode;
  onClick: () => void;
}

export function FloatingActionButton({ icon, onClick }: FloatingActionButtonProps) {
  return (
    <button
      onClick={onClick}
      className="fixed bottom-8 right-8 w-14 h-14 bg-indigo-600 hover:bg-indigo-700 
        rounded-full shadow-lg flex items-center justify-center text-white 
        transition-colors duration-200 focus:outline-none focus:ring-2 
        focus:ring-offset-2 focus:ring-indigo-500"
    >
      {icon}
    </button>
  );
}