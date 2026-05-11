"""
EBOPS Web Server v5 - Backend Flask alinhado ao ebops-cli.ps1.

Mudancas v5:
- Strip de ANSI escape codes nos logs do Zowe.
- Env NO_COLOR/FORCE_COLOR=0 para suprimir cores do chalk (Node).
- Tickets Jira-like em arquivo separado (tickets.json) — nao conflita com o CLI.
"""

import os
import re
import json
import shutil
import sys
import subprocess
import sqlite3
import random
from contextlib import closing
from datetime import datetime
from pathlib import Path
from flask import (Flask, jsonify, request, send_from_directory,
                   Response, stream_with_context)
from flask_cors import CORS

# --- Caminhos -------------------------------------------------
HERE = Path(__file__).resolve().parent
DATA_DIR = HERE / "data"
INJECOES_FILE = DATA_DIR / "injecoes.json"
ESTADO_FILE = DATA_DIR / "estado.json"
TICKETS_FILE = DATA_DIR / "tickets.json"
ARQUIVO_LOCAL_TEMP = HERE / "temp_injecao.txt"
BASE_DIR = HERE.parent
SCRIPT_PYTHON = BASE_DIR / "automation" / "geracao" / "gerar_lancamentos.py"
DATA_ENTRADA_DIR = BASE_DIR / "data" / "entrada"
HLQ_ENTRADA = "Z77948.EMUNAH.STAGE.ENTRADA.SEQ"
BANCO_DB = DATA_DIR / "banco.db"
ARQUIVOS_GERADOS_DIR = BASE_DIR / "data" / "arquivos_gerados"

# --- Config mainframe ----------------------------------------
HLQ_JCL = "Z77948.EMUNAH.DEV.JCL"
HLQ_COBOL = "Z77948.EMUNAH.DEV.COBOL"
HLQ_COPY = "Z77948.EMUNAH.DEV.COPY"

ALLOWED = {
    "COBOL": {"EBCTL01","EBVALI01","EBPOST01","EBACCR01","EBSNAP01",
              "EBCONC01","EBEXTR01","EBJEOD01"},
    "COPY":  {"CPLCT001","CPCNT001","CPAUD001","CPREJ001","CPSNP001",
              "CPCNC001","CPEXT001","CPSTS001"},
    "JCL":   {"EBJPRECK","EBJSOD","EBJBCKPD","EBJWAIT","EBJLOAD",
              "EBJVALD","EBJRPOST","EBJCUTE","EBJCUTF","EBJACCR",
              "EBJSNAP","EBJCONC","EBJEXTR","EBJEOD"},
}
JOBS_PERMITIDOS = {"EBRESET", "EBDEPLOY", "EBJCHAIN", "EBSETSTS"}
TICKET_STATUSES = {"backlog", "em_andamento", "em_revisao", "concluido"}

# --- ANSI scrubbing ------------------------------------------
ANSI_RE = re.compile(r'\x1b\[[0-9;]*[a-zA-Z]')

def strip_ansi(s):
    if not s: return s
    return ANSI_RE.sub('', s)


# --- Resolucao do Zowe (Windows: precisa achar .cmd/.bat) ---
def _find_zowe():
    for name in ("zowe", "zowe.cmd", "zowe.bat", "zowe.exe", "zowe.ps1"):
        p = shutil.which(name)
        if p:
            return p
    return None

ZOWE = _find_zowe()

def _no_color_env():
    env = os.environ.copy()
    env["NO_COLOR"] = "1"
    env["FORCE_COLOR"] = "0"
    env["CLICOLOR"] = "0"
    env["CLICOLOR_FORCE"] = "0"
    env["TERM"] = "dumb"
    return env


app = Flask(__name__, static_folder='web', static_url_path='')
app.config['JSON_AS_ASCII'] = False
CORS(app)


# --- Helpers --------------------------------------------------
def get_hlq(t):
    return {"COBOL": HLQ_COBOL, "COPY": HLQ_COPY, "JCL": HLQ_JCL}[t]

def membro_permitido(t, m):
    return m in ALLOWED.get(t, set())

def load_injecoes():
    with open(INJECOES_FILE, encoding="utf-8") as f:
        return json.load(f)

def load_estado():
    if ESTADO_FILE.exists():
        try:
            with open(ESTADO_FILE, encoding="utf-8") as f:
                d = json.load(f)
            return {
                "injecoes_ativas": list(d.get("injecoes_ativas") or []),
                "historico": list(d.get("historico") or []),
            }
        except Exception:
            pass
    return {"injecoes_ativas": [], "historico": []}

def save_estado(e):
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(ESTADO_FILE, "w", encoding="utf-8") as f:
        json.dump(e, f, indent=2, ensure_ascii=False)

def load_tickets():
    if TICKETS_FILE.exists():
        try:
            with open(TICKETS_FILE, encoding="utf-8") as f:
                return list(json.load(f) or [])
        except Exception:
            pass
    return []

def save_tickets(tk):
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(TICKETS_FILE, "w", encoding="utf-8") as f:
        json.dump(tk, f, indent=2, ensure_ascii=False)

def upsert_ticket(tid, status):
    """Cria ou atualiza o ticket de uma injecao. Preserva notas."""
    ts = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    tk = load_tickets()
    t = next((x for x in tk if int(x["Id"]) == int(tid)), None)
    if t:
        t["status"] = status
        t["atualizado_em"] = ts
    else:
        tk.append({
            "Id": int(tid),
            "status": status,
            "criado_em": ts,
            "atualizado_em": ts,
            "notas": "",
        })
    save_tickets(tk)


def _zowe_cmd(args):
    if not ZOWE:
        return None
    if ZOWE.lower().endswith(".ps1"):
        return ["powershell.exe", "-NoProfile",
                "-ExecutionPolicy", "Bypass", "-File", ZOWE] + list(args)
    return [ZOWE] + list(args)


def run_zowe(args, timeout=900):
    cmd = _zowe_cmd(args)
    if cmd is None:
        return 127, "Zowe CLI nao encontrado no PATH."
    try:
        r = subprocess.run(cmd, capture_output=True, text=True,
                           timeout=timeout, encoding="utf-8", errors="replace",
                           env=_no_color_env())
        out = strip_ansi((r.stdout or "") + (r.stderr or ""))
        return r.returncode, out
    except subprocess.TimeoutExpired:
        return 124, "Timeout na chamada Zowe."
    except Exception as ex:
        return 1, f"Erro ao chamar Zowe: {ex}"


def stream_zowe(args):
    """Generator que produz tuplas (evento, dado) - usado em SSE."""
    cmd = _zowe_cmd(args)
    if cmd is None:
        yield ("line", "ERRO: Zowe CLI nao encontrado no PATH.")
        yield ("done", {"ok": False, "rc": 127})
        return
    yield ("line", f"$ zowe {' '.join(args)}")
    try:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True, bufsize=1,
            encoding="utf-8", errors="replace",
            env=_no_color_env(),
        )
    except Exception as ex:
        yield ("line", f"ERRO ao iniciar processo: {ex}")
        yield ("done", {"ok": False, "rc": 1})
        return

    for raw in iter(proc.stdout.readline, ''):
        line = strip_ansi(raw.rstrip())
        if line:
            yield ("line", line)
    proc.stdout.close()
    rc = proc.wait()
    yield ("done", {"ok": rc == 0, "rc": rc})


def sse_response(generator):
    def make():
        for ev, data in generator:
            if ev == "line":
                yield f"data: {json.dumps(data, ensure_ascii=False)}\n\n"
            elif ev == "done":
                yield f"event: done\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"
    return Response(
        stream_with_context(make()),
        mimetype='text/event-stream',
        headers={'Cache-Control': 'no-cache', 'X-Accel-Buffering': 'no'},
    )


# --- Frontend -------------------------------------------------
@app.route('/')
def index():
    return send_from_directory('web', 'index.html')


@app.route('/api/info')
def api_info():
    e = load_estado()
    tk = load_tickets()
    counts = {s: 0 for s in TICKET_STATUSES}
    for t in tk:
        if t.get("status") in counts:
            counts[t["status"]] += 1
    return jsonify({
        "total_injecoes": len(load_injecoes()),
        "injecoes_ativas": len(e["injecoes_ativas"]),
        "historico": len(e["historico"]),
        "tickets_total": len(tk),
        "tickets_por_status": counts,
        "zowe_path": ZOWE or "(nao encontrado)",
    })


@app.route('/api/injecoes')
def api_injecoes():
    return jsonify(load_injecoes())


@app.route('/api/estado')
def api_estado():
    e = load_estado()
    e["tickets"] = load_tickets()
    return jsonify(e)


# --- Aplicar / Reverter --------------------------------------
def _processar_injecao(inj_id, reverter):
    injecoes = load_injecoes()
    inj = next((x for x in injecoes if int(x["Id"]) == inj_id), None)
    if not inj:
        return {"ok": False, "erro": f"Injecao #{inj_id} nao encontrada"}, 404

    estado = load_estado()
    ativa = next((a for a in estado["injecoes_ativas"]
                  if int(a["Id"]) == inj_id), None)

    if not reverter and ativa:
        return {"ok": False,
                "erro": f"Injecao ja ativa desde {ativa.get('Timestamp','?')}"}, 409
    if reverter and not ativa:
        return {"ok": False, "erro": "Injecao nao esta ativa"}, 409
    if not membro_permitido(inj["TipoDataset"], inj["Membro"]):
        return {"ok": False, "erro": "Membro nao esta na allowlist"}, 403

    dsn = f"{get_hlq(inj['TipoDataset'])}({inj['Membro']})"
    busca = inj["Injetado"] if reverter else inj["Original"]
    troca = inj["Original"] if reverter else inj["Injetado"]

    if ARQUIVO_LOCAL_TEMP.exists():
        try: ARQUIVO_LOCAL_TEMP.unlink()
        except Exception: pass

    rc, out = run_zowe(["zos-files", "download", "data-set", dsn,
                        "-f", str(ARQUIVO_LOCAL_TEMP)])
    if rc != 0 or not ARQUIVO_LOCAL_TEMP.exists():
        return {"ok": False, "erro": "Falha no download Zowe", "log": out}, 502

    conteudo = ARQUIVO_LOCAL_TEMP.read_text(encoding="utf-8", errors="replace")
    if busca not in conteudo:
        try: ARQUIVO_LOCAL_TEMP.unlink()
        except Exception: pass
        ctx = "injetada" if reverter else "original"
        return {"ok": False,
                "erro": f"String {ctx} nao encontrada em {dsn}",
                "buscada": busca}, 422

    novo = conteudo.replace(busca, troca)
    ARQUIVO_LOCAL_TEMP.write_text(novo, encoding="utf-8")
    rc, out = run_zowe(["zos-files", "upload", "file-to-data-set",
                        str(ARQUIVO_LOCAL_TEMP), dsn])
    try: ARQUIVO_LOCAL_TEMP.unlink()
    except Exception: pass
    if rc != 0:
        return {"ok": False, "erro": "Falha no upload Zowe", "log": out}, 502

    ts = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    if reverter:
        estado["historico"].append({
            "Id": int(inj["Id"]), "Titulo": inj["Titulo"],
            "Membro": inj["Membro"], "TipoDataset": inj["TipoDataset"],
            "Descricao": inj["Descricao"], "RevertidoEm": ts,
        })
        estado["injecoes_ativas"] = [a for a in estado["injecoes_ativas"]
                                     if int(a["Id"]) != inj_id]
    else:
        estado["injecoes_ativas"].append({
            "Id": int(inj["Id"]), "Titulo": inj["Titulo"],
            "Membro": inj["Membro"], "TipoDataset": inj["TipoDataset"],
            "Descricao": inj["Descricao"], "Timestamp": ts,
        })
    save_estado(estado)

    # Ticket workflow:
    #   aplicar  -> cria/abre ticket em "backlog"
    #   reverter -> move para "concluido"
    upsert_ticket(inj_id, "concluido" if reverter else "backlog")

    return {
        "ok": True, "reverter": reverter, "injecao": inj,
        "ticket_simulado": {
            "abertura": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "severidade": inj["SeveridadeTicket"],
            "camada": inj["CamadaFalha"],
            "rc_abend": inj["AbendOuRC"],
            "sintoma": inj["SintomaTicket"],
            "dica": inj["Dica"],
        },
        "precisa_compilar": inj["TipoDataset"] in ("COBOL", "COPY"),
    }, 200


@app.route('/api/injecoes/<int:inj_id>/aplicar', methods=['POST'])
def api_aplicar(inj_id):
    data, status = _processar_injecao(inj_id, reverter=False)
    return jsonify(data), status


@app.route('/api/injecoes/<int:inj_id>/reverter', methods=['POST'])
def api_reverter(inj_id):
    data, status = _processar_injecao(inj_id, reverter=True)
    return jsonify(data), status


# --- Tickets ---------------------------------------------
@app.route('/api/tickets')
def api_tickets():
    return jsonify(load_tickets())

@app.route('/api/tickets/<int:tid>/status', methods=['POST'])
def api_ticket_status(tid):
    data = request.get_json(force=True, silent=True) or {}
    novo = (data.get("status") or "").lower()
    if novo not in TICKET_STATUSES:
        return jsonify({"ok": False, "erro": "Status invalido"}), 400
    tk = load_tickets()
    t = next((x for x in tk if int(x["Id"]) == tid), None)
    if not t:
        # cria do nada
        tk.append({
            "Id": tid, "status": novo,
            "criado_em": datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
            "atualizado_em": datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
            "notas": "",
        })
    else:
        t["status"] = novo
        t["atualizado_em"] = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    save_tickets(tk)
    return jsonify({"ok": True})

@app.route('/api/tickets/<int:tid>/notas', methods=['POST'])
def api_ticket_notas(tid):
    data = request.get_json(force=True, silent=True) or {}
    tk = load_tickets()
    t = next((x for x in tk if int(x["Id"]) == tid), None)
    if not t:
        return jsonify({"ok": False, "erro": "Ticket nao encontrado"}), 404
    t["notas"] = data.get("notas", "")
    t["atualizado_em"] = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    save_tickets(tk)
    return jsonify({"ok": True})

@app.route('/api/tickets/<int:tid>', methods=['DELETE'])
def api_ticket_delete(tid):
    tk = load_tickets()
    tk = [x for x in tk if int(x["Id"]) != tid]
    save_tickets(tk)
    return jsonify({"ok": True})


# --- Jobs (SSE streaming) ------------------------------------
@app.route('/api/jobs/<nome>/stream')
def api_job_stream(nome):
    nome = nome.upper()
    if nome not in JOBS_PERMITIDOS:
        def err():
            yield ("line", f"Job {nome} nao permitido")
            yield ("done", {"ok": False, "rc": 403})
        return sse_response(err())
    return sse_response(stream_zowe([
        "zos-jobs", "submit", "data-set",
        f"{HLQ_JCL}({nome})", "--wfo"
    ]))


@app.route('/api/jobs/<nome>', methods=['POST'])
def api_job_sync(nome):
    nome = nome.upper()
    if nome not in JOBS_PERMITIDOS:
        return jsonify({"ok": False, "erro": f"Job {nome} nao permitido"}), 403
    rc, out = run_zowe(["zos-jobs", "submit", "data-set",
                        f"{HLQ_JCL}({nome})", "--wfo"], timeout=1800)
    return jsonify({"ok": rc == 0, "rc": rc, "log": out, "job": nome})


@app.route('/api/backup/stream')
def api_backup_stream():
    base = HERE.parent / "backup_emunah"
    base.mkdir(parents=True, exist_ok=True)
    return sse_response(stream_zowe([
        "zos-files", "download", "data-sets-matching",
        "Z77948.EMUNAH.**",
        "--directory", str(base),
        "--fail-fast", "false",
    ]))


@app.route('/api/diagnostico')
def api_diagnostico():
    injecoes = load_injecoes()
    resultado = []
    for inj in injecoes:
        item = {"Id": int(inj["Id"]), "Titulo": inj["Titulo"],
                "Membro": inj["Membro"], "TipoDataset": inj["TipoDataset"]}
        if not membro_permitido(inj["TipoDataset"], inj["Membro"]):
            item["status"] = "ignorado"; resultado.append(item); continue
        dsn = f"{get_hlq(inj['TipoDataset'])}({inj['Membro']})"
        tmp = HERE / f"diag_{inj['Id']}.txt"
        if tmp.exists():
            try: tmp.unlink()
            except Exception: pass
        rc, _ = run_zowe(["zos-files", "download", "data-set",
                          dsn, "-f", str(tmp)])
        if rc != 0 or not tmp.exists():
            item["status"] = "erro_download"; resultado.append(item); continue
        conteudo = tmp.read_text(encoding="utf-8", errors="replace")
        item["original_ok"] = inj["Original"] in conteudo
        item["injetado_presente"] = inj["Injetado"] in conteudo
        if not item["original_ok"]:
            item["preview"] = conteudo.splitlines()[:40]
            item["buscada"] = inj["Original"]
        item["status"] = "ok"
        try: tmp.unlink()
        except Exception: pass
        resultado.append(item)
    return jsonify(resultado)


@app.route('/api/estado/limpar', methods=['POST'])
def api_limpar_estado():
    save_estado({"injecoes_ativas": [], "historico": []})
    return jsonify({"ok": True})

@app.route('/api/injecoes/importar', methods=['POST'])
def api_importar_injecoes():
    data = request.get_json(force=True, silent=True)
    if not isinstance(data, list):
        return jsonify({"ok": False, "erro": "Envie um array JSON de injeções"}), 400

    existentes = load_injecoes()
    ids = {int(x["Id"]) for x in existentes}

    obrigatorios = {"Id","Titulo","TipoDataset","Membro","Original","Injetado",
                    "SeveridadeTicket","SintomaTicket","Dica"}
    adicionadas, ignoradas, erros = [], [], []

    for item in data:
        if not isinstance(item, dict):
            erros.append("item nao e objeto"); continue
        faltam = obrigatorios - set(item.keys())
        if faltam:
            erros.append(f"campos faltando: {sorted(faltam)}"); continue
        try: iid = int(item["Id"])
        except Exception:
            erros.append(f"Id invalido em '{item.get('Titulo','?')}'"); continue
        if iid in ids:
            ignoradas.append(iid); continue
        if item["TipoDataset"] not in ("COBOL","COPY","JCL"):
            erros.append(f"#{iid} TipoDataset invalido: {item['TipoDataset']}"); continue
        if not membro_permitido(item["TipoDataset"], item["Membro"]):
            erros.append(f"#{iid} Membro {item['Membro']} fora da allowlist"); continue
        if (item["SeveridadeTicket"] or "").lower() not in ("critica","alta","media","baixa"):
            erros.append(f"#{iid} Severidade invalida: {item['SeveridadeTicket']}"); continue
        item.setdefault("Descricao", "")
        item.setdefault("CamadaFalha", 0)
        item.setdefault("AbendOuRC", "")
        existentes.append(item)
        ids.add(iid)
        adicionadas.append(iid)

    with open(INJECOES_FILE, "w", encoding="utf-8") as f:
        json.dump(existentes, f, indent=2, ensure_ascii=False)

    return jsonify({
        "ok": True,
        "adicionadas": adicionadas,
        "ignoradas_duplicadas": ignoradas,
        "erros": erros,
    })


@app.route('/api/injecoes/<int:inj_id>', methods=['DELETE'])
def api_remover_injecao(inj_id):
    estado = load_estado()
    if any(int(a["Id"]) == inj_id for a in estado["injecoes_ativas"]):
        return jsonify({"ok": False, "erro": "Injecao esta ativa - reverte antes"}), 409
    existentes = load_injecoes()
    novo = [x for x in existentes if int(x["Id"]) != inj_id]
    if len(novo) == len(existentes):
        return jsonify({"ok": False, "erro": "Injecao nao encontrada"}), 404
    with open(INJECOES_FILE, "w", encoding="utf-8") as f:
        json.dump(novo, f, indent=2, ensure_ascii=False)
    return jsonify({"ok": True, "removida": inj_id})

# --- Gerar massa de lancamentos (Python) ---------------------
@app.route('/api/gerar-massa', methods=['POST'])
def api_gerar_massa():
    body = request.get_json(force=True, silent=True) or {}
    try:
        dia = int(body.get("dia", 0))
        qtd = int(body.get("quantidade", 0))
    except Exception:
        return jsonify({"ok": False, "erro": "dia e quantidade devem ser inteiros"}), 400
    if dia < 1 or dia > 31 or qtd < 1:
        return jsonify({"ok": False, "erro": "dia (1-31) e quantidade (>=1) obrigatorios"}), 400

    if not SCRIPT_PYTHON.exists():
        return jsonify({"ok": False,
                        "erro": f"Script Python nao encontrado: {SCRIPT_PYTHON}"}), 500

    DATA_ENTRADA_DIR.mkdir(parents=True, exist_ok=True)
    caminho_saida = DATA_ENTRADA_DIR / f"lancamentos-d{dia}.txt"
    data_full = datetime.now().strftime("%Y%m") + f"{dia:02d}"

    try:
        r = subprocess.run(
            [sys.executable, str(SCRIPT_PYTHON),
             "--quantidade", str(qtd),
             "--output", str(caminho_saida),
             "--data", data_full],
            capture_output=True, text=True, timeout=300,
            encoding="utf-8", errors="replace",
        )
        out = strip_ansi((r.stdout or "") + (r.stderr or ""))
        if r.returncode != 0:
            return jsonify({"ok": False, "rc": r.returncode, "log": out,
                            "erro": "gerador Python retornou erro"}), 502
        return jsonify({
            "ok": True, "rc": 0,
            "arquivo": str(caminho_saida),
            "linhas": qtd, "data": data_full,
            "log": out,
        })
    except subprocess.TimeoutExpired:
        return jsonify({"ok": False, "erro": "Timeout no gerador Python"}), 504
    except Exception as ex:
        return jsonify({"ok": False, "erro": str(ex)}), 500


# --- Seed (upload do arquivo para o STAGE) -------------------
@app.route('/api/seed', methods=['POST'])
def api_seed():
    body = request.get_json(force=True, silent=True) or {}
    try:
        dia = int(body.get("dia", 0))
    except Exception:
        return jsonify({"ok": False, "erro": "dia invalido"}), 400
    if dia < 1 or dia > 31:
        return jsonify({"ok": False, "erro": "dia (1-31) obrigatorio"}), 400

    caminho = DATA_ENTRADA_DIR / f"lancamentos-d{dia}.txt"
    if not caminho.exists():
        return jsonify({"ok": False,
                        "erro": f"Arquivo nao encontrado: {caminho}",
                        "hint": "Gere a massa primeiro"}), 404

    dsn_membro = f"{HLQ_ENTRADA}(LANCD{dia})"
    rc, out = run_zowe(["zos-files", "upload", "file-to-data-set",
                        str(caminho), dsn_membro], timeout=600)
    return jsonify({
        "ok": rc == 0, "rc": rc, "log": out,
        "arquivo": str(caminho), "destino": dsn_membro,
    })

# ============================================================
#   MINI BANCO DE DADOS (SQLite)
# ============================================================
def banco_conn():
    conn = sqlite3.connect(BANCO_DB)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn

def banco_init():
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with closing(banco_conn()) as conn:
        conn.executescript("""
        CREATE TABLE IF NOT EXISTS clientes (
            client_id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            cpf  TEXT NOT NULL UNIQUE,
            data_nasc TEXT NOT NULL,
            data_cad  TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'A'
        );
        CREATE TABLE IF NOT EXISTS contas (
            numero INTEGER PRIMARY KEY AUTOINCREMENT,
            agencia INTEGER NOT NULL DEFAULT 1,
            client_id INTEGER NOT NULL,
            tipo TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'A',
            data_abertura TEXT NOT NULL,
            saldo_centavos INTEGER NOT NULL DEFAULT 0,
            saldo_atual_centavos INTEGER NOT NULL DEFAULT 0,
            limite_centavos INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (client_id) REFERENCES clientes(client_id) ON DELETE CASCADE
        );
        CREATE TABLE IF NOT EXISTS lancamentos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conta_numero INTEGER NOT NULL,
            agencia INTEGER NOT NULL,
            data_movimento TEXT NOT NULL,
            tipo TEXT NOT NULL,
            valor_centavos INTEGER NOT NULL,
            historico TEXT NOT NULL,
            canal TEXT NOT NULL,
            lote INTEGER NOT NULL DEFAULT 1,
            nseq INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'P',
            arquivo TEXT,
            FOREIGN KEY (conta_numero) REFERENCES contas(numero) ON DELETE CASCADE
        );
        CREATE TABLE IF NOT EXISTS arquivos_gerados (
            nome TEXT PRIMARY KEY,
            data_geracao TEXT NOT NULL,
            quantidade INTEGER NOT NULL
        );
        """)
        conn.commit()

banco_init()


@app.route('/api/banco/stats')
def api_banco_stats():
    with closing(banco_conn()) as conn:
        q = lambda t: conn.execute(f"SELECT COUNT(*) c FROM {t}").fetchone()["c"]
        return jsonify({"clientes": q("clientes"), "contas": q("contas"),
                        "lancamentos": q("lancamentos"), "arquivos": q("arquivos_gerados")})


# ---- CLIENTES ----------------------------------------------
@app.route('/api/banco/clientes')
def api_banco_clientes():
    with closing(banco_conn()) as conn:
        rows = conn.execute("""
            SELECT c.*, (SELECT COUNT(*) FROM contas WHERE client_id=c.client_id) AS qtd_contas
            FROM clientes c ORDER BY c.client_id
        """).fetchall()
        return jsonify([dict(r) for r in rows])

@app.route('/api/banco/clientes', methods=['POST'])
def api_banco_cliente_add():
    b = request.get_json(force=True, silent=True) or {}
    nome = (b.get("nome") or "").strip().upper()
    cpf = re.sub(r"\D", "", b.get("cpf") or "")
    nasc = (b.get("data_nasc") or "").strip()
    if not nome: return jsonify({"error": "Nome obrigatorio"}), 400
    if len(cpf) != 11: return jsonify({"error": "CPF deve ter 11 digitos"}), 400
    if len(nasc) != 8 or not nasc.isdigit():
        return jsonify({"error": "Nascimento AAAAMMDD"}), 400
    hoje = datetime.now().strftime("%Y%m%d")
    try:
        with closing(banco_conn()) as conn:
            cur = conn.execute(
                "INSERT INTO clientes (nome,cpf,data_nasc,data_cad,status) VALUES (?,?,?,?,'A')",
                (nome, cpf, nasc, hoje))
            conn.commit()
            return jsonify({"client_id": cur.lastrowid, "nome": nome})
    except sqlite3.IntegrityError:
        return jsonify({"error": "CPF ja cadastrado"}), 409

@app.route('/api/banco/clientes/<int:cid>', methods=['DELETE'])
def api_banco_cliente_del(cid):
    with closing(banco_conn()) as conn:
        conn.execute("DELETE FROM clientes WHERE client_id=?", (cid,))
        conn.commit()
    return jsonify({"message": f"Cliente {cid} excluido"})

@app.route('/api/banco/clientes/seed', methods=['POST'])
def api_banco_cliente_seed():
    b = request.get_json(force=True, silent=True) or {}
    qtd = int(b.get("quantidade") or 20)
    cpc = int(b.get("contas_por_cliente") or 2)
    sv = b.get("seed")
    if sv is not None:
        try: random.seed(int(sv))
        except Exception: pass
    NM = ["JOAO","PEDRO","MARCOS","LUIS","CARLOS","ANTONIO","RAFAEL","BRUNO","TIAGO","FELIPE",
          "MARIA","ANA","JULIA","BEATRIZ","SOFIA","LARA","ISABEL","CLARA","HELENA","LIVIA"]
    SOB = ["SILVA","SANTOS","OLIVEIRA","SOUZA","RODRIGUES","FERREIRA",
           "ALMEIDA","COSTA","PEREIRA","LIMA","CARVALHO","GOMES"]
    hoje = datetime.now().strftime("%Y%m%d")
    nc = nco = 0
    with closing(banco_conn()) as conn:
        for _ in range(qtd):
            nome = f"{random.choice(NM)} {random.choice(SOB)}"
            cpf = "".join(str(random.randint(0,9)) for _ in range(11))
            ano, mes, dia = random.randint(1960,2003), random.randint(1,12), random.randint(1,28)
            try:
                cur = conn.execute(
                    "INSERT INTO clientes (nome,cpf,data_nasc,data_cad,status) VALUES (?,?,?,?,'A')",
                    (nome, cpf, f"{ano:04d}{mes:02d}{dia:02d}", hoje))
                cid = cur.lastrowid; nc += 1
                for _ in range(cpc):
                    tipo = random.choice(["C","P"])
                    saldo = random.randint(0, 500000)
                    limite = random.randint(0, 200000) if tipo == "C" else 0
                    conn.execute(
                        """INSERT INTO contas (agencia,client_id,tipo,status,data_abertura,
                           saldo_centavos,saldo_atual_centavos,limite_centavos)
                           VALUES (1,?,?,'A',?,?,?,?)""",
                        (cid, tipo, hoje, saldo, saldo, limite))
                    nco += 1
            except sqlite3.IntegrityError:
                continue
        conn.commit()
    return jsonify({"clientes": nc, "contas": nco})


# ---- CONTAS ------------------------------------------------
@app.route('/api/banco/contas')
def api_banco_contas():
    with closing(banco_conn()) as conn:
        rows = conn.execute("""
            SELECT co.*, cl.nome AS cliente_nome
            FROM contas co JOIN clientes cl ON cl.client_id = co.client_id
            ORDER BY co.numero
        """).fetchall()
        return jsonify([dict(r) for r in rows])

@app.route('/api/banco/contas', methods=['POST'])
def api_banco_conta_add():
    b = request.get_json(force=True, silent=True) or {}
    try:
        cid = int(b.get("client_id", 0))
        ag = int(b.get("agencia") or 1)
        saldo = int(round(float(str(b.get("saldo","0")).replace(",", ".")) * 100))
        limite = int(round(float(str(b.get("limite","0")).replace(",", ".")) * 100))
    except (ValueError, TypeError):
        return jsonify({"error": "valores invalidos"}), 400
    tipo = (b.get("tipo") or "C").upper()
    if tipo not in ("C","P"): return jsonify({"error": "tipo C ou P"}), 400
    hoje = datetime.now().strftime("%Y%m%d")
    with closing(banco_conn()) as conn:
        if not conn.execute("SELECT 1 FROM clientes WHERE client_id=?", (cid,)).fetchone():
            return jsonify({"error": "Cliente nao encontrado"}), 404
        cur = conn.execute(
            """INSERT INTO contas (agencia,client_id,tipo,status,data_abertura,
               saldo_centavos,saldo_atual_centavos,limite_centavos)
               VALUES (?,?,?,'A',?,?,?,?)""",
            (ag, cid, tipo, hoje, saldo, saldo, limite))
        conn.commit()
        return jsonify({"numero": cur.lastrowid})

@app.route('/api/banco/contas/<int:n>', methods=['DELETE'])
def api_banco_conta_del(n):
    with closing(banco_conn()) as conn:
        conn.execute("DELETE FROM contas WHERE numero=?", (n,))
        conn.commit()
    return jsonify({"message": f"Conta {n} excluida"})


# ---- LANCAMENTOS -------------------------------------------
@app.route('/api/banco/lancamentos')
def api_banco_lancamentos():
    conta = request.args.get("conta")
    arq = request.args.get("arquivo")
    lim = int(request.args.get("limit", 200))
    q = "SELECT * FROM lancamentos WHERE 1=1"
    p = []
    if conta: q += " AND conta_numero=?"; p.append(int(conta))
    if arq:   q += " AND arquivo=?";       p.append(arq)
    q += " ORDER BY id DESC LIMIT ?"; p.append(lim)
    with closing(banco_conn()) as conn:
        return jsonify([dict(r) for r in conn.execute(q, p).fetchall()])

@app.route('/api/banco/lancamentos/<int:lid>', methods=['DELETE'])
def api_banco_lanc_del(lid):
    with closing(banco_conn()) as conn:
        conn.execute("DELETE FROM lancamentos WHERE id=?", (lid,))
        conn.commit()
    return jsonify({"message": f"Lancamento {lid} excluido"})

@app.route('/api/banco/lancamentos/gerar', methods=['POST'])
def api_banco_gerar():
    b = request.get_json(force=True, silent=True) or {}
    try:
        qtd = int(b.get("quantidade", 0))
        vmin = int(round(float(str(b.get("valor_min","10")).replace(",", ".")) * 100))
        vmax = int(round(float(str(b.get("valor_max","1000")).replace(",", ".")) * 100))
        lote_ini = int(b.get("lote_inicial", 1))
    except (ValueError, TypeError):
        return jsonify({"error": "valores numericos invalidos"}), 400
    if qtd < 1: return jsonify({"error": "quantidade obrigatoria"}), 400
    if vmin > vmax: vmin, vmax = vmax, vmin
    data = (b.get("data") or "").strip() or datetime.now().strftime("%Y%m%d")
    if not re.fullmatch(r"\d{8}", data):
        return jsonify({"error": "data AAAAMMDD"}), 400
    status = (b.get("status") or "P").upper()
    sv = b.get("seed")
    if sv is not None:
        try: random.seed(int(sv))
        except Exception: pass
    tipos = b.get("tipos") or ["C","D"]
    canais = b.get("canais") or ["APP","PIX","TED"]
    hist = b.get("historicos") or ["TRANSFERENCIA","PAGAMENTO BOLETO"]
    cli_filter = b.get("clientes") or []

    with closing(banco_conn()) as conn:
        qry = """SELECT co.* FROM contas co
                 JOIN clientes cl ON cl.client_id = co.client_id
                 WHERE co.status='A'"""
        params = []
        if cli_filter:
            ids, nomes_like = [], []
            for x in cli_filter:
                s = str(x).strip()
                if s.isdigit(): ids.append(int(s))
                else: nomes_like.append(f"%{s.upper()}%")
            conds = []
            if ids:
                conds.append("co.client_id IN (" + ",".join(str(i) for i in ids) + ")")
            if nomes_like:
                conds.append("(" + " OR ".join("cl.nome LIKE ?" for _ in nomes_like) + ")")
                params.extend(nomes_like)
            if conds: qry += " AND (" + " OR ".join(conds) + ")"
        contas = conn.execute(qry, params).fetchall()
        if not contas:
            return jsonify({"error": "Nenhuma conta elegivel - cadastre clientes/contas primeiro"}), 400

        nome_arq = f"LANC{data}_{datetime.now().strftime('%H%M%S')}.txt"
        ARQUIVOS_GERADOS_DIR.mkdir(parents=True, exist_ok=True)
        caminho = ARQUIVOS_GERADOS_DIR / nome_arq

        linhas, regs = [], []
        for i in range(qtd):
            c = random.choice(contas)
            tipo = random.choice(tipos)
            valor = random.randint(vmin, vmax)
            h = random.choice(hist)
            canal = random.choice(canais)
            lote = lote_ini + (i // 100)
            nseq = (i % 100) + 1
            linhas.append(
                f"{c['agencia']:04d}{c['numero']:08d}{data}{tipo}{valor:012d}"
                f"{h:<20.20}{canal:<10.10}{lote:06d}{nseq:06d}{status}")
            regs.append((c['numero'], c['agencia'], data, tipo, valor,
                         h, canal, lote, nseq, status, nome_arq))

        caminho.write_text("\n".join(linhas) + "\n", encoding="utf-8")
        conn.executemany(
            """INSERT INTO lancamentos (conta_numero,agencia,data_movimento,tipo,
               valor_centavos,historico,canal,lote,nseq,status,arquivo)
               VALUES (?,?,?,?,?,?,?,?,?,?,?)""", regs)
        conn.execute(
            "INSERT INTO arquivos_gerados (nome,data_geracao,quantidade) VALUES (?,?,?)",
            (nome_arq, datetime.now().isoformat(timespec='seconds'), qtd))
        conn.commit()
    return jsonify({"arquivo": nome_arq, "quantidade": qtd, "contas": len(contas)})


# ---- ARQUIVOS ----------------------------------------------
@app.route('/api/banco/arquivos')
def api_banco_arquivos():
    with closing(banco_conn()) as conn:
        rows = conn.execute("SELECT * FROM arquivos_gerados ORDER BY data_geracao DESC").fetchall()
    out = []
    for r in rows:
        d = dict(r)
        d["existe"] = (ARQUIVOS_GERADOS_DIR / d["nome"]).exists()
        out.append(d)
    return jsonify(out)

@app.route('/api/banco/arquivos/<nome>')
def api_banco_arquivo_dl(nome):
    nome = os.path.basename(nome)
    return send_from_directory(ARQUIVOS_GERADOS_DIR, nome, as_attachment=True)

@app.route('/api/banco/arquivos/<nome>', methods=['DELETE'])
def api_banco_arquivo_del(nome):
    nome = os.path.basename(nome)
    p = ARQUIVOS_GERADOS_DIR / nome
    with closing(banco_conn()) as conn:
        conn.execute("DELETE FROM lancamentos WHERE arquivo=?", (nome,))
        conn.execute("DELETE FROM arquivos_gerados WHERE nome=?", (nome,))
        conn.commit()
    try:
        if p.exists(): p.unlink()
    except Exception: pass
    return jsonify({"message": f"{nome} excluido"})


# ---- SEED ao MAINFRAME -------------------------------------
@app.route('/api/banco/seed-mainframe', methods=['POST'])
def api_banco_seed_mainframe():
    b = request.get_json(force=True, silent=True) or {}
    nome = os.path.basename(b.get("arquivo") or "")
    if not nome:
        return jsonify({"ok": False, "erro": "informe 'arquivo'"}), 400
    caminho = ARQUIVOS_GERADOS_DIR / nome
    if not caminho.exists():
        return jsonify({"ok": False, "erro": f"arquivo nao encontrado: {nome}"}), 404
    base = re.sub(r"[^A-Z0-9]", "", nome.upper().replace(".TXT",""))[:8] or "SEEDLANC"
    dsn_membro = f"{HLQ_ENTRADA}({base})"
    rc, out = run_zowe(["zos-files","upload","file-to-data-set",
                        str(caminho), dsn_membro], timeout=600)
    return jsonify({"ok": rc == 0, "rc": rc, "log": out,
                    "arquivo": str(caminho), "destino": dsn_membro})


# ---- EXPORT TXT --------------------------------------------
@app.route('/api/banco/export/<tipo>')
def api_banco_export(tipo):
    if tipo not in ("clientes","contas","lancamentos"):
        return jsonify({"error": "tipo invalido"}), 400
    with closing(banco_conn()) as conn:
        if tipo == "clientes":
            rows = conn.execute("SELECT * FROM clientes ORDER BY client_id").fetchall()
            content = "\n".join(
                f"{r['client_id']:05d}{r['nome']:<50.50}{r['cpf']}"
                f"{r['data_nasc']}{r['data_cad']}{r['status']}" for r in rows)
        elif tipo == "contas":
            rows = conn.execute("SELECT * FROM contas ORDER BY numero").fetchall()
            content = "\n".join(
                f"{r['agencia']:04d}{r['numero']:08d}{r['client_id']:05d}"
                f"{r['tipo']}{r['status']}{r['data_abertura']}"
                f"{r['saldo_centavos']:013d}{r['saldo_atual_centavos']:013d}"
                f"{r['limite_centavos']:013d}" for r in rows)
        else:
            rows = conn.execute("SELECT * FROM lancamentos ORDER BY id").fetchall()
            content = "\n".join(
                f"{r['agencia']:04d}{r['conta_numero']:08d}{r['data_movimento']}"
                f"{r['tipo']}{r['valor_centavos']:012d}{r['historico']:<20.20}"
                f"{r['canal']:<10.10}{r['lote']:06d}{r['nseq']:06d}{r['status']}"
                for r in rows)
    return Response(content, mimetype="text/plain",
                    headers={"Content-Disposition": f"attachment; filename={tipo}.txt"})


# ============================================================
#   DEMANDAS DO DIA — sorteia N injecoes aleatorias e aplica
# ============================================================
@app.route('/api/demandas/gerar/stream')
def api_demandas_gerar_stream():
    try:
        qtd = int(request.args.get("quantidade", 1))
    except (TypeError, ValueError):
        qtd = 1
    qtd = max(1, min(qtd, 5))   # limite de seguranca
    return sse_response(_gerar_demandas_stream(qtd))


def _gerar_demandas_stream(qtd_pedida):
    injecoes = load_injecoes()
    estado = load_estado()
    ids_ativas = {int(a["Id"]) for a in estado["injecoes_ativas"]}

    candidatas = [
        inj for inj in injecoes
        if int(inj["Id"]) not in ids_ativas
        and membro_permitido(inj["TipoDataset"], inj["Membro"])
    ]

    if not candidatas:
        yield ("line", "Nenhuma injecao disponivel (todas ja estao ativas).")
        yield ("done", {"ok": False, "rc": 0, "aplicadas": []})
        return

    qtd = qtd_pedida
    if qtd > len(candidatas):
        yield ("line", f"Apenas {len(candidatas)} injecao(oes) disponivel(eis) "
                       f"(pedido: {qtd_pedida}).")
        qtd = len(candidatas)

    random.shuffle(candidatas)
    selecionadas = candidatas[:qtd]

    yield ("line", f">>> Gerando {qtd} demanda(s) aleatoria(s) do dia")
    yield ("line", "")

    aplicadas, falhas = [], []
    for i, inj in enumerate(selecionadas, 1):
        sev = (inj.get("SeveridadeTicket") or "").upper()
        yield ("line", f"[{i}/{qtd}] #{inj['Id']} - {inj['Titulo']}")
        yield ("line", f"        Severidade: {sev} | Camada: {inj['CamadaFalha']}")
        yield ("line", f"        Aplicando via Zowe...")

        result, _ = _processar_injecao(int(inj["Id"]), reverter=False)
        if result.get("ok"):
            aplicadas.append(inj)
            yield ("line", f"        OK - ticket EB-{int(inj['Id']):03d} criado em Backlog")
        else:
            falhas.append({"Id": int(inj["Id"]), "erro": result.get("erro", "?")})
            yield ("line", f"        FALHA: {result.get('erro', '?')}")
        yield ("line", "")

    yield ("line", f">>> Resultado: {len(aplicadas)} aplicada(s), {len(falhas)} falha(s)")
    if aplicadas:
        yield ("line", "")
        yield ("line", "Para reverter: aba 'Ativas', cards do 'Catalogo' ou botao na")
        yield ("line", "aba 'Tickets (Jira)' (icone do envelope vermelho).")

    yield ("done", {
        "ok": len(aplicadas) > 0,
        "rc": 0 if not falhas else 1,
        "aplicadas": [{"Id": int(a["Id"]), "Titulo": a["Titulo"]} for a in aplicadas],
        "falhas": falhas,
    })


if __name__ == '__main__':
    print("\n  EBOPS Web Server v5")
    print(f"  Injecoes: {INJECOES_FILE}")
    print(f"  Estado:   {ESTADO_FILE}")
    print(f"  Tickets:  {TICKETS_FILE}")
    print(f"  Zowe:     {ZOWE or '(NAO ENCONTRADO no PATH)'}")
    print(f"  Acesse:   http://localhost:5000\n")
    if not ZOWE:
        print("  AVISO: 'zowe' nao foi encontrado no PATH deste processo.\n")
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)