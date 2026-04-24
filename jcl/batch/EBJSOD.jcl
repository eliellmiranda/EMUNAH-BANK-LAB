//* ============================================================
//* ARQUIVO      : EBJSOD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJSOD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJSOD)
//*
//* FINALIDADE:
//*   Start of Day - abre o ciclo batch do laboratorio
//*   marcando CTL.STATUS = OPEN.
//*
//* POSICAO NA CADEIA DIARIA:
//*   EBJSOD (primeiro job do dia) --> EBJPRECK --> EBJWAIT --> ...
//*
//* MAQUINA DE ESTADOS CTL.STATUS:
//*   CLOSED (fim do dia anterior)
//*     --> OPEN    (EBJSOD - este job)
//*     --> EOTI    (EBJCUTF - corte financeiro)
//*     --> EOFI    (EBJCUTE - corte contabil)
//*     --> CLOSED  (EBJEOD/CLOSDAY - fechamento do dia)
//*
//* PRE-REQUISITO:
//*   ARQ.CTL.STATUS deve ja existir no catalogo.
//*   No primeiro uso do laboratorio: executar EBALLOC antes.
//*   Nos dias seguintes: o dataset persiste com status CLOSED.
//*
//* OBS: Esta versao usa IEBGENER para gravacao direta.
//*      Sera substituida pelo programa EBCTL01 (COBOL) que
//*      valida a transicao de estado antes de gravar.
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = OPEN gravado com sucesso - cadeia pode prosseguir
//*   RC 12 = falha no IEBGENER - STATUS nao atualizado
//* ============================================================
//EBJSOD   JOB ,'EMUNAH SOD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP WRTSTAT: GRAVAR STATUS = OPEN ======================
//*   IEBGENER grava o literal "OPEN" (4 bytes) em CTL.STATUS.
//*   DISP=OLD: acesso exclusivo, sobrescreve "CLOSED" anterior.
//*   Se CTL.STATUS nao existe, o step abenda com JCL error.
//*
//WRTSTAT  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD *
OPEN
/*
//*           Literal de 4 bytes gravado no arquivo de status.
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=OLD
//*           Arquivo de controle de status. Deve ja existir.
//SYSIN    DD DUMMY
//*
//* === STEP VERIFY: CONFIRMAR STATUS GRAVADO ===================
//*   COND=(0,NE): executa somente se WRTSTAT terminou RC=0.
//*   LISTCAT gera evidencia auditavel no SYSPRINT.
//*
//VERIFY   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CTL.STATUS') ALL
/*