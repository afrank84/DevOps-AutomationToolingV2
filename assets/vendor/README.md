# Vendored browser dependencies

- `marked.js`: Marked 18.1.3, UMD build from the npm `marked` package.
- `purify.js`: DOMPurify 3.4.17, minified browser build from npm `dompurify`.
- Licenses are retained beside the builds.

These assets are served locally; reading guides needs no CDN, GitHub API token,
or remote Markdown service. Marked parses Markdown; DOMPurify sanitizes the
result before insertion into the page. Do not remove sanitization when upgrading.

Packages were fetched through npm with normal registry integrity/TLS checking
and lifecycle scripts disabled. To refresh, install explicit reviewed versions
in a temporary directory with `npm install --prefix <temporary-directory>
--ignore-scripts --no-audit --no-fund marked@<version> dompurify@<version>`, copy
the corresponding UMD/browser builds and licenses, update this note, and run the
reader browser regressions. There are no runtime npm dependencies or install
steps for the static host.
