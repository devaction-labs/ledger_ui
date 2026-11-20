"""Localiza o material de referência (somente leitura, fora do repo) e monta um workspace temporário.

O gerador de referência (`gen/c*.py`) espera `out/design-system/project/tokens.json` ao lado de `gen/`.
Em vez de editar a referência, copiamos `gen/*.py` e os tokens para um workspace em /tmp, que é
reconstruído só quando a referência muda. Nada disto entra no repositório nem no pacote Hex.

Variáveis de ambiente:
  LEDGER_REF   pasta da referência (padrão: ../ledger_ui_ref da raiz do repo; ../../ledger_ui_ref se for um worktree)
  CHROME       navegador (padrão /usr/bin/chromium)
  PARITY_DIR   saída/temporários (padrão /tmp/parity)
"""
import os, shutil, hashlib, tempfile

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CHROME = os.environ.get("CHROME", "/usr/bin/chromium")
PARITY_DIR = os.environ.get("PARITY_DIR", "/tmp/parity")


def ref_root():
    cands = [os.environ.get("LEDGER_REF")] if os.environ.get("LEDGER_REF") else []
    cands += [os.path.join(REPO, "..", "ledger_ui_ref"), os.path.join(REPO, "..", "..", "ledger_ui_ref")]
    for c in cands:
        if c and os.path.isfile(os.path.join(c, "referencia", "tokens.json")):
            return os.path.abspath(c)
    raise SystemExit("referência não encontrada: defina LEDGER_REF=/caminho/para/ledger_ui_ref")


REF = ref_root()
TOKENS = f"{REF}/referencia/tokens.json"
BUNDLE_CSS = f"{REF}/gen/bundle.css"          # fonte da verdade do visual (lu-*)
BUNDLE_JS = f"{REF}/referencia/components/bundle.js"


def _stamp():
    h = hashlib.sha1()
    for f in sorted(os.listdir(f"{REF}/gen")):
        p = f"{REF}/gen/{f}"
        if f.endswith(".py"):
            h.update(f.encode()); h.update(str(os.path.getmtime(p)).encode())
    h.update(str(os.path.getmtime(TOKENS)).encode())
    return h.hexdigest()[:12]


def workspace():
    """Retorna <ws>/gen (com c1.py … c17.py importáveis) sem tocar na referência."""
    base = os.path.join(PARITY_DIR, "_refws")
    ws = os.path.join(base, _stamp())
    if not os.path.isdir(ws):
        os.makedirs(base, exist_ok=True)
        tmp = tempfile.mkdtemp(dir=base)
        os.makedirs(f"{tmp}/gen"); os.makedirs(f"{tmp}/out/design-system/project")
        for f in os.listdir(f"{REF}/gen"):
            if f.endswith(".py"):
                shutil.copy(f"{REF}/gen/{f}", f"{tmp}/gen/{f}")
        shutil.copy(TOKENS, f"{tmp}/out/design-system/project/tokens.json")
        try:
            os.rename(tmp, ws)
        except OSError:  # outro processo montou primeiro
            shutil.rmtree(tmp, ignore_errors=True)
    return f"{ws}/gen"
