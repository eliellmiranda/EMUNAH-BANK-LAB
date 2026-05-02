//* ============================================================
//* ARQUIVO      : EBJEXTR.jcl
//* CAMINHO LOCAL: jcl/batch/EBJEXTR.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJEXTR)
//*
//* FINALIDADE:
//* Gerar o extrato de movimentos do dia a partir dos
//* lancamentos ja validados e postados.
//*
//* POSICAO NA CADEIA DIARIA:
//* EBJPOST --> EBJEXTR (pode ser paralelo ao EBJCONC)
//*
//* O QUE ESTE JOB FAZ:
//* 1. Le todos os lancamentos do ESDS (MOVTIN)
//* 2. Formata cada movimento com data DD/MM/AAAA,
//* tipo, valor editado, historico e canal
//* 3. Agrupa por conta (agencia+numero)
//* 4. Grava extrato em nova geracao GDG (EXTROUT)
//*
//* GDG DE EXTRATO:
//* Cada execucao gera EXTRATO.GDG(+1).
//* Consulta de dias anteriores: GDG(-1), GDG(-2), etc.
//* Retencao controlada pela base GDG (EBDEFGDG).
//*
//* CODIGOS DE RETORNO:
//* RC 0 = extrato gerado com sucesso
//* RC 4 = LANCTO.ESDS vazio - extrato gerado sem linhas
//* RC 8 = erro de I/O
//* ============================================================
//EBJEXTR  JOB ,'EMUNAH EXTR',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP1: GERAR EXTRATO (EBEXTR01) =========================
//*
//STEP1    EXEC PGM=EBEXTR01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca contendo o modulo executavel EBEXTR01.
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//* VSAM ESDS de lancamentos validados/postados.
//* Leitura sequencial (browse) do inicio ao fim.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* KSDS de contas para lookup do saldo-posicao
//* (saldo atual do KSDS, nao historico).
//*
//* --- ARQUIVOS DE SAIDA (EXTRATO GDG) ---
//EXTROUT  DD DSN=Z77948.EMUNAH.ARQ.EXTRATO.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//* Extrato gerado para cada cliente (LRECL=132).
//*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*