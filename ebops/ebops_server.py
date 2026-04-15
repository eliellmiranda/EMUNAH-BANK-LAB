"""
EBOPS Web Server — Backend Flask para o Emunah Bank Operations Simulator.

Expõe todas as funcionalidades do ebops.py como API REST para o frontend HTML.
Roda em http://localhost:5000
"""

import os
import sys
import json
import random
import subprocess
from datetime import datetime
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS

# Importa dados e funções do ebops original
sys.path.insert(0, os.path.dirname(__file__))
from ebops import (
    TEMPLATES, INJECTIONS, INJ_MAP, MUTATIONS, GRADE,
    STATUS_LABELS, find_project, load_state, save_state
)

app = Flask(__name__, static_folder='web', static_url_path='')
app.config['JSON_AS_ASCII'] = False
CORS(app)

# ─── Estado global ───────────────────────────────────────────
PROJ = None

def get_proj():
    global PROJ
    if PROJ is None:
        PROJ = find_project()
    return PROJ

def get_state():
    return load_state(get_proj())

def put_state(state):
    save_state(get_proj(), state)

# ─── Frontend ────────────────────────────────────────────────
@app.route('/')
def index():
    return send_from_directory('web', 'index.html')

# ─── API: Info do Projeto ────────────────────────────────────
@app.route('/api/info')
def api_info():
    proj = get_proj()
    state = get_state()
    return jsonify({
        "project": proj,
        "day": state.get("day", 1),
        "total_tickets": len(state.get("tickets", [])),
        "active_injections": len(state.get("injections_active", [])),
        "history_count": len(state.get("history", []))
    })

# ─── API: Grade Batch ────────────────────────────────────────
@app.route('/api/batch')
def api_batch():
    fail = request.args.get('fail', 'false').lower() == 'true'
    if not fail:
        jobs = [{"job": j, "hora": h, "pgm": p, "status": "ok", "rc": "0000"} for j, h, p in GRADE]
    else:
        fi = random.randint(0, len(GRADE) - 1)
        ft = random.choice(["error", "warning", "hold"])
        jobs = []
        for i, (j, h, p) in enumerate(GRADE):
            if i < fi:
                jobs.append({"job": j, "hora": h, "pgm": p, "status": "ok", "rc": "0000"})
            elif i == fi:
                rc = "0012" if ft == "error" else "0004" if ft == "warning" else "HOLD"
                jobs.append({"job": j, "hora": h, "pgm": p, "status": ft, "rc": rc})
            else:
                jobs.append({"job": j, "hora": h, "pgm": p, "status": "pending", "rc": "----"})
    return jsonify(jobs)

# ─── API: Templates ──────────────────────────────────────────
@app.route('/api/templates')
def api_templates():
    cat = request.args.get('cat')
    if cat:
        filtered = [t for t in TEMPLATES if t["cat"] == cat]
        return jsonify(filtered)
    return jsonify(TEMPLATES)

# ─── API: Catálogo de Injeções ───────────────────────────────
@app.route('/api/injections')
def api_injections():
    return jsonify(INJECTIONS)

# ─── API: Gerar Novo Dia ─────────────────────────────────────
@app.route('/api/dia', methods=['POST'])
def api_gerar_dia():
    proj = get_proj()
    state = get_state()
    dia = state.get("day", 1)
    all_templates = TEMPLATES + state.get("custom_templates", [])

    # Simula batch (50% chance de falha)
    fail = random.random() < 0.5
    if not fail:
        batch = [{"job": j, "hora": h, "pgm": p, "status": "ok", "rc": "0000"} for j, h, p in GRADE]
    else:
        fi = random.randint(0, len(GRADE) - 1)
        ft = random.choice(["error", "warning", "hold"])
        batch = []
        for i, (j, h, p) in enumerate(GRADE):
            if i < fi:
                batch.append({"job": j, "hora": h, "pgm": p, "status": "ok", "rc": "0000"})
            elif i == fi:
                rc = "0012" if ft == "error" else "0004" if ft == "warning" else "HOLD"
                batch.append({"job": j, "hora": h, "pgm": p, "status": ft, "rc": rc})
            else:
                batch.append({"job": j, "hora": h, "pgm": p, "status": "pending", "rc": "----"})

    # Sorteia 2-4 tickets
    qty = random.randint(2, 4)
    chosen = random.sample(all_templates, min(qty, len(all_templates)))
    new_tickets = []
    for i, tmpl in enumerate(chosen):
        ticket = {
            "ticket_id": f"EB-{dia:03d}-{i+1:02d}",
            "template_id": tmpl["id"],
            "titulo": tmpl["t"],
            "categoria": tmpl["cat"],
            "severidade": tmpl["sev"],
            "dificuldade": tmpl["dif"],
            "tempo": tmpl["tmp"],
            "ferramenta": tmpl["fer"],
            "descricao": tmpl["desc"],
            "tags": tmpl.get("tags", []),
            "inj": tmpl.get("inj", ""),
            "status": "backlog",
            "dia": dia,
            "notas": "",
            "criado_em": datetime.now().isoformat()
        }
        new_tickets.append(ticket)
        state.setdefault("tickets", []).append(ticket)

    # Identifica injeções disponíveis
    injectable = [t for t in chosen if t.get("inj") and t["inj"] in INJ_MAP]

    state["day"] = dia + 1
    put_state(state)

    return jsonify({
        "dia": dia,
        "batch": batch,
        "tickets": new_tickets,
        "injectable": [{"inj_id": t["inj"], "ticket": t["t"], "template_id": t["id"]} for t in injectable]
    })

# ─── API: Tickets ────────────────────────────────────────────
@app.route('/api/tickets')
def api_tickets():
    state = get_state()
    filtro = request.args.get('filtro', '').lower()
    tickets = state.get("tickets", [])
    if filtro:
        tickets = [t for t in tickets if
                   filtro in t.get("categoria", "").lower() or
                   filtro in t.get("severidade", "").lower() or
                   filtro in t.get("dificuldade", "").lower() or
                   filtro in t.get("status", "").lower() or
                   filtro in t.get("titulo", "").lower()]
    # Conta por status
    counts = {}
    for t in state.get("tickets", []):
        s = t.get("status", "backlog")
        counts[s] = counts.get(s, 0) + 1

    return jsonify({"tickets": tickets, "counts": counts})

@app.route('/api/tickets/move', methods=['POST'])
def api_move_ticket():
    data = request.json
    ticket_id = data.get("ticket_id")
    novo_status = data.get("status")
    if novo_status not in STATUS_LABELS:
        return jsonify({"error": f"Status inválido: {novo_status}"}), 400

    state = get_state()
    for t in state.get("tickets", []):
        if t["ticket_id"] == ticket_id:
            t["status"] = novo_status
            put_state(state)
            return jsonify({"ok": True, "ticket_id": ticket_id, "status": novo_status})
    return jsonify({"error": "Ticket não encontrado"}), 404

@app.route('/api/tickets/notas', methods=['POST'])
def api_update_notas():
    data = request.json
    ticket_id = data.get("ticket_id")
    notas = data.get("notas", "")

    state = get_state()
    for t in state.get("tickets", []):
        if t["ticket_id"] == ticket_id:
            t["notas"] = notas
            put_state(state)
            return jsonify({"ok": True})
    return jsonify({"error": "Ticket não encontrado"}), 404

# ─── API: Injetar Defeito ────────────────────────────────────
@app.route('/api/inject', methods=['POST'])
def api_inject():
    data = request.json
    inj_id = data.get("inj_id")
    proj = get_proj()
    state = get_state()

    inj = INJ_MAP.get(inj_id)
    if not inj:
        return jsonify({"error": f"Injeção {inj_id} não encontrada"}), 404
    if inj_id in [a["id"] for a in state.get("injections_active", [])]:
        return jsonify({"error": f"{inj_id} já está ativo"}), 409

    for f in inj["arqs"]:
        if not os.path.isfile(os.path.join(proj, f)):
            return jsonify({"error": f"Arquivo não encontrado: {f}"}), 404

    fn = MUTATIONS.get(inj_id)
    if not fn:
        return jsonify({"error": "Mutação não implementada"}), 501

    try:
        fn(proj)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

    state.setdefault("injections_active", []).append({
        "id": inj_id,
        "titulo": inj["t"],
        "arquivos": inj["arqs"],
        "timestamp": datetime.now().isoformat()
    })
    put_state(state)

    return jsonify({
        "ok": True,
        "inj_id": inj_id,
        "titulo": inj["t"],
        "arquivos": inj["arqs"],
        "sintoma": inj["sintoma"],
        "dica": inj["dica"]
    })

# ─── API: Injeções Ativas ────────────────────────────────────
@app.route('/api/injections/active')
def api_active_injections():
    state = get_state()
    return jsonify(state.get("injections_active", []))

# ─── API: Reverter Injeção ───────────────────────────────────
@app.route('/api/revert', methods=['POST'])
def api_revert():
    data = request.json
    inj_id = data.get("inj_id")  # None = reverter todas
    proj = get_proj()
    state = get_state()
    active = state.get("injections_active", [])

    if not active:
        return jsonify({"error": "Nenhuma injeção ativa"}), 404

    target = [a for a in active if a["id"] == inj_id] if inj_id else active
    if not target:
        return jsonify({"error": f"{inj_id} não está ativa"}), 404

    files = set()
    for a in target:
        for f in a.get("arquivos", []):
            files.add(f)

    results = []
    for f in sorted(files):
        try:
            res = subprocess.run(["git", "checkout", "--", f], cwd=proj,
                                 capture_output=True, text=True)
            results.append({"file": f, "ok": res.returncode == 0,
                            "msg": res.stderr.strip() if res.returncode != 0 else ""})
        except Exception as e:
            results.append({"file": f, "ok": False, "msg": str(e)})

    ids_to_remove = {a["id"] for a in target}
    state["injections_active"] = [a for a in active if a["id"] not in ids_to_remove]
    state.setdefault("history", []).extend(target)
    put_state(state)

    return jsonify({"ok": True, "reverted": [a["id"] for a in target], "files": results})

# ─── API: Histórico ──────────────────────────────────────────
@app.route('/api/history')
def api_history():
    state = get_state()
    return jsonify(state.get("history", []))

# ─── API: Reset ──────────────────────────────────────────────
@app.route('/api/reset', methods=['POST'])
def api_reset():
    proj = get_proj()
    state = get_state()

    # Reverte injeções ativas
    active = state.get("injections_active", [])
    files = set()
    for a in active:
        for f in a.get("arquivos", []):
            files.add(f)
    for f in files:
        try:
            subprocess.run(["git", "checkout", "--", f], cwd=proj, capture_output=True)
        except:
            pass

    # Limpa state
    new_state = {"tickets": [], "custom_templates": state.get("custom_templates", []),
                 "day": 1, "injections_active": [], "history": []}
    put_state(new_state)
    return jsonify({"ok": True, "msg": "Estado resetado"})

# ─── API: Exportar tickets ───────────────────────────────────
@app.route('/api/export')
def api_export():
    state = get_state()
    return jsonify(state.get("tickets", []))

# ─── Inicialização ───────────────────────────────────────────
if __name__ == '__main__':
    print("\n  EBOPS Web Server")
    print("  ================")
    proj = get_proj()
    print(f"  Projeto: {proj}")
    print(f"  Acesse:  http://localhost:5000\n")
    app.run(host='0.0.0.0', port=5000, debug=True)
