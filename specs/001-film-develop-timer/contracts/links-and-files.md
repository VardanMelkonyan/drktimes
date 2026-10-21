# Contract: Share Links, Files, and the Landing Site

This covers FR-053, FR-056 and FR-064. See research R5, R6 and R8.

`<host>` means the public static host. Until the owner picks a domain it is a
GitHub *user* site (`<user>.github.io`). It is a single constant in the app
(`kShareHost`), and the same value is used in the two `.well-known` files.

## 1. Recipe link

```text
https://<host>/r#<payload>
payload = base64url( deflate-raw( utf8( exchange document, kind="recipe" ) ) )   # no padding
```

- The payload is always in the **fragment**, never in the path or the query
  string, so no server ever receives it (FR-072).
- If the encoded link is longer than **6,000 characters**, Share offers only
  the file.
- **Decoding failures** (bad base64, inflate error, schema violation, or a
  higher major `format_version`) show the "This link isn't a valid drktimes
  recipe" screen. Existing data is untouched.
- The **app route** is `/import`. The payload is passed in memory to the
  import preview. It is not persisted until the user taps Import.

## 2. Recipe and backup file

| Property | Value |
|---|---|
| Extension | `.drktimes` |
| Content | UTF-8 JSON exchange document (`kind` = `recipe` or `backup`) |
| iOS | `UTExportedTypeDeclarations`: `am.drktimes.exchange` conforms to `public.json` and `public.data`, extension `drktimes`. `CFBundleDocumentTypes` declares the app as owner. `LSSupportsOpeningDocumentsInPlace` is false |
| Android | An intent filter on `ACTION_VIEW` / `ACTION_SEND` with `application/json` and `application/octet-stream`, plus the path pattern `.*\\.drktimes` |
| File names | `<Film>-<Developer>-<dilution>-ISO<ei>-<temp>C.drktimes` for a recipe; `drktimes-backup-YYYY-MM-DD.drktimes` for a backup |

Opening a `kind=backup` file goes to the backup import confirmation, not the
recipe preview.

## 3. Universal Links / App Links

**`https://<host>/.well-known/apple-app-site-association`**, served as
`application/json` with no extension:

```json
{ "applinks": { "details": [ { "appIDs": ["<TEAMID>.am.drktimes"], "components": [ { "/": "/r*" } ] } ] } }
```

**`https://<host>/.well-known/assetlinks.json`**:

```json
[{ "relation": ["delegate_permission/common.handle_all_urls"],
   "target": { "namespace": "android_app", "package_name": "am.drktimes",
               "sha256_cert_fingerprints": ["<release cert SHA-256>"] } }]
```

The bundle id and package `am.drktimes` are placeholders. They are confirmed
when the App Store Connect app record is created.

## 4. Landing page `https://<host>/r/`

- A static HTML page with inline JS. It has no analytics, no external
  scripts and no cookies.
- It decodes the fragment with the same algorithm and shows a read-only
  preview: author, film, developer, dilution, ISO, temperature, time and
  notes.
- It shows a "Get drktimes" button that links to the App Store or TestFlight.
- It shows "Open in drktimes" for the case where the Universal Link was
  bypassed, e.g. the link was pasted into a browser.
- An invalid payload shows a short explanation and the "Get" link.

## 5. Dataset manifest `https://<host>/dataset/manifest.json`

```json
{
  "format": "drktimes-dataset-manifest",
  "format_version": "1.0",
  "dataset_version": "2026.10.21-1",
  "url": "https://<host>/dataset/devdata-2026.10.21-1.json",
  "sha256": "<hex>",
  "bytes": 412345,
  "min_app_version": "1.0.0"
}
```

**Client rules:**
- Check at most once per 24 h, never during an active session.
- Send a plain `GET` with no query string and no custom headers.
- Replace the current dataset only if `dataset_version` is newer, the app
  version is at least `min_app_version`, the SHA-256 matches, and
  `lib/devdata/validator.dart` passes. Any failure keeps the current
  dataset, silently.
- The dataset bundle is the compiled single-file form of `resources/devdata`,
  produced by `tool/build_dataset.dart` with the same `schema_version: 1`
  objects.
