//EBHKLOG  JOB (ACCT),'EMUNAH HSKP-LOGREC',CLASS=A,MSGCLASS=H,
//             NOTIFY=&SYSUID,REGION=0M
//*------------------------------------------------------------------
//* EBHKLOG - EMUNAH BANK LAB - HOUSEKEEPING DO SYS1.LOGREC
//*
//* FASE 1 (EREP) : IFCEREP1 imprime/descarrega o conteudo atual do
//*                  LOGREC para um dataset historico (GDG) ANTES de
//*                  limpar - assim voce nao perde o historico de
//*                  erros/eventos.
//* FASE 2 (CLEAR): IFCDIP00 reinicializa (limpa) o SYS1.LOGREC.
//*                  So roda se a FASE 1 nao tiver falhado (RC>4).
//*
//* AJUSTE ANTES DE USAR:
//*   - DSN do LOGREC (SERLOG/SERERDS) ja preenchido abaixo como
//*     VSPROV.VS01.LOGREC, com base no seu proprio JCL LOGRCLR.
//*     CONFIRME antes de rodar com o comando de operador: D LOGREC
//*     (mostra CURRENT MEDIUM / MEDIUM NAME = dataset em uso agora).
//*   - GDG base ELIEL.EMUNAH.EBHKLOG.RPT precisa existir antes da
//*     primeira execucao. Rode uma vez (setup unico):
//*
//*     //DEFGDG   JOB (ACCT),'DEFINE GDG',CLASS=A,MSGCLASS=H
//*     //STEP1    EXEC PGM=IDCAMS
//*     //SYSPRINT DD   SYSOUT=*
//*     //SYSIN    DD   *
//*       DEFINE GDG (NAME(ELIEL.EMUNAH.EBHKLOG.RPT) -
//*            LIMIT(14)                             -
//*            NOEMPTY                                -
//*            SCRATCH)
//*     /*
//*
//*   - BLKSIZE abaixo esta explicito (nao 0) porque o seu Hercules
//*     ja mostrou problema com BLKSIZE resolvido so no OPEN/CLOSE -
//*     mesma licao do EBJCHAIN.
//*------------------------------------------------------------------
//*
//* --- FASE 1: RELATORIO/OFFLOAD EREP ANTES DE LIMPAR ---------------
//EREP     EXEC PGM=IFCEREP1,PARM='CARD'
//EREPPT   DD   DSN=ELIEL.EMUNAH.EBHKLOG.RPT(+1),
//             DISP=(NEW,CATLG,DELETE),
//             SPACE=(TRK,(10,5),RLSE),
//             DCB=(RECFM=FBA,LRECL=121,BLKSIZE=4840)
//TOURIST  DD   SYSOUT=*
//SERLOG   DD   DSN=VSPROV.VS01.LOGREC,DISP=SHR
//ACCDEV   DD   DUMMY
//SYSIN    DD   *
  PRINT=ALL
  HIST=Y
  TYPE=S,H,O
  ENDPARM
/*
//*
//* --- FASE 2: LIMPA/REINICIALIZA O LOGREC --------------------------
//* COND=(4,LT,EREP): so roda se o RC do step EREP NAO for maior que
//* 4 (ou seja, EREP terminou OK ou so com aviso leve).
//CLEAR    EXEC PGM=IFCDIP00,COND=(4,LT,EREP)
//SERERDS  DD   DSN=VSPROV.VS01.LOGREC,DISP=OLD
//
