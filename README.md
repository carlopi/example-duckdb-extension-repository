# example-duckdb-extension-repository

A demo DuckDB extension repository, served by GitHub Pages at
`https://carlopi.github.io/example-duckdb-extension-repository`.

- `.well-known/duckdb-extension-repo.json`: the repository's metadata, with the public key that signs its extensions.
- `<version>/<platform>/<name>.duckdb_extension.gz`: the extensions, laid out as DuckDB expects.
- `scripts/sign-extension.sh`: signs an extension with the repository's private key (kept outside this repo) and
  places it.

The host `carlopi.github.io` points DuckDB here from its own `.well-known/duckdb-extension-repo.json`, so:

```sql
CREATE EXTENSION REPOSITORY carlopi.github.io;
INSTALL inet FROM carlopi.github.io;
LOAD inet FROM carlopi.github.io;
```

`.nojekyll` makes GitHub Pages serve the `.well-known` directory.
