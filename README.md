# Portfolio — Octavian Alexandru

Personal portfolio and resume landing page, built as a static site — no build step, no framework, no server required.

![Portfolio preview](docs/preview.png)

**Live preview:** [octavian-alexandru-dev.it](https://octavian-alexandru-dev.it)

## Stack

Plain HTML5, CSS3 and vanilla JavaScript (ES5-compatible, no transpiler needed). No dependencies, no `node_modules` at runtime — the whole site is a handful of static files that any web host can serve as-is.

- Self-hosted variable fonts ([Inter](https://fonts.google.com/specimen/Inter) and [Space Grotesk](https://fonts.google.com/specimen/Space+Grotesk), latin subset only) — no third-party requests at runtime.
- Italian / English content switch, implemented with a small translation table and `data-i18n` attributes (see [Content & translations](#content--translations)).
- Scroll-based reveal animations and an animated gradient background, both disabled automatically when the visitor's OS requests reduced motion.

## Project structure

```
.
├── index.html              Single-page site (all sections)
├── 404.html                 Custom not-found page
├── robots.txt
├── assets/
│   ├── css/style.css        Design system + layout (custom properties, no preprocessor)
│   ├── js/
│   │   ├── main.js          Navigation, scroll reveal, language switch
│   │   └── i18n.js          English strings, keyed to the data-i18n attributes in index.html
│   ├── fonts/                Self-hosted woff2 fonts
│   └── img/                 Favicon and images
└── package.json             Optional local dev server script
```

## Local development

No installation required. Any static file server works; for convenience:

```bash
npm run dev
```

This starts a local server on `http://localhost:5500` via `npx serve` (nothing is installed globally or added to the repo).

Opening `index.html` directly in a browser also works, since the site has no build step.

## Content & translations

Italian is the source language and lives directly in `index.html`. Every translatable element carries a `data-i18n="section.key"` attribute; the English copy for that same key lives in `assets/js/i18n.js`. To update content:

- **Italian text:** edit it directly in `index.html`.
- **English text:** update the matching key in `assets/js/i18n.js`.
- **New translatable element:** add `data-i18n="your.key"` in the HTML and the English value in the dictionary — the switch logic in `main.js` picks it up automatically.

## Deployment (FTP — Tophost)

The site is a static bundle, so deployment is a plain file upload. Publishing is automated with a local git hook:

### Automatic (recommended)

A `pre-push` hook (`.githooks/pre-push`) uploads every file to Tophost via FTP whenever you `git push` to `main`, running `scripts/ftp-deploy.sh`. It only ever runs locally, on whichever machine has it configured — never in CI, since Tophost blocks FTP connections from GitHub Actions runner IPs.

Credentials are pulled from **Bitwarden Secrets Manager** (project `Portfolio`) when available, so the actual FTP password only needs to be entered once, ever — not copy-pasted onto every machine. A local, git-ignored file is kept as a fallback for machines without Bitwarden access.

One-time setup on a given machine:

1. Enable the hook: `git config core.hooksPath .githooks`.
2. **Preferred — Bitwarden Secrets Manager:**
   - Install the CLI: `cargo install bws` (or download a prebuilt binary from the [bitwarden/sdk-sm releases](https://github.com/bitwarden/sdk-sm/releases)).
   - Create `.bws-token` in the repo root (git-ignored, never committed):
     ```
     BWS_ACCESS_TOKEN='<machine account access token>'
     BWS_PROJECT_ID='<Portfolio project id>'
     BWS_SERVER_URL='https://vault.bitwarden.eu'
     ```
   - The hook detects this file automatically and runs the deploy through `bws run`, which injects `FTP_HOST`/`FTP_USERNAME`/`FTP_PASSWORD` as environment variables without ever writing them to disk.
3. **Fallback — local file:** if `.bws-token` is absent (or `bws` isn't installed), copy `.ftp-credentials.example` to `.ftp-credentials` and fill in the real values. `scripts/ftp-deploy.sh` uses whichever source provided the variables.

From then on, every push to `main` re-publishes the whole site automatically. Without either setup, `git push` still works normally — the hook just no-ops with a message if no credentials are available.

### Manual (fallback)

1. Connect to the Tophost space with an FTP client (e.g. FileZilla) using the credentials from the Tophost control panel.
2. Upload `index.html`, `404.html`, `robots.txt` and the whole `assets/` folder into the site's web root (the FTP account lands there directly — no subfolder to navigate into), **keeping the folder structure**.
3. Make sure `index.html` ends up directly in the web root, not inside a subfolder, so it's served at the domain root.

Either way, the site works with no further configuration once uploaded — there's no database and no server-side code to set up.

## Browser support

Modern evergreen browsers (Chrome, Firefox, Safari, Edge). The layout degrades gracefully without JavaScript: content stays in Italian and fully readable, only the language switch and scroll animations are unavailable.
