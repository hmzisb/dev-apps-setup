# Security

Please report a vulnerability privately through GitHub:
**Security > Report a vulnerability** on this repository. Don't open a public issue.

## What this tool does on your Mac

- Clones each app's public GitHub repository and builds it with `npm`, `yarn` or
  `pnpm`. Dependency install scripts are skipped (`--ignore-scripts`), but the build
  still runs the app's own build tooling. Only add apps whose code you trust.
- Serves the builds only on your machine, through Laravel Herd at `https://*.test`.
- Never uses `sudo`. Installing Homebrew or Herd may ask for your password in their own
  installers.
- Stores no credentials and sends nothing anywhere except `git` and package-registry
  requests during a build.
