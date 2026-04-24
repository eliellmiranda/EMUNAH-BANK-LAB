//* ============================================================
//* ARQUIVO      : EBJEODP.jcl
//* CAMINHO LOCAL: jcl/prd/EBJEODP.jcl
//* HOST / PDS   : Z77948.EMUNAH.PRD.JCL(EBJEODP)
//*
//* FINALIDADE:
//*   Executar o fechamento batch (End-Of-Day) em producao,
//*   simulando um fluxo mais proximo de um ambiente real:
//*   backup -> postagem -> conciliacao.
//*
//* DIFERENCAS EM RELACAO AO BATCH DEV (EBJEOD):
//*   - STEPLIB aponta para PRD.LOADLIB (executaveis promovidos)
//*   - Inclui step de backup (EBBACK01) antes da postagem
//*   - Usa IF/ENDIF condicional para garantir que postagem e
//*     conciliacao so ocorrem apos backup bem-sucedido
//*   - CONTA usa DISP=OLD (acesso exclusivo em PRD)
//*   - NOTIFY=&SYSUID notifica o submissor
//*
//* FLUXO DE 3 STEPS:
//*   STEPBKP  : EBBACK01 backup das contas (BAK.CONTA.SEQ)
//*   IF RC < 8 THEN:
//*     STEPPOST : EBPOST01 postagem dos movimentos
//*     STEPCONC : EBCONC01 conciliacao do resultado
//*   ENDIF
//* ============================================================
//EBJEODP  JOB ,'EMUNAH PRD EOD',CLASS=A,MSGCLASS=X,
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*
//* === STEP STEPBKP: BACKUP DAS CONTAS ANTES DO UPDATE =========
//*   EBBACK01 exporta o KSDS de contas para BAK.CONTA.SEQ,
//*   preservando o estado pre-batch para rollback se necessario.
//*
//STEPBKP  EXEC PGM=EBBACK01
//STEPLIB  DD DSN=Z77948.EMUNAH.PRD.LOADLIB,DISP=SHR
//*           LOADLIB oficial de producao (executaveis promovidos).
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//*           VSAM KSDS de contas - leitura para backup.
//BAKOUT   DD DSN=Z77948.EMUNAH.BAK.CONTA.SEQ,DISP=OLD
//*           Arquivo de backup das contas. DISP=OLD = sobrescreve.
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//*
//* === BLOCO CONDICIONAL: so executa se backup ok (RC < 8) ======
//*   IF/ENDIF e suportado pelo JES2/JES3 para controle de fluxo
//*   condicional mais legivel que COND= em cada EXEC.
//*
//IFPOST   IF (STEPBKP.RC LT 8) THEN
//*
//* === STEP STEPPOST: POSTAGEM DOS MOVIMENTOS (EBPOST01) ========
//*   CONTA usa DISP=OLD em PRD: acesso exclusivo para REWRITE,
//*   impedindo leituras concorrentes durante a atualizacao.
//*
//STEPPOST EXEC PGM=EBPOST01
//STEPLIB  DD DSN=Z77948.EMUNAH.PRD.LOADLIB,DISP=SHR
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.VALID.SEQ,DISP=SHR
//*           Movimentos validos a postar.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=OLD
//*           KSDS de contas. DISP=OLD = exclusivo para REWRITE.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//*           Auditoria da postagem. DISP=MOD = append.
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//*
//* === STEP STEPCONC: CONCILIACAO DO RESULTADO (EBCONC01) =======
//*
//STEPCONC EXEC PGM=EBCONC01
//STEPLIB  DD DSN=Z77948.EMUNAH.PRD.LOADLIB,DISP=SHR
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.VALID.SEQ,DISP=SHR
//*           Mesmos movimentos usados na postagem para conferencia.
//CONCOUT  DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,DISP=OLD
//*           Resultado da conciliacao. DISP=OLD = sobrescreve.
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//*
//ENDIF    ENDIF