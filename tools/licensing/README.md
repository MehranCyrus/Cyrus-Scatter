# Cyrus 0.79 offline team licensing

This is the owner-operated team pilot. It needs no server. The signed deadline is **30 days after issuance**, not 30 days after import. The client remains loadable and can render existing scenes after expiry; supported creation/editing paths require a valid license. See [tested scope and limitations](../../docs/licensing/TEAM_PILOT_0.79_2026-10-11.md).

The candidate still needs an artist acceptance pass before broad team rollout. Long staged strokes and expiry rollback are automated-test covered; physical mouse/tablet interaction and your renderer should also be checked.

## Mehran: generate a license

1. Open `tools/licensing/Open Generator.cmd`. Python 3.11+ must be available as `python`. The launcher creates a private environment and installs the pinned requirements on first use; subsequent issuance works offline.
2. Select **Generate license from request**, select your teammate's request JSON, enter their name and choose an output `.cyruslicense` file.
3. Send only that license and the matching Max installer to the teammate. Never send this generator, your owner store or an issuer backup.
4. To renew, have the teammate save a **new** activation request, then issue again. Reissuing the identical request deliberately returns the same license/deadline rather than a fresh month.

The initialized owner store is `%USERPROFILE%\.CyrusScatter\LicenseIssuer`. `issuer.dpapi` contains the private signing key protected for this Windows user. `issued.sqlite3` records recipients, installation IDs and issued grants. `runtime/` is disposable tooling. This location avoids packaged-app LocalAppData virtualization so Explorer and terminal launches see the same key.

**Make an owner backup before relying on team distribution:** use **Back up owner key** in the GUI. Choose a private `.cyrusissuer` file and a strong passphrase, stored separately. Also back up `issued.sqlite3` while the generator is closed. A copy of `issuer.dpapi` alone is not a portable disaster-recovery backup. Loss of the key without an encrypted backup means new builds with a new public key and reissued licenses. Never run `init` to repair an existing authority.

## Teammate: activate

1. Install the MZP matching Max 2026 or 2027, then restart Max.
2. In Scatter's Modify panel choose **License / activation**. With no scatter selected, run `CyrusOpenLicenseDialog()` in the MAXScript Listener, or assign the **Cyrus License** action from category **Cyrus** to a toolbar/menu.
3. Choose **Save activation request**, send that JSON to Mehran, and import the returned `.cyruslicense` file.
4. Check **Active** and the UTC expiry shown in the panel. Importing late does not move the deadline. An already-open second Max process can take up to 60 seconds to observe activation/renewal.

No Python, generator, internet connection or private signing key is required on the teammate's machine. The request binds the license to a Windows-user installation key; it contains no IP address. Different Windows users or a lost installation key require a new request. This is not physical hardware attestation or a floating-seat service.

Expiry locks authoring; activation stays available. Saved scenes, inspection and the tested render paths continue working. Correct Windows time and restart Max if a clock anomaly is reported. A damaged protected license state or lost installation key needs owner-assisted recovery; do not delete state as a routine renewal step. Local state is under `%LOCALAPPDATA%\CyrusScatter\Licenses\<key-id>`; the device key is managed by Windows CNG.

## CLI and recovery

Use the generator environment's Python, or install `requirements.txt` into an isolated environment. Commands run from the repository root:

```powershell
python tools/licensing/issuer.py issue --request request.json --recipient "Team member" --output Team.cyruslicense
python tools/licensing/issuer.py backup private-backup.cyrusissuer
python tools/licensing/issuer.py --store C:/Private/RestoredIssuer restore private-backup.cyrusissuer
python tools/licensing/issuer.py --store C:/Private/RestoredIssuer public-header restored-team_public_key.h
```

Backup/restore prompt for the passphrase; do not put it on the command line. Restore refuses to overwrite an existing key. Verify the restored public key ID against the shipped build, and restore the issuance ledger before normal issuance. `--store` precedes the subcommand. Initial provisioning on a genuinely new project is `issuer.py init`, then `issuer.py public-header CyrusLicensing/team/team_public_key.h`. The owner for this project has already been initialized; preserve that authority.

## Build and qualification

`tools/build_max.py` enables team licensing, pins the selected public header, rejects laboratory binaries and refuses a native module missing the matching authority/import primitive. The public header is safe to commit. Owner secrets, grants, scenes and installers are excluded from Git.

For an isolated candidate:

```powershell
python tools/licensing/build_candidate.py --year 2027 --output build/my-fresh-candidate --trust-header CyrusLicensing/team/team_public_key.h
python tools/licensing/launch_test_host.py --candidate build/my-fresh-candidate --name my-owned-profile
python tools/licensing/package_candidate.py --candidate build/my-fresh-candidate --output dist/my-candidate
```

`run_host_tests.py` requires a **separate test authority**, because it issues short real-time grants to exercise expiry. Never point it at the owner's store. `owner_smoke.py` instead issues an ordinary 30-day grant for two explicitly named private hosts and records it in the real owner's ledger. Test profiles never modify the artist's Max installation. Packages do not contain the test transport or issuer.
