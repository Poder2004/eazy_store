import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: "#4F46E5",
        "primary-light": "#6366F1",
        danger: "#E11D48",
        success: "#10B981",
        dark: "#0F172A",
      },
      fontFamily: {
        sans: ["var(--font-sarabun)", "Sarabun", "sans-serif"],
      },
    },
  },
  plugins: [],
};
export default config;
