"""Helpers dos casos de paridade (lado original, CSS lu-*). Cada arquivo `cases/<grupo>.py` define
`C = {id: (largura_px, html)}`; `run.py` junta todos. O mesmo id precisa existir em `cases/<grupo>.exs`."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "scripts", "tw"))
import ref
sys.path.insert(0, ref.workspace())          # gen/base.py, c1.py … c17.py da referência (cópia em /tmp)
from base import ic, field, inp, card        # noqa: E402,F401
import c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16, c17  # noqa: E402,F401

COLORS = ["neutral", "primary", "secondary", "info", "success", "warning", "error", "white", "mono"]
VARIANTS = ["solid", "glow", "outline", "soft", "bordered", "flat", "glass", "ghost", "dim"]
SIZES = ["xs", "sm", "md", "lg", "xl"]


def row(*x): return '<div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap">' + "".join(x) + "</div>"
def colm(*x): return '<div style="display:flex;flex-direction:column;gap:14px">' + "".join(x) + "</div>"
