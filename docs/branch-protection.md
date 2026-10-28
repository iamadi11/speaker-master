# Branch protection notes

Repo: `iamadi11/speaker-master` (private).

## Enable in GitHub (Settings → Branches → `main`)

> **Note (2026-10-28):** On a **private** repo, classic branch protection / rulesets via API returned **403 — upgrade to GitHub Pro**. Free private repos may lack this UI feature. Until Pro (or public), agents must self-enforce the gates below.

1. Require a pull request before merging  
2. Require status checks to pass: workflow **CI** / job **build-and-test**  
3. Restrict force pushes (admins included if possible)  
4. Optional: require linear history / squash merge only  

## Agent obligation (even before UI is enabled)

- No force-push to `main`
- No merge without green `swift test` / CI
- No install without verify

See `docs/agent-workflow.md` and `.agents/skills/autonomous-gap-fix`.
