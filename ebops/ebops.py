#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EBOPS — Emunah Bank Operations Simulator (Ghost Injection Edition)
Um script. Gera dias. Injeta defeitos REAIS direto no mainframe via Zowe.
Working tree local permanece intacto — sem spoiler no git.

Uso:
    python ebops.py                     # Menu interativo
    python ebops.py dia                 # Gera novo dia
    python ebops.py tickets             # Lista tickets
    python ebops.py status              # Injeções ativas
    python ebops.py inject INJ-001      # Injeta no remoto via Zowe
    python ebops.py revert [ID]         # Reverte do snapshot
    python ebops.py spy [ID]            # Compara local vs remoto
    python ebops.py submit-all          # Submete cadeia inteira (EBJALL)
    python ebops.py where               # Mostra caminho do projeto
    python ebops.py set-path /caminho   # Define caminho manualmente
    python ebops.py reset               # Reseta tudo
    python ebops.py importar arq.json   # Importa templates customizados
    python ebops.py exportar            # Exporta tickets para JSON
"""

import os, sys, json, random, subprocess, re
from datetime import datetime

# ═════════════════════════════════════════════════════════════
# CORES
# ═════════════════════════════════════════════════════════════
class C:
    R="\033[0m"; B="\033[1m"; D="\033[2m"
    GR="\033[32m"; RD="\033[31m"; YL="\033[33m"; BL="\033[34m"
    CY="\033[36m"; MG="\033[35m"; WH="\033[37m"
    BGr="\033[42m"; BGrd="\033[41m"; BGyl="\033[43m"

def cprint(msg, color=C.R): print(f"{color}{msg}{C.R}")

# ═════════════════════════════════════════════════════════════
# LOCALIZAÇÃO DO PROJETO
# ═════════════════════════════════════════════════════════════
STATE_FILE = "ebops_state.json"
CONFIG_FILE = ".ebops_config.json"
MARKER = "EBVALI01.cbl"
SNAPSHOT_REL = ".ebops/snapshots"

def _is_proj(p): return os.path.isfile(os.path.join(p, MARKER))

def _walk_up(start):
    cur = os.path.abspath(start)
    vis = set()
    while cur not in vis:
        vis.add(cur)
        if _is_proj(cur): return cur
        for s in ["src","cobol","source","emunah-bank-lab","emunah"]:
            c = os.path.join(cur, s)
            if os.path.isdir(c) and _is_proj(c): return c
        p = os.path.dirname(cur)
        if p == cur: break
        cur = p
    return None

def _search(start, depth=3):
    start = os.path.abspath(start)
    for root, dirs, files in os.walk(start):
        rel = os.path.relpath(root, start)
        lv = 0 if rel == '.' else rel.count(os.sep) + 1
        if lv > depth: dirs.clear(); continue
        if MARKER in files: return root
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ('node_modules','__pycache__','venv')]
    return None

def _load_cfg():
    for loc in [os.getcwd(), os.path.expanduser("~")]:
        cfg = os.path.join(loc, CONFIG_FILE)
        if os.path.isfile(cfg):
            try:
                with open(cfg) as f: data = json.load(f)
                p = data.get("project_dir","")
                if p and _is_proj(p): return p
            except: pass
    return None

def _save_cfg(p):
    data = {"project_dir": os.path.abspath(p)}
    for loc in [p, os.path.expanduser("~")]:
        try:
            with open(os.path.join(loc, CONFIG_FILE), 'w') as f: json.dump(data, f)
        except: pass

def find_project():
    sd = os.path.dirname(os.path.abspath(__file__))
    if _is_proj(sd): return sd
    for fn in [lambda: _walk_up(sd), lambda: _walk_up(os.getcwd()),
               lambda: _search(os.getcwd(), 3), _load_cfg,
               lambda: _search(os.path.expanduser("~"), 4)]:
        r = fn() if callable(fn) else fn
        if r: return r
    cprint(f"\n  Projeto não encontrado. Use: python ebops.py set-path /caminho\n", C.RD)
    sys.exit(1)

# ═════════════════════════════════════════════════════════════
# ESTADO
# ═════════════════════════════════════════════════════════════
def load_state(proj):
    p = os.path.join(proj, STATE_FILE)
    default = {"tickets":[],"custom_templates":[],"day":1,"injections_active":[],"history":[]}
    if os.path.isfile(p):
        try:
            with open(p, encoding='utf-8') as f: data = json.load(f)
            for k,v in default.items():
                if k not in data: data[k] = v
            return data
        except: pass
    return default

def save_state(proj, state):
    with open(os.path.join(proj, STATE_FILE), 'w', encoding='utf-8') as f:
        json.dump(state, f, indent=2, ensure_ascii=False)

# ═════════════════════════════════════════════════════════════
# CATÁLOGO DE TEMPLATES (67 Nativos)
# ═════════════════════════════════════════════════════════════
TEMPLATES = [
{"id":"INC-001","t":"Abend S0C7 em EBPOST01","cat":"incidente","sev":"alta","dif":"pleno","tmp":"45min","fer":"Abendaid / SDSF","desc":"Job EBJPOST abendou com S0C7. Spool mostra offset 0003A2 no EBPOST01.","tags":["abend","S0C7","COBOL"],"inj":"INJ-005"},
{"id":"INC-002","t":"RC=08 em EBJVALD — rejeição acima de 30%","cat":"incidente","sev":"media","dif":"junior","tmp":"30min","fer":"SDSF / File Manager","desc":"EBJVALD terminou RC=08. 47% de rejeição. Taxa normal é abaixo de 5%.","tags":["validação","RC","massa"],"inj":"INJ-001"},
{"id":"INC-003","t":"Arquivo de entrada ausente — cadeia bloqueada","cat":"incidente","sev":"critica","dif":"junior","tmp":"20min","fer":"Zowe CLI / TSO","desc":"EBJLOAD falhou. ARQ.ENTRADA.SEQ não existe. Cadeia bloqueada.","tags":["arquivo","bloqueio","cadeia"],"inj":"INJ-019"},
{"id":"INC-004","t":"Conciliação divergente — R$ 150,00","cat":"incidente","sev":"alta","dif":"pleno","tmp":"60min","fer":"SDSF / File Manager","desc":"EBJCONC detectou divergência de R$ 150,00. EBJEOD bloqueado.","tags":["conciliação","saldo","fechamento"],"inj":"INJ-005"},
{"id":"INC-005","t":"FILE STATUS 35 ao abrir ARQ.CONTA.KSDS","cat":"incidente","sev":"alta","dif":"junior","tmp":"25min","fer":"IDCAMS / Zowe CLI","desc":"EBPOST01 retornou FILE STATUS 35. VSAM não catalogado.","tags":["VSAM","FILE STATUS","IDCAMS"],"inj":"INJ-028"},
{"id":"INC-006","t":"Job EBJSNAP em HOLD","cat":"incidente","sev":"media","dif":"junior","tmp":"15min","fer":"SDSF / Zowe Explorer","desc":"EBJSNAP em HOLD. Snapshot de saldo não rodou, EBJCUTE/EBJCONC ficaram presos.","tags":["HOLD","scheduler","SDSF"],"inj":"INJ-020"},
{"id":"INC-007","t":"Layout divergente — TIPO-LANCTO errado","cat":"incidente","sev":"media","dif":"pleno","tmp":"40min","fer":"File Manager / Notepad++","desc":"Copybook CPLCT001 alterado mas massa não ajustada. Campos deslocados.","tags":["layout","copybook","compilação"],"inj":"INJ-015"},
{"id":"INC-008","t":"Abend S806 — módulo não na LOADLIB","cat":"incidente","sev":"alta","dif":"junior","tmp":"20min","fer":"SDSF / JCL","desc":"EBJPOST abendou S806-04. Módulo não encontrado na LOADLIB.","tags":["S806","LOADLIB","link-edit"],"inj":"INJ-007"},
{"id":"INC-009","t":"Saldo negativo em conta corrente","cat":"incidente","sev":"critica","dif":"pleno","tmp":"50min","fer":"File Manager / COBOL","desc":"Conta com -R$ 2.300,00. Regra não permite saldo negativo em CC.","tags":["saldo","regra de negócio","estorno"],"inj":"INJ-005"},
{"id":"INC-010","t":"GDG sem nova geração","cat":"incidente","sev":"media","dif":"junior","tmp":"25min","fer":"IDCAMS / JCL","desc":"EBJEXTR RC=00 mas GDG não criou geração. Limite atingido?","tags":["GDG","IDCAMS","extrato"]},
{"id":"INC-011","t":"Abend S0C4 no utilitário EBSALD01","cat":"incidente","sev":"alta","dif":"pleno","tmp":"50min","fer":"Abendaid / SDSF","desc":"Utilitário de consulta manual de saldo (cobol/util) abendou S0C4. Referência inválida de memória, possivelmente OCCURS fora do limite ou READ em KSDS sem checar FILE STATUS.","tags":["S0C4","memória","COBOL","utilitário"],"inj":"INJ-032"},
{"id":"INC-012","t":"REGION S878 no EBJPOST","cat":"incidente","sev":"media","dif":"junior","tmp":"15min","fer":"JCL / SDSF","desc":"REGION insuficiente. Massa com 10.000 registros, REGION=4M.","tags":["REGION","S878","JCL"],"inj":"INJ-022"},
{"id":"INC-013","t":"Dataset locked — ENQ em CONTA.KSDS","cat":"incidente","sev":"alta","dif":"pleno","tmp":"25min","fer":"SDSF / TSO","desc":"EBJPOST em WAIT. Outro job com DISP=OLD travando o VSAM.","tags":["ENQ","lock","concorrência"]},
{"id":"INC-014","t":"JCL ERROR — sintaxe inválida no EXEC","cat":"incidente","sev":"media","dif":"junior","tmp":"10min","fer":"SDSF / JCL","desc":"EBJVALD nem executou. JCL ERROR com IEF631I.","tags":["JCL ERROR","sintaxe"],"inj":"INJ-009"},
{"id":"INC-015","t":"Auditoria cheia — B37","cat":"incidente","sev":"alta","dif":"junior","tmp":"20min","fer":"JCL / IDCAMS","desc":"EBJPOST abendou B37 ao gravar ARQ.AUDIT.SEQ. Sem espaço.","tags":["B37","auditoria","SPACE"]},
{"id":"INC-016","t":"SORT RC=16 — entrada vazia","cat":"incidente","sev":"media","dif":"junior","tmp":"20min","fer":"DFSORT / JCL","desc":"SORT retornou RC=16. Arquivo de entrada com 0 registros.","tags":["SORT","RC16","DFSORT"]},
{"id":"INC-017","t":"Timestamp de auditoria gravando zeros","cat":"incidente","sev":"media","dif":"junior","tmp":"25min","fer":"COBOL / File Manager","desc":"ACCEPT FROM DATE gerando zeros. PIC X em vez de PIC 9?","tags":["ACCEPT","timestamp","auditoria"],"inj":"INJ-023"},
{"id":"INC-018","t":"VSAM I/O ERROR em ESDS","cat":"incidente","sev":"alta","dif":"pleno","tmp":"45min","fer":"IDCAMS / VSAM","desc":"Performance degradada e I/O error no ARQ.LANCTO.ESDS.","tags":["VSAM","ESDS","I/O"]},
{"id":"INC-019","t":"SQLCODE -805 — DBRM não no PLAN","cat":"incidente","sev":"alta","dif":"pleno","tmp":"35min","fer":"DB2 / BIND","desc":"EBAUDB01 abendou com -805. BIND não executado após pré-compilação.","tags":["DB2","-805","BIND"]},
{"id":"INJ-020","t":"EBJSNAP com TYPRUN=HOLD","cat":"jcl","dif":"junior","tmp":"10min","arqs":["EBJSNAP.jcl"],
 "desc":"TYPRUN=HOLD adicionado ao cartão JOB do EBJSNAP. Snapshot de saldo não dispara, cadeia trava antes de EBJCUTE.",
 "sintoma":"Job submetido fica em HOLD no SDSF. EBJCUTE e EBJCONC nunca rodam porque SALDO.GDG não ganhou geração nova.",
 "dica":"Verifique o cartão JOB do JCL. Procure por TYPRUN=HOLD."},{"id":"INC-021","t":"SQLCODE -811 — SELECT INTO múltiplas linhas","cat":"incidente","sev":"media","dif":"junior","tmp":"25min","fer":"DB2 / SPUFI","desc":"SELECT INTO retornou mais de um registro. Duplicidade?","tags":["DB2","-811","SELECT INTO"]},
{"id":"INC-022","t":"Encoding corrompido após upload","cat":"incidente","sev":"media","dif":"junior","tmp":"25min","fer":"Zowe CLI / iconv","desc":"Caracteres acentuados corrompidos. EBCDIC vs UTF-8.","tags":["encoding","EBCDIC","Zowe CLI"],"inj":"INJ-024"},
{"id":"DEV-001","t":"Incluir CPF no copybook CPCLI001","cat":"desenvolvimento","sev":"media","dif":"pleno","tmp":"90min","fer":"Changeman / VS Code","desc":"Incluir CPF PIC 9(11). Avaliar impacto em todos os programas.","tags":["copybook","análise de impacto"],"inj":"INJ-015"},
{"id":"DEV-002","t":"Validação de DV módulo 11","cat":"desenvolvimento","sev":"baixa","dif":"junior","tmp":"45min","fer":"COBOL","desc":"Implementar DV no EBVALI01. Contas com DV inválido rejeitadas.","tags":["COBOL","validação","módulo 11"]},
{"id":"DEV-003","t":"Novo tipo de lançamento: TED","cat":"desenvolvimento","sev":"media","dif":"pleno","tmp":"120min","fer":"COBOL / JCL","desc":"Adicionar tipo 'T' (TED). Valor R$1-R$10M, horário 06-17h.","tags":["TED","regra de negócio"]},
{"id":"DEV-004","t":"Relatório de contas sem movimento","cat":"desenvolvimento","sev":"baixa","dif":"junior","tmp":"60min","fer":"COBOL / JCL","desc":"Criar EBRCSM01 listando contas sem lançamento no dia.","tags":["relatório","programa novo"]},
{"id":"DEV-005","t":"Flag de conta bloqueada","cat":"desenvolvimento","sev":"media","dif":"pleno","tmp":"90min","fer":"COBOL / Copybook","desc":"CNT-STATUS: A/B/E. EBPOST01 rejeita se ≠ 'A'.","tags":["conta","status","copybook"]},
{"id":"DEV-006","t":"Corrigir cálculo de tarifa","cat":"desenvolvimento","sev":"alta","dif":"junior","tmp":"30min","fer":"COBOL","desc":"Tarifa R$0,00 em vez de R$8,50. PIC sem V99.","tags":["bug","COMPUTE","decimal"],"inj":"INJ-016"},
{"id":"DEV-007","t":"Programa COBOL-DB2 — EBAUDB01","cat":"desenvolvimento","sev":"media","dif":"pleno","tmp":"120min","fer":"COBOL-DB2 / BIND","desc":"Consulta batch em TB_AUDITORIA com cursor e SQLCODE.","tags":["DB2","cursor","BIND"]},
{"id":"DEV-008","t":"UPDATE DB2 com COMMIT controlado","cat":"desenvolvimento","sev":"media","dif":"pleno","tmp":"90min","fer":"COBOL-DB2","desc":"EBAUDC01 com COMMIT a cada 100 registros.","tags":["DB2","COMMIT","UOW"]},
{"id":"DEV-009","t":"DCLGEN para TB_CLIENTE","cat":"desenvolvimento","sev":"baixa","dif":"junior","tmp":"30min","fer":"DB2 / DCLGEN","desc":"Gerar DCLGEN e mapear tipos SQL↔COBOL.","tags":["DB2","DCLGEN"]},
{"id":"DEV-010","t":"Documentar transação CICS consulta saldo","cat":"desenvolvimento","sev":"media","dif":"pleno","tmp":"90min","fer":"CICS / BMS","desc":"EBTR01 — consulta online com RECEIVE MAP, SEND MAP.","tags":["CICS","online","BMS"]},
{"id":"DEV-011","t":"Documentar CICS depósito com SYNCPOINT","cat":"desenvolvimento","sev":"media","dif":"pleno","tmp":"75min","fer":"CICS","desc":"EBTR02 — depósito com REWRITE FILE e SYNCPOINT.","tags":["CICS","SYNCPOINT","online"]},
{"id":"DEV-012","t":"Script REXX EBRESET","cat":"desenvolvimento","sev":"baixa","dif":"junior","tmp":"45min","fer":"REXX / TSO","desc":"Reset completo: DELETE/DEFINE VSAM, limpar SEQ, recarregar.","tags":["REXX","reset","automação"]},
{"id":"DEV-013","t":"Expandir EBCHKLAB — 15+ datasets","cat":"desenvolvimento","sev":"baixa","dif":"junior","tmp":"40min","fer":"REXX / LISTCAT","desc":"Healthcheck ampliado com contagem e integridade.","tags":["REXX","healthcheck","LISTCAT"]},
{"id":"DEV-014","t":"Validação de Pix no EBVALI01","cat":"desenvolvimento","sev":"media","dif":"pleno","tmp":"90min","fer":"COBOL","desc":"Tipo 'P' com regras BACEN: limites dia/noite, chave obrigatória.","tags":["Pix","BACEN","validação"]},
{"id":"DEV-015","t":"Programa EBLIMCR — limite de crédito","cat":"desenvolvimento","sev":"media","dif":"junior","tmp":"60min","fer":"COBOL / VSAM","desc":"Verificar se saldo+débitos não ultrapassa limite. Relatório de risco.","tags":["limite de crédito","relatório"]},
{"id":"DEV-016","t":"Padronizar DISPLAY/log em todos os EB*","cat":"desenvolvimento","sev":"baixa","dif":"junior","tmp":"60min","fer":"COBOL","desc":"Formato: PROGRAMA - PARAGRAFO - ACAO - DETALHES.","tags":["DISPLAY","log","observabilidade"]},
{"id":"DEV-017","t":"JCL parametrizado com COND","cat":"desenvolvimento","sev":"media","dif":"pleno","tmp":"60min","fer":"JCL / PARM","desc":"EBBATCHP com 5 STEPs, COND para dependência, PARM para data.","tags":["JCL","COND","PARM"]},
{"id":"DEV-018","t":"PROC catalogada para compilação","cat":"desenvolvimento","sev":"baixa","dif":"pleno","tmp":"45min","fer":"JCL / PROC","desc":"EBPRCOMP com &PGMNAME e &ENV. Padroniza compilação.","tags":["PROC","compilação","JCL"]},
{"id":"DEV-019","t":"GDG para rejeitos com histórico","cat":"desenvolvimento","sev":"baixa","dif":"junior","tmp":"35min","fer":"IDCAMS / JCL","desc":"Trocar SEQ por GDG. Histórico de 7 dias de rejeitos.","tags":["GDG","rejeitos","IDCAMS"]},
{"id":"DEV-020","t":"Smoke test EBSMKH01","cat":"desenvolvimento","sev":"media","dif":"junior","tmp":"50min","fer":"COBOL / JCL","desc":"Abre VSAM, verifica FILE STATUS, conta registros, retorna RC.","tags":["smoke test","healthcheck"]},
{"id":"DEV-021","t":"Documentar integração Pix × batch","cat":"desenvolvimento","sev":"media","dif":"pleno","tmp":"75min","fer":"Documentação","desc":"Arquitetura: SPI/BACEN → mainframe → cadeia batch.","tags":["Pix","SPI","arquitetura"]},
{"id":"OPS-001","t":"Reprocessar rejeitos do dia anterior","cat":"operação","sev":"media","dif":"junior","tmp":"35min","fer":"JCL / Zowe CLI","desc":"12 registros corrigidos. Preparar massa e executar EBJREPR.","tags":["reprocessamento","rejeitos"]},
{"id":"OPS-002","t":"Verificar spool RC=04 do EBJCONC","cat":"operação","sev":"baixa","dif":"junior","tmp":"20min","fer":"SDSF","desc":"RC=04 — warning aceitável ou requer ação?","tags":["spool","RC","decisão"]},
{"id":"OPS-003","t":"Backup pré-carga especial com REPRO","cat":"operação","sev":"media","dif":"junior","tmp":"30min","fer":"IDCAMS","desc":"500 novas contas fora da janela. Backup antes de executar.","tags":["backup","REPRO","carga especial"]},
{"id":"OPS-004","t":"Gerar evidência de teste para HML","cat":"operação","sev":"baixa","dif":"junior","tmp":"40min","fer":"Zowe CLI / SDSF","desc":"Pacote de evidência formal para promoção.","tags":["evidência","homologação"]},
{"id":"OPS-005","t":"Cadeia batch end-to-end com evidência","cat":"operação","sev":"media","dif":"junior","tmp":"90min","fer":"Zowe CLI / SDSF","desc":"PRECHECK até EBJEOD. Documentar cada etapa.","tags":["end-to-end","teste integrado"]},
{"id":"OPS-006","t":"Simular missing-input + executar runbook","cat":"operação","sev":"media","dif":"junior","tmp":"30min","fer":"Runbook","desc":"Não enviar arquivo, executar EBJLOAD, seguir runbook.","tags":["runbook","missing-input","cenário"],"inj":"INJ-019"},
{"id":"OPS-007","t":"Simular saldo-inconsistente e investigar","cat":"operação","sev":"alta","dif":"pleno","tmp":"45min","fer":"File Manager","desc":"Alterar saldo no VSAM, rodar EBJCONC, localizar divergência.","tags":["conciliação","investigação","cenário"],"inj":"INJ-027"},
{"id":"OPS-008","t":"Massa de 1000 registros — teste de volume","cat":"operação","sev":"baixa","dif":"junior","tmp":"45min","fer":"Python","desc":"Testar performance da cadeia com volume maior.","tags":["massa","performance","volume"]},
{"id":"OPS-009","t":"Documento de SLA da cadeia batch","cat":"operação","sev":"baixa","dif":"pleno","tmp":"40min","fer":"Documentação","desc":"SLA por job: horário, duração máxima, RC aceitável.","tags":["SLA","ITIL","operação"]},
{"id":"OPS-010","t":"Contingência para falha total da cadeia","cat":"operação","sev":"media","dif":"pleno","tmp":"50min","fer":"Runbook","desc":"Runbook de contingência: escalação, opções, comunicação.","tags":["contingência","escalação","risco"]},
{"id":"OPS-011","t":"Configurar Zowe profiles por ambiente","cat":"operação","sev":"baixa","dif":"junior","tmp":"20min","fer":"Zowe CLI","desc":"Profiles separados para DEV, HML, PRD.","tags":["Zowe CLI","profiles","ambientes"]},
{"id":"CHG-001","t":"Promover EBPOST01 DEV → HML","cat":"change","sev":"media","dif":"pleno","tmp":"45min","fer":"Changeman / Git","desc":"Compilar em HML, teste de regressão, aprovação.","tags":["promoção","Changeman","Git"],"inj":"INJ-007"},
{"id":"CHG-002","t":"Rollback de EBVALI01 — versão com bug","cat":"change","sev":"critica","dif":"pleno","tmp":"40min","fer":"Git / LOADLIB","desc":"Versão em HML rejeita créditos válidos. Rollback urgente.","tags":["rollback","emergência","Git"],"inj":"INJ-001"},
{"id":"CHG-003","t":"Análise de impacto — CPCNT001","cat":"change","sev":"media","dif":"pleno","tmp":"30min","fer":"VS Code / grep","desc":"Mapear todos os programas e JCLs impactados por alteração.","tags":["análise de impacto","copybook"],"inj":"INJ-015"},
{"id":"CHG-004","t":"Fluxo de promoção DEV→HML→PRD com Git","cat":"change","sev":"media","dif":"pleno","tmp":"60min","fer":"Git / Zowe CLI","desc":"Documentar e implementar fluxo completo com branches e tags.","tags":["promoção","Git","DEV-HML-PRD"]},
{"id":"CHG-005","t":"Teste de regressão após alteração","cat":"change","sev":"media","dif":"pleno","tmp":"60min","fer":"JCL / SDSF","desc":"Verificar que alteração não quebrou cenários existentes.","tags":["regressão","teste","baseline"],"inj":"INJ-032"},
{"id":"INV-001","t":"Comparar VSAM antes/depois do EBJPOST","cat":"investigação","sev":"baixa","dif":"junior","tmp":"25min","fer":"File Manager / REPRO","desc":"Exportar ARQ.SALDO.KSDS antes e depois. Comparar diferenças.","tags":["comparação","VSAM","validação"]},
{"id":"INV-002","t":"Analisar dump S0C7 com offset no listing","cat":"investigação","sev":"media","dif":"pleno","tmp":"40min","fer":"Abendaid / Listing","desc":"Cruzar offset 0003A2 com listing para achar instrução COBOL.","tags":["dump","offset","S0C7"],"inj":"INJ-021"},
{"id":"INV-003","t":"Integridade pós-reprocessamento","cat":"investigação","sev":"media","dif":"pleno","tmp":"35min","fer":"File Manager / IDCAMS","desc":"Verificar: sem duplicidade, saldos ok, auditoria, conciliação.","tags":["integridade","reprocessamento"],"inj":"INJ-029"},
{"id":"INV-004","t":"Mapear FILE STATUS dos programas","cat":"investigação","sev":"baixa","dif":"junior","tmp":"35min","fer":"COBOL / grep","desc":"Quais programas tratam quais FILE STATUS? Quais lacunas?","tags":["FILE STATUS","qualidade","análise"],"inj":"INJ-003"},
{"id":"INV-005","t":"Analisar warnings de compilação COBOL","cat":"investigação","sev":"baixa","dif":"junior","tmp":"40min","fer":"SDSF / Compilador","desc":"Listar IGYW* e classificar: aceitável, atenção, risco.","tags":["compilação","warnings","qualidade"]},
{"id":"INV-006","t":"Rastrear lançamento end-to-end","cat":"investigação","sev":"media","dif":"pleno","tmp":"50min","fer":"File Manager / VSAM","desc":"Trilha completa: entrada → validação → saldo → extrato → auditoria.","tags":["rastreabilidade","auditoria","BACEN"],"inj":"INJ-014"},
{"id":"INV-007","t":"Estudo de caso para portfólio","cat":"investigação","sev":"baixa","dif":"pleno","tmp":"90min","fer":"Documentação","desc":"Documentar incidente real resolvido como estudo de caso.","tags":["estudo de caso","portfólio","recrutador"]},
{"id":"INV-008","t":"Mapa completo de datasets do lab","cat":"investigação","sev":"baixa","dif":"junior","tmp":"45min","fer":"LISTCAT","desc":"Todos os datasets: tipo, LRECL, programas que leem/gravam.","tags":["datasets","documentação","mapa"]},
]

# ═════════════════════════════════════════════════════════════
# CATÁLOGO DE INJEÇÕES
# ═════════════════════════════════════════════════════════════
INJECTIONS = [
{"id":"INJ-001","t":"EBVALI01 rejeita créditos válidos","cat":"cobol","dif":"junior","tmp":"20min","arqs":["EBVALI01.cbl"],"desc":"Validação de tipo alterada: aceita apenas 'D', rejeitando 'C'.","sintoma":"Todos os créditos vão para REJEITO com motivo TIPO INVALIDO.","dica":"Analise o EVALUATE/IF de tipo no parágrafo 2100-VALIDAR-REGISTRO."},
{"id":"INJ-002","t":"EBVALI01 aceita valor zero","cat":"cobol","dif":"junior","tmp":"15min","arqs":["EBVALI01.cbl"],"desc":"Operador de comparação de valor alterado: zero passa como válido.","sintoma":"Registros com valor R$0,00 passam na validação e chegam ao EBJPOST.","dica":"Verifique o operador de comparação (<= vs <) na regra de valor."},
{"id":"INJ-003","t":"EBVALI01 sem FILE STATUS no OPEN","cat":"cobol","dif":"pleno","tmp":"30min","arqs":["EBVALI01.cbl"],"desc":"Verificações de FILE STATUS após OPEN removidas.","sintoma":"Se um dataset estiver ausente, o programa não detecta e pode abender depois.","dica":"Compare o parágrafo 1000-ABRIR-ARQUIVOS com o que deveria ter."},
{"id":"INJ-004","t":"EBVALI01 para no primeiro erro","cat":"cobol","dif":"pleno","tmp":"25min","arqs":["EBVALI01.cbl"],"desc":"GO TO inserido após primeiro erro. Não acumula múltiplos motivos.","sintoma":"Rejeitos mostram apenas um motivo, mesmo com múltiplos erros.","dica":"Procure um GO TO no meio do 2100-VALIDAR-REGISTRO."},
{"id":"INJ-005","t":"EBPOST01 inverte crédito e débito","cat":"cobol","dif":"pleno","tmp":"35min","arqs":["EBPOST01.cbl"],"desc":"Créditos subtraem do saldo e débitos somam. Lógica invertida.","sintoma":"Saldos inconsistentes. Crédito reduz saldo. Conciliação diverge.","dica":"Verifique o IF que testa tipo C/D antes do ADD/SUBTRACT."},
{"id":"INJ-006","t":"EBPOST01 com DDNAME errado","cat":"cobol","dif":"junior","tmp":"15min","arqs":["EBPOST01.cbl"],"desc":"ASSIGN TO do arquivo de auditoria trocado de AUDIT para AUDITLOG.","sintoma":"FILE STATUS 35 ou abend ao abrir auditoria. DDNAME não corresponde ao JCL.","dica":"Compare o ASSIGN TO do SELECT AUDIT-OUT com o DD no EBJPOST.jcl."},
{"id":"INJ-007","t":"EBJVALD STEPLIB apontando para HML","cat":"jcl","dif":"junior","tmp":"10min","arqs":["EBJVALD.jcl"],"desc":"STEPLIB trocada de DEV.LOADLIB para HML.LOADLIB.","sintoma":"S806-04 se o módulo não existir em HML.","dica":"Verifique o DD STEPLIB — qual ambiente está apontando?"},
{"id":"INJ-008","t":"EBJPOST DISP=SHR no AUDIT (deveria ser MOD)","cat":"jcl","dif":"junior","tmp":"10min","arqs":["EBJPOST.jcl"],"desc":"DISP do DD AUDIT trocado de MOD para SHR.","sintoma":"Registros de auditoria podem sobrescrever em vez de acrescentar.","dica":"Verifique DISP do DD AUDIT — para append deve ser MOD, não SHR."},
{"id":"INJ-009","t":"EBJVALD sem DD REJEITOS","cat":"jcl","dif":"junior","tmp":"10min","arqs":["EBJVALD.jcl"],"desc":"DD REJEITOS removido do JCL.","sintoma":"FILE STATUS 35 ao tentar abrir arquivo de rejeitos.","dica":"Compare os DDNAMEs do JCL com os SELECT do EBVALI01."},
{"id":"INJ-010","t":"EBJPOST dataset errado no MOVTIN","cat":"jcl","dif":"junior","tmp":"10min","arqs":["EBJPOST.jcl"],"desc":"Nome do dataset trocado: ARQ.LANCAMENTO.ESDS em vez de ARQ.LANCTO.ESDS.","sintoma":"IEF212I — dataset não encontrado. Job falha na alocação.","dica":"Verifique o nome do dataset no DD MOVTIN e compare com o mapa de datasets."},
{"id":"INJ-011","t":"Massa com letras no campo valor","cat":"massa","dif":"junior","tmp":"15min","arqs":["lancamentos_d0.txt"],"desc":"Registros 2 e 5 com 'ABC' no campo de valor.","sintoma":"IS NUMERIC falha → rejeição com VALOR INVALIDO (ou S0C7 se não tratar).","dica":"Examine as posições 22-34 (campo valor) de cada registro."},
{"id":"INJ-012","t":"Massa com tipo 'X' inválido","cat":"massa","dif":"junior","tmp":"10min","arqs":["lancamentos_d0.txt"],"desc":"Registros 3 e 7 com tipo 'X' em vez de 'C' ou 'D'.","sintoma":"Rejeição com motivo TIPO INVALIDO.","dica":"Verifique a posição 21 (campo tipo) de cada registro."},
{"id":"INJ-013","t":"Massa com registros truncados","cat":"massa","dif":"pleno","tmp":"20min","arqs":["lancamentos_d0.txt"],"desc":"Registros 4 e 8 truncados para 80 bytes (deveriam ser 120).","sintoma":"Campos deslocados ou faltando. Rejeição massiva ou abend.","dica":"Verifique tamanho de cada registro. RECORD CONTAINS 120 CHARACTERS."},
{"id":"INJ-014","t":"Massa com conta inexistente","cat":"massa","dif":"junior","tmp":"15min","arqs":["lancamentos_d0.txt"],"desc":"Registros 1 e 6 com conta 99999999 (não existe no KSDS).","sintoma":"Rejeição no EBPOST01 — FILE STATUS 23 (not found) no READ do VSAM.","dica":"Compare contas da massa com contas carregadas pelo EBCLLOAD."},
{"id":"INJ-015","t":"Copybook CPLCT001 deslocado","cat":"copybook","dif":"pleno","tmp":"30min","arqs":["CPLCT001.cpy"],"desc":"LCT-TIPO mudou de PIC X(01) para PIC X(02) sem ajustar FILLER. Tudo desloca.","sintoma":"Campos interpretados incorretamente. Valor vira histórico, data fica lixo.","dica":"Some os tamanhos dos campos no copybook. Deve dar 120. Está dando 121."},
{"id":"INJ-016","t":"Copybook CPCNT001 sem sinal no saldo","cat":"copybook","dif":"pleno","tmp":"35min","arqs":["CPCNT001.cpy"],"desc":"PIC S9(13)V99 virou PIC 9(13)V99 — sem sinal. Débitos não subtraem.","sintoma":"Saldos incorretos. Conciliação diverge. Valores absurdos após débitos.","dica":"Verifique definição do campo de saldo no CPCNT001. Campos monetários precisam de S."},
{"id":"INJ-017","t":"COMBO: bug validação + massa corrompida","cat":"combinado","dif":"pleno","tmp":"45min","arqs":["EBVALI01.cbl","lancamentos_d0.txt"],"desc":"Dois problemas: EBVALI01 rejeita créditos E massa tem valores com letras.","sintoma":"Rejeição massiva. Parte é bug do programa, parte é massa ruim. Separe as causas.","dica":"Analise os motivos de rejeição: TIPO INVALIDO (bug) vs VALOR INVALIDO (massa)."},
{"id":"INJ-018","t":"COMBO: JCL errado + copybook deslocado","cat":"combinado","dif":"pleno","tmp":"50min","arqs":["EBJVALD.jcl","CPLCT001.cpy"],"desc":"STEPLIB errada E campo deslocado no copybook. Dois problemas em camadas.","sintoma":"Primeiro: S806. Após corrigir: campos errados. Precisa resolver em duas etapas.","dica":"Resolva na ordem: primeiro JCL (STEPLIB), depois copybook (soma dos campos)."},
{"id":"INJ-019","t":"Arquivo de entrada renomeado — ausente","cat":"massa","dif":"junior","tmp":"10min","arqs":["lancamentos_d0.txt"],"desc":"Dataset ARQ.ENTRADA.SEQ deletado no remoto (local intacto).","sintoma":"Arquivo de entrada não existe para EBJLOAD/EBJVALD. Cadeia bloqueada.","dica":"Liste os datasets via Zowe. O membro foi deletado, não o arquivo local."},
{"id":"INJ-020","t":"EBJSALD com TYPRUN=HOLD","cat":"jcl","dif":"junior","tmp":"10min","arqs":["EBJSALD.jcl"],"desc":"TYPRUN=HOLD adicionado ao cartão JOB do EBJSALD. Job não executa automaticamente.","sintoma":"Job é submetido mas fica em HOLD. Não aparece como executado no SDSF.","dica":"Verifique o cartão JOB no JCL. Procure por TYPRUN=HOLD."},
{"id":"INJ-021","t":"EBPOST01 sem IS NUMERIC antes de comparação","cat":"cobol","dif":"pleno","tmp":"30min","arqs":["EBPOST01.cbl"],"desc":"Checagem IS NUMERIC removida antes da comparação de valor no EBPOST01. Dado sujo causa S0C7.","sintoma":"Se a massa tiver valor não-numérico, o programa abenda com S0C7 no MOVE ou COMPUTE.","dica":"Procure onde MV-VALOR é comparado ou movido. A checagem IS NUMERIC deveria existir antes."},
{"id":"INJ-022","t":"EBJPOST com REGION=1K — insuficiente","cat":"jcl","dif":"junior","tmp":"10min","arqs":["EBJPOST.jcl"],"desc":"REGION=1K adicionado ao JCL do EBJPOST. Memória insuficiente para o programa.","sintoma":"Abend S878 — REGION insuficiente.","dica":"Verifique o cartão JOB ou EXEC no JCL. REGION muito baixo."},
{"id":"INJ-023","t":"EBPOST01 — ACCEPT com PIC errado","cat":"cobol","dif":"junior","tmp":"20min","arqs":["EBPOST01.cbl"],"desc":"Campo de data para auditoria trocado de PIC 9(8) para PIC X(8). ACCEPT FROM DATE grava lixo.","sintoma":"Registros de auditoria com data/hora ilegíveis ou zeradas.","dica":"Verifique a definição dos campos WS-DATA e WS-HORA na WORKING-STORAGE."},
{"id":"INJ-024","t":"Massa com caracteres UTF-8 no histórico","cat":"massa","dif":"junior","tmp":"15min","arqs":["lancamentos_d0.txt"],"desc":"Campo de histórico de alguns registros contém acentos UTF-8 (ã, é, ç). Em EBCDIC, isso corrompe.","sintoma":"Campos desalinhados ou lixo no histórico após upload para z/OS.","dica":"Examine o campo de histórico (posições 34-63) nos registros alterados."},
{"id":"INJ-025","t":"EBJCONC com dataset errado no MOVTIN","cat":"jcl","dif":"junior","tmp":"10min","arqs":["EBJCONC.jcl"],"desc":"DD MOVTIN no EBJCONC aponta para ARQ.ENTRADA.SEQ em vez de ARQ.LANCTO.ESDS.","sintoma":"EBJCONC lê arquivo errado. Conciliação diverge completamente.","dica":"Compare o DD MOVTIN com o mapa de datasets. EBJCONC lê lançamentos aprovados, não entrada bruta."},
{"id":"INJ-026","t":"EBJSNAP sem DD SNAPOUT","cat":"jcl","dif":"junior","tmp":"10min","arqs":["EBJSNAP.jcl"],"desc":"DD SNAPOUT removido do EBJSNAP. Programa EBSNAP01 não tem onde gravar a geração nova do SALDO.GDG.","sintoma":"FILE STATUS 35 ao abrir saída. Snapshot não é criado. EBJCONC vai divergir na seção S3 por falta de SALDO.GDG(+1).","dica":"Compare os DDNAMEs do JCL com os SELECT do EBSNAP01 (CONTA, SNAPOUT)."},
{"id":"INJ-027","t":"Seed de contas com saldo inicial corrompido","cat":"massa","dif":"pleno","tmp":"25min","arqs":["contas.txt"],"desc":"Campo de saldo inicial em contas.txt alterado com letras. Carga inicial grava lixo no VSAM.","sintoma":"EBCLLOAD carrega, mas saldos ficam inconsistentes. EBPOST01 e EBCONC01 divergem.","dica":"Examine o campo de saldo no contas.txt e compare com o layout do CPCNT001."},
{"id":"INJ-028","t":"EBJPOST sem DD CLIENTE","cat":"jcl","dif":"junior","tmp":"10min","arqs":["EBJPOST.jcl"],"desc":"DD CLIENTE removido do EBJPOST. Programa não consegue acessar cadastro de clientes.","sintoma":"FILE STATUS 35 ao abrir ARQ.CLIENTE.KSDS. Programa abenda ou rejeita tudo.","dica":"Compare os DDNAMEs do JCL com os SELECT do EBPOST01."},
{"id":"INJ-029","t":"EBPOST01 sem REWRITE — saldo nunca persiste","cat":"cobol","dif":"pleno","tmp":"35min","arqs":["EBPOST01.cbl"],"desc":"REWRITE CONTA-REG removido do EBPOST01. O programa calcula o novo saldo mas não grava de volta.","sintoma":"EBJPOST executa RC=00, mas saldos no VSAM permanecem inalterados. Conciliação diverge.","dica":"Procure o parágrafo 2200-ATUALIZAR-SALDO. O REWRITE deveria estar logo após o EVALUATE."},
{"id":"INJ-030","t":"EBJCLLD com DDNAMEs trocados (cliente↔conta)","cat":"jcl","dif":"pleno","tmp":"25min","arqs":["EBJCLLD.jcl"],"desc":"DDs CLIENTIN e CONTAIN trocados. Programa lê contas como clientes e vice-versa.","sintoma":"Carga aparentemente ok (RC=00) mas dados cruzados. Clientes no KSDS de contas.","dica":"Compare CLIENTIN e CONTAIN no JCL com o que o EBCLLOAD espera de cada DD."},
{"id":"INJ-031","t":"Massa toda de crédito — sem débitos","cat":"massa","dif":"junior","tmp":"15min","arqs":["lancamentos_d0.txt"],"desc":"Todos os registros do lancamentos_d0.txt foram alterados para tipo 'C'. Nenhum débito no dia.","sintoma":"Saldos só crescem, nunca diminuem. Pode ser legítimo ou indicar falha no gerador de massa.","dica":"Examine o campo de tipo (posição 21) de todos os registros. Todos são 'C'."},
{"id":"INJ-032","t":"EBVALI01 sem IS NUMERIC na agência","cat":"cobol","dif":"pleno","tmp":"25min","arqs":["EBVALI01.cbl"],"desc":"Checagem IS NUMERIC removida da validação de agência. MOVE direto para campo numérico.","sintoma":"Se massa tiver agência com letras, MOVE para WS-AGENCIA-NUM causa S0C7.","dica":"Procure a Regra 2 (agência) no 2100-VALIDAR-REGISTRO. O IF IS NUMERIC deveria estar lá."},
{"id":"INJ-033","t":"COMBO: arquivo ausente + JCL com HOLD","cat":"combinado","dif":"pleno","tmp":"35min","arqs":["lancamentos_d0.txt","EBJSNAP.jcl"],"desc":"Massa deletada no remoto E EBJSNAP com TYPRUN=HOLD. Dois bloqueios em pontos diferentes da cadeia.","sintoma":"Primeiro: EBJWAIT não acha STAGE.ENTRADA.SEQ. Segundo: mesmo após resolver e a cadeia andar até EBJCUTF, EBJSNAP trava em HOLD e nunca gera SALDO.GDG(+1).","dica":"Resolva na ordem: primeiro o arquivo (re-upload), depois o JCL (remover TYPRUN=HOLD)."},
{"id":"INJ-034","t":"COMBO: sem REWRITE + seed corrompida","cat":"combinado","dif":"pleno","tmp":"50min","arqs":["EBPOST01.cbl","contas.txt"],"desc":"EBPOST01 sem REWRITE (saldo não persiste) E contas.txt com saldo corrompido.","sintoma":"Mesmo corrigindo o REWRITE, a base já tem dados ruins. Precisa corrigir programa E seed.","dica":"Resolva o REWRITE primeiro, depois investigue por que os saldos base estão errados."},
{"id":"INJ-042","t":"S0C7: Falha de Input Sanitization","cat":"cobol","dif":"pleno","tmp":"30min","arqs":["EBVALI01.cbl"],"desc":"Remove o guard IS NUMERIC antes de operações aritméticas. Dados externos com espaços causarão abend.","sintoma":"Job EBJVALD estoura com S0C7 (Data Exception) ao processar campos de valor com espaços.","dica":"Procure onde campos de arquivo externo são movidos para campos de cálculo sem validação prévia."},
{"id":"INJ-043","t":"Saldo Zerado: CALL sem ON EXCEPTION","cat":"cobol","dif":"pleno","tmp":"45min","arqs":["EBPOST01.cbl"],"desc":"Remove o tratamento de erro em chamadas de subprogramas. Se o módulo falhar, o erro é ignorado.","sintoma":"Saldos aparecem zerados no extrato ou auditoria porque o subprograma de cálculo falhou e o chamador não percebeu.","dica":"Verifique a instrução CALL e a ausência da cláusula ON EXCEPTION."},
{"id":"INJ-044","t":"Arredondamento Bancário Incorreto","cat":"cobol","dif":"pleno","tmp":"40min","arqs":["EBPOST01.cbl"],"desc":"Substitui o arredondamento manual pela cláusula ROUNDED padrão do COBOL (Half-up).","sintoma":"Divergência de centavos na conciliação no final do lote devido ao erro de acumulação de arredondamento.","dica":"O banco exige Banker's Rounding (arredondar para o par mais próximo), não o ROUNDED comum."},
{"id":"INJ-045","t":"Inconsistência: INITIALIZE esquecido no Loop","cat":"cobol","dif":"junior","tmp":"25min","arqs":["EBVALI01.cbl"],"desc":"Comenta o INITIALIZE de acumuladores dentro do loop de leitura.","sintoma":"Registros processados com sucesso começam a somar valores do registro anterior. Erro intermitente.","dica":"Verifique se as variáveis de trabalho são limpas a cada iteração do READ."},
{"id":"INJ-046","t":"File Status 35 Ignorado","cat":"cobol","dif":"pleno","tmp":"30min","arqs":["EBVALI01.cbl"],"desc":"O programa abre um arquivo, o status é 35 (não encontrado), mas o programa continua lendo 'nada'.","sintoma":"Job termina RC=00 mas não processa nenhum registro, pois o OPEN falhou silenciosamente.","dica":"Compare o parágrafo de OPEN com a tabela de códigos de erro de File Status."},
{"id":"INJ-047","t":"S0C4: Subscript fora do OCCURS","cat":"cobol","dif":"pleno","tmp":"50min","arqs":["EBPOST01.cbl"],"desc":"Reduz o tamanho de uma tabela (OCCURS) interna para simular estouro de memória em produção.","sintoma":"Abend S0C4 (Protection Exception) ao tentar acessar um índice de conta inexistente na tabela.","dica":"Verifique se o contador do loop ultrapassa o limite definido na Working-Storage."},
{"id":"INJ-051","t":"Mismatch de Atributos (Status 39)","cat":"jcl","dif":"pleno","tmp":"20min","arqs":["EBJPOST.jcl"],"desc":"Altera o LRECL no JCL para um valor diferente do definido na FD do COBOL.","sintoma":"O programa recusa a abertura do arquivo com FILE STATUS 39 logo no início.","dica":"Verifique se os atributos físicos definidos no IDCAMS/JCL batem com a SELECT/ASSIGN."},
{"id":"INJ-053","t":"Falha Crítica de Fluxo JCL (COND)","cat":"jcl","dif":"junior","tmp":"15min","arqs":["EBJPOST.jcl"],"desc":"Remove o parâmetro COND do step de posting, permitindo que rode mesmo se a validação falhar.","sintoma":"Dados inválidos são postados no banco de dados porque o job de atualização ignorou o erro do job anterior.","dica":"Examine os códigos de retorno (RC) no SDSF e veja se o JCL respeitou a hierarquia."},
{"id":"INJ-RAND-01","t":"Corrupção Aleatória de Variável","cat":"aleatorio","dif":"pleno","tmp":"?","arqs":["EBVALI01.cbl"],"desc":"Remove uma letra de uma variável de trabalho no meio da Procedure Division.","sintoma":"Erro de compilação estranho ou comportamento imprevisível em tempo de execução.","dica":"O compilador avisará que a variável não está definida, ou você verá um campo deslocado."}
]

INJ_MAP = {i["id"]: i for i in INJECTIONS}

# ═════════════════════════════════════════════════════════════
# RESOLUÇÃO DE PATHS LOCAIS (apenas leitura — nada é gravado)
# ═════════════════════════════════════════════════════════════
def _rf(p):
    with open(p,'r',encoding='utf-8',errors='replace') as f: return f.read()

def _root(d): return os.path.dirname(os.path.dirname(d))
def _jcl(d):
    j = os.path.join(_root(d), 'jcl', 'batch')
    return j if os.path.isdir(j) else d
def _copy(d):
    c = os.path.join(_root(d), 'copybooks', 'layouts')
    return c if os.path.isdir(c) else d
def _data_in(d):
    e = os.path.join(_root(d), 'data', 'entrada')
    return e if os.path.isdir(e) else d
def _data_seed(d):
    s = os.path.join(_root(d), 'data', 'seed')
    return s if os.path.isdir(s) else d

def _resolve_file(proj, filename):
    for candidate in [
        os.path.join(proj, filename),
        os.path.join(_jcl(proj), filename),
        os.path.join(_copy(proj), filename),
        os.path.join(_data_in(proj), filename),
        os.path.join(_data_seed(proj), filename),
    ]:
        if os.path.isfile(candidate): return candidate
    return None

def _expected_path(proj, filename):
    existing = _resolve_file(proj, filename)
    if existing:
        return existing
    ext = os.path.splitext(filename)[1].lower()
    if ext in ('.jcl', '.proc'):
        return os.path.join(_jcl(proj), filename)
    if ext in ('.cbl', '.cpy'):
        return os.path.join(_copy(proj), filename)
    return os.path.join(proj, filename)

# ═════════════════════════════════════════════════════════════
# MAPA LOCAL → DATASET REMOTO
# ═════════════════════════════════════════════════════════════
HLQ = os.environ.get("EBOPS_HLQ", "Z77948.EMUNAH")

DS_MAP = {
    "EBVALI01.cbl": f"{HLQ}.DEV.SOURCE(EBVALI01)",
    "EBPOST01.cbl": f"{HLQ}.DEV.SOURCE(EBPOST01)",
    "EBJVALD.jcl":  f"{HLQ}.DEV.JCL(EBJVALD)",
    "EBJPOST.jcl":  f"{HLQ}.DEV.JCL(EBJPOST)",
    "EBJSNAP.jcl":  f"{HLQ}.DEV.JCL(EBJSNAP)",
    "EBJSALD.jcl":  f"{HLQ}.DEV.JCL(EBJSALD)",
    "EBJCONC.jcl":  f"{HLQ}.DEV.JCL(EBJCONC)",
    "EBJCLLD.jcl":  f"{HLQ}.DEV.JCL(EBJCLLD)",
    "EBJALL.jcl":   f"{HLQ}.DEV.JCL(EBJALL)",
    "CPLCT001.cpy": f"{HLQ}.DEV.COPYLIB(CPLCT001)",
    "CPCNT001.cpy": f"{HLQ}.DEV.COPYLIB(CPCNT001)",
    "lancamentos_d0.txt": f"{HLQ}.STAGE.ENTRADA.SEQ",
    "contas.txt":         f"{HLQ}.SEED.CONTAS.SEQ",
}

def _ds_member_for(filename: str) -> str:
    if filename in DS_MAP: return DS_MAP[filename]
    ext = os.path.splitext(filename)[1].lower()
    base = os.path.splitext(os.path.basename(filename))[0].upper()
    if ext == ".jcl": return f"{HLQ}.DEV.JCL({base})"
    if ext == ".cbl": return f"{HLQ}.DEV.SOURCE({base})"
    if ext == ".cpy": return f"{HLQ}.DEV.COPYLIB({base})"
    return f"{HLQ}.DEV.MISC({base})"

# ═════════════════════════════════════════════════════════════
# HELPERS ZOWE
# ═════════════════════════════════════════════════════════════
def _zowe_check():
    try:
        r = subprocess.run(["zowe","--version"], capture_output=True, text=True, timeout=10)
        return r.returncode == 0
    except: return False

def _zowe_upload_text(content, dataset_member):
    try:
        r = subprocess.run(
            ["zowe","files","upload","stdin-to-data-set", dataset_member],
            input=content, text=True, capture_output=True, timeout=120
        )
        return r.returncode == 0, (r.stderr or r.stdout).strip()
    except Exception as e:
        return False, str(e)

def _zowe_download(dataset_member, local_path):
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    try:
        r = subprocess.run(
            ["zowe","files","download","data-set", dataset_member,
             "-f", local_path, "--binary","false"],
            capture_output=True, text=True, timeout=120
        )
        return r.returncode == 0, (r.stderr or r.stdout).strip()
    except Exception as e:
        return False, str(e)

def _zowe_delete_member(dataset_member):
    try:
        r = subprocess.run(
            ["zowe","files","delete","data-set", dataset_member,"-f"],
            capture_output=True, text=True, timeout=60
        )
        return r.returncode == 0, (r.stderr or r.stdout).strip()
    except Exception as e:
        return False, str(e)

def _snapshot_dir(proj, inj_id):
    p = os.path.join(_root(proj), SNAPSHOT_REL, inj_id)
    os.makedirs(p, exist_ok=True)
    return p

# ═════════════════════════════════════════════════════════════
# REGISTRO DE MUTAÇÕES
# Cada @mut DEVE retornar dict {filename: novo_conteudo}.
# Use None como conteúdo para sinalizar DELETE remoto.
# ═════════════════════════════════════════════════════════════
MUTATIONS = {}
def mut(name):
    def decorator(fn):
        MUTATIONS[name] = fn; return fn
    return decorator

REVERTS = {}
def rev(name):
    def decorator(fn):
        REVERTS[name] = fn; return fn
    return decorator

def _read_local(proj, filename):
    p = _resolve_file(proj, filename)
    if not p: raise FileNotFoundError(filename)
    return _rf(p)

# ═════════════════════════════════════════════════════════════
# MUTAÇÕES (todas em memória)
# ═════════════════════════════════════════════════════════════
@mut("INJ-001")
def _(d):
    s = _read_local(d, "EBVALI01.cbl")
    old = """           IF LCT-TIPO OF ENTRADA-REG NOT = 'C'
              AND LCT-TIPO OF ENTRADA-REG NOT = 'D'"""
    new = """           IF LCT-TIPO OF ENTRADA-REG NOT = 'D'
                                                   """
    return {"EBVALI01.cbl": s.replace(old, new)}

@mut("INJ-002")
def _(d):
    s = _read_local(d, "EBVALI01.cbl")
    old = """           IF REG-VALIDO AND
              LCT-VALOR OF ENTRADA-REG <= ZERO"""
    new = """           IF REG-VALIDO AND
              LCT-VALOR OF ENTRADA-REG < ZERO """
    return {"EBVALI01.cbl": s.replace(old, new)}

@mut("INJ-003")
def _(d):
    s = _read_local(d, "EBVALI01.cbl")
    old = """           IF NOT FS-ENTRADA-OK
               DISPLAY '*** EBVALI01 ERRO OPEN ENTRADA - ' WS-FS-ENTRADA
               SET COM-ERRO TO TRUE
           END-IF"""
    new = """      *    IF NOT FS-ENTRADA-OK
      *        DISPLAY '*** EBVALI01 ERRO OPEN ENTRADA - ' WS-FS-ENTRADA
      *        SET COM-ERRO TO TRUE
      *    END-IF"""
    return {"EBVALI01.cbl": s.replace(old, new)}

@mut("INJ-004")
def _(d):
    s = _read_local(d, "EBVALI01.cbl")
    old1 = """               MOVE 'TIPO INVALIDO ' TO WS-REJ-DESC
               SET REG-INVALIDO TO TRUE
           END-IF"""
    new1 = """               MOVE 'TIPO INVALIDO ' TO WS-REJ-DESC
               SET REG-INVALIDO TO TRUE
               GO TO 2100-FIM-VALIDACAO
           END-IF"""
    old2 = """      *--- Encaminha para valido ou rejeito ----------------------------*"""
    new2 = """       2100-FIM-VALIDACAO.
      *--- Encaminha para valido ou rejeito ----------------------------*"""
    s = s.replace(old1, new1).replace(old2, new2)
    return {"EBVALI01.cbl": s}

@mut("INJ-005")
def _(d):
    s = _read_local(d, "EBPOST01.cbl")
    s = s.replace("= 'C'","= 'TEMP_SWAP'").replace("= 'D'","= 'C'").replace("= 'TEMP_SWAP'","= 'D'")
    return {"EBPOST01.cbl": s}

@mut("INJ-006")
def _(d):
    s = _read_local(d, "EBPOST01.cbl")
    return {"EBPOST01.cbl": s.replace("ASSIGN TO AUDIT","ASSIGN TO AUDITLOG")}

@mut("INJ-007")
def _(d):
    s = _read_local(d, "EBJVALD.jcl")
    return {"EBJVALD.jcl": s.replace("DEV.LOADLIB","HML.LOADLIB")}

@mut("INJ-008")
def _(d):
    s = _read_local(d, "EBJPOST.jcl")
    return {"EBJPOST.jcl": s.replace("ARQ.AUDIT.SEQ,DISP=MOD","ARQ.AUDIT.SEQ,DISP=SHR")}

@mut("INJ-009")
def _(d):
    s = _read_local(d, "EBJVALD.jcl")
    lines = [l for l in s.split('\n')
             if '//REJEITOS' not in l
             and not ('rejeitados' in l.lower() and l.startswith('//*'))]
    return {"EBJVALD.jcl": '\n'.join(lines)}

@mut("INJ-010")
def _(d):
    s = _read_local(d, "EBJPOST.jcl")
    return {"EBJPOST.jcl": s.replace("ARQ.LANCTO.ESDS","ARQ.LANCAMENTO.ESDS")}

@mut("INJ-011")
def _(d):
    lines = _read_local(d, "lancamentos_d0.txt").split('\n')
    for i in [1,4]:
        if i<len(lines) and len(lines[i])>=34:
            l=list(lines[i]); l[21]='A'; l[22]='B'; l[23]='C'; lines[i]=''.join(l)
    return {"lancamentos_d0.txt": '\n'.join(lines)}

@mut("INJ-012")
def _(d):
    lines = _read_local(d, "lancamentos_d0.txt").split('\n')
    for i in [2,6]:
        if i<len(lines) and len(lines[i])>=21:
            l=list(lines[i]); l[20]='X'; lines[i]=''.join(l)
    return {"lancamentos_d0.txt": '\n'.join(lines)}

@mut("INJ-013")
def _(d):
    lines = _read_local(d, "lancamentos_d0.txt").split('\n')
    for i in [3,7]:
        if i<len(lines) and len(lines[i])>80: lines[i]=lines[i][:80]
    return {"lancamentos_d0.txt": '\n'.join(lines)}

@mut("INJ-014")
def _(d):
    lines = _read_local(d, "lancamentos_d0.txt").split('\n')
    for i in [0,5]:
        if i<len(lines) and len(lines[i])>=12:
            l=list(lines[i]); l[4:12]=list('99999999'); lines[i]=''.join(l)
    return {"lancamentos_d0.txt": '\n'.join(lines)}

@mut("INJ-015")
def _(d):
    s = _read_local(d, "CPLCT001.cpy")
    s = re.sub(r'(LCT-TIPO\s+PIC\s+X\()01(\))', r'\g<1>02\2', s)
    return {"CPLCT001.cpy": s}

@mut("INJ-016")
def _(d):
    s = _read_local(d, "CPCNT001.cpy")
    s = re.sub(r'(CNT-SALDO\s+PIC\s+)S(9)', r'\g<1>\2', s, count=1)
    return {"CPCNT001.cpy": s}

@mut("INJ-017")
def _(d):
    out = {}
    out.update(MUTATIONS["INJ-001"](d))
    out.update(MUTATIONS["INJ-011"](d))
    return out

@mut("INJ-018")
def _(d):
    out = {}
    out.update(MUTATIONS["INJ-007"](d))
    out.update(MUTATIONS["INJ-015"](d))
    return out

@mut("INJ-019")
def _(d):
    return {"lancamentos_d0.txt": None}

@mut("INJ-020")
def _(d):
    s = _read_local(d, "EBJSNAP.jcl")
    return {"EBJSNAP.jcl": s.replace("CLASS=A,MSGCLASS=X","CLASS=A,MSGCLASS=X,TYPRUN=HOLD")}

@mut("INJ-021")
def _(d):
    s = _read_local(d, "EBPOST01.cbl")
    s = s.replace(
        "IF MV-VALOR <= ZERO",
        "IF MV-VALOR NOT NUMERIC\n               CONTINUE\n           ELSE\n           IF MV-VALOR <= ZERO"
    )
    return {"EBPOST01.cbl": s}

@mut("INJ-022")
def _(d):
    s = _read_local(d, "EBJPOST.jcl")
    return {"EBJPOST.jcl": s.replace("EXEC PGM=EBPOST01","EXEC PGM=EBPOST01,REGION=1K")}

@mut("INJ-023")
def _(d):
    s = _read_local(d, "EBPOST01.cbl")
    s = re.sub(r'(WS-DATA-AUDIT\s+PIC\s+)9\(8\)', r'\g<1>X(8)', s, count=1)
    s = re.sub(r'(WS-HORA-AUDIT\s+PIC\s+)9\(6\)', r'\g<1>X(6)', s, count=1)
    return {"EBPOST01.cbl": s}

@mut("INJ-024")
def _(d):
    lines = _read_local(d, "lancamentos_d0.txt").split('\n')
    for i in [0,3,6]:
        if i<len(lines) and len(lines[i])>=63:
            l=list(lines[i])
            l[34]='D'; l[35]='E'; l[36]='P'; l[37]='Ó'; l[38]='S'
            l[39]='I'; l[40]='T'; l[41]='O'; l[42]=' '; l[43]='I'
            l[44]='N'; l[45]='I'; l[46]='C'; l[47]='I'; l[48]='A'; l[49]='L'
            lines[i]=''.join(l)
    return {"lancamentos_d0.txt": '\n'.join(lines)}

@mut("INJ-025")
def _(d):
    s = _read_local(d, "EBJCONC.jcl")
    return {"EBJCONC.jcl": s.replace("ARQ.LANCTO.ESDS","ARQ.ENTRADA.SEQ")}

@mut("INJ-026")
def _(d):
    s = _read_local(d, "EBJSNAP.jcl")
    lines = [l for l in s.split('\n') if 'SNAPOUT' not in l and 'SNAP-OUT' not in l]
    return {"EBJSNAP.jcl": '\n'.join(lines)}

@mut("INJ-027")
def _(d):
    lines = _read_local(d, "contas.txt").split('\n')
    for i in [0,2]:
        if i<len(lines) and len(lines[i])>=40:
            l=list(lines[i]); l[30]='X'; l[31]='X'; l[32]='X'; lines[i]=''.join(l)
    return {"contas.txt": '\n'.join(lines)}

@mut("INJ-028")
def _(d):
    s = _read_local(d, "EBJPOST.jcl")
    lines = [l for l in s.split('\n')
             if '//CLIENTE' not in l
             and not('clientes' in l.lower() and l.startswith('//*'))]
    return {"EBJPOST.jcl": '\n'.join(lines)}

@mut("INJ-029")
def _(d):
    s = _read_local(d, "EBPOST01.cbl")
    s = s.replace("            REWRITE CONTA-REG","      *    REWRITE CONTA-REG")
    return {"EBPOST01.cbl": s}

@mut("INJ-030")
def _(d):
    s = _read_local(d, "EBJCLLD.jcl")
    s = s.replace(
        "//CLIENTIN DD DSN=Z77948.EMUNAH.SEED.CLIENTES.SEQ",
        "//CLIENTIN DD DSN=Z77948.EMUNAH.SEED.CONTAS.SEQ"
    )
    s = s.replace(
        "//CONTAIN  DD DSN=Z77948.EMUNAH.SEED.CONTAS.SEQ",
        "//CONTAIN  DD DSN=Z77948.EMUNAH.SEED.CLIENTES.SEQ"
    )
    return {"EBJCLLD.jcl": s}

@mut("INJ-031")
def _(d):
    lines = _read_local(d, "lancamentos_d0.txt").split('\n')
    for i in range(len(lines)):
        if len(lines[i])>=21:
            l=list(lines[i]); l[20]='C'; lines[i]=''.join(l)
    return {"lancamentos_d0.txt": '\n'.join(lines)}

@mut("INJ-032")
def _(d):
    s = _read_local(d, "EBVALI01.cbl")
    old = "            IF EN-AGENCIA IS NUMERIC\n                MOVE EN-AGENCIA TO WS-AGENCIA-NUM"
    new = "                MOVE EN-AGENCIA TO WS-AGENCIA-NUM"
    s = s.replace(old, new)
    s = s.replace(
        "            ELSE\n                SET REGISTRO-INVALIDO TO TRUE\n                MOVE 'AGENCIA INVALIDA' TO WS-NOVO-MOTIVO\n                PERFORM 2300-ACUMULAR-MOTIVO\n            END-IF\n\n      *    Regra 3:",
        "            END-IF\n\n      *    Regra 3:"
    )
    return {"EBVALI01.cbl": s}

@mut("INJ-033")
def _(d):
    out = {}
    out.update(MUTATIONS["INJ-019"](d))
    out.update(MUTATIONS["INJ-020"](d))
    return out

@mut("INJ-034")
def _(d):
    out = {}
    out.update(MUTATIONS["INJ-029"](d))
    out.update(MUTATIONS["INJ-027"](d))
    return out

@mut("INJ-042")
def _(d):
    s = _read_local(d, "EBVALI01.cbl")
    s = re.sub(r"IF\s+[A-Za-z0-9\-]+\s+IS\s+NUMERIC", "IF 1 = 1", s, flags=re.IGNORECASE)
    return {"EBVALI01.cbl": s}

@mut("INJ-043")
def _(d):
    s = _read_local(d, "EBPOST01.cbl")
    s = re.sub(r"ON\s+EXCEPTION.*?END-CALL", "END-CALL", s, flags=re.DOTALL | re.IGNORECASE)
    return {"EBPOST01.cbl": s}

@mut("INJ-044")
def _(d):
    s = _read_local(d, "EBPOST01.cbl")
    s = re.sub(r"(COMPUTE\s+[A-Za-z0-9\-]+)\s*=", r"\1 ROUNDED =", s, flags=re.IGNORECASE)
    return {"EBPOST01.cbl": s}

@mut("INJ-045")
def _(d):
    s = _read_local(d, "EBVALI01.cbl")
    s = re.sub(r"(\s+INITIALIZE\s+WS-[A-Za-z0-9\-]+)", r"      * \1", s, flags=re.IGNORECASE)
    return {"EBVALI01.cbl": s}

@mut("INJ-046")
def _(d):
    s = _read_local(d, "EBVALI01.cbl")
    s = re.sub(r"IF\s+FS-[A-Za-z0-9\-]+\s+NOT\s*=\s*'00'.*?END-IF\.",
               "           CONTINUE.", s, flags=re.DOTALL | re.IGNORECASE)
    return {"EBVALI01.cbl": s}

@mut("INJ-047")
def _(d):
    s = _read_local(d, "EBPOST01.cbl")
    s = re.sub(r"OCCURS\s+([0-9]+)", "OCCURS 2", s, flags=re.IGNORECASE)
    return {"EBPOST01.cbl": s}

@mut("INJ-051")
def _(d):
    s = _read_local(d, "EBJPOST.jcl")
    s = re.sub(r"LRECL=([0-9]+)", "LRECL=99", s, flags=re.IGNORECASE)
    return {"EBJPOST.jcl": s}

@mut("INJ-053")
def _(d):
    s = _read_local(d, "EBJPOST.jcl")
    s = re.sub(r",COND=\([0-9]+,[A-Z]+\)", "", s, flags=re.IGNORECASE)
    return {"EBJPOST.jcl": s}

@mut("INJ-RAND-01")
def _(d):
    s = _read_local(d, "EBVALI01.cbl")
    vars_ = re.findall(r"WS-[A-Za-z0-9\-]+", s)
    if vars_:
        target = random.choice(vars_)
        s = s.replace(target, target[:-1], 1)
    return {"EBVALI01.cbl": s}

# ═════════════════════════════════════════════════════════════
# GRADE BATCH / DISPLAY
# ═════════════════════════════════════════════════════════════
GRADE=[("EBJPRECK","05:45","—"),
       ("EBJSOD",  "06:00","—"),
       ("EBJBCKPD","06:15","—"),
       ("EBJWAIT", "06:30","—"),
       ("EBJLOAD", "06:45","—"),
       ("EBJVALD", "07:00","EBVALI01"),
       ("EBJPOST", "07:30","EBPOST01"),
       ("EBJCUTF", "08:00","—"),
       ("EBJACCR", "08:15","EBACCR01"),
       ("EBJSNAP", "08:30","EBSNAP01"),
       ("EBJCUTE", "08:45","—"),
       ("EBJCONC", "09:00","EBCONC01"),
       ("EBJEXTR", "09:30","EBEXTR01"),
       ("EBJEOD",  "10:00","EBJEOD01")]

STATUS_LABELS={"backlog":"Backlog","em_andamento":"Em Andamento","em_revisao":"Em Revisão","concluido":"Concluído"}
CAT_ICONS={"incidente":"🔥","desenvolvimento":"⚙️","operação":"📋","change":"🔄","investigação":"🔍"}
SEV_COLORS={"critica":C.RD,"alta":C.YL,"media":C.CY,"baixa":C.GR}
DIF_COLORS={"junior":C.BL,"pleno":C.MG}

def header():
    print(f"\n{C.GR}{C.B}╔══════════════════════════════════════════════════════════════╗")
    print(f"║  EBOPS — Emunah Bank Operations Simulator (Ghost Edition)    ║")
    print(f"╚══════════════════════════════════════════════════════════════╝{C.R}\n")

def show_batch(fail=False):
    if not fail:
        jobs = [(j,h,p,"ok","0000") for j,h,p in GRADE]
    else:
        fi=random.randint(0,len(GRADE)-1)
        ft=random.choice(["error","warning","hold"])
        jobs=[]
        for i,(j,h,p) in enumerate(GRADE):
            if i<fi: jobs.append((j,h,p,"ok","0000"))
            elif i==fi: jobs.append((j,h,p,ft,"0012" if ft=="error" else "0004" if ft=="warning" else "HOLD"))
            else: jobs.append((j,h,p,"pending","----"))
    icons={"ok":"✓","error":"✗","warning":"⚠","hold":"⏸","pending":"◌","running":"▶"}
    colors={"ok":C.GR,"error":C.RD,"warning":C.YL,"hold":C.MG,"pending":C.D,"running":C.BL}
    print(f"  {C.GR}{C.B}⏱ CONTROL-M — Grade Batch{C.R}")
    for j,h,p,st,rc in jobs:
        c=colors[st]; ic=icons[st]
        print(f"    {c}{ic} {h} {C.B}{j:10}{C.R}{c} {p:10} RC={rc}{C.R}")
    print(f"  {C.D}PRECK→SOD→BCKPD→WAIT→LOAD→VALD→POST→CUTF→ACCR→SNAP→CUTE→CONC→EXTR→EOD{C.R}\n")
    return jobs

# ═════════════════════════════════════════════════════════════
# INJEÇÃO / REVERT / SPY / SUBMIT-ALL
# ═════════════════════════════════════════════════════════════
def do_inject(proj, inj_id, state, confirm=True):
    inj = INJ_MAP.get(inj_id)
    if not inj:
        print(f"  {C.RD}Injeção {inj_id} não encontrada.{C.R}"); return False
    if inj_id in [a["id"] for a in state["injections_active"]]:
        print(f"  {C.YL}{inj_id} já está ativo.{C.R}"); return False
    if not _zowe_check():
        print(f"  {C.RD}Zowe CLI não encontrado no PATH.{C.R}"); return False

    fn = MUTATIONS.get(inj_id)
    if not fn:
        print(f"  {C.RD}Mutação não implementada.{C.R}"); return False

    try:
        mutated = fn(proj)
    except Exception as e:
        print(f"  {C.RD}Erro na mutação: {e}{C.R}"); return False

    print(f"\n  {C.YL}{C.B}Injeção: {inj_id}{C.R} — {inj['t']}")
    print(f"  {inj['desc']}")
    print(f"  {C.D}Alvos remotos:{C.R}")
    for f, content in mutated.items():
        action = "DELETE" if content is None else "UPLOAD"
        print(f"    {C.B}{action}{C.R} {_ds_member_for(f)}")

    if confirm:
        if input(f"\n  {C.B}Confirmar? (s/N): {C.R}").strip().lower() != 's':
            print(f"  {C.D}Cancelado.{C.R}"); return False

    snap_dir = _snapshot_dir(proj, inj_id)
    snapshot_meta = []

    print(f"\n  {C.B}1/2 Backup do remoto:{C.R}")
    for filename in mutated.keys():
        ds = _ds_member_for(filename)
        snap_path = os.path.join(snap_dir, filename)
        ok, msg = _zowe_download(ds, snap_path)
        if ok:
            snapshot_meta.append((filename, ds, snap_path))
            print(f"    {C.GR}✓{C.R} {ds}")
        else:
            snapshot_meta.append((filename, ds, None))
            head = msg.splitlines()[0] if msg else 'inexistente'
            print(f"    {C.YL}!{C.R} {ds} (sem backup — {head})")

    print(f"\n  {C.B}2/2 Aplicação no remoto:{C.R}")
    aplicados = []
    for filename, content in mutated.items():
        ds = _ds_member_for(filename)
        if content is None:
            ok, msg = _zowe_delete_member(ds); tag = "DELETE"
        else:
            ok, msg = _zowe_upload_text(content, ds); tag = "UPLOAD"
        if ok:
            aplicados.append((filename, ds, tag))
            print(f"    {C.GR}✓{C.R} {tag} {ds}")
        else:
            head = msg.splitlines()[0] if msg else ''
            print(f"    {C.RD}✗{C.R} {tag} {ds} — {head}")
            for fn2, ds2, _t in aplicados:
                snap = next((s for f,d,s in snapshot_meta if f==fn2), None)
                if snap and os.path.isfile(snap):
                    _zowe_upload_text(_rf(snap), ds2)
            return False

    state["injections_active"].append({
        "id": inj_id,
        "titulo": inj["t"],
        "arquivos": list(mutated.keys()),
        "operacoes": [{"file": f, "ds": d, "action": t} for f,d,t in aplicados],
        "snapshot_dir": os.path.relpath(snap_dir, _root(proj)),
        "timestamp": datetime.now().isoformat()
    })
    save_state(proj, state)

    print(f"\n  {C.BGrd}{C.WH}{C.B} DEFEITO INJETADO NO MAINFRAME {C.R}")
    print(f"  {C.D}Working tree local: intacto. Sem spoiler no git.{C.R}")
    print(f"\n  {C.B}Sintoma:{C.R} {inj['sintoma']}")
    print(f"  {C.D}Dica: {inj['dica']}{C.R}")
    print(f"\n  Próximos passos:")
    print(f"    1. Submeta a cadeia: {C.CY}python ebops.py submit-all{C.R}")
    print(f"    2. Diagnostique pelo SDSF / spool")
    print(f"    3. Compare local × remoto: {C.CY}python ebops.py spy {inj_id}{C.R}")
    print(f"    4. Ao terminar, reverta:    {C.CY}python ebops.py revert {inj_id}{C.R}\n")
    return True

def do_revert(proj, state, inj_id=None):
    active = state["injections_active"]
    if not active:
        print(f"  {C.GR}Nenhuma injeção ativa.{C.R}\n"); return
    target = [a for a in active if a["id"]==inj_id] if inj_id else active
    if not target:
        print(f"  {C.RD}{inj_id} não está ativa.{C.R}\n"); return
    if not _zowe_check():
        print(f"  {C.RD}Zowe CLI não encontrado no PATH.{C.R}"); return

    print(f"  {C.B}Revertendo no mainframe:{C.R}")
    for a in target: print(f"    {C.CY}{a['id']}{C.R} — {a['titulo']}")
    if input(f"  {C.B}Confirmar re-upload dos snapshots? (s/N): {C.R}").strip().lower() != 's':
        return

    repo_root = _root(proj)
    for a in target:
        snap_dir = os.path.join(repo_root, a.get("snapshot_dir", os.path.join(SNAPSHOT_REL, a["id"])))
        for op in a.get("operacoes", []):
            f, ds, action = op["file"], op["ds"], op["action"]
            snap = os.path.join(snap_dir, f)
            if os.path.isfile(snap):
                ok, _ = _zowe_upload_text(_rf(snap), ds)
                print(f"    {C.GR if ok else C.RD}{'✓' if ok else '✗'}{C.R} restore {ds}")
            else:
                if action == "UPLOAD":
                    _zowe_delete_member(ds)
                    print(f"    {C.YL}!{C.R} {ds} (não existia antes — deletado)")
                else:
                    print(f"    {C.YL}!{C.R} {ds} (sem snapshot, ação era DELETE)")

    ids = {a["id"] for a in target}
    state["injections_active"] = [a for a in active if a["id"] not in ids]
    state["history"].extend(target)
    save_state(proj, state)
    print(f"\n  {C.BGr}{C.WH}{C.B} REVERTIDO {C.R}\n")

def do_spy(proj, state, inj_id=None):
    active = state["injections_active"]
    if not active:
        print(f"  {C.D}Nenhuma injeção ativa.{C.R}\n"); return
    target = [a for a in active if a["id"]==inj_id] if inj_id else active
    if not target:
        print(f"  {C.RD}{inj_id} não está ativa.{C.R}\n"); return
    if not _zowe_check():
        print(f"  {C.RD}Zowe CLI não encontrado no PATH.{C.R}"); return

    tmp_root = os.path.join(_root(proj), ".ebops", "spy")
    os.makedirs(tmp_root, exist_ok=True)

    for a in target:
        print(f"\n  {C.YL}{C.B}{a['id']}{C.R} — {a['titulo']}")
        for op in a.get("operacoes", []):
            f, ds = op["file"], op["ds"]
            print(f"\n  {C.D}── {ds}{C.R}")
            tmp = os.path.join(tmp_root, f"{a['id']}__{os.path.basename(f)}")
            ok, msg = _zowe_download(ds, tmp)
            if not ok:
                head = msg.splitlines()[0] if msg else ''
                print(f"    {C.RD}download falhou:{C.R} {head}"); continue
            local = _resolve_file(proj, f)
            if not local:
                print(f"    {C.YL}local não encontrado.{C.R}"); continue
            r = subprocess.run(["diff","-u", local, tmp], capture_output=True, text=True)
            if r.stdout.strip(): print(r.stdout)
            else: print(f"    {C.GR}(local e remoto idênticos){C.R}")

def do_submit_all(proj):
    if not _zowe_check():
        print(f"  {C.RD}Zowe CLI não encontrado no PATH.{C.R}"); return
    ds = DS_MAP.get("EBJALL.jcl", f"{HLQ}.DEV.JCL(EBJALL)")
    print(f"\n  {C.B}Submetendo cadeia completa via {ds} ...{C.R}")
    r = subprocess.run(
        ["zowe","jobs","submit","ds", ds, "--wait-for-output"],
        capture_output=True, text=True, timeout=1800
    )
    print(r.stdout)
    if r.returncode != 0:
        print(f"  {C.RD}Falha:{C.R} {r.stderr}")
    else:
        print(f"  {C.GR}Cadeia finalizada.{C.R} Inspecione spool no SDSF.\n")

# ═════════════════════════════════════════════════════════════
# GERAR DIA
# ═════════════════════════════════════════════════════════════
def gerar_dia(proj, state):
    header()
    day = state["day"]
    print(f"  {C.GR}{C.B}═══ DIA #{day} ═══{C.R}\n")

    fail = random.random() > 0.5
    batch = show_batch(fail)
    batch_problem = None
    for j,h,p,st,rc in batch:
        if st in ("error","hold","warning"):
            batch_problem = (j,st,rc); break

    if batch_problem:
        j,st,rc = batch_problem
        print(f"  {C.RD}{C.B}⚠ ALERTA:{C.R} Job {C.B}{j}{C.R} status {C.YL}{st.upper()}{C.R} RC={rc}\n")

    all_t = TEMPLATES + state.get("custom_templates", [])
    count = random.randint(2, 4)
    pool = list(all_t); random.shuffle(pool)
    tickets_novos = []

    for i in range(min(count, len(pool))):
        tmpl = pool[i]
        ticket = {
            "ticket_id": f"EB-{day:03d}-{i+1:02d}",
            "template_id": tmpl["id"],
            "titulo": tmpl["t"],
            "categoria": tmpl["cat"],
            "severidade": tmpl.get("sev","media"),
            "dificuldade": tmpl.get("dif","junior"),
            "tempo": tmpl.get("tmp","30min"),
            "ferramenta": tmpl.get("fer","Geral"),
            "descricao": tmpl.get("desc",""),
            "tags": tmpl.get("tags",[]),
            "inj": tmpl.get("inj"),
            "status": "backlog",
            "dia": day,
            "notas": "",
            "criado_em": datetime.now().isoformat()
        }
        tickets_novos.append(ticket)

    print(f"  {C.GR}{C.B}Tickets do dia ({len(tickets_novos)}):{C.R}\n")
    for tk in tickets_novos:
        sc = SEV_COLORS.get(tk["severidade"], C.CY)
        dc = DIF_COLORS.get(tk["dificuldade"], C.BL)
        icon = CAT_ICONS.get(tk["categoria"], "📌")
        has_inj = f" {C.RD}⚡ INJEÇÃO DISPONÍVEL{C.R}" if tk.get("inj") else ""
        print(f"  {C.CY}{tk['ticket_id']}{C.R} {icon} {C.B}{tk['titulo']}{C.R}")
        print(f"    [{sc}{tk['severidade'].upper()}{C.R}] [{dc}{tk['dificuldade'].upper()}{C.R}] {C.D}{tk['ferramenta']} · {tk['tempo']}{C.R}{has_inj}")
        print()

    injectables = [tk for tk in tickets_novos if tk.get("inj") and tk["inj"] in INJ_MAP]
    if injectables:
        print(f"  {C.RD}{C.B}═══ DEFEITOS REAIS DISPONÍVEIS ═══{C.R}\n")
        for tk in injectables:
            inj = INJ_MAP[tk["inj"]]
            print(f"  {C.CY}{tk['ticket_id']}{C.R} → {C.RD}{tk['inj']}{C.R}: {inj['t']}")
            print(f"    {C.D}Datasets que serão alterados no host:{C.R}")
            for f in inj['arqs']:
                print(f"      {C.D}• {_ds_member_for(f)}{C.R}")
            print(f"    {C.D}{inj['desc']}{C.R}\n")

        r = input(f"  {C.B}Injetar defeitos reais no MAINFRAME via Zowe? (s/N): {C.R}").strip().lower()
        if r == 's':
            for tk in injectables:
                print(f"\n  {C.D}{'─'*50}{C.R}")
                if do_inject(proj, tk["inj"], state, confirm=False):
                    tk["inj_ativo"] = True

    state["tickets"] = tickets_novos + state["tickets"]
    state["day"] = day + 1
    save_state(proj, state)

    print(f"\n  {C.GR}{C.B}Dia #{day} gerado.{C.R} {len(tickets_novos)} tickets no backlog.\n")

# ═════════════════════════════════════════════════════════════
# TICKETS
# ═════════════════════════════════════════════════════════════
def show_tickets(state, filtro=None):
    header()
    tickets = state["tickets"]
    if filtro:
        tickets = [t for t in tickets if filtro in (t.get("categoria",""),t.get("severidade",""),t.get("dificuldade",""),t.get("status",""))]
    if not tickets:
        print(f"  {C.D}Nenhum ticket. Use: python ebops.py dia{C.R}\n"); return

    counts = {}
    for t in state["tickets"]:
        s = t.get("status","backlog")
        counts[s] = counts.get(s,0)+1

    print(f"  {C.D}Backlog:{counts.get('backlog',0)} Em Andamento:{counts.get('em_andamento',0)} Em Revisão:{counts.get('em_revisao',0)} Concluído:{counts.get('concluido',0)}{C.R}\n")

    for tk in tickets:
        sc = SEV_COLORS.get(tk.get("severidade","media"), C.CY)
        dc = DIF_COLORS.get(tk.get("dificuldade","junior"), C.BL)
        icon = CAT_ICONS.get(tk.get("categoria",""), "📌")
        st_label = STATUS_LABELS.get(tk.get("status","backlog"), "Backlog")
        inj_flag = f" {C.RD}⚡{tk.get('inj','')}{C.R}" if tk.get("inj") else ""
        print(f"  {C.CY}{tk['ticket_id']}{C.R} {icon} {tk['titulo']}")
        print(f"    [{sc}{tk.get('severidade','media').upper()}{C.R}] [{dc}{tk.get('dificuldade','junior').upper()}{C.R}] {C.D}Dia #{tk.get('dia',0)} · {st_label}{C.R}{inj_flag}")

    print(f"\n  {C.D}Total: {len(tickets)} ticket(s){C.R}\n")

def mover_ticket(state, ticket_id, novo_status):
    for t in state["tickets"]:
        if t["ticket_id"] == ticket_id:
            old = t.get("status","backlog")
            t["status"] = novo_status
            print(f"  {C.GR}✓{C.R} {ticket_id}: {old} → {C.B}{STATUS_LABELS.get(novo_status, novo_status)}{C.R}")
            return True
    print(f"  {C.RD}Ticket {ticket_id} não encontrado.{C.R}")
    return False

# ═════════════════════════════════════════════════════════════
# MENU
# ═════════════════════════════════════════════════════════════
def menu(proj, state):
    while True:
        header()
        active_inj = state["injections_active"]
        total = len(state["tickets"])
        bk = len([t for t in state["tickets"] if t.get("status")=="backlog"])

        print(f"  {C.GR}✓ Projeto:{C.R} {C.B}{proj}{C.R}")
        print(f"  {C.D}HLQ remoto: {HLQ}{C.R}")
        print(f"  {C.D}Dia: #{state['day']} · Tickets: {total} (backlog: {bk}) · Injeções ativas: {len(active_inj)}{C.R}")
        if active_inj:
            print(f"  {C.RD}{C.B}⚡ DEFEITOS ATIVOS NO MAINFRAME:{C.R}")
            for a in active_inj:
                print(f"     {C.RD}{a['id']}{C.R} → {', '.join(a['arquivos'])}")
        print()
        print(f"  {C.B}1{C.R} — Gerar novo dia")
        print(f"  {C.B}2{C.R} — Ver tickets")
        print(f"  {C.B}3{C.R} — Mover ticket")
        print(f"  {C.B}4{C.R} — Injetar defeito manual")
        print(f"  {C.B}5{C.R} — Ver injeções ativas")
        print(f"  {C.B}6{C.R} — Reverter injeções")
        print(f"  {C.B}7{C.R} — Listar cenários de injeção")
        print(f"  {C.B}8{C.R} — Importar templates JSON")
        print(f"  {C.B}9{C.R} — Exportar tickets")
        print(f"  {C.B}S{C.R} — Spy (comparar local × remoto)")
        print(f"  {C.B}A{C.R} — Submeter cadeia inteira (EBJALL)")
        print(f"  {C.B}R{C.R} — Resetar tudo")
        print(f"  {C.B}0{C.R} — Sair")
        print()

        ch = input(f"  {C.GR}>{C.R} ").strip()

        if ch == '1':
            gerar_dia(proj, state); input(f"  {C.D}Enter para continuar...{C.R}")
        elif ch == '2':
            show_tickets(state); input(f"  {C.D}Enter para continuar...{C.R}")
        elif ch == '3':
            show_tickets(state)
            tid = input(f"  {C.GR}Ticket ID:{C.R} ").strip().upper()
            if tid:
                print(f"  1=Backlog  2=Em Andamento  3=Em Revisão  4=Concluído")
                ns = input(f"  {C.GR}Novo status (1-4):{C.R} ").strip()
                sm = {"1":"backlog","2":"em_andamento","3":"em_revisao","4":"concluido"}
                if ns in sm:
                    mover_ticket(state, tid, sm[ns]); save_state(proj, state)
            input(f"  {C.D}Enter para continuar...{C.R}")
        elif ch == '4':
            print(f"\n  {C.B}Cenários de injeção:{C.R}")
            for inj in INJECTIONS:
                dc = DIF_COLORS.get(inj["dif"],C.BL)
                print(f"  {C.CY}{inj['id']}{C.R} {inj['t']} [{dc}{inj['dif'].upper()}{C.R}] {C.D}{', '.join(inj['arqs'])}{C.R}")
            print()
            iid = input(f"  {C.GR}ID da injeção:{C.R} ").strip().upper()
            if iid: do_inject(proj, iid, state)
            input(f"  {C.D}Enter para continuar...{C.R}")
        elif ch == '5':
            if not active_inj: print(f"\n  {C.GR}Nenhuma injeção ativa.{C.R}")
            else:
                print(f"\n  {C.RD}{C.B}Injeções ativas ({len(active_inj)}):{C.R}")
                for a in active_inj:
                    print(f"  {C.CY}{a['id']}{C.R} — {a['titulo']}")
                    print(f"    {C.YL}Arquivos: {', '.join(a['arquivos'])}{C.R}")
                    print(f"    {C.D}Desde: {a['timestamp']}{C.R}")
            input(f"\n  {C.D}Enter para continuar...{C.R}")
        elif ch == '6':
            do_revert(proj, state); input(f"  {C.D}Enter para continuar...{C.R}")
        elif ch == '7':
            for inj in INJECTIONS:
                dc=DIF_COLORS.get(inj["dif"],C.BL)
                print(f"  {C.CY}{inj['id']}{C.R} {inj['t']} [{dc}{inj['dif'].upper()}{C.R}] {C.D}{inj['tmp']}{C.R}")
                print(f"    {C.D}Arquivos: {', '.join(inj['arqs'])}{C.R}")
            input(f"\n  {C.D}Enter para continuar...{C.R}")
        elif ch == '8':
            path = input(f"  {C.GR}Caminho do JSON:{C.R} ").strip().strip('"')
            if path and os.path.isfile(path):
                try:
                    with open(path) as f: data = json.load(f)
                    arr = data if isinstance(data, list) else [data]
                    valid = [t for t in arr if t.get("titulo") or t.get("t")]
                    for t in valid:
                        if "t" not in t and "titulo" in t: t["t"] = t["titulo"]
                        if "cat" not in t and "categoria" in t: t["cat"] = t["categoria"]
                        if "desc" not in t and "descricao" in t: t["desc"] = t["descricao"]
                        t.setdefault("id", f"CUST-{random.randint(1000,9999)}")
                        t.setdefault("sev","media"); t.setdefault("dif","junior")
                        t.setdefault("tmp","30min"); t.setdefault("tags",[])
                    state["custom_templates"].extend(valid)
                    save_state(proj, state)
                    print(f"  {C.GR}✓ {len(valid)} template(s) importado(s).{C.R}")
                except Exception as e: print(f"  {C.RD}Erro: {e}{C.R}")
            input(f"  {C.D}Enter para continuar...{C.R}")
        elif ch == '9':
            out = os.path.join(proj, "ebops_tickets_export.json")
            with open(out,'w') as f: json.dump(state["tickets"], f, indent=2, ensure_ascii=False)
            print(f"  {C.GR}✓ Exportado: {out}{C.R}")
            input(f"  {C.D}Enter para continuar...{C.R}")
        elif ch.upper() == 'S':
            iid = input(f"  {C.GR}ID da injeção (vazio = todas):{C.R} ").strip().upper() or None
            do_spy(proj, state, iid)
            input(f"  {C.D}Enter para continuar...{C.R}")
        elif ch.upper() == 'A':
            do_submit_all(proj)
            input(f"  {C.D}Enter para continuar...{C.R}")
        elif ch.upper() == 'R':
            if input(f"  {C.RD}Resetar TUDO? (s/N): {C.R}").strip().lower()=='s':
                do_revert(proj, state)
                state.update({"tickets":[],"custom_templates":[],"day":1,"injections_active":[],"history":[]})
                save_state(proj, state)
                print(f"  {C.GR}✓ Resetado.{C.R}")
            input(f"  {C.D}Enter para continuar...{C.R}")
        elif ch == '0':
            print(f"\n  {C.GR}Até a próxima sessão.{C.R}\n"); break

# ═════════════════════════════════════════════════════════════
# MAIN
# ═════════════════════════════════════════════════════════════
def main():
    args = sys.argv[1:]

    if args and args[0] == 'set-path' and len(args) > 1:
        p = os.path.expanduser(args[1])
        if _is_proj(p): _save_cfg(p); print(f"  {C.GR}✓ Salvo: {p}{C.R}\n")
        else: print(f"  {C.RD}{MARKER} não encontrado em {p}{C.R}\n")
        return

    proj = find_project()
    state = load_state(proj)

    if not args:
        menu(proj, state)
    elif args[0] == 'dia':
        gerar_dia(proj, state)
    elif args[0] == 'tickets':
        show_tickets(state, args[1] if len(args)>1 else None)
    elif args[0] == 'mover' and len(args) >= 3:
        mover_ticket(state, args[1].upper(), args[2]); save_state(proj, state)
    elif args[0] == 'status':
        header()
        active = state["injections_active"]
        if not active: print(f"  {C.GR}Nenhuma injeção ativa.{C.R}\n")
        else:
            for a in active:
                print(f"  {C.CY}{a['id']}{C.R} — {a['titulo']}")
                print(f"    {C.YL}Arquivos: {', '.join(a['arquivos'])}{C.R}")
                print(f"    {C.D}Desde: {a['timestamp']}{C.R}\n")
    elif args[0] == 'inject' and len(args) > 1:
        do_inject(proj, args[1].upper(), state)
    elif args[0] == 'revert':
        do_revert(proj, state, args[1].upper() if len(args)>1 else None)
    elif args[0] == 'spy':
        do_spy(proj, state, args[1].upper() if len(args)>1 else None)
    elif args[0] == 'submit-all':
        do_submit_all(proj)
    elif args[0] == 'where':
        print(f"\n  {C.GR}✓ Projeto:{C.R} {C.B}{proj}{C.R}")
        print(f"  {C.D}HLQ remoto:{C.R} {HLQ}")
        for f in ["EBVALI01.cbl","EBPOST01.cbl","EBJVALD.jcl","EBJPOST.jcl","CPLCT001.cpy","CPCNT001.cpy","lancamentos_d0.txt"]:
            ok = bool(_resolve_file(proj, f))
            print(f"    {C.GR+'✓' if ok else C.RD+'✗'}{C.R} {f}  →  {_ds_member_for(f)}")
        print()
    elif args[0] == 'reset':
        if input(f"  Resetar TUDO? (s/N): ").strip().lower()=='s':
            do_revert(proj, state)
            state.update({"tickets":[],"custom_templates":[],"day":1,"injections_active":[],"history":[]})
            save_state(proj, state)
            print(f"  {C.GR}✓ Resetado.{C.R}\n")
    elif args[0] == 'importar' and len(args) > 1:
        path = args[1]
        if os.path.isfile(path):
            with open(path) as f: data = json.load(f)
            arr = data if isinstance(data, list) else [data]
            valid = [t for t in arr if t.get("titulo") or t.get("t")]
            for t in valid:
                if "t" not in t and "titulo" in t: t["t"]=t["titulo"]
                if "cat" not in t and "categoria" in t: t["cat"]=t["categoria"]
                t.setdefault("id",f"CUST-{random.randint(1000,9999)}")
            state["custom_templates"].extend(valid)
            save_state(proj, state)
            print(f"  {C.GR}✓ {len(valid)} template(s) importado(s).{C.R}\n")
    elif args[0] == 'exportar':
        out = os.path.join(proj, "ebops_tickets_export.json")
        with open(out,'w') as f: json.dump(state["tickets"], f, indent=2, ensure_ascii=False)
        print(f"  {C.GR}✓ Exportado: {out}{C.R}\n")
    else:
        print(f"""
  Uso:
    python ebops.py                 Menu interativo
    python ebops.py dia             Gera novo dia
    python ebops.py tickets [filtro] Lista tickets
    python ebops.py mover EB-001-01 em_andamento
    python ebops.py inject INJ-001  Injeta no MAINFRAME via Zowe
    python ebops.py revert [INJ-ID] Reverte (re-upload do snapshot)
    python ebops.py spy [INJ-ID]    Compara local × remoto
    python ebops.py submit-all      Submete cadeia completa (EBJALL)
    python ebops.py status          Injeções ativas
    python ebops.py where           Mostra caminho e DS_MAP
    python ebops.py set-path /dir   Define caminho manualmente
    python ebops.py importar a.json Importa templates
    python ebops.py exportar        Exporta tickets
    python ebops.py reset           Reseta tudo

  Variáveis de ambiente:
    EBOPS_HLQ                       HLQ dos datasets (default: Z77948.EMUNAH)
""")

if __name__ == "__main__":
    main()