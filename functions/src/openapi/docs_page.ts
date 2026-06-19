// Standalone Scalar reference page. Loads a pinned, integrity-checked Scalar
// build from a CDN and points it at /openapi.json (kept as a string route to
// avoid an ESM-only npm dependency that conflicts with the CommonJS/ts-jest
// setup). The version + SRI hash are pinned together; bump both as a pair.
const SCALAR_VERSION = "1.60.0";
const SCALAR_SRI = "sha384-3sxnxyp7pbU2/o4+gs4EbvQ4YKyF60pWDL2LW8SoFZNQBTSiPah2xcHpxsndZEgF";

export function docsHtml(): string {
  const src =
    `https://cdn.jsdelivr.net/npm/@scalar/api-reference@${SCALAR_VERSION}` +
    "/dist/browser/standalone.js";
  return `<!doctype html>
<html>
  <head>
    <title>Agape Logos API</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
  </head>
  <body>
    <script id="api-reference" data-url="/openapi.json"></script>
    <script src="${src}" integrity="${SCALAR_SRI}" crossorigin="anonymous"></script>
  </body>
</html>`;
}
