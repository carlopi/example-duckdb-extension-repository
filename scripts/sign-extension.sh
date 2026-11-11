#!/bin/bash
# Sign a DuckDB extension with this repository's key and place it where DuckDB looks for it:
#   scripts/sign-extension.sh <private key.pem> <extension.duckdb_extension> <duckdb version or source id> <platform>
# An already signed extension (e.g. a core build) is re-signed: its old 256-byte signature is replaced.
# The signature is RSA-2048 PKCS#1 v1.5 over SHA-256 of the SHA-256 digests of the file's 1 MiB segments,
# exactly what DuckDB verifies at LOAD, and what duckdb/scripts/verify-extension-signing.sh checks.
set -euo pipefail
key="$1"; input="$2"; version="$3"; platform="$4"
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
name="$(basename "$input" .duckdb_extension)"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

size=$(stat -f%z "$input" 2>/dev/null || stat -c%s "$input")
# RESIGN=1: the input is already signed (e.g. a core build); its trailing 256-byte signature is replaced
if [ "${RESIGN:-0}" = 1 ]; then
	head -c $((size - 256)) "$input" > "$work/unsigned"
else
	cp "$input" "$work/unsigned"
fi

split -b 1048576 "$work/unsigned" "$work/chunk_"
: > "$work/concat"
for f in "$work"/chunk_*; do openssl dgst -binary -sha256 "$f" >> "$work/concat"; done
openssl dgst -binary -sha256 "$work/concat" > "$work/hash"
openssl pkeyutl -sign -inkey "$key" -in "$work/hash" -pkeyopt digest:sha256 -out "$work/sig"
[ "$(stat -f%z "$work/sig" 2>/dev/null || stat -c%s "$work/sig")" -eq 256 ]

out_dir="$repo_dir/$version/$platform"; mkdir -p "$out_dir"
cat "$work/unsigned" "$work/sig" > "$out_dir/$name.duckdb_extension"
gzip -f -9 "$out_dir/$name.duckdb_extension"
echo "wrote $out_dir/$name.duckdb_extension.gz"
