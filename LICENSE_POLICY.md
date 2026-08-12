# License and release policy

This is a multi-license repository. The top-level Apache-2.0 notice applies only
to repository-authored curation metadata, schemas, tools, documentation, and CI.
It does not relicense third-party HDL.

Each artifact is assigned one release status:

- `source_released`: redistribution evidence is recorded and source can be part
  of the release manifest under its upstream license.
- `metadata_only`: the project remains in the catalog, but a license-clean
  release artifact must omit its HDL source until rights are resolved.
- `pending_review`: evidence exists but its scope or exact terms require review.
- `private_until_release`: a benchmark artifact is intentionally withheld until
  the preregistered evaluation is complete.

A disclaimer does not create redistribution rights. `LicenseRef-Unknown` and an
unspecified license version are release blockers, even when a copy already
exists in Git history. The machine-readable audit is in
`catalog/license_audit.json`.

Before publishing a GitHub Release, run:

```bash
python3 tools/audit_licenses.py
python3 tools/check_leakage.py
```

The release process must use `catalog/release_manifest.json` as its allowlist
and must not describe `metadata_only` projects as open-source RTL data.
