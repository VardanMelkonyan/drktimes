# drktimes development-time dataset

Black-and-white film development times, built so that every number can be
redistributed under CC0 1.0 (see `LICENSE`).

## Files

| File | Contents |
|---|---|
| `films.json` | Film catalog: brand, name, box ISO, process, sensitivity, formats, status, rebrand links. |
| `developers.json` | Developer catalog. |
| `sources.json` | Every document a number came from: publisher, title, edition, URL, retrieval date, SHA-256. |
| `times/<source-id>.json` | Development times transcribed from exactly one source document, with page numbers. |
| `.cache/` | Downloaded PDFs and text extracts. Git-ignored. Never commit or ship these. |

Times are stored in seconds and temperatures in °C, exactly as the source
prints them. Values the app can calculate (temperature compensation, push/pull
estimates) are never stored. Times are recorded against the original film,
never a rebrand; the app looks up rebrands through `rebrand_of`.

## Allowed sources

1. **Film manufacturer datasheets** (Kodak, Ilford/Harman, Fujifilm, Foma, Adox, Rollei, ORWO, Bergger, Ferrania, Leica, ...).
2. **Developer manufacturer datasheets.** These list times for many films, including other brands' films.
3. **Distributor or rebrander sheets** for their own products (e.g. Freestyle for Arista EDU).
4. **Packaging inserts** (the leaflet or print inside the film box).
5. **Written permission** from a publisher (`kind: permission`, with `permission_ref`).
6. **Our own tests** (`kind: own_test`).
7. **Contributors** who dedicate their submission to CC0 when they submit it (`kind: contributor`).

We copy facts only (film, developer, dilution, EI, temperature, time, method),
never a document's wording, layout, tables-as-images, or the PDF itself. Every
row cites its source and page.

## Forbidden sources

- The Massive Dev Chart / digitaltruth.com: its terms forbid republishing. This includes manufacturer PDFs re-hosted there; get those from the manufacturer instead.
- darkroom-solutions.com and other commercial compilations.
- Scribd uploads, forum posts, Reddit, blogs, Emulsive: unknown provenance and no consent.
- Wikipedia text: CC BY-SA would force share-alike. Its film list may be used only as leads to verify elsewhere.

Why facts from manufacturers are safe: a single fact is not copyrightable, and
the EU database right protects investment in *collecting* existing data (which
is what the compilations above did), not data a manufacturer created by testing
its own product (CJEU, *British Horseracing Board v William Hill*, C-203/02).
This is not legal advice.

## Catalog confidence

`verified_by` is set only when a film was confirmed against a fetched primary
source. `rebrand_basis: reported` means the rebrand is widely reported but not
stated by the seller, so the app should label inherited times accordingly.
