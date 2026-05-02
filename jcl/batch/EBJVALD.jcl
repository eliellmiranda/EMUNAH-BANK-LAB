//* ============================================================
//* ARQUIVO      : EBJVALD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJVALD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJVALD)
//*
//* FINALIDADE:
//* Validar os lancamentos do dia recebidos em ARQ.ENTRADA.SEQ
//* e segregar em aprovados (LANCTO.ESDS) e rejeitos.
//*
//* POSICAO NA CADEIA DIARIA:
//* EBJLOAD (carga do arquivo) --> EBJVALD --> EBJPOST (postagem)
//*
//* O QUE ESTE JOB FAZ:
//* 0. Valida se o CTL.STATUS = OPEN (janela de entrada aberta)
//* 1. Le ARQ.ENTRADA.SEQ registro a registro (ENTRADA)
//* 2. Aplica 6 regras de validacao (V001-V006)
//* 3. Aprovados -> LANCTO.ESDS (VALIDOS)
//* 4. Rejeitados -> REJEITOS.SEQ com codigo V00x (REJEITOS)
//* 5. Registra auditoria de cada decisao (AUDIT)
//*
//* CODIGOS DE RETORNO:
//* RC 0 = todos aprovados
//* RC 4 = ha rejeitos - verificar REJEITOS.SEQ
//* RC 8 = dia nao esta OPEN (EBCTL01) ou erro de I/O
//* ============================================================
//EBJVALD  JOB ,'EMUNAH VALD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP CHKSTAT: GARANTIR QUE O DIA ESTA ABERTO ===========
//* Usa o EBCTL01 em modo leitura (CHK) para validar se o
//* status e OPEN. Impede validacao de novos lancamentos se ja
//* passou do horario de corte (EOTI/EOFI) ou se dia fechado.
//*
//CHKSTAT  EXEC PGM=EBCTL01,PARM='CHK,OPEN'
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=SHR
//*
//* === STEP VALIDA: VALIDACAO DE LANCAMENTOS (EBVALI01) =======
//* Executa somente se a checagem de status retornou RC=0.
//*
//VALIDA   EXEC PGM=EBVALI01,COND=(0,NE)
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca contendo o modulo executavel EBVALI01.
//ENTRADA  DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,DISP=SHR
//* Arquivo de entrada com lancamentos do dia.
//VALIDOS  DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=OLD
//* VSAM ESDS para lancamentos aprovados.
//* DISP=OLD garante lock exclusivo para insercao segura.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* VSAM KSDS de contas para validacao V006 (somente leitura).
//REJEITOS DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,
//             DISP=(MOD,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=156,BLKSIZE=0)
//* Saida para lancamentos rejeitados.
//* DISP=MOD: acumula rejeitos de multiplas execucoes
//* do dia sem sobrescrever o conteudo anterior.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,
//             DISP=(MOD,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=128,BLKSIZE=0)
//* Auditoria. DISP=MOD = append.
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*