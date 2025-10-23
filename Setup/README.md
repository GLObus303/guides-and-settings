# ESLint Configurations

[**<- Back to main**](../README.md)

- **eslint.config.js** - ESLint v9+ (flat config)
- **.eslintrc** - ESLint v8 and earlier (legacy config)

## Framework Notes

- **Next.js**: Both configs include `next/core-web-vitals` - remove for non-Next.js projects
- **Vite**: Remove Next.js config and add `eslint-plugin-react-refresh` for fast refresh
