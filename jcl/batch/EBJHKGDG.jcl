//* ============================================================
//* ARQUIVO      : EBJHKGDG.jcl
//* CAMINHO LOCAL: jcl/batch/EBJHKGDG.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJHKGDG)
//*
//* FINALIDADE:
//*   Housekeeping de monitoramento das bases GDG do laboratorio.
//*   Gera evidencia do estado atual de cada base: quantidade
//*   de geracoes ativas, LIMIT configurado, atributos NOEMPTY/
//*   SCRATCH e lista de todas as geracoes catalogadas.
//*
//* O QUE ESTE JOB FAZ:
//*   Executa IDCAMS LISTCAT ALL para as 6 bases GDG:
//*   1. ARQ.EXTRATO.GDG     - extratos diarios
//*   2. ARQ.SALDO.GDG       - snapshots de saldo
//*   3. ARQ.BKP.CLIENTE.GDG - backup do KSDS de clientes
//*   4. ARQ.BKP.CONTA.GDG   - backup do KSDS de contas
//*   5. ARQ.BKP.AUDIT.GDG   - backup de auditoria
//*   6. ARQ.BKP.REJEITOS.GDG- backup de rejeitos
//*
//* IMPORTANTE - O QUE ESTE JOB NAO FAZ:
//*   Nao realiza DELETE ativo de geracoes antigas.
//*   A expiracao automatica e controlada pelos atributos
//*   NOEMPTY e SCRATCH definidos na base GDG (EBDEFGDG).
//*   Quando o LIMIT e atingido, a geracao mais antiga e
//*   automaticamente descatalogada pelo sistema ao criar (+1).
//*
//* FREQUENCIA:
//*   Executar periodicamente (semanal ou mensal) como
//*   monitoramento operacional. Saida em SYSPRINT e
//*   arquivavel como trilha de auditoria.
//* ============================================================
//EBJHKGDG JOB ,'EMUNAH HKGDG',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP LISTGDG: LISTAR ESTADO DAS 6 BASES GDG =============
//*   LISTCAT ALL mostra: nome da base, LIMIT, geracoes ativas,
//*   atributos NOEMPTY/SCRATCH, VOLSER e CREDT/EXPDT de cada
//*   geracao. Saida apenas em SYSPRINT (sem arquivos de saida).
//*
//LISTGDG  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.EXTRATO.GDG')      ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.SALDO.GDG')        ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.BKP.CLIENTE.GDG')  ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.BKP.CONTA.GDG')    ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.BKP.AUDIT.GDG')    ALL
  LISTCAT ENT('Z77948.EMUNAH.ARQ.BKP.REJEITOS.GDG') ALL
/*