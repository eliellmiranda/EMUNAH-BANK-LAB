//* ============================================================
//* ARQUIVO      : EBJCLLD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJCLLD.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJCLLD)
//*
//* FINALIDADE:
//*   Executar o programa EBCLLOAD para carga inicial dos
//*   arquivos do laboratorio EMUNAH Bank Lab.
//*
//* O QUE ESTE JOB FAZ:
//*   1. Le arquivo sequencial de clientes (CLIENTIN)
//*   2. Le arquivo sequencial de contas   (CONTAIN)
//*   3. Grava clientes no VSAM KSDS (CLIENTE)
//*   4. Grava contas no VSAM KSDS (CONTA)
//*   5. Registra eventos na auditoria (AUDIT)
//*
//* PRE-REQUISITOS:
//*   - EBALLOC ja executado (VSAMs alocados e catalogados)
//*   - Arquivos seed presentes em SEED.CLIENTES.SEQ e SEED.CONTAS.SEQ
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = carga concluida sem erros
//*   RC 8  = erro de I/O (duplicata ou KSDS inacessivel)
//*   RC 12 = erro critico de abertura de arquivo
//* ============================================================
//EBJCLLD  JOB ,'EMUNAH CARGA',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*           EBJCLLD   = nome do job no JES
//*           CLASS=A   = classe de execucao do ambiente
//*           MSGCLASS=X = classe de saida do spool
//*           MSGLEVEL=(1,1) = exibe instrucoes JCL + mensagens
//*
//* === STEP1: CARGA INICIAL (EBCLLOAD) ==========================
//*   EBCLLOAD le os dois arquivos de seed e popula os KSDS.
//*   Duplicatas sao detectadas por INVALID KEY e auditadas.
//*
//STEP1    EXEC PGM=EBCLLOAD
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//*           Biblioteca contendo o modulo executavel EBCLLOAD.
//*           DISP=SHR = acesso compartilhado (leitura).
//CLIENTIN DD DSN=Z77948.EMUNAH.SEED.CLIENTES.SEQ,DISP=SHR
//*           Arquivo sequencial de entrada com registros de
//*           clientes no layout CPCLI001 (80 bytes, RECFM=FB).
//*           DDNAME esperado pelo programa: CLIENTIN.
//CONTAIN  DD DSN=Z77948.EMUNAH.SEED.CONTAS.SEQ,DISP=SHR
//*           Arquivo sequencial de entrada com registros de
//*           contas no layout CPCNT001 (100 bytes, RECFM=FB).
//*           DDNAME esperado pelo programa: CONTAIN.
//CLIENTE  DD DSN=Z77948.EMUNAH.ARQ.CLIENTE.KSDS,DISP=SHR
//*           VSAM KSDS de clientes - destino da carga.
//*           Chave: CLI-ID-CLIENTE. INVALID KEY detecta duplicatas.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//*           VSAM KSDS de contas - destino da carga.
//*           Chave: CNT-CHAVE (agencia 4 + conta 8).
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//*           Auditoria do processamento.
//*           DISP=MOD = append; preserva registros anteriores.
//SYSOUT   DD SYSOUT=*
//*           Saida operacional do programa (DISPLAY/WRITE SYSOUT).
//SYSPRINT DD SYSOUT=*
//*           Mensagens tecnicas e relatorio de diagnostico.