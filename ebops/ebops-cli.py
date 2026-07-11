#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ebops-cli — backend CLI simplificado para desenvolver/testar a cadeia EOD.

Fluxo "dia":
  1) EBRESET                                    (reset do ciclo)
  2) Upload de lancamentos_dN.txt -> STAGE      (massa do dia)
  3) Injecao Ghost (download -> mutar -> upload)
  4) EBDEPLOY                                   (compila programas)
  5) EBJCHAIN                                   (executa cadeia EOD)

Uso:
  python ebops-cli.py menu
  python ebops-cli.py dia <N> [--inj INJ-XXX] [--manual] [--auto-massa]
  python ebops-cli.py reset
  python ebops-cli.py upload-massa <N> [--gerar]
  python ebops-cli.py compile
  python ebops-cli.py chain
  python ebops-cli.py inject <INJ-XXX>
  python ebops-cli.py revert
  python ebops-cli.py wait <JOBID> [--label NOME]
  python ebops-cli.py status
  python ebops-cli.py catalogo [INJ-XXX]
  python ebops-cli.py logs

Variaveis de ambiente:
  EBOPS_HLQ              HLQ remoto (default: ELIEL.EMUNAH)
  EBOPS_POLL_INTERVAL    segundos entre polls (default: 5)
  EBOPS_MAX_WAIT         timeout maximo por job em segundos (default: 1800)
"""

import argparse
import json
import os
import random
import re
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ebops import (
    MUTATIONS, INJ_MAP, DS_MAP, HLQ,
    _zowe_exe, _zowe_check, _zowe_upload_text, _zowe_download,
    _ds_member_for, _resolve_file, _rf, find_project, _root,
)

# ============================================================
# CONFIG
# ============================================================
POLL_INTERVAL = int(os.environ.get("EBOPS_POLL_INTERVAL", "5"))
MAX_WAIT = int(os.environ.get("EBOPS_MAX_WAIT", "1800"))

DS_EBRESET = f"{HLQ}.DEV.JCL(EBRESET)"
DS_EBDEPLOY = f"{HLQ}.DEV.JCL(EBDEPLOY)"
DS_EBJCHAIN = f"{HLQ}.DEV.JCL(EBJCHAIN)"
DS_STAGE_ENTRADA = f"{HLQ}.STAGE.ENTRADA.SEQ"

STATE_FILENAME = "ebops2_state.json"

# ============================================================
# CATALOGO INICIAL — 5 INJECOES (extensivel via INJ_MAP do ebops.py)
# ============================================================
SIMPLE_CATALOG = [
    {"id": "INJ-001", "categoria": "cobol",    "dificuldade": "junior"},
    {"id": "INJ-005", "categoria": "cobol",    "dificuldade": "pleno" },
    {"id": "INJ-007", "categoria": "jcl",      "dificuldade": "junior"},
    {"id": "INJ-015", "categoria": "copybook", "dificuldade": "pleno" },
    {"id": "INJ-022", "categoria": "jcl",      "dificuldade": "junior"},
]
SIMPLE_IDS = [i["id"] for i in SIMPLE_CATALOG]

# ============================================================
# CORES
# ============================================================
class C:
    R  = "\033[0m";  B  = "\033[1m"; D  = "\033[2m"
    GR = "\033[32m"; RD = "\033[31m"; YL = "\033[33m"
    BL = "\033[34m"; CY = "\033[36m"; MG = "\033[35m"

# ============================================================
# LOG
# ============================================================
_LOG_FH = None

def open_log(proj, label):
    global _LOG_FH
    log_dir = Path(_root(proj)) / ".ebops" / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    path = log_dir / f"{label}-{ts}.log"
    _LOG_FH = open(path, "w", encoding="utf-8")
    return path

def close_log():
    global _LOG_FH
    if _LOG_FH:
        _LOG_FH.close()
        _LOG_FH = None

_ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")

def _to_log_file(s, end="\n"):
    if _LOG_FH:
        clean = _ANSI_RE.sub("", s)
        _LOG_FH.write(clean + (end if end != "\r" else "\n"))
        _LOG_FH.flush()

def log(msg="", color=None, end="\n"):
    if color:
        sys.stdout.write(f"{color}{msg}{C.R}{end}")
    else:
        sys.stdout.write(f"{msg}{end}")
    sys.stdout.flush()
    _to_log_file(msg, end)

def live(msg):
    """Atualiza linha em-place no terminal, escreve linha cheia no log."""
    sys.stdout.write(f"\r{msg}    ")
    sys.stdout.flush()
    _to_log_file(msg, end="\n")

# ============================================================
# ESTADO
# ============================================================
def state_path(proj):
    return os.path.join(proj, STATE_FILENAME)

def load_state(proj):
    default = {
        "current_day": 0,
        "current_injection": None,
        "snapshot_dir": None,
        "snapshot_meta": [],
        "operacoes": [],
        "history": [],
    }
    p = state_path(proj)
    if os.path.isfile(p):
        try:
            with open(p, encoding="utf-8") as f:
                data = json.load(f)
            for k, v in default.items():
                data.setdefault(k, v)
            return data
        except Exception:
            pass
    return default

def save_state(proj, state):
    with open(state_path(proj), "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)

# ============================================================
# ZOWE WRAPPERS (alem dos existentes em ebops.py)
# ============================================================
def zowe_check_or_die():
    if not _zowe_check():
        log("Zowe CLI nao encontrado no PATH ou 'zowe --version' falhou.", C.RD)
        log("Verifique no terminal: zowe --version", C.D)
        sys.exit(1)

def zowe_submit_jcl(ds_member):
    """Submete JCL e retorna (jobid, erro). Nao espera."""
    exe = _zowe_exe()
    if not exe:
        return None, "Zowe nao encontrado"
    r = subprocess.run(
        [exe, "jobs", "submit", "data-set", ds_member, "--rfj"],
        capture_output=True, text=True, timeout=60,
    )
    if r.returncode != 0:
        return None, (r.stderr or r.stdout).strip()
    try:
        data = json.loads(r.stdout)
        return data.get("data", {}).get("jobid"), None
    except Exception as e:
        return None, str(e)

def zowe_job_status(jobid):
    exe = _zowe_exe()
    if not exe: return None
    r = subprocess.run(
        [exe, "jobs", "view", "job-status-by-jobid", jobid, "--rfj"],
        capture_output=True, text=True, timeout=30,
    )
    if r.returncode != 0:
        return None
    try:
        return json.loads(r.stdout).get("data", {})
    except Exception:
        return None

def zowe_list_spool(jobid):
    exe = _zowe_exe()
    if not exe: return []
    r = subprocess.run(
        [exe, "jobs", "list", "spool-files-by-jobid", jobid, "--rfj"],
        capture_output=True, text=True, timeout=30,
    )
    if r.returncode != 0:
        return []
    try:
        return json.loads(r.stdout).get("data", []) or []
    except Exception:
        return []

def zowe_view_spool(jobid, file_id):
    exe = _zowe_exe()
    if not exe: return ""
    r = subprocess.run(
        [exe, "jobs", "view", "spool-file-by-id", jobid, str(file_id)],
        capture_output=True, text=True, timeout=60,
    )
    return r.stdout if r.returncode == 0 else ""

def zowe_upload_file(local_path, ds, binary=False):
    exe = _zowe_exe()
    if not exe:
        return False, "Zowe nao encontrado"
    cmd = [exe, "files", "upload", "file-to-data-set", str(local_path), ds]
    if binary:
        cmd.append("--binary")
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    return r.returncode == 0, (r.stderr or r.stdout).strip()

# ============================================================
# RC PARSING + JOB WATCHER
# ============================================================
def parse_rc(retcode_str):
    """'CC 0008' -> 8 ; 'JCL ERROR' / 'ABEND ...' -> -1"""
    if not retcode_str:
        return -1
    m = re.search(r"CC\s+(\d+)", retcode_str)
    if m:
        return int(m.group(1))
    return -1

def wait_for_job(jobid, label):
    """Faz poll ate status=OUTPUT, retorna (rc_int, retcode_str)."""
    start = time.time()
    last_step = "-"
    last_count = 0
    while True:
        elapsed = int(time.time() - start)
        if elapsed > MAX_WAIT:
            log("")
            log(f"  TIMEOUT apos {MAX_WAIT}s — job {jobid} ainda no host.", C.RD)
            return -1, "TIMEOUT"
        st = zowe_job_status(jobid)
        if not st:
            live(f"  [{elapsed:4d}s] {label} {jobid} (sem resposta do Zowe)")
            time.sleep(POLL_INTERVAL); continue
        status = st.get("status", "?")
        retcode = st.get("retcode") or ""
        spool = zowe_list_spool(jobid)
        if spool and len(spool) >= last_count:
            last_count = len(spool)
            for sp in reversed(spool):
                step = sp.get("stepname") or ""
                if step:
                    last_step = step; break
        live(f"  [{elapsed:4d}s] {label:8} {jobid} status={status:7} step={last_step:8} {retcode}")
        if status == "OUTPUT":
            log("")  # quebra linha do live
            return parse_rc(retcode), retcode
        time.sleep(POLL_INTERVAL)

# ============================================================
# GERADOR DE MASSA
# ============================================================
def generate_massa(proj, day, quantidade=50):
    gen = Path(_root(proj)) / "automation" / "geracao" / "gerar_lancamentos.py"
    out = Path(_root(proj)) / "data" / "entrada" / f"lancamentos_d{day}.txt"
    out.parent.mkdir(parents=True, exist_ok=True)
    if not gen.exists():
        log(f"  Gerador nao encontrado: {gen}", C.RD); return False
    log(f"  Gerando {out.name} (quantidade={quantidade}, seed={day})...", C.D)
    r = subprocess.run(
        [sys.executable, str(gen),
         "--quantidade", str(quantidade),
         "--output", str(out),
         "--seed", str(day)],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        log(f"  Geracao falhou:\n{r.stderr.strip() or r.stdout.strip()}", C.RD)
        return False
    log(f"  ✓ Massa gerada: {out.name}", C.GR)
    return True

# ============================================================
# FASES
# ============================================================
def confirm(msg, manual):
    if not manual: return True
    return input(f"  {C.B}{msg}{C.R} (s/N): ").strip().lower() == "s"

def phase_reset(proj, manual=False):
    log(f"\n{C.B}━━━ FASE 1/5 ━━━ Reset do ambiente (EBRESET){C.R}", C.GR)
    if not confirm("Confirmar EBRESET?", manual):
        log("  Reset pulado.", C.YL); return True
    log(f"  Submetendo {DS_EBRESET}...", C.D)
    jobid, err = zowe_submit_jcl(DS_EBRESET)
    if not jobid:
        log(f"  Falha ao submeter: {err}", C.RD); return False
    log(f"  JobID: {C.CY}{jobid}{C.R}")
    rc, retcode = wait_for_job(jobid, "EBRESET")
    if rc < 0 or rc > 4:
        log(f"  ✗ EBRESET FALHOU: {retcode}", C.RD); return False
    log(f"  ✓ EBRESET OK ({retcode})", C.GR)
    return True

def phase_upload_massa(proj, day, manual=False, auto_gen=False):
    log(f"\n{C.B}━━━ FASE 2/5 ━━━ Upload massa do dia {day}{C.R}", C.GR)
    massa = Path(_root(proj)) / "data" / "entrada" / f"lancamentos_d{day}.txt"
    if not massa.exists():
        log(f"  Arquivo nao encontrado: {massa}", C.YL)
        if auto_gen or (input(f"  Gerar agora? (s/N): ").strip().lower() == "s"):
            if not generate_massa(proj, day):
                return False
        else:
            log("  Upload abortado.", C.YL); return False
    if not confirm(f"Confirmar upload de {massa.name} -> {DS_STAGE_ENTRADA}?", manual):
        log("  Upload pulado.", C.YL); return True
    log(f"  Upload {massa.name} -> {DS_STAGE_ENTRADA}...", C.D)
    ok, msg = zowe_upload_file(massa, DS_STAGE_ENTRADA)
    if not ok:
        head = msg.splitlines()[0] if msg else ""
        log(f"  ✗ Falha no upload: {head}", C.RD); return False
    log(f"  ✓ Upload concluido", C.GR)
    return True

def phase_inject(proj, state, inj_id, manual=False):
    log(f"\n{C.B}━━━ FASE 3/5 ━━━ Injecao ({inj_id}){C.R}", C.GR)
    inj = INJ_MAP.get(inj_id)
    if not inj:
        log(f"  Injecao {inj_id} nao existe em INJ_MAP.", C.RD); return False
    log(f"  {inj.get('t','')}", C.YL)
    log(f"  cat={inj.get('cat','-')} dif={inj.get('dif','-')}", C.D)
    fn = MUTATIONS.get(inj_id)
    if not fn:
        log(f"  Mutacao {inj_id} nao implementada.", C.RD); return False
    if not confirm("Confirmar injecao?", manual):
        log("  Injecao pulada.", C.YL); return True

    try:
        mutated = fn(proj)
    except Exception as e:
        log(f"  Erro na mutacao: {e}", C.RD); return False

    snap_dir = Path(_root(proj)) / ".ebops" / "snapshots" / inj_id
    snap_dir.mkdir(parents=True, exist_ok=True)

    log(f"  Backup do remoto:", C.D)
    snapshot_meta = []
    for filename in mutated.keys():
        ds = _ds_member_for(filename)
        snap_path = snap_dir / filename
        ok, msg = _zowe_download(ds, str(snap_path))
        if ok:
            log(f"    ✓ {ds}", C.GR)
            snapshot_meta.append({"file": filename, "ds": ds,
                                  "backup_path": str(snap_path), "had_backup": True})
        else:
            head = msg.splitlines()[0] if msg else ""
            log(f"    ! {ds} (sem backup: {head})", C.YL)
            snapshot_meta.append({"file": filename, "ds": ds,
                                  "backup_path": None, "had_backup": False})

    log(f"  Aplicacao:", C.D)
    aplicados = []
    for filename, content in mutated.items():
        ds = _ds_member_for(filename)
        if content is None:
            log(f"    ! DELETE remoto nao suportado neste fluxo ({ds})", C.YL)
            continue
        ok, msg = _zowe_upload_text(content, ds)
        if ok:
            log(f"    ✓ UPLOAD {ds}", C.GR)
            aplicados.append({"file": filename, "ds": ds, "action": "UPLOAD"})
        else:
            head = msg.splitlines()[0] if msg else ""
            log(f"    ✗ UPLOAD {ds} — {head}", C.RD)
            return False

    state["current_injection"] = inj_id
    state["snapshot_dir"] = str(snap_dir.relative_to(Path(_root(proj))))
    state["snapshot_meta"] = snapshot_meta
    state["operacoes"] = aplicados
    save_state(proj, state)

    log(f"  ✓ Injecao aplicada", C.GR)
    return True

def phase_compile(proj, manual=False):
    log(f"\n{C.B}━━━ FASE 4/5 ━━━ Compilacao (EBDEPLOY){C.R}", C.GR)
    if not confirm("Confirmar EBDEPLOY?", manual):
        log("  Compile pulado.", C.YL); return True
    log(f"  Submetendo {DS_EBDEPLOY}...", C.D)
    jobid, err = zowe_submit_jcl(DS_EBDEPLOY)
    if not jobid:
        log(f"  Falha ao submeter: {err}", C.RD); return False
    log(f"  JobID: {C.CY}{jobid}{C.R}")
    rc, retcode = wait_for_job(jobid, "EBDEPLOY")
    if rc < 0 or rc > 4:
        log(f"  ✗ EBDEPLOY FALHOU: {retcode}", C.RD); return False
    log(f"  ✓ EBDEPLOY OK ({retcode})", C.GR)
    return True

def phase_chain(proj, manual=False):
    log(f"\n{C.B}━━━ FASE 5/5 ━━━ Cadeia batch (EBJCHAIN){C.R}", C.GR)
    if not confirm("Confirmar EBJCHAIN?", manual):
        log("  Chain pulado.", C.YL); return None, None
    log(f"  Submetendo {DS_EBJCHAIN}...", C.D)
    jobid, err = zowe_submit_jcl(DS_EBJCHAIN)
    if not jobid:
        log(f"  Falha ao submeter: {err}", C.RD); return None, None
    log(f"  JobID: {C.CY}{jobid}{C.R}")
    rc, retcode = wait_for_job(jobid, "EBJCHAIN")
    if rc < 0:
        log(f"  ✗ EBJCHAIN status anomalo: {retcode}", C.RD)
    elif rc > 4:
        log(f"  ✗ EBJCHAIN FALHOU: RC={rc} ({retcode})", C.RD)
    else:
        log(f"  ✓ EBJCHAIN OK ({retcode})", C.GR)
    return jobid, rc

# ============================================================
# COMANDO: dia (orquestra as 5 fases)
# ============================================================
def cmd_dia(proj, day, inj_id=None, manual=False, auto_massa=False):
    state = load_state(proj)
    log_path = open_log(proj, f"dia-{day:03d}")
    try:
        log("")
        log(f"{C.B}╔══════════════════════════════════════════════════════════════╗{C.R}", C.GR)
        title = f"║  EBOPS-CLI — DIA #{day:03d}"
        log(f"{C.B}{title}{' '*(64-len(title)-1)}║{C.R}", C.GR)
        log(f"{C.B}╚══════════════════════════════════════════════════════════════╝{C.R}", C.GR)
        log(f"  Log: {log_path}", C.D)
        log(f"  Modo: {'manual' if manual else 'auto'} | poll={POLL_INTERVAL}s | max_wait={MAX_WAIT}s", C.D)

        zowe_check_or_die()

        # Sorteio ou validacao da injecao
        if not inj_id:
            inj_id = random.choice(SIMPLE_IDS)
            log(f"  Injecao sorteada: {C.YL}{inj_id}{C.R}")
        else:
            inj_id = inj_id.upper()
            if inj_id not in INJ_MAP:
                log(f"  ID de injecao invalido: {inj_id}", C.RD); return
            if inj_id not in SIMPLE_IDS:
                log(f"  AVISO: {inj_id} nao esta no catalogo simples (5).", C.YL)

        ok = (phase_reset(proj, manual)
              and phase_upload_massa(proj, day, manual, auto_massa)
              and phase_inject(proj, state, inj_id, manual)
              and phase_compile(proj, manual))
        if not ok:
            log(f"\n  Pipeline interrompido. Veja log: {log_path}", C.RD); return

        chain_jobid, chain_rc = phase_chain(proj, manual)

        # Atualiza state + history
        state["current_day"] = day
        state["history"].append({
            "day": day, "inj": inj_id,
            "chain_jobid": chain_jobid, "chain_rc": chain_rc,
            "ts": datetime.now().isoformat(),
            "log": str(log_path.relative_to(Path(_root(proj)))),
        })
        save_state(proj, state)

        # Demanda do dia (so sintoma — dica fica oculta)
        inj = INJ_MAP[inj_id]
        log(f"\n{C.B}━━━ DEMANDA DO DIA #{day:03d} ━━━{C.R}", C.YL)
        log(f"  {C.B}Sintoma:{C.R} {inj.get('sintoma','')}", C.YL)
        log("")
        log(f"  Para revelar a dica:    {C.CY}python ebops-cli.py catalogo {inj_id}{C.R}", C.D)
        log(f"  Para reverter o defeito: {C.CY}python ebops-cli.py revert{C.R}", C.D)
        log(f"  Log do dia:              {log_path}", C.D)
    finally:
        close_log()

# ============================================================
# OUTROS COMANDOS
# ============================================================
def cmd_reset(proj):
    open_log(proj, "reset")
    try:
        zowe_check_or_die()
        phase_reset(proj, manual=False)
    finally: close_log()

def cmd_upload_massa(proj, day, gerar=False):
    open_log(proj, f"upload-massa-d{day:03d}")
    try:
        zowe_check_or_die()
        phase_upload_massa(proj, day, manual=False, auto_gen=gerar)
    finally: close_log()

def cmd_compile(proj):
    open_log(proj, "compile")
    try:
        zowe_check_or_die()
        phase_compile(proj, manual=False)
    finally: close_log()

def cmd_chain(proj):
    open_log(proj, "chain")
    try:
        zowe_check_or_die()
        phase_chain(proj, manual=False)
    finally: close_log()

def cmd_inject(proj, inj_id):
    state = load_state(proj)
    open_log(proj, f"inject-{inj_id}")
    try:
        zowe_check_or_die()
        phase_inject(proj, state, inj_id.upper(), manual=False)
    finally: close_log()

def cmd_revert(proj):
    state = load_state(proj)
    inj_id = state.get("current_injection")
    if not inj_id:
        log("Nenhuma injecao ativa.", C.YL); return
    open_log(proj, f"revert-{inj_id}")
    try:
        zowe_check_or_die()
        log(f"\n{C.B}Revertendo {inj_id}{C.R}", C.GR)
        snap_root = Path(_root(proj))
        for op in state.get("operacoes", []):
            f, ds = op["file"], op["ds"]
            snap_meta = next((s for s in state.get("snapshot_meta", []) if s["file"] == f), None)
            if snap_meta and snap_meta.get("had_backup"):
                snap_path = Path(snap_meta["backup_path"])
                if snap_path.is_absolute():
                    full = snap_path
                else:
                    full = snap_root / snap_path
                if full.is_file():
                    ok, msg = _zowe_upload_text(_rf(str(full)), ds)
                    if ok:
                        log(f"  ✓ restore {ds}", C.GR)
                    else:
                        log(f"  ✗ restore {ds} — {msg.splitlines()[0] if msg else ''}", C.RD)
                else:
                    log(f"  ! snapshot ausente em {full}", C.YL)
            else:
                log(f"  ! sem snapshot pra {ds} (nao havia no remoto antes)", C.YL)
        # Limpa state
        state["history"].append({
            "reverted": inj_id, "ts": datetime.now().isoformat()
        })
        state["current_injection"] = None
        state["snapshot_dir"] = None
        state["snapshot_meta"] = []
        state["operacoes"] = []
        save_state(proj, state)
        log(f"\n  REVERTIDO\n", C.GR)
    finally: close_log()

def cmd_wait(proj, jobid, label="JOB"):
    open_log(proj, f"wait-{jobid}")
    try:
        zowe_check_or_die()
        log(f"\n{C.B}Acompanhando {jobid}{C.R}", C.GR)
        rc, retcode = wait_for_job(jobid, label)
        log(f"  RC={rc} ({retcode})", C.GR if 0 <= rc <= 4 else C.RD)
    finally: close_log()

def cmd_status(proj):
    state = load_state(proj)
    log(f"\n{C.B}EBOPS-CLI status{C.R}", C.GR)
    log(f"  Projeto:        {proj}")
    log(f"  HLQ:            {HLQ}")
    log(f"  Dia atual:      #{state.get('current_day', 0):03d}")
    inj_id = state.get('current_injection')
    if inj_id:
        inj = INJ_MAP.get(inj_id, {})
        log(f"  Injecao ativa:  {C.YL}{inj_id}{C.R} — {inj.get('t','')}")
        for op in state.get("operacoes", []):
            log(f"    • {op['action']} {op['ds']}", C.D)
    else:
        log(f"  Injecao ativa:  (nenhuma)")
    zowe_ok = _zowe_check()
    log(f"  Zowe CLI:       {(C.GR + 'OK') if zowe_ok else (C.RD + 'OFF')}{C.R}")
    log(f"\n  Historico ({len(state.get('history',[]))} entradas):", C.D)
    for h in state.get("history", [])[-5:]:
        if "day" in h:
            rc = h.get("chain_rc", "?")
            color = C.GR if isinstance(rc, int) and 0 <= rc <= 4 else C.RD
            log(f"    {h.get('ts','')[:19]} dia #{h['day']:03d} inj={h.get('inj','-')} chain_rc={color}{rc}{C.R}")
        elif "reverted" in h:
            log(f"    {h.get('ts','')[:19]} REVERT {h['reverted']}", C.YL)
    log("")

def cmd_catalogo(proj, inj_id=None):
    if inj_id:
        inj_id = inj_id.upper()
        inj = INJ_MAP.get(inj_id)
        if not inj:
            log(f"Injecao {inj_id} nao encontrada.", C.RD); return
        log(f"\n{C.B}{inj_id}{C.R} — {inj.get('t','')}", C.YL)
        log(f"  Categoria:    {inj.get('cat','-')}")
        log(f"  Dificuldade:  {inj.get('dif','-')}")
        log(f"  Tempo medio:  {inj.get('tmp','-')}")
        log(f"  Arquivos:     {', '.join(inj.get('arqs',[]))}")
        log(f"  Descricao:    {inj.get('desc','')}")
        log(f"  {C.B}Sintoma:{C.R}      {inj.get('sintoma','')}", C.YL)
        log(f"  {C.B}Dica:{C.R}         {inj.get('dica','')}", C.CY)
        log("")
        return
    log(f"\n{C.B}Catalogo simplificado (5 injecoes){C.R}", C.GR)
    log(f"{'ID':10} {'CAT':10} {'DIF':8} TITULO", C.D)
    for ent in SIMPLE_CATALOG:
        inj = INJ_MAP.get(ent["id"], {})
        log(f"{ent['id']:10} {ent['categoria']:10} {ent['dificuldade']:8} {inj.get('t','-')}")
    log(f"\n  Detalhes: {C.CY}python ebops-cli.py catalogo INJ-XXX{C.R}\n", C.D)

def cmd_logs(proj, name=None):
    log_dir = Path(_root(proj)) / ".ebops" / "logs"
    if not log_dir.is_dir():
        log("(sem logs)", C.D); return
    if name:
        path = log_dir / name
        if not path.is_file():
            log(f"Log nao encontrado: {name}", C.RD); return
        with open(path, encoding="utf-8") as f:
            sys.stdout.write(f.read())
        return
    files = sorted(log_dir.glob("*.log"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not files:
        log("(sem logs)", C.D); return
    log(f"\n{C.B}Logs em {log_dir}{C.R}", C.GR)
    for f in files[:20]:
        sz = f.stat().st_size
        ts = datetime.fromtimestamp(f.stat().st_mtime).strftime("%Y-%m-%d %H:%M:%S")
        log(f"  {ts}  {sz:7d}b  {f.name}")
    log(f"\n  Ver um log: {C.CY}python ebops-cli.py logs <NOME>{C.R}\n", C.D)

# ============================================================
# MENU INTERATIVO
# ============================================================
def cmd_menu(proj):
    while True:
        state = load_state(proj)
        log("")
        log(f"{C.B}╔══════════════════════════════════════════════════════════════╗{C.R}", C.GR)
        log(f"{C.B}║  EBOPS-CLI — MENU                                            ║{C.R}", C.GR)
        log(f"{C.B}╚══════════════════════════════════════════════════════════════╝{C.R}", C.GR)
        log(f"  Dia atual:     #{state.get('current_day', 0):03d}")
        ci = state.get("current_injection")
        if ci:
            log(f"  Injecao ativa: {C.YL}{ci}{C.R} — {INJ_MAP.get(ci,{}).get('t','')}")
        else:
            log("  Injecao ativa: (nenhuma)")
        zowe_ok = _zowe_check()
        log(f"  Zowe CLI:      {(C.GR+'OK') if zowe_ok else (C.RD+'OFF')}{C.R}")
        log("")
        log(f"  {C.B}1{C.R}) Gerar dia (orquestra as 5 fases)")
        log(f"  {C.B}2{C.R}) Reset (EBRESET)")
        log(f"  {C.B}3{C.R}) Upload massa de um dia")
        log(f"  {C.B}4{C.R}) Aplicar injecao (escolher do catalogo)")
        log(f"  {C.B}5{C.R}) Reverter injecao atual")
        log(f"  {C.B}6{C.R}) Compilar (EBDEPLOY)")
        log(f"  {C.B}7{C.R}) Submeter cadeia (EBJCHAIN)")
        log(f"  {C.B}8{C.R}) Acompanhar JobID")
        log(f"  {C.B}9{C.R}) Catalogo (5 injecoes)")
        log(f"  {C.B}L{C.R}) Listar logs")
        log(f"  {C.B}S{C.R}) Status detalhado")
        log(f"  {C.B}0{C.R}) Sair")
        ch = input(f"\n  > ").strip().lower()
        if ch in ("0", "q"): break
        try:
            if ch == "1":
                day = int(input("  Dia: ").strip())
                manual = input("  Modo manual (pausa entre fases)? (s/N): ").strip().lower() == "s"
                inj = input("  Injecao (vazio = sortear): ").strip().upper() or None
                cmd_dia(proj, day, inj, manual, auto_massa=False)
            elif ch == "2": cmd_reset(proj)
            elif ch == "3":
                day = int(input("  Dia: ").strip())
                gerar = input("  Gerar arquivo se nao existir? (s/N): ").strip().lower() == "s"
                cmd_upload_massa(proj, day, gerar)
            elif ch == "4":
                cmd_catalogo(proj)
                iid = input("  ID: ").strip().upper()
                if iid: cmd_inject(proj, iid)
            elif ch == "5": cmd_revert(proj)
            elif ch == "6": cmd_compile(proj)
            elif ch == "7": cmd_chain(proj)
            elif ch == "8":
                jid = input("  JobID: ").strip().upper()
                if jid: cmd_wait(proj, jid)
            elif ch == "9":
                iid = input("  ID (vazio = lista): ").strip().upper() or None
                cmd_catalogo(proj, iid)
            elif ch == "l": cmd_logs(proj)
            elif ch == "s": cmd_status(proj)
            else: log(f"  opcao desconhecida", C.YL)
        except (KeyboardInterrupt, EOFError):
            log("\n  cancelado", C.YL); continue
        except Exception as e:
            log(f"  ERRO: {e}", C.RD)
        input(f"\n  Enter pra continuar...")

# ============================================================
# ARGPARSE
# ============================================================
def main():
    parser = argparse.ArgumentParser(prog="ebops-cli", description=__doc__)
    sub = parser.add_subparsers(dest="cmd")

    p_dia = sub.add_parser("dia", help="Orquestra as 5 fases do dia")
    p_dia.add_argument("day", type=int)
    p_dia.add_argument("--inj", help="ID da injecao (vazio = sortear)")
    p_dia.add_argument("--manual", action="store_true", help="Pausa entre fases")
    p_dia.add_argument("--auto-massa", action="store_true", help="Gera massa sem perguntar se ausente")

    sub.add_parser("menu", help="Menu interativo")
    sub.add_parser("reset", help="Submete apenas EBRESET")
    sub.add_parser("compile", help="Submete apenas EBDEPLOY")
    sub.add_parser("chain", help="Submete apenas EBJCHAIN")
    sub.add_parser("revert", help="Reverte injecao ativa")
    sub.add_parser("status", help="Mostra estado")

    p_um = sub.add_parser("upload-massa", help="Upload da massa de um dia")
    p_um.add_argument("day", type=int)
    p_um.add_argument("--gerar", action="store_true", help="Gera o arquivo se ausente")

    p_inj = sub.add_parser("inject", help="Aplica uma injecao")
    p_inj.add_argument("inj_id")

    p_w = sub.add_parser("wait", help="Acompanha um JobID em tempo real")
    p_w.add_argument("jobid")
    p_w.add_argument("--label", default="JOB")

    p_cat = sub.add_parser("catalogo", help="Mostra catalogo ou detalhes de uma injecao")
    p_cat.add_argument("inj_id", nargs="?")

    p_logs = sub.add_parser("logs", help="Lista ou exibe um log")
    p_logs.add_argument("name", nargs="?")

    args = parser.parse_args()
    proj = find_project()

    if args.cmd is None:
        cmd_menu(proj); return
    if args.cmd == "dia":          cmd_dia(proj, args.day, args.inj, args.manual, args.auto_massa)
    elif args.cmd == "menu":        cmd_menu(proj)
    elif args.cmd == "reset":       cmd_reset(proj)
    elif args.cmd == "compile":     cmd_compile(proj)
    elif args.cmd == "chain":       cmd_chain(proj)
    elif args.cmd == "revert":      cmd_revert(proj)
    elif args.cmd == "status":      cmd_status(proj)
    elif args.cmd == "upload-massa":cmd_upload_massa(proj, args.day, args.gerar)
    elif args.cmd == "inject":      cmd_inject(proj, args.inj_id)
    elif args.cmd == "wait":        cmd_wait(proj, args.jobid.upper(), args.label)
    elif args.cmd == "catalogo":    cmd_catalogo(proj, args.inj_id)
    elif args.cmd == "logs":        cmd_logs(proj, args.name)

if __name__ == "__main__":
    main()