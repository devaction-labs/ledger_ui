"""Compatibilidade TEMPORÁRIA do showcase: as regras do CSS antigo que dimensionam/colorem `.lu-i` dentro de
componentes ainda não migrados (`.lu-nav-item .lu-i { width: 19px }`) passam a valer para `svg[data-icon]`.
Gera showcase/assets/css/legacy_icons.css. Apague com o último componente migrado."""
import re, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref
src = "".join(open(f"{ref.REPO}/priv/static/{f}").read() for f in ("ledger.css", "ledger_ui.css"))
src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
out = []
for m in re.finditer(r"(?:^|\})\s*([^{}@]+)\{([^{}]*)\}", src):
    sels = [s.strip() for s in m.group(1).split(",")]
    keep = [re.sub(r"\.lu-i(?![\w-])", "svg[data-icon]", s) for s in sels if re.search(r"[\s>+~]\.lu-i(?![\w-])", s)]
    if keep: out.append(", ".join(keep) + " {" + m.group(2).strip() + "}")
dst = f"{ref.REPO}/showcase/assets/css/legacy_icons.css"
open(dst, "w").write("/* GERADO por scripts/tw/legacy_icons.py — temporário, ver o script. */\n" + "\n".join(out) + "\n")
print("ok", len(out), "regras")
