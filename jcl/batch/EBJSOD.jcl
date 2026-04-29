//* ============================================================
//* ARQUIVO      : EBJSOD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJSOD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJSOD)
//*
//* FINALIDADE:
//* Start of Day - abre o ciclo batch do laboratorio
//* marcando CTL.STATUS = OPEN via programa EBCTL01.
//*
//* POSICAO NA CADEIA DIARIA:
//* EBJSOD (primeiro job do dia) --> EBJPRECK --> EBJWAIT --> ...
//*
//* MAQUINA DE ESTADOS CTL.STATUS:
//* CLOSED (fim do dia anterior)
//* --> OPEN    (EBJSOD - este job)
//* --> EOTI    (EBJCUTF - corte financeiro)
//* --> EOFI    (EBJCUTE - corte contabil)
//* --> CLOSED  (EBJEOD/CLOSDAY - fechamento do dia)
//*
//* PRE-REQUISITO:
//* ARQ.CTL.STATUS deve ja existir no catalogo.
//*
//* CODIGOS DE RETORNO (EBCTL01):
//* RC 0 = OPEN gravado com sucesso - transicao permitida
//* RC 8 = Transicao invalida ou erro de I/O
//* ============================================================
//EBJSOD   JOB ,'EMUNAH SOD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP WRTSTAT: START OF DAY =============================
//* Chama o EBCTL01 passando o status destino via PARM.
//* O programa valida se o status atual e 'CLOSED' (ou vazio)
//* antes de atualizar para 'OPEN'.
//* DISP=OLD garante acesso exclusivo e previne concorrencia.
//*
//WRTSTAT  EXEC PGM=EBCTL01,PARM='OPEN'
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=OLD
//*