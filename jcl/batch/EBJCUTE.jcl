//* ============================================================
//* ARQUIVO      : EBJCUTE.jcl
//* CAMINHO LOCAL: jcl/batch/EBJCUTE.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJCUTE)
//*
//* FINALIDADE:
//* Cutoff Contabil - marca CTL.STATUS = EOFI
//* (End Of Financial Input): fecha a janela contabil do dia,
//* sinalizando que nenhum novo lancamento contabil pode entrar.
//* Utiliza o programa EBCTL01 para validar a transicao.
//*
//* POSICAO NA CADEIA DIARIA:
//* EBJACCR (accruals) --> EBJCUTE (EOFI) --> EBJCONC/EBJEXTR
//*
//* MAQUINA DE ESTADOS CTL.STATUS:
//* vazio/CLOSED -> OPEN (EBJSOD)
//* -> EOTI (EBJCUTF)   <- janela financeira fechada
//* -> EOFI (EBJCUTE - este job) <- janela contabil fechada
//* -> CLOSED (EBJEOD)
//*
//* CODIGOS DE RETORNO (EBCTL01):
//* RC 0  = EOFI gravado com sucesso - transicao permitida
//* RC 8  = Transicao invalida (nao estava EOTI) ou erro de I/O
//* ============================================================
//EBJCUTE  JOB ,'EMUNAH CUTE',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP WRTSTAT: CUTOFF CONTABIL (EOFI) ===================
//* Chama o EBCTL01 passando a acao e o status destino via PARM.
//* O programa valida se o status atual e 'EOTI'
//* antes de atualizar para 'EOFI'.
//* DISP=OLD garante acesso exclusivo ao arquivo de controle.
//*
//WRTSTAT  EXEC PGM=EBCTL01,PARM='UPD,EOFI'
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=OLD
//*