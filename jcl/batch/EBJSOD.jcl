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
//* EBJPRECK (valida fechamento anterior) --> EBJSOD --> EBJWAIT
//* O SOD e o "gatilho" que libera a entrada de arquivos.
//*
//* MAQUINA DE ESTADOS CTL.STATUS:
//* CLOSED (fim do dia anterior)
//* --> OPEN    (EBJSOD - este job)
//* --> EOTI    (EBJCUTF - corte financeiro)
//* --> EOFI    (EBJCUTE - corte contabil)
//* --> CLOSED  (EBJEOD/CLOSDAY - fechamento do dia)
//*
//* CODIGOS DE RETORNO (EBCTL01):
//* RC 0 = OPEN gravado com sucesso - transicao permitida
//* RC 8 = Transicao invalida (nao estava CLOSED) ou erro de I/O
//* ============================================================
//EBJSOD   JOB ,'EMUNAH SOD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP WRTSTAT: START OF DAY (EBCTL01) ===================
//* Chama o EBCTL01 passando o status destino via PARM.
//* O programa valida se o status atual e 'CLOSED'
//* antes de atualizar para 'OPEN'.
//*
//WRTSTAT  EXEC PGM=EBCTL01,PARM='UPD,OPEN'
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca contendo o executavel EBCTL01.
//SYSPRINT DD SYSOUT=*
//* Mensagens tecnicas do sistema.
//SYSOUT   DD SYSOUT=*
//* Saida operacional do programa (DISPLAY).
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=OLD
//* Arquivo de controle de status. DISP=OLD garante lock exclusivo.
//*