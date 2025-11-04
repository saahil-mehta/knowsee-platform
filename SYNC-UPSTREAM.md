# Syncing With Onyx Upstream

This repository keeps a curated `sync-up` branch aligned with the public Onyx codebase (`onyx-upstream/main`). The steps below capture the agreed process now that the histories have been linked via a one-time merge.

## Prerequisites
- Remote `onyx-upstream` must point at the official Onyx repository (check with `git remote -v`).
- Local branches:
  - `sync-up`: mirrors upstream and is the branch used for syncing.
  - `main`: contains Knowsee-specific work that you merge or cherry-pick after updating `sync-up`.

## Regular Sync Workflow
1. **Fetch latest upstream commits**
   ```bash
   git fetch onyx-upstream
   ```
2. **Update the mirror branch**
   ```bash
   git checkout sync-up
   git rebase onyx-upstream/main
   ```
   - Resolve any conflicts, keeping the upstream (`sync-up` / `ours`) version by default.
   - Use `git status` to verify when all conflicts are resolved.
3. **Push the refreshed mirror**
   ```bash
   git push --force-with-lease origin sync-up
   ```
   This keeps the GitHub mirror current without overwriting anyone else’s work unexpectedly.
4. **Incorporate upstream into Knowsee branches**
   - For `main`: merge the refreshed `sync-up` branch.
     ```bash
     git checkout main
     git merge sync-up
     git push origin main
     ```
   - For feature branches: rebase them onto `main` (or directly onto `sync-up` if they track upstream closely).

## Conflict Guidance
- When rebasing `sync-up`, prefer the Onyx version in conflicts (`git checkout --ours <file>`), unless you have intentional local changes to retain.
- When merging `sync-up` into `main`, resolve conflicts case-by-case:
  - Keep upstream changes unless you are intentionally customizing Knowsee behaviour.
  - After editing, stage the file (`git add`) before continuing.

## First-Time or Recovery Steps
- If `sync-up` and upstream ever diverge unexpectedly, realign by hard-resetting *after* creating a backup branch:
  ```bash
  git checkout sync-up
  git branch sync-up-backup
  git reset --hard onyx-upstream/main
  git push --force-with-lease origin sync-up
  ```
- The one-time `git merge main --allow-unrelated-histories` you already ran created a shared ancestor, so future pulls will not complain about “no common history.”

## Verification
- Run regression checks or smoke tests as needed after major upstream updates.
- Confirm CI passes on GitHub after pushing the refreshed branches.

Following this playbook keeps `sync-up` aligned with Onyx while giving `main` a clean path to absorb upstream changes and continue Knowsee-specific work.
