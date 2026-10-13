module.exports = {
  content: ["./**/*.html", "./assets/js/**/*.js"],
  darkMode: "class",
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter", "ui-sans-serif", "system-ui"],
        display: ["Manrope", "Inter", "ui-sans-serif", "system-ui"],
      },
      colors: {
        cb: {
          deep: "#061428",
          sea: "#0EA5E9",
          aqua: "#22D3EE",
          dusk: "#A78BFA",
          sunset: "#FB7185",
          amber: "#FBBF24",
        },
      },
      boxShadow: {
        glow: "0 0 0 1px rgba(34,211,238,.25), 0 18px 60px -20px rgba(34,211,238,.45)",
      },
    },
  },
};
