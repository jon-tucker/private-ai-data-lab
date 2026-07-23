# ADR 0006: Separate APEX software, state, and installation

- Status: Accepted
- Date: 2026-07-23

## Context

Oracle APEX is installed into the database from a versioned software archive. The
expanded installer is large, the static browser resources must remain available to
ORDS, and installation requires temporary SYSDBA access. None of those concerns
belongs in the Git repository or the long-running ORDS container.

## Decision

- Keep the downloaded and expanded APEX software under
  `/srv/oracle-ai-work/apex`.
- Verify Oracle's published SHA-256 checksum before using the archive.
- Copy only the required `images` tree to
  `/srv/oracle-ai-data/apex/images`.
- Stage the installer temporarily inside the database container.
- Run the full development installation as an explicit administrative operation.
- Use dedicated `APEX` and `APEX_FILES` tablespaces.
- Continue to run ORDS as `ORDS_PUBLIC_USER`, with
  `APEX_PUBLIC_USER` configured as its proxied PL/SQL gateway user.
- Never add the APEX archive, expanded Oracle software, database files, or
  credentials to Git.

## Consequences

The source repository remains small and redistributable. A rebuild must download
the exact APEX archive again, verify it, and run the documented installation
workflow. APEX installation changes the database and therefore requires a
database backup or recovery point before future upgrades.
