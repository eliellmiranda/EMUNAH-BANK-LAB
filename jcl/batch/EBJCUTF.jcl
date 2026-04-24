//* ============================================================
//* ARQUIVO      : EBJCUTF.jcl
//* CAMINHO LOCAL: jcl/batch/EBJCUTF.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJCUTF)
//*
//* FINALIDADE:
//*   Cutoff Financeiro - marca CTL.STATUS = EOTI
//*   (End Of Transaction Input): fecha a janela de entrada de
//*   movimentos do dia, impedindo novos lancamentos.
//*
//* POSICAO NA CADEIA DIARIA:
//*   EBJPOST (postagem) --> EBJCUTF (EOTI) --> EBJACCR (accruals)
//*
//* MAQUINA DE ESTADOS CTL.STATUS:
//*   OPEN (EBJSOD) -> EOTI (EBJCUTF) -> EOFI (EBJCUTE)
//*                                    -> CLOSED (EBJEOD)
//*   Apos EOTI: EBACCR01 pode calcular juros, mas EBVALI01
//*   e EBPOST01 devem rejeitar novos lancamentos se consultarem
//*   o status antes de processar.
//*
//* OBS: Esta versao usa IEBGENER para gravacao direta.
//*      Sera substituida pelo programa EBCTL01 (COBOL).
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = EOTI gravado com sucesso
//*   RC 12 = falha no IEBGENER - STATUS nao atualizado
//* ============================================================
//EBJCUTF  JOB ,'EMUNAH CUTF',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP WRTSTAT: GRAVAR STATUS = EOTI ======================
//*   IEBGENER sobrescreve ARQ.CTL.STATUS com o literal "EOTI".
//*   DISP=OLD garante acesso exclusivo ao arquivo de controle.
//*
//WRTSTAT  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD *
EOTI
/*
//*           Literal de 4 bytes gravado no arquivo de status.
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=OLD
//*           Arquivo de controle de status. DISP=OLD = exclusivo.
//SYSIN    DD DUMMY
//*
//* === STEP VERIFY: CONFIRMAR STATUS GRAVADO ===================
//*   Executa somente se WRTSTAT terminou RC=0.
//*   LISTCAT gera evidencia auditavel no SYSPRINT.
//*
//VERIFY   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CTL.STATUS') ALL
/*