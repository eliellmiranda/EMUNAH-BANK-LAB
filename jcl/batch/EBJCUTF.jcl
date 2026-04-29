//* ============================================================
//* ARQUIVO      : EBJCUTF.jcl
//* CAMINHO LOCAL: jcl/batch/EBJCUTF.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJCUTF)
//*
//* FINALIDADE:
//* Cutoff Financeiro - marca CTL.STATUS = EOTI
//* (End Of Transaction Input): fecha a janela de entrada de
//* movimentos do dia, impedindo novos lancamentos.
//* Utiliza o programa EBCTL01 para validar a transicao.
//*
//* POSICAO NA CADEIA DIARIA:
//* EBJPOST (postagem) --> EBJCUTF (EOTI) --> EBJACCR (accruals)
//*
//* MAQUINA DE ESTADOS CTL.STATUS:
//* OPEN (EBJSOD) -> EOTI (EBJCUTF - este job) -> EOFI (EBJCUTE)
//* -> CLOSED (EBJEOD)
//* Apos EOTI: EBACCR01 pode calcular juros, mas EBVALI01
//* e EBPOST01 devem rejeitar novos lancamentos se consultarem
//* o status antes de processar.
//*
//* CODIGOS DE RETORNO (EBCTL01):
//* RC 0  = EOTI gravado com sucesso - transicao permitida
//* RC 8  = Transicao invalida ou erro de I/O
//* ============================================================
//EBJCUTF  JOB ,'EMUNAH CUTF',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP WRTSTAT: CUTOFF FINANCEIRO (EOTI) =================
//* Chama o EBCTL01 passando o status destino via PARM.
//* O programa valida se o status atual e 'OPEN'
//* antes de atualizar para 'EOTI'.
//* DISP=OLD garante acesso exclusivo ao arquivo de controle.
//*
//WRTSTAT  EXEC PGM=EBCTL01,PARM='EOTI'
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=OLD
//*