//* ============================================================
//* ARQUIVO      : EBJEOD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJEOD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJEOD)
//*
//* FINALIDADE:
//*   Fechamento diario (End-Of-Day): consolida o dia contabil,
//*   gera relatorio de fechamento e marca CTL.STATUS = CLOSED.
//*
//* POSICAO NA CADEIA DIARIA:
//*   EBJCONC (conciliacao) --> EBJEOD --> fim do ciclo
//*
//* O QUE ESTE JOB FAZ:
//*   1. STEP1   - EBJEOD01 le CONCIL.SEQ, detecta divergencias
//*                (R11/R31 com CC-STATUS contendo 'DIVERGENTE'),
//*                totaliza contas, gera FECHOUT (relatorio de
//*                fechamento) e registra na auditoria.
//*   2. CLOSDAY - IEBGENER grava "CLOSED" em CTL.STATUS apenas
//*                se STEP1 terminou com RC=0 (dia sem erros).
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = dia fechado com sucesso - CLOSED gravado
//*   RC 4  = aviso em STEP1 - CLOSDAY nao executa, revisar
//*   RC 8  = divergencia detectada - CLOSDAY bloqueado
//*   RC 12 = falha critica - investigar antes de rerun
//* ============================================================
//EBJEOD   JOB ,'EMUNAH EOD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP1: FECHAMENTO DIARIO (EBJEOD01) =====================
//*
//STEP1    EXEC PGM=EBJEOD01
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//*           Biblioteca contendo o modulo executavel EBJEOD01.
//CONCIN   DD DSN=Z77948.EMUNAH.ARQ.CONCIL.SEQ,DISP=SHR
//*           Arquivo de conciliacao gerado pelo EBJCONC.
//*           EBJEOD01 le registros R11/R31 para detectar
//*           divergencias (CC-STATUS(1:10)='DIVERGENTE').
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//*           VSAM KSDS de contas para totalizacao do dia.
//SALDOIN  DD DSN=Z77948.EMUNAH.ARQ.SALDO.GDG(0),DISP=SHR
//*           GDG de saldo do dia anterior (opcional).
//*           Se ausente, o programa usa saldo inicial zero.
//FECHOUT  DD DSN=Z77948.EMUNAH.ARQ.FECHTO.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(5,5)),
//             DCB=(RECFM=FB,LRECL=132,BLKSIZE=0)
//*           Relatorio de fechamento do dia.
//*           LRECL=132 = largura padrao de impressora mainframe.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//*           Auditoria do fechamento. DISP=MOD = append.
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*
//* === STEP CLOSDAY: GRAVAR STATUS = CLOSED ====================
//*   COND=(0,NE): executa SOMENTE se STEP1 terminou com RC=0.
//*   Isso garante que o dia so e marcado CLOSED se o EOD
//*   processou sem erros ou divergencias bloqueantes.
//*   DISP=OLD: sobrescreve o conteudo anterior (era EOFI).
//*
//CLOSDAY  EXEC PGM=IEBGENER,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD *
CLOSED
/*
//*           Literal de 6 bytes gravado no arquivo de status.
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=OLD
//*           Arquivo de controle. DISP=OLD = acesso exclusivo.
//SYSIN    DD DUMMY