//* ============================================================
//* ARQUIVO      : EBJHKAUD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJHKAUD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJHKAUD)
//*
//* FINALIDADE:
//*   Housekeeping do ARQ.AUDIT.SEQ: arquiva o conteudo corrente
//*   em GDG e recria o arquivo vazio para o proximo ciclo.
//*
//* POR QUE E NECESSARIO:
//*   Todos os programas abrem AUDIT com DISP=MOD (append).
//*   Sem rotacao, o arquivo cresce indefinidamente a cada
//*   ciclo diario. Este job faz a rotacao de forma segura:
//*   arquiva -> deleta -> recria vazio.
//*
//* FREQUENCIA:
//*   Executar uma vez por ciclo diario, apos EBJEOD (EOD).
//*
//* FLUXO DOS 3 STEPS:
//*   ARCHAUD -> DELAUD -> ALLOCAUD
//*   Se ARCHAUD falhar, DELAUD e ALLOCAUD nao executam
//*   (COND=(0,NE) em ambos), preservando o arquivo original.
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = rotacao concluida - AUDIT.SEQ arquivado e reiniciado
//*   RC 4  = aviso em IEBGENER (aceitar se GDG catalogado)
//*   RC 8  = falha em ARCHAUD ou DELAUD - arquivo nao rotacionado
//*   RC 12 = falha critica - GDG nao gerado
//* ============================================================
//EBJHKAUD JOB ,'EMUNAH HKAUD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP ARCHAUD: ARQUIVAR AUDIT.SEQ EM GDG(+1) =============
//*   IEBGENER copia o conteudo atual do arquivo de auditoria
//*   para uma nova geracao do GDG de backup.
//*
//ARCHAUD  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=SHR
//*           Arquivo de auditoria corrente (acumulado via MOD).
//SYSUT2   DD DSN=Z77948.EMUNAH.BKP.AUDIT.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=128,BLKSIZE=0)
//SYSIN    DD DUMMY
//*
//* === STEP DELAUD: DELETAR AUDIT.SEQ ATUAL ====================
//*   COND=(0,NE): executa somente se ARCHAUD terminou RC=0.
//*   SET MAXCC=0 suprime RC=8 quando o arquivo ja nao existe
//*   (torna o step idempotente - seguro para rerun).
//*
//DELAUD   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.AUDIT.SEQ' NONVSAM
  SET MAXCC = 0
/*
//*
//* === STEP ALLOCAUD: RECRIAR AUDIT.SEQ VAZIO ==================
//*   IEFBR14 e um programa nulo; a alocacao ocorre pelo DD card.
//*   DISP=(NEW,CATLG,DELETE) cria o arquivo vazio e o cataloga.
//*   O novo arquivo tem o mesmo DCB do original: FB/120.
//*
//ALLOCAUD EXEC PGM=IEFBR14,COND=(0,NE)
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=128,BLKSIZE=0)