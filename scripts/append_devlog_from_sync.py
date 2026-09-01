#!/usr/bin/env python3
"""Actualiza docs/club/bitacora-de-desarrollo.md desde sync-pm-ai.md (entrada por fecha de corte)."""

from __future__ import annotations

import re
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SYNC_PATH = Path(
    sys.argv[1] if len(sys.argv) > 1 else ROOT / "docs/club/sync-pm-ai.md"
)
BITACORA_PATH = Path(
    sys.argv[2] if len(sys.argv) > 2 else ROOT / "docs/club/bitacora-de-desarrollo.md"
)

HEADER = """# Bitácora de desarrollo — SICLUB / ICDPE Pedro Echagüe

Se genera desde [`sync-pm-ai.md`](sync-pm-ai.md) al cerrar sesión.
Publicada en Google Drive (misma carpeta que el sync PM).

---

"""

ENTRY_RE = re.compile(r"^## (\d{4}-\d{2}-\d{2})\s*$", re.MULTILINE)


def _read(path: Path) -> str:
	if not path.is_file():
		return ""
	return path.read_text(encoding="utf-8")


def _corte_date(sync_text: str) -> str | None:
	m = re.search(r"\*\*Corte:\*\*\s*(\d{4}-\d{2}-\d{2})", sync_text)
	return m.group(1) if m else None


def _section(sync_text: str, heading_prefix: str) -> str:
	"""Extrae una sección ## N. ... hasta la siguiente ## de mismo nivel o superior."""
	pattern = re.compile(
		rf"(^## {re.escape(heading_prefix)}[^\n]*\n)(.*?)(?=^## \d|\Z)",
		re.MULTILINE | re.DOTALL,
	)
	m = pattern.search(sync_text)
	if not m:
		return ""
	return (m.group(1) + m.group(2)).strip() + "\n"


def _mensaje_pm(sync_text: str) -> str:
	m = re.search(
		r"## 6\. Mensaje corto[^\n]*\n\n(.+?)(?=\n---|\n## |\Z)",
		sync_text,
		re.DOTALL,
	)
	if not m:
		return ""
	return m.group(1).strip()


def _build_entry(sync_text: str, corte: str) -> str:
	parts: list[str] = [f"## {corte}", ""]
	for prefix in ("0.", "0.1"):
		block = _section(sync_text, prefix)
		if block:
			# Renumerar títulos internos: ## 0. → ### para anidar bajo la fecha
			block = re.sub(r"^## (\d+(?:\.\d+)?)", r"### \1", block, flags=re.MULTILINE)
			parts.append(block.strip())
			parts.append("")
	msg = _mensaje_pm(sync_text)
	if msg:
		parts.extend(["### Mensaje PM (§6)", "", msg, ""])
	parts.append(f"_Actualizado: {datetime.now().strftime('%Y-%m-%d %H:%M')} ART_")
	parts.append("")
	parts.append("---")
	return "\n".join(parts)


def _upsert_entry(devlog: str, corte: str, entry: str) -> str:
	if not devlog.strip():
		devlog = HEADER
	elif not devlog.startswith("# Bitácora de desarrollo"):
		devlog = HEADER + devlog.lstrip()

	marker = f"## {corte}"
	if marker in devlog:
		# Reemplazar bloque existente para esta fecha
		pattern = re.compile(
			rf"## {re.escape(corte)}\s*\n.*?(?=\n## \d{{4}}-\d{{2}}-\d{{2}}\s|\Z)",
			re.DOTALL,
		)
		updated = pattern.sub(entry + "\n\n", devlog, count=1)
		return updated

	# Insertar después del HEADER (primera entrada = más reciente arriba)
	insert_at = devlog.find("---\n")
	if insert_at == -1:
		return devlog.rstrip() + "\n\n" + entry + "\n"
	pos = insert_at + len("---\n")
	return devlog[:pos] + "\n" + entry + "\n\n" + devlog[pos:].lstrip("\n")


def main() -> int:
	if not SYNC_PATH.is_file():
		print(f"No existe sync: {SYNC_PATH}", file=sys.stderr)
		return 1
	sync_text = _read(SYNC_PATH)
	corte = _corte_date(sync_text)
	if not corte:
		print("sync-pm-ai.md sin **Corte:** — no se actualiza la bitácora.", file=sys.stderr)
		return 1
	entry = _build_entry(sync_text, corte)
	devlog = _read(BITACORA_PATH)
	new_devlog = _upsert_entry(devlog, corte, entry)
	BITACORA_PATH.parent.mkdir(parents=True, exist_ok=True)
	BITACORA_PATH.write_text(new_devlog, encoding="utf-8")
	print(f"Bitácora actualizada: {BITACORA_PATH} (entrada {corte})")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
