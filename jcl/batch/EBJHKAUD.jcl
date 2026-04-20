//* ------------------------------------------------------------
//* ARQUIVO      : EBJHKAUD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJHKAUD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJHKAUD)
//* FINALIDADE:
//* Housekeeping ativo do ARQ.AUDIT.SEQ: arquiva o conteudo
//* corrente em ARQ.BKP.AUDIT.GDG(+1) e recria o arquivo vazio,
//* evitando crescimento indefinido via DISP=MOD.
//*
//* FLUXO ESPERADO:
//* 1. ARCHAUD  - IEBGENER copia AUDIT.SEQ -> ARQ.BKP.AUDIT.GDG(+1).
//* 2. DELAUD   - IDCAMS deleta AUDIT.SEQ atual.
//* 3. ALLOCAUD - IEFBR14 recria AUDIT.SEQ vazio.
//*
//* Roda tipicamente no fim do ciclo diario, apos EBJEOD.
//* ------------------------------------------------------------
//EBJHKAUD JOB ,'EMUNAH HKAUD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP 1: ARQUIVAR AUDIT.SEQ EM ARQ.BKP.AUDIT.GDG(+1) ===
//*
//ARCHAUD  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=SHR
//* Arquivo de auditoria corrente, gravado via DISP=MOD pelos programas.
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.BKP.AUDIT.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(MODEL.DSCB,RECFM=FB,LRECL=120,BLKSIZE=0)
//* Nova geracao do GDG de backup de auditoria.
//SYSIN    DD DUMMY
//*
//* === STEP 2: DELETAR AUDIT.SEQ ATUAL ===
//*
//DELAUD   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.AUDIT.SEQ' NONVSAM
  SET MAXCC = 0
/*
//* Deleta o arquivo fisico do catalogo para permitir realocacao limpa.
//* SET MAXCC=0 suprime RC=8 quando o arquivo ja nao existe (idempotente).
//*
//* === STEP 3: REALOCAR AUDIT.SEQ VAZIO ===
//*
//ALLOCAUD EXEC PGM=IEFBR14,COND=(0,NE)
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* Recria o arquivo vazio com o mesmo layout, pronto para o proximo ciclo.
//*
//* RC 0  = rotacao concluida - AUDIT.SEQ arquivado e reiniciado.
//* RC 4  = aviso em IEBGENER (aceitar se output catalogado).
//* RC 8  = falha em ARCHAUD ou DELAUD - verificar SYSPRINT do step.
//* RC 12 = falha critica - GDG nao gerado ou AUDIT.SEQ nao recriado.
