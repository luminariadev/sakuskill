/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#ECFDF5',
          100: '#D1FAE5',
          200: '#A7F3D0',
          300: '#6EE7B7',
          400: '#34D399',
          500: '#10B981',
          600: '#059669',
          700: '#047857',
          800: '#065F46',
          900: '#064E3B',
        },
        canvas: {
          light: '#F2F6F4',
          subtle: '#F0F4F2',
          clayTop: '#FFFFFF',
          clayBottom: '#F7FAF8',
          clayBorder: '#E6EFEA',
          forest: '#0B1512',
          forestDeep: '#0F2D24',
        },
        barter: {
          50: '#F3E8FF',
          200: '#D8B4FE',
          500: '#8B5CF6',
          700: '#7E22CE',
        },
        escrow: {
          50: '#EFF6FF',
          500: '#3B82F6',
          700: '#2563EB',
        },
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'ui-monospace', 'SFMono-Regular', 'Menlo', 'monospace'],
      },
      boxShadow: {
        'clay': '0 10px 26px -6px rgba(11, 41, 30, 0.08), 0 3px 8px rgba(11, 41, 30, 0.04), inset 0 1px 0 rgba(255, 255, 255, 0.95)',
        'clay-sm': '0 6px 16px -4px rgba(11, 41, 30, 0.07), 0 2px 5px rgba(11, 41, 30, 0.03), inset 0 1px 0 rgba(255, 255, 255, 0.95)',
        'clay-emerald': '0 14px 30px -8px rgba(5, 150, 105, 0.34), inset 0 1px 0 rgba(255, 255, 255, 0.35)',
        'glass': '0 14px 36px -8px rgba(11, 31, 23, 0.09), inset 0 1px 0 rgba(255, 255, 255, 0.92)',
      },
    },
  },
  plugins: [],
};
