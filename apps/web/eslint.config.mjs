import shared from "../../tooling/eslint/index.js";

// The shared config lints TypeScript (the Worker). The site's sources are
// JavaScript with JSX (the React pages and components Docusaurus renders), so
// they get the same parser options for .js; the generated .docusaurus/ and
// the build/ output are not sources.
export default [
  ...shared,
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      parserOptions: { ecmaFeatures: { jsx: true } },
    },
  },
  { ignores: ["build/**", ".docusaurus/**"] },
];
