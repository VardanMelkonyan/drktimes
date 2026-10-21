# drktimes static site

Three things live here and nothing else (research R6, R8):

| Path | What |
|---|---|
| `r/index.html` | Landing page for recipe links. Decodes the `#fragment` in the browser; nothing is sent anywhere. |
| `.well-known/apple-app-site-association` | iOS Universal Links, paths `/r*`. |
| `.well-known/assetlinks.json` | Android App Links. |
| `dataset/manifest.json` | Optional dataset update manifest (contracts/links-and-files.md §5). |

## Deploying

Until you pick a domain this is hosted as a GitHub *user* site:

1. Create a public repository named `<user>.github.io`.
2. Copy the contents of this folder into its root, **including** `.well-known/`.
   GitHub Pages skips dot-folders by default, so add an empty `.nojekyll`
   file at the root.
3. Set `kShareHost` in `lib/app/config.dart` to `<user>.github.io`, and use
   the same host in `ios/Runner/Runner.entitlements` (`applinks:`) and
   `android/app/src/main/AndroidManifest.xml`.
4. Replace the two placeholders:
   - `TEAMID` in `apple-app-site-association` with your Apple Team ID;
   - `REPLACE_WITH_RELEASE_CERT_SHA256` in `assetlinks.json` with the
     release signing certificate's SHA-256.
5. `apple-app-site-association` must be served as `application/json`; GitHub
   Pages does this for an extension-less file.

The bundle id / package `am.drktimes` is a placeholder until the App Store
Connect record exists.
