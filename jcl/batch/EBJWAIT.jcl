//* ============================================================
//* ARQUIVO      : EBJWAIT.jcl
//* CAMINHO LOCAL: jcl/batch/EBJWAIT.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJWAIT)
//*
//* FINALIDADE:
//*   File-watcher do STAGE.ENTRADA.SEQ.
//*   Garante que o arquivo de entrada foi depositado e nao
//*   esta vazio antes de liberar a cadeia diaria (EBJLOAD).
//*
//* POSICAO NA CADEIA DIARIA:
//*   EBJPRECK --> EBJWAIT --> EBJLOAD --> EBJVALD --> ...
//*
//* O QUE ESTE JOB FAZ:
//*   1. CHKEXST : IDCAMS LISTCAT verifica se STAGE esta catalogado
//*   2. CHKCNT  : ICETOOL COUNT NOEMPTY aborta se vazio
//*
//* LIMITACOES DESTA VERSAO:
//*   - Nao valida registro trailer (count declarado)
//*   - Nao confere count fisico vs count declarado no trailer
//*   - Nao valida hash/checksum de integridade do arquivo
//*   Essas verificacoes entram com EBWAIT01 (COBOL) na Onda 5/6.
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = arquivo presente e nao vazio - cadeia liberada
//*   RC 4  = IDCAMS aviso (aceitar se LISTCAT imprimiu)
//*   RC 8  = STAGE nao catalogado ou ICETOOL detectou vazio
//*   RC 12 = falha critica
//* ============================================================
//EBJWAIT  JOB ,'EMUNAH WAIT',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP CHKEXST: VERIFICAR EXISTENCIA DO STAGE =============
//*   IDCAMS LISTCAT retorna RC=0 se o dataset esta catalogado,
//*   RC=8 se nao existe. Se RC != 0, CHKCNT nao executa.
//*
//CHKEXST  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.STAGE.ENTRADA.SEQ') ALL
/*
//*
//* === STEP CHKCNT: CONTAR REGISTROS (ABORTA SE VAZIO) ==========
//*   COND=(0,NE): executa somente se CHKEXST terminou RC=0.
//*   ICETOOL COUNT com NOEMPTY: encerra com RC != 0 se o
//*   arquivo nao contiver nenhum registro.
//*   Um arquivo vazio indica falha na transferencia do sistema
//*   externo e deve bloquear toda a cadeia batch do dia.
//*
//CHKCNT   EXEC PGM=ICETOOL,COND=(0,NE)
//TOOLMSG  DD SYSOUT=*
//*           Mensagens do ICETOOL (resultado do COUNT).
//DFSMSG   DD SYSOUT=*
//*           Mensagens do DFSORT subjacente.
//STAGE    DD DSN=Z77948.EMUNAH.STAGE.ENTRADA.SEQ,DISP=SHR
//*           Dataset a ser contado. Referenciado pelo FROM(STAGE).
//TOOLIN   DD *
  COUNT FROM(STAGE) NOEMPTY
/*
//*           COUNT: conta registros e retorna RC=0 se ok.
//*           NOEMPTY: eleva RC se nenhum registro encontrado.