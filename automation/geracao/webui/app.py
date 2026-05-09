#!/usr/bin/env python3
"""Emunah Bank Lab - Interface Web de Gerenciamento."""
from __future__ import annotations

import random
import re
import sqlite3
import unicodedata
from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

from flask import Flask, Response, g, jsonify, render_template, request, send_file

BASE_DIR = Path(__file__).resolve().parents[3]
DATA_DIR = BASE_DIR / "data" / "entrada"
DB_PATH = BASE_DIR / "data" / "emunah_lab.db"

DEFAULT_CANAIS = ["APP", "ATM", "PIX", "INTERNET", "BATCH", "POS", "TED", "RH"]
DEFAULT_HISTORICOS = [
    "DEPOSITO", "PAGAMENTO BOLETO", "TRANSFERENCIA", "SAQUE",
    "COMPRA DEBITO", "APORTE", "TED RECEBIDA", "PIX ENVIADO",
    "PIX RECEBIDO", "AJUSTE FINANCEIRO",
]
NOMES_SEED = [
    "JOAO SILVA", "MARIA SOUZA", "PEDRO SANTOS", "ANA COSTA", "CARLA MORAES",
    "LUCAS BARBOSA", "BRUNO LIMA", "PAULA ALMEIDA", "RENATA ARAUJO",
    "FABIO PEREIRA", "MARTA FERNANDES", "GUSTAVO ROCHA", "JULIANA TEIXEIRA",
    "THIAGO RIBEIRO", "FERNANDA MELO", "DANIEL OLIVEIRA", "AMANDA MARTINS",
    "RODRIGO NUNES", "CAMILA GOMES", "RAFAEL DUARTE",
]

app = Flask(__name__)


# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

def get_db() -> sqlite3.Connection:
    if "db" not in g:
        g.db = sqlite3.connect(str(DB_PATH))
        g.db.row_factory = sqlite3.Row
        g.db.execute("PRAGMA foreign_keys = ON")
    return g.db


@app.teardown_appcontext
def close_db(exc=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_db() -> None:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(DB_PATH))
    conn.execute("PRAGMA foreign_keys = ON")
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS clientes (
            client_id   INTEGER PRIMARY KEY,
            nome        TEXT NOT NULL,
            cpf         TEXT UNIQUE NOT NULL,
            data_nasc   TEXT NOT NULL,
            status      TEXT NOT NULL DEFAULT 'A',
            data_cad    TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS contas (
            numero          INTEGER PRIMARY KEY,
            agencia         INTEGER NOT NULL DEFAULT 1,
            client_id       INTEGER NOT NULL,
            tipo            TEXT NOT NULL,
            status          TEXT NOT NULL DEFAULT 'A',
            data_abertura   TEXT NOT NULL,
            saldo_centavos  INTEGER NOT NULL DEFAULT 0,
            limite_centavos INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (client_id) REFERENCES clientes(client_id)
        );
        CREATE TABLE IF NOT EXISTS lancamentos (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            agencia         INTEGER NOT NULL,
            conta_numero    INTEGER NOT NULL,
            data_movimento  TEXT NOT NULL,
            tipo            TEXT NOT NULL,
            valor_centavos  INTEGER NOT NULL,
            historico       TEXT NOT NULL,
            canal           TEXT NOT NULL,
            lote            INTEGER NOT NULL,
            nseq            INTEGER NOT NULL,
            status          TEXT NOT NULL DEFAULT 'P',
            arquivo         TEXT,
            created_at      TEXT NOT NULL DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS arquivos (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            nome            TEXT UNIQUE NOT NULL,
            data_geracao    TEXT NOT NULL,
            quantidade      INTEGER NOT NULL
        );
    """)
    conn.commit()
    conn.close()


# ---------------------------------------------------------------------------
# Layout serialization
# ---------------------------------------------------------------------------

def serialize_cliente(r: dict) -> str:
    rec = (
        f"{r['client_id']:05d}"
        f"{r['nome'][:30].ljust(30)}"
        f"{r['cpf']}"
        f"{r['data_nasc']}"
        f"{r['status'][:1]}"
        f"{r['data_cad']}"
    )
    return rec.ljust(80)


def serialize_conta(r: dict) -> str:
    rec = (
        f"{r['agencia']:04d}"
        f"{r['numero']:08d}"
        f"{r['client_id']:05d}"
        f"{r['tipo'][:1]}"
        f"{r['status'][:1]}"
        f"{r['data_abertura']}"
        f" {r['saldo_centavos']:012d}"
        f" {r['limite_centavos']:010d}"
    )
    return rec.ljust(100)


def serialize_lancamento(r: dict) -> str:
    rec = (
        f"{r['agencia']:04d}"
        f"{r['conta_numero']:08d}"
        f"{r['data_movimento']}"
        f"{r['tipo'][:1]}"
        f"{r['valor_centavos']:013d}"
        f"{r['historico'].upper()[:30].ljust(30)}"
        f"{r['canal'].upper()[:10].ljust(10)}"
        f"{r['lote']:06d}"
        f"{r['nseq']:06d}"
        f"{r['status'][:1].upper()}"
        f"{' ' * 33}"
    )
    if len(rec) != 120:
        raise ValueError(f"Tamanho de registro invalido: {len(rec)}")
    return rec


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def normalize_text(value: str) -> str:
    nfkd = unicodedata.normalize("NFKD", value)
    return "".join(ch for ch in nfkd if not unicodedata.combining(ch))


def valida_cpf(cpf: str) -> str:
    digits = re.sub(r"\D", "", cpf)
    if len(digits) != 11:
        raise ValueError("CPF deve conter 11 digitos.")
    return digits


def valida_data(value: str) -> str:
    try:
        datetime.strptime(value, "%Y%m%d")
    except ValueError:
        raise ValueError(f"Data invalida (use AAAAMMDD): {value}")
    return value


def compute_saldo_atual(conn, conta_numero: int, saldo_base: int) -> int:
    rows = conn.execute(
        "SELECT tipo, COALESCE(SUM(valor_centavos), 0) as total "
        "FROM lancamentos WHERE conta_numero=? GROUP BY tipo",
        (conta_numero,),
    ).fetchall()
    balance = saldo_base
    for row in rows:
        if row["tipo"] == "C":
            balance += row["total"]
        else:
            balance -= row["total"]
    return balance


def next_arquivo_numero(conn) -> int:
    row = conn.execute("SELECT COALESCE(MAX(id), 0) as m FROM arquivos").fetchone()
    return (row["m"] or 0) + 1


def gerar_cpf_aleatorio(rng: random.Random, existentes: set) -> str:
    while True:
        base = [rng.randint(0, 9) for _ in range(9)]

        def dv(parcial: list) -> int:
            soma = sum(d * w for d, w in zip(parcial, range(len(parcial) + 1, 1, -1)))
            resto = (soma * 10) % 11
            return 0 if resto == 10 else resto

        d1 = dv(base)
        d2 = dv(base + [d1])
        cpf = "".join(map(str, base + [d1, d2]))
        if cpf not in existentes:
            return cpf


def fmt_brl(centavos: int) -> str:
    return f"R$ {centavos / 100:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")


# ---------------------------------------------------------------------------
# API: Clientes
# ---------------------------------------------------------------------------

@app.route("/api/clientes", methods=["GET"])
def list_clientes():
    db = get_db()
    rows = db.execute("SELECT * FROM clientes ORDER BY client_id").fetchall()
    result = []
    for r in rows:
        d = dict(r)
        cnt = db.execute(
            "SELECT COUNT(*) as c FROM contas WHERE client_id=?", (d["client_id"],)
        ).fetchone()["c"]
        d["qtd_contas"] = cnt
        result.append(d)
    return jsonify(result)


@app.route("/api/clientes", methods=["POST"])
def create_cliente():
    db = get_db()
    data = request.json or {}
    try:
        nome = normalize_text(data.get("nome", "").strip()).upper()
        if not nome:
            raise ValueError("Nome e obrigatorio.")
        cpf = valida_cpf(data.get("cpf", ""))
        data_nasc = valida_data(data.get("data_nasc", ""))

        if db.execute("SELECT 1 FROM clientes WHERE cpf=?", (cpf,)).fetchone():
            raise ValueError(f"CPF {cpf} ja cadastrado.")

        max_id = db.execute("SELECT COALESCE(MAX(client_id), 0) as m FROM clientes").fetchone()["m"]
        client_id = max_id + 1
        data_cad = datetime.now().strftime("%Y%m%d")
        db.execute(
            "INSERT INTO clientes VALUES (?,?,?,?,?,?)",
            (client_id, nome, cpf, data_nasc, "A", data_cad),
        )
        db.commit()
        return jsonify({"client_id": client_id, "nome": nome}), 201
    except (ValueError, KeyError) as exc:
        return jsonify({"error": str(exc)}), 400


@app.route("/api/clientes/seed", methods=["POST"])
def seed_clientes():
    db = get_db()
    data = request.json or {}
    qtd = int(data.get("quantidade", 10))
    contas_por_cli = int(data.get("contas_por_cliente", 2))
    seed = data.get("seed")
    rng = random.Random(int(seed) if seed is not None else None)

    existentes = {r["cpf"] for r in db.execute("SELECT cpf FROM clientes").fetchall()}
    max_id = db.execute("SELECT COALESCE(MAX(client_id), 0) as m FROM clientes").fetchone()["m"]
    max_conta = db.execute("SELECT COALESCE(MAX(numero), 0) as m FROM contas").fetchone()["m"]
    today = datetime.now().strftime("%Y%m%d")
    cc = 0
    ca = 0
    for i in range(qtd):
        nome = NOMES_SEED[i % len(NOMES_SEED)] if i < len(NOMES_SEED) else f"CLIENTE SINTETICO {i + 1:04d}"
        cpf = gerar_cpf_aleatorio(rng, existentes)
        existentes.add(cpf)
        nasc = f"{rng.randint(1960, 2005)}{rng.randint(1, 12):02d}{rng.randint(1, 28):02d}"
        max_id += 1
        db.execute("INSERT INTO clientes VALUES (?,?,?,?,?,?)", (max_id, nome, cpf, nasc, "A", today))
        cc += 1
        for j in range(contas_por_cli):
            tipo = "C" if j == 0 else ("P" if j == 1 else rng.choice(["C", "P"]))
            max_conta += 1
            saldo = rng.randint(50_000, 500_000)
            db.execute(
                "INSERT INTO contas VALUES (?,?,?,?,?,?,?,?)",
                (max_conta, 1, max_id, tipo, "A", today, saldo, 500_000),
            )
            ca += 1
    db.commit()
    return jsonify({"clientes": cc, "contas": ca})


@app.route("/api/clientes/<int:client_id>", methods=["DELETE"])
def delete_cliente(client_id):
    db = get_db()
    if not db.execute("SELECT 1 FROM clientes WHERE client_id=?", (client_id,)).fetchone():
        return jsonify({"error": "Cliente nao encontrado."}), 404
    nums = [
        r["numero"]
        for r in db.execute("SELECT numero FROM contas WHERE client_id=?", (client_id,)).fetchall()
    ]
    for num in nums:
        db.execute("DELETE FROM lancamentos WHERE conta_numero=?", (num,))
    db.execute("DELETE FROM contas WHERE client_id=?", (client_id,))
    db.execute("DELETE FROM clientes WHERE client_id=?", (client_id,))
    db.commit()
    return jsonify({"message": "Cliente removido."})


# ---------------------------------------------------------------------------
# API: Contas
# ---------------------------------------------------------------------------

@app.route("/api/contas", methods=["GET"])
def list_contas():
    db = get_db()
    client_id = request.args.get("client_id")
    if client_id:
        rows = db.execute(
            "SELECT c.*, cl.nome as cliente_nome FROM contas c "
            "JOIN clientes cl ON c.client_id=cl.client_id WHERE c.client_id=? ORDER BY c.numero",
            (client_id,),
        ).fetchall()
    else:
        rows = db.execute(
            "SELECT c.*, cl.nome as cliente_nome FROM contas c "
            "JOIN clientes cl ON c.client_id=cl.client_id ORDER BY c.numero"
        ).fetchall()
    result = []
    for r in rows:
        d = dict(r)
        d["saldo_atual_centavos"] = compute_saldo_atual(db, d["numero"], d["saldo_centavos"])
        result.append(d)
    return jsonify(result)


@app.route("/api/contas", methods=["POST"])
def create_conta():
    db = get_db()
    data = request.json or {}
    try:
        client_id = int(data.get("client_id", 0))
        tipo = str(data.get("tipo", "C")).upper()
        agencia = int(data.get("agencia", 1))
        saldo_str = str(data.get("saldo", "0")).replace(",", ".")
        limite_str = str(data.get("limite", "0")).replace(",", ".")

        if tipo not in {"C", "P"}:
            raise ValueError("Tipo invalido. Use C (Corrente) ou P (Poupanca).")
        if not db.execute("SELECT 1 FROM clientes WHERE client_id=?", (client_id,)).fetchone():
            raise ValueError(f"Cliente {client_id} nao encontrado.")

        saldo_c = int(round(float(saldo_str) * 100))
        limite_c = int(round(float(limite_str) * 100))
        max_num = db.execute("SELECT COALESCE(MAX(numero), 0) as m FROM contas").fetchone()["m"]
        numero = max_num + 1
        today = datetime.now().strftime("%Y%m%d")
        db.execute(
            "INSERT INTO contas VALUES (?,?,?,?,?,?,?,?)",
            (numero, agencia, client_id, tipo, "A", today, saldo_c, limite_c),
        )
        db.commit()
        return jsonify({"numero": numero}), 201
    except (ValueError, KeyError) as exc:
        return jsonify({"error": str(exc)}), 400


@app.route("/api/contas/<int:numero>", methods=["DELETE"])
def delete_conta(numero):
    db = get_db()
    if not db.execute("SELECT 1 FROM contas WHERE numero=?", (numero,)).fetchone():
        return jsonify({"error": "Conta nao encontrada."}), 404
    db.execute("DELETE FROM lancamentos WHERE conta_numero=?", (numero,))
    db.execute("DELETE FROM contas WHERE numero=?", (numero,))
    db.commit()
    return jsonify({"message": "Conta removida."})


# ---------------------------------------------------------------------------
# API: Lancamentos
# ---------------------------------------------------------------------------

@app.route("/api/lancamentos", methods=["GET"])
def list_lancamentos():
    db = get_db()
    conta = request.args.get("conta")
    arquivo = request.args.get("arquivo")
    limit = min(int(request.args.get("limit", 200)), 1000)

    sql = "SELECT * FROM lancamentos WHERE 1=1"
    params: list = []
    if conta:
        sql += " AND conta_numero=?"
        params.append(conta)
    if arquivo:
        sql += " AND arquivo=?"
        params.append(arquivo)
    sql += " ORDER BY id DESC LIMIT ?"
    params.append(limit)
    rows = db.execute(sql, params).fetchall()
    return jsonify([dict(r) for r in rows])


@app.route("/api/lancamentos/<int:lid>", methods=["DELETE"])
def delete_lancamento(lid):
    db = get_db()
    if not db.execute("SELECT 1 FROM lancamentos WHERE id=?", (lid,)).fetchone():
        return jsonify({"error": "Lancamento nao encontrado."}), 404
    db.execute("DELETE FROM lancamentos WHERE id=?", (lid,))
    db.commit()
    return jsonify({"message": "Lancamento removido."})


@app.route("/api/lancamentos/gerar", methods=["POST"])
def gerar_lancamentos():
    db = get_db()
    data = request.json or {}
    try:
        quantidade = int(data.get("quantidade", 10))
        if quantidade <= 0:
            raise ValueError("quantidade deve ser > 0.")

        data_mov = valida_data(data.get("data") or datetime.now().strftime("%Y%m%d"))
        valor_min = Decimal(str(data.get("valor_min", "10.00")))
        valor_max = Decimal(str(data.get("valor_max", "5000.00")))
        status_lanc = str(data.get("status", "P")).upper()[:1]
        lote_ini = int(data.get("lote_inicial", 1))
        seed = data.get("seed")
        tipos = [t.upper() for t in (data.get("tipos") or ["C", "D"])]
        canais = [c.upper() for c in (data.get("canais") or DEFAULT_CANAIS)]
        historicos = list(data.get("historicos") or DEFAULT_HISTORICOS)
        filtros = [str(f).strip() for f in (data.get("clientes") or [])]

        if any(t not in {"C", "D"} for t in tipos):
            raise ValueError("tipos permitidos: C e D.")

        min_c = int((valor_min * 100).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
        max_c = int((valor_max * 100).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
        if min_c > max_c:
            raise ValueError("valor_min nao pode ser maior que valor_max.")

        if filtros:
            normalized = [f.casefold() for f in filtros]
            all_rows = db.execute(
                "SELECT c.*, cl.nome FROM contas c "
                "JOIN clientes cl ON c.client_id=cl.client_id WHERE c.status='A'"
            ).fetchall()
            contas = [
                dict(r) for r in all_rows
                if any(
                    f == str(r["client_id"]) or f in r["nome"].casefold()
                    for f in normalized
                )
            ]
        else:
            contas = [dict(r) for r in db.execute("SELECT * FROM contas WHERE status='A'").fetchall()]

        if not contas:
            raise ValueError("Nenhuma conta elegivel encontrada.")

        rng = random.Random(int(seed) if seed is not None else None)
        num_arq = next_arquivo_numero(db)
        nome_arq = f"lancamentos-d{num_arq}.txt"

        regs_db: list[dict] = []
        regs_txt: list[str] = []
        for indice in range(quantidade):
            conta = rng.choice(contas)
            rec = {
                "agencia": conta["agencia"],
                "conta_numero": conta["numero"],
                "data_movimento": data_mov,
                "tipo": rng.choice(tipos),
                "valor_centavos": rng.randint(min_c, max_c),
                "historico": rng.choice(historicos),
                "canal": rng.choice(canais),
                "lote": lote_ini + (indice // 999999),
                "nseq": (indice % 999999) + 1,
                "status": status_lanc,
                "arquivo": nome_arq,
            }
            regs_db.append(rec)
            regs_txt.append(serialize_lancamento(rec))

        DATA_DIR.mkdir(parents=True, exist_ok=True)
        with (DATA_DIR / nome_arq).open("w", encoding="utf-8", newline="\n") as fh:
            for linha in regs_txt:
                fh.write(linha + "\n")

        now = datetime.now().isoformat()
        for rec in regs_db:
            db.execute(
                "INSERT INTO lancamentos "
                "(agencia,conta_numero,data_movimento,tipo,valor_centavos,"
                "historico,canal,lote,nseq,status,arquivo,created_at) "
                "VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
                (
                    rec["agencia"], rec["conta_numero"], rec["data_movimento"],
                    rec["tipo"], rec["valor_centavos"], rec["historico"],
                    rec["canal"], rec["lote"], rec["nseq"],
                    rec["status"], rec["arquivo"], now,
                ),
            )
        db.execute(
            "INSERT INTO arquivos (nome,data_geracao,quantidade) VALUES (?,?,?)",
            (nome_arq, now, quantidade),
        )
        db.commit()
        return jsonify({"arquivo": nome_arq, "quantidade": quantidade, "contas": len(contas)}), 201
    except (ValueError, KeyError) as exc:
        return jsonify({"error": str(exc)}), 400


# ---------------------------------------------------------------------------
# API: Arquivos
# ---------------------------------------------------------------------------

@app.route("/api/arquivos", methods=["GET"])
def list_arquivos():
    db = get_db()
    rows = db.execute("SELECT * FROM arquivos ORDER BY id DESC").fetchall()
    result = []
    for r in rows:
        d = dict(r)
        d["existe"] = (DATA_DIR / d["nome"]).exists()
        result.append(d)
    return jsonify(result)


@app.route("/api/arquivos/<nome>", methods=["GET"])
def download_arquivo(nome):
    if not re.match(r"^lancamentos-d\d+\.txt$", nome):
        return jsonify({"error": "Nome invalido."}), 400
    path = DATA_DIR / nome
    if not path.exists():
        return jsonify({"error": "Arquivo nao encontrado."}), 404
    return send_file(str(path), as_attachment=True, download_name=nome)


@app.route("/api/arquivos/<nome>", methods=["DELETE"])
def delete_arquivo(nome):
    if not re.match(r"^lancamentos-d\d+\.txt$", nome):
        return jsonify({"error": "Nome invalido."}), 400
    db = get_db()
    path = DATA_DIR / nome
    if path.exists():
        path.unlink()
    db.execute("DELETE FROM lancamentos WHERE arquivo=?", (nome,))
    db.execute("DELETE FROM arquivos WHERE nome=?", (nome,))
    db.commit()
    return jsonify({"message": "Arquivo removido."})


# ---------------------------------------------------------------------------
# API: Exportar layouts fixos
# ---------------------------------------------------------------------------

@app.route("/api/export/clientes")
def export_clientes():
    db = get_db()
    rows = db.execute("SELECT * FROM clientes ORDER BY client_id").fetchall()
    content = "".join(serialize_cliente(dict(r)) + "\n" for r in rows)
    return Response(content, mimetype="text/plain",
                    headers={"Content-Disposition": "attachment; filename=clientes.txt"})


@app.route("/api/export/contas")
def export_contas():
    db = get_db()
    rows = db.execute("SELECT * FROM contas ORDER BY numero").fetchall()
    content = "".join(serialize_conta(dict(r)) + "\n" for r in rows)
    return Response(content, mimetype="text/plain",
                    headers={"Content-Disposition": "attachment; filename=contas.txt"})


# ---------------------------------------------------------------------------
# API: Stats
# ---------------------------------------------------------------------------

@app.route("/api/stats")
def stats():
    db = get_db()
    clientes = db.execute("SELECT COUNT(*) as c FROM clientes").fetchone()["c"]
    contas = db.execute("SELECT COUNT(*) as c FROM contas WHERE status='A'").fetchone()["c"]
    lancamentos = db.execute("SELECT COUNT(*) as c FROM lancamentos").fetchone()["c"]
    arquivos = db.execute("SELECT COUNT(*) as c FROM arquivos").fetchone()["c"]
    return jsonify({"clientes": clientes, "contas": contas, "lancamentos": lancamentos, "arquivos": arquivos})


# ---------------------------------------------------------------------------
# Frontend
# ---------------------------------------------------------------------------

@app.route("/")
def index():
    return render_template("index.html")


if __name__ == "__main__":
    init_db()
    print(f"Banco de dados: {DB_PATH}")
    print(f"Arquivos de saida: {DATA_DIR}")
    app.run(debug=True, port=5001, host="0.0.0.0")
