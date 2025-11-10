import nextLintConfig from "eslint-config-next";

export default [
  ...nextLintConfig,
  {
    ignores: ["node_modules", ".next", "dist"],
  },
];
