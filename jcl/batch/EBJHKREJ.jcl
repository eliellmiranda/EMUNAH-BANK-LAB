//* ============================================================
//* ARQUIVO      : EBJHKREJ.jcl
//* CAMINHO LOCAL: jcl/batch/EBJHKREJ.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJHKREJ)
//*
//* FINALIDADE:
//*   Housekeeping do ARQ.REJEITOS.SEQ: arquiva o conteudo em GDG
//*   e recria o arquivo vazio para o proximo ciclo.
//*
//* POR QUE E NECESSARIO:
//*   O EBJVALD grava rejeitos com DISP=MOD acumulando registros
//*   a cada execucao. Sem rotacao o arquivo cresce sem limite.
//*
//* POSICAO NA CADEIA:
//*   Executar apos EBJRPOST (ciclo de reprocessamento encerrado).
//*   EBJHKREJ -> EBJHKAUD (housekeepings de encerramento do dia).
//*
//* FLUXO DOS 3 STEPS:
//*   ARCHREJ -> DELREJ -> ALLOCREJ
//*   Se ARCHREJ falhar, os demais nao executam (COND=(0,NE)),
//*   preservando o arquivo de rejeitos original.
//*
//* NOTA DE LRECL:
//*   REJEITOS.SEQ = 120 bytes (layout CPLCT001 original)
//*   REJPERM.SEQ  = 150 bytes (120 + 30 motivo acumulado)
//*   Este job rotaciona apenas o REJEITOS.SEQ (120 bytes).
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = rotacao concluida com sucesso
//*   RC 8  = falha em ARCHREJ - arquivo nao rotacionado
//*   RC 12 = falha critica - GDG nao gerado
//* ============================================================
//EBJHKREJ JOB ,'EMUNAH HKREJ',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP ARCHREJ: ARQUIVAR REJEITOS.SEQ EM GDG(+1) ==========
//*
//ARCHREJ  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,DISP=SHR
//*           Arquivo de rejeitos corrente (acumulado via MOD).
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.BKP.REJEITOS.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(MODEL.DSCB,RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Nova geracao GDG de backup de rejeitos.
//SYSIN    DD DUMMY
//*
//* === STEP DELREJ: DELETAR REJEITOS.SEQ ATUAL =================
//*   COND=(0,NE): executa somente se ARCHREJ terminou RC=0.
//*   SET MAXCC=0: idempotente - seguro para rerun.
//*
//DELREJ   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.REJEITOS.SEQ' NONVSAM
  SET MAXCC = 0
/*
//*
//* === STEP ALLOCREJ: RECRIAR REJEITOS.SEQ VAZIO ===============
//*   IEFBR14 nao executa logica; a alocacao e feita pelo DD.
//*   Recria o arquivo vazio com o mesmo layout original (FB/120).
//*
//ALLOCREJ EXEC PGM=IEFBR14,COND=(0,NE)
//REJEITOS DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Arquivo recriado vazio, pronto para o proximo ciclo.