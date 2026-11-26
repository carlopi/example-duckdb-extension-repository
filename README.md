# example-duckdb-extension-repository

A demo DuckDB extension repository, served by GitHub Pages at
`https://carlopi.github.io/example-duckdb-extension-repository`.

- `.well-known/duckdb-extension-repo.json`: the repository's metadata, with the public key that signs its extensions.
- `<version>/<platform>/<name>.duckdb_extension.gz`: the extensions, laid out as DuckDB expects: `container` for v2.0.1 (containers as external resources, from github.com/carlopi/duckdb-container, built from branch show-without-engine at ba32f04, stamped b0e3ff6110), `inet` for v2.0.1 on `wasm_eh` and `wasm_threads` (the core builds, re-signed; stored uncompressed because GitHub Pages cannot set the `Content-Encoding: br` header the core repository uses), `inet` for v2.0.0 and
  `inet`, `autocomplete` and `httpfs` for the development build c323c78907 of the branch implementing `CREATE EXTENSION REPOSITORY <host>`.
- `scripts/sign-extension.sh`: signs an extension with the repository's private key (kept outside this repo) and
  places it.

The host `carlopi.github.io` points DuckDB here from its own `.well-known/duckdb-extension-repo.json`, so:

```sql
CREATE EXTENSION REPOSITORY carlopi.github.io;
INSTALL inet FROM carlopi.github.io;
LOAD inet FROM carlopi.github.io;

-- DuckDB v2.0.1 on macOS arm64: containers as external resources (needs a container engine on the machine)
CREATE EXTENSION REPOSITORY IF NOT EXISTS carlopi.github.io;
INSTALL AND LOAD container FROM carlopi.github.io;
CALL container_engine();                       -- stops here with the reason when no Docker/Finch/Colima/Podman is around
ATTACH TO NEW TEMPORARY EXTERNAL RESOURCE container.postgres     AS pg;
ATTACH TO NEW TEMPORARY EXTERNAL RESOURCE container.ducklake     AS lake;
ATTACH TO NEW TEMPORARY EXTERNAL RESOURCE container.iceberg-rest AS ice;
FROM duckdb_databases();
CREATE TABLE pg.orders AS SELECT range AS id, 'customer ' || (range % 7) AS customer, (range * 3.5)::DECIMAL(10,2) AS amount FROM range(1000);
CREATE TABLE lake.orders AS FROM pg.orders;          -- PostgreSQL -> DuckLake
CREATE SCHEMA ice.sales;
CREATE TABLE ice.sales.orders AS FROM lake.orders;   -- DuckLake -> Iceberg REST
DETACH pg; DETACH lake; DETACH ice;                  -- the containers go with the session
```

`.nojekyll` makes GitHub Pages serve the `.well-known` directory.

## Publishing from other repositories' CI

`.github/workflows/publish.yml` publishes builds made elsewhere. A producer's CI sends a `repository_dispatch`
(`publish-extensions`, payload `{repository, run_id, token}`); this repository takes that run's artifacts only if the
producer is listed in `sources.json`, the token's SHA-256 matches the one listed there, and the run succeeded on an
allowed branch; it checks each footer, signs with its own key (secret `EXTENSION_REPO_SIGNING_KEY`, never anywhere
else), places them at `<version dir>/<platform>/<name>.duckdb_extension.gz` and commits to `main`. Producers so far:
`carlopi/duckdb-v2_capi_shim` (`v2_capi_shim`). A producer is added, or its token rotated, by editing `sources.json`.
