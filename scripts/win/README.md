# Scripts Windows — fallback cuando WSL no tiene HTTPS

WSL2 a veces **no llega** a `github.com:443` ni a Google Drive (`googleapis.com`). SSH a Hetzner suele funcionar desde WSL.

Desde **PowerShell** (no hace falta Admin):

```powershell
cd \\wsl.localhost\Ubuntu\home\francisco\ERSport\club_manager_infra
```

| Tarea | Comando |
|-------|---------|
| Comprobar red | `wsl -e bash -lc './scripts/https-preflight.sh'` |
| Push infra | `.\scripts\win\git-push.ps1` |
| Push app | `cd development\frappe-bench\apps\club_management; ..\..\..\..\..\scripts\win\git-push.ps1` |
| Sync PM + bitácora | `.\scripts\publish-dev-session.sh` vía WSL, o `.\scripts\sync-pm-ai-to-drive.ps1` |
| Deploy prod | Seguir en WSL: `./scripts/prod/deploy-club-management.sh` (solo SSH) |

Los scripts usan `git -c safe.directory=...` **por invocación** — no tocan `git config --global`.
