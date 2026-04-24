//* ============================================================
//* ARQUIVO      : EBJPOSTP.jcl
//* CAMINHO LOCAL: jcl/prd/EBJPOSTP.jcl
//* HOST / PDS   : Z77948.EMUNAH.PRD.JCL(EBJPOSTP)
//*
//* FINALIDADE:
//*   Executar a postagem de movimentos (EBPOST01) em producao.
//*
//* DIFERENCAS EM RELACAO AO BATCH DEV (EBJPOST):
//*   - STEPLIB aponta para PRD.LOADLIB (executaveis promovidos)
//*   - CONTA usa DISP=OLD (exclusivo) ao inves de DISP=SHR
//*   - NOTIFY=&SYSUID notifica o submissor ao terminar
//*
//* POR QUE CONTA USA DISP=OLD EM PRD:
//*   DISP=OLD garante acesso exclusivo ao KSDS durante a postagem,
//*   impedindo que outros jobs leiam dados inconsistentes (saldo
//*   parcialmente atualizado) durante o processamento.
//*   Em DEV/batch usa-se DISP=SHR pois o ambiente e controlado
//*   e nao ha risco de acesso concorrente.
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = todos os movimentos postados com sucesso
//*   RC 4  = algum movimento rejeitado por saldo insuficiente
//*   RC 8  = erro de I/O no KSDS de contas
//* ============================================================
//EBJPOSTP JOB ,'EMUNAH PRD POST',CLASS=A,MSGCLASS=X,
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*
//* === STEP1: POSTAGEM EM PRODUCAO (EBPOST01) ==================
//*
//STEP1    EXEC PGM=EBPOST01
//STEPLIB  DD DSN=Z77948.EMUNAH.PRD.LOADLIB,DISP=SHR
//*           LOADLIB oficial de producao. Contem os executaveis
//*           promovidos e testados em HML antes do deploy em PRD.
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.VALID.SEQ,DISP=SHR
//*           Arquivo de movimentos validos a postar em PRD.
//*           Leitura compartilhada (nao ha REWRITE neste arquivo).
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=OLD
//*           VSAM KSDS de contas. DISP=OLD = acesso exclusivo.
//*           Obrigatorio em PRD para garantir atomicidade dos
//*           REWRITE de saldo durante a postagem.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//*           Trilha de auditoria. DISP=MOD = append sem apagar
//*           o historico de execucoes anteriores do dia.
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*