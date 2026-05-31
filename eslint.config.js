const muscleMoneyConfig = require('@muscle-money/eslint-config');

module.exports = [
  ...muscleMoneyConfig,
  {
    ignores: ['dist/**', 'build/**', 'node_modules/**', '.turbo/**'],
  },
  {
    files: ['**/*.spec.ts'],
    languageOptions: {
      globals: {
        beforeEach: 'readonly',
        describe: 'readonly',
        expect: 'readonly',
        it: 'readonly',
        jest: 'readonly',
      },
    },
  },
];
