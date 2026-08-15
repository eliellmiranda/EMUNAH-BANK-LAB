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