# MANUAL — Adição de volume de spool `JSPVS2` ao JES2 (z/OS 3.1 VSI / Hercules)

> Conforme `mainframe-behavior.md` (regra global) — registra **apenas passos validados**,
> com o comando exato que funcionou e o resultado esperado. Nunca documenta passos falhos.

## 1. Ambiente (diagnóstico validado — Passo 1/6)

| Item | Valor |
|---|---|
| Sistema | z/OS 3.1, LPAR `VS01`, Hercules — config `E:\ZOS31\MF_31.cnf` |
| Acesso | Console do operador (MSTCON 3270) / SDSF `$`; host z/OSMF `192.168.100.150` |
| Spool dataset | `DSNAME=VSPROV.VS01.HASPACE` (custom) |
| Prefixo de volser | `VOLUME=JSPVS` → volumes `JSPVS*` |
| Spool atual | `JSPVS1` (device `DE2D`) ACTIVE ≈97%; utilização global ≈97,7% |
| Novo volume | `JSPVS2` — device `DE34` (`E:\zos31\JSPVS2.CCKD`, `sf`, shadow) |
| Sombra | `E:\zos31\SHADOW\JSPVS2_*.CCKD` |

## 2. Passos validados

### ✅ Passo 1/6 — Diagnóstico do estado do spool e do JES2
**O que foi feito:** levantamento do ambiente de spooling, volumes ativos e device novo no Hercules.
**Comandos que funcionaram (validados):**
- `$D SPOOLDEF` → `$HASP844` com `VOLUME=JSPVS`, `DSNAME=VSPROV.VS01.HASPACE`,
  `BUFSIZE=3992`, `TGSIZE=36`, `SPOOLNUM=32`, `TGSPACE(...PERCENT=97.7755, FREE=371, WARN=90)`,
  `ADVANCED_FORMAT=DISABLED`.
- `$D SPOOL` → `$HASP893 VOLUME(JSPVS1) STATUS=ACTIVE,PERCENT=97` e
  `$HASP646 97.7455 PERCENT SPOOL UTILIZATION`.
- Hernance (fonte): arquivo `MF_31.cnf` → `DE34 3390 E:\zos31\JSPVS2.CCKD ...` presente.
- Física: `JSPVS2.cckd` com ~118 KB e **sem shadow** → volume cru (sem label/VTOC).
**Resultado esperado:** quadro do ambiente fechado; volser do novo volume = `JSPVS2`; device `DE34` já definido no Hercules.

### ✅ Passo 2/6 — Publicar o device `DE34` no z/OS
**O que foi feito:** colocar o 3390 `DE34` (futuro `JSPVS2`) no estado ONLINE do z/OS.
**Comando que funcionou (validado):**
- `V DE34,ONLINE`
**Resultado esperado/obtido:**
```
IOS452I DE34,DE, OPERATIONAL PATH ADDED TO PATH GROUP
IEE302I DE34     ONLINE
```
**Observação registrada:** o console do operador **não** permite `D U,cuu`/`D U,ALL` completos
(`IEE453I` e lista restrita). Portanto a verificação de volser/geometria do volume é feita via
**ICKDSF** no Passo 3 (o SYSPRINT reporta a geometria sem depender do `D U`).

### ✅ Passo 3/6 — Inicializar o `JSPVS2` com ICKDSF (label + VTOC)
**O que foi feito:** o 3390 `DE34` foi inicializado — label `JSPVS2` + VTOC em formato indexado.
**Passo anterior obrigatório:** `V DE34,OFFLINE` (o ICKDSF recusa INIT com o volume ONLINE — `ICK31049I`, CC=12).
**Comando que funcionou (validado)** — JCL `EBSPINIT` (PGM=ICKDSF, PARM=`NOREPLYU`):
- SYSIN: `INIT UNIT(DE34) VOLID(JSPVS2) OWNER('EMUNAH SPOOL') NOVERIFY`
**Interação de operador validada:** no `ICK003D REPLY U TO ALTER VOLUME DE34 CONTENTS`, responder `R <id>,U`.
**Resultado esperado/obtido:**
```
ICK00700I ... PHYSICAL DEVICE = 3390 ... TRKS/CYL = 15, # PRIMARY CYLS = 20000
ICK03091I EXISTING VOLUME SERIAL READ = JSPVS2
ICK061I   DE34 VTOC INDEX CREATION SUCCESSFUL: VOLUME IS IN INDEX FORMAT
$HASP395 EBSPINIT ENDED - RC=0000
```
**Depois:** `V DE34,ONLINE` (JES2 só usa volume ONLINE).

### ⏳ Passo 4/6 — Pendente (`$S SPL(JSPVS2)`)

### ⏳ Passo 5/6 — Pendente (verificação/teste)

### ⏳ Passo 6/6 — Pendente (consolidação deste manual + COMANDOS.md)

---
> Fonte de referência: `E:\MANUAIS\JES2_Manual_Otimizado.md` — Cap. 3 (linhas 8784–10162),
> "SPOOL volume configuration, control, and performance" (z/OS 3.1, SA32-0991-60).