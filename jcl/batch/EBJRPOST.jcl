//* ============================================================
//* ARQUIVO      : EBJRPOST.jcl
//* CAMINHO LOCAL: jcl/batch/EBJRPOST.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJRPOST)
//*
//* FINALIDADE:
//*   Postar nas contas os lancamentos reprocessados pelo EBJREPR.
//*   Fecha o ciclo completo de rejeitos:
//*   EBJVALD -> EBJREPR -> EBJRPOST
//*
//* POSICAO NA CADEIA:
//*   EBJREPR (recuperados em REPR.LANCTO.SEQ) --> EBJRPOST
//*   --> EBJHKREJ (housekeeping de rejeitos)
//*
//* REUTILIZACAO DO EBPOST01:
//*   Este JCL executa o mesmo programa EBPOST01 do EBJPOST,
//*   porem MOVTIN aponta para REPR.LANCTO.SEQ (arquivo
//*   sequencial PS) ao inves do LANCTO.ESDS (VSAM ESDS).
//*   EBPOST01 usa ORGANIZATION SEQUENTIAL no SELECT, tornando
//*   a leitura agnostica entre ESDS e PS via DDNAME MOVTIN.
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = todos os reprocessados postados com sucesso
//*   RC 4  = algum reprocessado rejeitado por saldo insuficiente
//*   RC 8  = erro de I/O no KSDS de contas
//*   RC 12 = erro critico de abertura de arquivo
//* ============================================================
//EBJRPOST JOB ,'EMUNAH RPOST',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP1: POSTAGEM DE REPROCESSADOS (EBPOST01) =============
//*
//STEP1    EXEC PGM=EBPOST01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//*           Biblioteca contendo o modulo executavel EBPOST01.
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.REPR.LANCTO.SEQ,DISP=SHR
//*           Entrada: lancamentos recuperados pelo EBJREPR.
//*           Arquivo sequencial PS (nao ESDS); mesmo DDNAME
//*           MOVTIN permite reutilizacao do EBPOST01.
//CLIENTE  DD DSN=Z77948.EMUNAH.ARQ.CLIENTE.KSDS,DISP=SHR
//*           VSAM KSDS de clientes para validacao do cadastro.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//*           VSAM KSDS de contas. Aberto I-O para REWRITE.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//*           Auditoria da postagem de reprocessados. DISP=MOD.
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*