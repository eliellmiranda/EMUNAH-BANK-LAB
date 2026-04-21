//* ------------------------------------------------------------
//* ARQUIVO      : EBJACCR.jcl
//* CAMINHO LOCAL: jcl/batch/EBJACCR.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJACCR)
//* FINALIDADE:
//* Calcular e aplicar accruals diarios (juros e tarifas)
//* sobre as contas ativas do laboratorio.
//*
//* POSICAO NA CADEIA: apos EBJCUTF (EOTI) e antes de EBJCUTE.
//*
//* FLUXO ESPERADO:
//* 1. ACCR - EBACCR01 le PARM.JUROS.CONFIG e CONTA.KSDS,
//*           calcula juros (corrente/poupanca) e tarifas,
//*           faz REWRITE em CONTA.KSDS, grava movimentos
//*           em ARQ.ACCR.MOV.SEQ e appenda em LANCTO.ESDS.
//*
//* PRE-REQUISITO: EBALLOC + EBDEFGDG ja executados.
//* ------------------------------------------------------------
//EBJACCR  JOB ,'EMUNAH ACCR',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: APLICAR ACCRUALS (EBACCR01) ===
//*
//ACCR     EXEC PGM=EBACCR01
//* Programa de calculo e aplicacao de juros e tarifas.
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca do executavel EBACCR01.
//PARMLIB  DD DSN=Z77948.EMUNAH.PARM.JUROS.CONFIG,DISP=SHR
//* Parametros de juros e tarifas por tipo de conta (pos 80 bytes).
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* VSAM KSDS de contas - aberto I-O pelo programa para REWRITE.
//ACCROUT  DD DSN=Z77948.EMUNAH.ARQ.ACCR.MOV.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* Movimentos de accrual gerados no dia (feed de evidencia).
//LANCTO   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//* VSAM ESDS de historico - aberto EXTEND pelo programa.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Auditoria do processamento de accruals.
//SYSOUT   DD SYSOUT=*
//* Saida geral do programa.
//SYSPRINT DD SYSOUT=*
//* Mensagens tecnicas.
//*
//* RC 0  = accruals aplicados com sucesso.
//* RC 4  = CONTA.KSDS vazio - nenhum accrual calculado.
//* RC 8  = erro de I/O - verificar SYSPRINT antes de rerun.
//* RC 12 = erro critico - CONTA.KSDS ou LANCTO.ESDS inacessivel.