# COMANDOS — Registro de comandos validados

> Conforme `mainframe-behavior.md` (regra global, item 4) — registra **apenas comandos
> que funcionaram**, organizados por categoria, com saída esperada.

## Categoria: Diagnóstico JES2 (console do operador)

| Comando | Uso | Saída esperada |
|---|---|---|
| `$D SPOOLDEF` | Mostrar o ambiente de spooling do JES2 | `$HASP844` com `VOLUME=`, `DSNAME=`, `BUFSIZE=`, `TGSIZE=`, `TGSPACE=`, `SPOOLNUM=` |
| `$D SPOOL` | Listar volumes de spool e status | `$HASP893 VOLUME(x) STATUS=...` + `$HASP646 nn PERCENT SPOOL UTILIZATION` |

## Categoria: Operação de dispositivos DASD (VARY)

| Comando | Uso | Saída esperada |
|---|---|---|
| `V DE34,ONLINE` | Colocar o 3390 `DE34` online no z/OS | `IOS452I DE34,DE, OPERATIONAL PATH ADDED TO PATH GROUP` e `IEE302I DE34 ONLINE` |

## Categoria: Inicialização de volume DASD (ICKDSF — PGM=ICKDSF)

| Comando (SYSIN) | Uso | Saída esperada |
|---|---|---|
| `INIT UNIT(DE34) VOLID(JSPVS2) OWNER('EMUNAH SPOOL') NOVERIFY` | Inicializar volume novo (label + VTOC) | `ICK061I VTOC INDEX CREATION SUCCESSFUL`; `$HASP395 ... RC=0000` |

> NOTAS (validadas):
> - Rodar com o device **OFFLINE** (`V DE34,OFFLINE`); com ONLINE o ICKDSF aborta (`ICK31049I`, CC=12).
> - Com  JCL `PARM='NOREPLYU'`, o ICKDSF ainda emite `ICK003D`; responder `R <id>,U` para alterar o volume.

---
> NOTAS:
> - Não documentados (falharam/não validados): `D U,3390`, `D U,DE34` (`IEE453I`) e
>   `D U,ALL` (lista restrita no console).
> - Fonte de referência: `E:\MANUAIS\JES2_Manual_Otimizado.md` (Cap. 3).

---

## Categoria: Diagnóstico CICS-DB2 (transação CEDA / CEMT / CEBR)

> **Status:** pendentes de validação — registrados como plano de ação para Step 3.5.
> Serão movidos para "validados" após confirmação no ambiente.

| Comando | Uso | Saída esperada |
|---|---|---|
| `CEBR CSSL` | Ler a fila transiente CSSL via browser CICS | Lista de mensagens; procurar `DSNC1020`, `DSNC1022`, `DSNC2005` |
| `CEDA DISPLAY DB2CONN(DBD1)` | Verificar se o recurso DB2CONN existe no CSD | Detalhes do objeto ou `OBJECT NOT FOUND` |
| `CEDA DEFINE DB2CONN(DBD1) GROUP(EMUNAH) DB2ID(DBD1) ACCOUNTREC(TASK) AUTHTYPE(USERID)` | Definir a conexão CICS-DB2 no CSD | `DEFINE SUCCESSFUL` |
| `CEDA INSTALL DB2CONN(DBD1) GROUP(EMUNAH)` | Instalar DB2CONN sem reciclar o CICS | `INSTALL SUCCESSFUL` |
| `CEMT INQUIRE DB2CONN` | Verificar status da conexão CICS-DB2 | `DB2ID(DBD1) CONNECTED AVAILABLE` |

> NOTAS (contexto Step 3.5):
> - APCT antes do primeiro `EXEC CICS` em programa CICS/DB2 aponta para `DB2CONN` ausente ou inativo.
> - CEDF confirma que o EIB é preenchido (tarefa iniciada) mas o stub DSNCSQL aborta na inicialização da thread.
> - Mensagens `DSNC*` no CSSL são a evidência definitiva do problema de attachment.
> - Após `CEDA INSTALL DB2CONN`, reexecutar `CEMT INQUIRE DB2CONN` antes de retestar ESLD.
> - Referência: *CICS Transaction Server for z/OS — CICS DB2 Guide* (SC34-7462), seção "Defining DB2CONN".