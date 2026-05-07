//* ============================================================
//* ARQUIVO      : EBSETSTS.jcl
//* CAMINHO LOCAL: jcl/util/EBSETSTS.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBSETSTS)
//*
//* FINALIDADE:
//*   Grava 'CLOSED  ' diretamente no CTL.STATUS via IEBGENER.
//*   Permite reiniciar a cadeia batch do zero sem depender
//*   da maquina de estados do EBCTL01.
//*
//* QUANDO USAR:
//*   - CTL.STATUS ficou em estado inconsistente (EOFI/EOTI/OPEN)
//*     e voce precisa recomecar o ciclo do lab.
//*   - Apos um factory reset (EBRESETF) para preparar o Day-One.
//*
//* PROXIMO PASSO APOS RODAR ESTE JOB:
//*   EBJSOD -> EBJLOAD -> EBJVALD -> EBJCUTF -> EBJCUTE
//*   -> EBJSNAP -> EBJCONC
//*
//* TECNICA:
//*   IEBGENER com GENERATE/RECORD grava 8 bytes no CTL.STATUS.
//*   SYSUT1 DD * contem o valor desejado ('CLOSED  ') como dado
//*   de card image (80 bytes). FIELD=(8,1,1) le os 8 primeiros
//*   bytes do input e escreve na posicao 1 do output.
//*   NAO usar literal em FIELD=(n,'...',pos) quando o valor
//*   tem espacos finais - o parser IEBGENER descarta esses
//*   espacos e o tamanho declarado diverge (IEB338I col.30).
//* ============================================================
//EBSETSTS JOB ,'EMUNAH SETSTS',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//SETSTAT  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  GENERATE MAXFLDS=1
  RECORD FIELD=(8,1,1)
/*
//SYSUT1   DD *
CLOSED
/*
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=OLD
