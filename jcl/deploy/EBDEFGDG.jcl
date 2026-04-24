//* ============================================================
//* ARQUIVO      : EBDEFGDG.jcl
//* CAMINHO LOCAL: jcl/deploy/EBDEFGDG.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBDEFGDG)
//*
//* FINALIDADE:
//*   Definir as 6 bases GDG (Generation Data Groups) do
//*   laboratorio. Executar UMA UNICA VEZ apos EBALLOC.
//*
//* ORDEM DE EXECUCAO INICIAL DO AMBIENTE:
//*   1. EBALLOC  (datasets e VSAMs)
//*   2. EBDEFGDG (bases GDG)     <- este job
//*   3. EBSEED   (carga inicial)
//*
//* ATRIBUTOS GDG:
//*   LIMIT   = numero maximo de geracoes ativas no catalogo
//*   NOEMPTY = ao criar GDG(+1) com LIMIT atingido, descataloga
//*             a geracao mais antiga (GDG(-LIMIT)) sem deletar
//*             fisicamente. O dataset permanece em disco ate
//*             expiracao da data de retencao.
//*   SCRATCH = deleta fisicamente a geracao descatalogada pelo
//*             NOEMPTY, liberando espaco em disco automaticamente.
//*
//* LIMITES POR BASE E JUSTIFICATIVA:
//*   EXTRATO.GDG      LIMIT(30) = retencao mensal (1 por dia)
//*   SALDO.GDG        LIMIT(30) = retencao mensal (snapshot diario)
//*   BKP.CLIENTE.GDG  LIMIT(7)  = retencao semanal
//*   BKP.CONTA.GDG    LIMIT(7)  = retencao semanal
//*   BKP.AUDIT.GDG    LIMIT(14) = retencao quinzenal
//*   BKP.REJEITOS.GDG LIMIT(14) = retencao quinzenal
//*
//* DELETE + SET MAXCC=0 antes de cada DEFINE: idempotente.
//*   Permite reexecutar sem erro se a base ja existir.
//* ============================================================
//EBDEFGDG JOB ,'EMUNAH DEFGDG',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP DEFGDG: DEFINIR 6 BASES GDG ========================
//*
//DEFGDG   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'Z77948.EMUNAH.ARQ.EXTRATO.GDG' GDG FORCE
  SET MAXCC = 0
  DEFINE GENERATIONDATAGROUP -
    (NAME('Z77948.EMUNAH.ARQ.EXTRATO.GDG') -
     LIMIT(30) -
     NOEMPTY -
     SCRATCH)
//* Extratos diarios gerados pelo EBJEXTR (EBEXTR01). LIMIT=30.

  DELETE 'Z77948.EMUNAH.ARQ.SALDO.GDG' GDG FORCE
  SET MAXCC = 0
  DEFINE GENERATIONDATAGROUP -
    (NAME('Z77948.EMUNAH.ARQ.SALDO.GDG') -
     LIMIT(30) -
     NOEMPTY -
     SCRATCH)
//* Snapshots de saldo gerados pelo EBJSNAP (EBSNAP01). LIMIT=30.

  DELETE 'Z77948.EMUNAH.ARQ.BKP.CLIENTE.GDG' GDG FORCE
  SET MAXCC = 0
  DEFINE GENERATIONDATAGROUP -
    (NAME('Z77948.EMUNAH.ARQ.BKP.CLIENTE.GDG') -
     LIMIT(7) -
     NOEMPTY -
     SCRATCH)
//* Backup diario do KSDS de clientes (EBJBCKPD). LIMIT=7 (semana).

  DELETE 'Z77948.EMUNAH.ARQ.BKP.CONTA.GDG' GDG FORCE
  SET MAXCC = 0
  DEFINE GENERATIONDATAGROUP -
    (NAME('Z77948.EMUNAH.ARQ.BKP.CONTA.GDG') -
     LIMIT(7) -
     NOEMPTY -
     SCRATCH)
//* Backup diario do KSDS de contas (EBJBCKPD). LIMIT=7 (semana).

  DELETE 'Z77948.EMUNAH.ARQ.BKP.AUDIT.GDG' GDG FORCE
  SET MAXCC = 0
  DEFINE GENERATIONDATAGROUP -
    (NAME('Z77948.EMUNAH.ARQ.BKP.AUDIT.GDG') -
     LIMIT(14) -
     NOEMPTY -
     SCRATCH)
//* Backup de auditoria rotacionado pelo EBJHKAUD. LIMIT=14.

  DELETE 'Z77948.EMUNAH.ARQ.BKP.REJEITOS.GDG' GDG FORCE
  SET MAXCC = 0
  DEFINE GENERATIONDATAGROUP -
    (NAME('Z77948.EMUNAH.ARQ.BKP.REJEITOS.GDG') -
     LIMIT(14) -
     NOEMPTY -
     SCRATCH)
//* Backup de rejeitos rotacionado pelo EBJHKREJ. LIMIT=14.
/*
//*
//* === STEP VERIFY: CONFIRMAR DEFINICAO DAS 6 BASES ============
//*   LISTCAT ALL mostra LIMIT, NOEMPTY, SCRATCH e geracoes ativas.
//*
//VERIFY   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.EXTRATO.GDG')      ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.SALDO.GDG')        ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.BKP.CLIENTE.GDG')  ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.BKP.CONTA.GDG')    ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.BKP.AUDIT.GDG')    ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.BKP.REJEITOS.GDG') ALL
/*