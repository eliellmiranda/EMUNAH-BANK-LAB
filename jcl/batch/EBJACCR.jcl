//* ============================================================
//* ARQUIVO      : EBJACCR.jcl
//* CAMINHO LOCAL: jcl/batch/EBJACCR.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJACCR)
//*
//* FINALIDADE:
//* Calcular e aplicar accruals diarios (juros e tarifas)
//* sobre as contas ativas do laboratorio.
//*
//* POSICAO NA CADEIA DIARIA:
//* EBJCUTF (-> EOTI) --> EBJACCR --> EBJCUTE (-> EOFI)
//* Os accruals sao calculados APOS o corte financeiro (EOTI)
//* e ANTES do corte contabil (EOFI), garantindo que os juros
//* do dia sejam incorporados antes do fechamento contabil.
//*
//* PRE-REQUISITOS:
//* - EBALLOC e EBDEFGDG ja executados (infraestrutura pronta)
//* - ARQ.CTL.STATUS = EOTI (validado pelo step CHKSTAT)
//* - PARM.JUROS.CONFIG catalogado com regras do dia
//*
//* CODIGOS DE RETORNO:
//* RC 0  = accruals aplicados com sucesso em todas as contas
//* RC 4  = CONTA.KSDS vazio - nenhum accrual calculado
//* RC 8  = dia nao esta EOTI (EBCTL01) ou erro de I/O
//* RC 12 = erro critico - CONTA.KSDS ou LANCTO.ESDS inacessivel
//* ============================================================
//EBJACCR  JOB ,'EMUNAH ACCR',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP CHKSTAT: GARANTIR CORTE FINANCEIRO (EOTI) =========
//* Usa o EBCTL01 em modo leitura (CHK) para validar se o
//* status e EOTI. Impede a geracao de juros se o dia ainda
//* estiver OPEN (aceitando entradas) ou ja estiver EOFI/CLOSED.
//*
//CHKSTAT  EXEC PGM=EBCTL01,PARM='CHK,EOTI'
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=SHR
//*
//* === STEP ACCR: APLICAR ACCRUALS (EBACCR01) ==================
//* Executa somente se a checagem de status retornou RC=0.
//* EBACCR01 le PARM.JUROS.CONFIG (regras de juros/tarifas),
//* percorre o CONTA.KSDS por READ NEXT, calcula juros para
//* contas Corrente/Poupanca e tarifas conforme configuracao,
//* faz REWRITE do saldo atualizado no KSDS, grava movimento
//* em ACCROUT e appenda lancamento no LANCTO.ESDS.
//*
//ACCR     EXEC PGM=EBACCR01,COND=(0,NE)
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca contendo o modulo executavel EBACCR01.
//PARMLIB  DD DSN=Z77948.EMUNAH.PARM.JUROS.CONFIG,DISP=SHR
//* Arquivo de parametros de juros e tarifas.
//* Layout: pos1=tipo (J/T/*), pos2=modalidade (C/P),
//* pos3-7=taxa PIC 9(3)V99. Uma regra por registro.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* VSAM KSDS de contas. Aberto em I-O pelo programa
//* para REWRITE dos saldos apos calculo do accrual.
//ACCROUT  DD DSN=Z77948.EMUNAH.ARQ.ACCR.MOV.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,SPACE=(TRK,(10,5)),
//             DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//* Arquivo de movimentos de accrual do dia.
//* Serve como evidencia auditavel dos juros aplicados.
//* NEW/CATLG = cria nova geracao a cada execucao.
//LANCTO   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//* VSAM ESDS historico de lancamentos.
//* Aberto em EXTEND pelo programa para append dos
//* movimentos de juros/tarifas gerados no dia.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Arquivo de auditoria. DISP=MOD garante append
//* sem apagar registros de steps anteriores do dia.
//SYSOUT   DD SYSOUT=*
//* Saida operacional do programa (DISPLAY).
//SYSPRINT DD SYSOUT=*
//* Mensagens tecnicas e diagnostico do sistema.