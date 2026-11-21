"""Shell/app, parte A: ai (chat, composer, insights, message, promo, proposal, tool trace, conversation list,
prompt suggestions, greeting), code_block, email (preview), glow_text, tool, trace: lado original.

O original de cada caso é um instantâneo de `shell_a.exs` renderizado com a biblioteca ANTES da migração (classes
lu-* + estilos inline, commit 3506478) sobre a folha legada: o bundle da referência (já carregado por run.py) mais o
CSS companheiro da biblioteca (`parity/legacy/ledger_ui.css`, 3º elemento do caso). Alguns casos vêm do gerador da
referência (c6.py, prefixo `ref-`). Regenerar o instantâneo: `bash parity/cases/shell_a_snapshot.sh`.
"""
import json, os
from _common import *

H = os.path.dirname(os.path.abspath(__file__))
ORIG = json.load(open(f"{H}/shell_a_orig.json"))
COMPANION = open(f"{H}/../legacy/ledger_ui.css").read()   # regras lu-* que só existem no CSS da lib

# id -> largura do quadro (px)
W = {
    "glow-text-tones": 420,
    "code-block-basic": 520, "code-block-plain": 460, "code-block-diff": 520, "code-block-variants": 360, "code-block-parts": 360,
    "email-preview": 640, "email-preview-bare": 640,
    "trace-lines": 420, "trace-spans": 420, "trace-steps": 420,
    "tool-lines": 460, "tool-panels": 460, "tool-approval": 460,
    "ai-insights-card": 520, "ai-insights-list": 480,
    "ai-promo-card": 300, "ai-promo-rail": 300, "ai-greeting": 520,
    "ai-message-roles": 640, "ai-message-stream": 520, "ai-message-trace": 520,
    "ai-tool-trace-open": 420,
    "ai-proposal-pending": 480, "ai-proposal-layouts": 480, "ai-proposal-status": 480,
    "ai-composer-default": 680, "ai-composer-states": 560, "ai-composer-canvas": 680,
    "prompt-suggestions-card": 560, "prompt-suggestions-pill-grid": 620,
    "conversation-list-card": 340, "conversation-list-rail": 300,
    "ai-chat-card": 680, "ai-chat-start": 680, "ai-chat-variants": 680,
}

C = {k: (W[k], ORIG[k], COMPANION) for k in W}
