//* ============================================================
//* ARQUIVO      : EBJVALD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJVALD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJVALD)
//*
//* FINALIDADE:
//*   Validar os lancamentos do dia recebidos em ARQ.ENTRADA.SEQ
//*   e segregar em aprovados (LANCTO.ESDS) e rejeitos.
//*
//* POSICAO NA CADEIA DIARIA:
//*   EBJLOAD (carga do arquivo) --> EBJVALD --> EBJPOST (postagem)
//*
//* O QUE ESTE JOB FAZ:
//*   1. Le ARQ.ENTRADA.SEQ registro a registro (ENTRADA)
//*   2. Aplica 6 regras de validacao (V001-V006):
//*      V001 = tipo 'C' ou 'D'
//*      V002 = agencia numerica > 0
//*      V003 = conta numerica > 0
//*      V004 = valor numerico > 0
//*      V005 = data numerica > 0
//*      V006 = conta existe no KSDS
//*   3. Aprovados -> LANCTO.ESDS (VALIDOS)
//*   4. Rejeitados -> REJEITOS.SEQ com codigo V00x (REJEITOS)
//*   5. Registra auditoria de cada decisao (AUDIT)
//*
//* CODIGOS DE RETORNO:
//*   RC 0 = todos aprovados
//*   RC 4 = ha rejeitos - verificar REJEITOS.SEQ
//*   RC 8 = erro de I/O
//* ============================================================
//EBJVALD  JOB ,'EMUNAH VALD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP1: VALIDACAO DE LANCAMENTOS (EBVALI01) ==============
//*
//STEP1    EXEC PGM=EBVALI01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//*           Biblioteca contendo o modulo executavel EBVALI01.
//ENTRADA  DD DSN=Z77948.EMUNAH.ARQ.ENTRADA.SEQ,DISP=SHR
//*           Arquivo de entrada com lancamentos do dia.
//*           Carregado pelo EBJLOAD a partir do STAGE.
//*           Layout CPLCT001 (120 bytes, RECFM=FB).
//VALIDOS  DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//*           VSAM ESDS de saida para lancamentos aprovados.
//*           Aberto em OUTPUT (EXTEND) pelo programa para
//*           append dos lancamentos validos do dia.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//*           VSAM KSDS de contas para validacao V006
//*           (existencia da conta no cadastro master).
//REJEITOS DD DSN=Z77948.EMUNAH.ARQ.REJEITOS.SEQ,
//             DISP=(MOD,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//*           Saida para lancamentos rejeitados.
//*           DISP=MOD: acumula rejeitos de multiplas execucoes
//*           do dia sem sobrescrever o conteudo anterior.
//*           CATLG na terminacao normal, DELETE em abend.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//*           Auditoria. DISP=MOD = append.
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*