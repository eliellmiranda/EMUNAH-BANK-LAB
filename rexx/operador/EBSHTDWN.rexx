/* REXX ----------------------------------------------------------- */
/* PROGRAMA : EBSHTDWN                                              */
/* FUNCAO   : SHUTDOWN ORDENADO DO AMBIENTE - EMUNAH BANK LAB       */
/* LOCAL    : RECURSO DE OPERADOR                                    */
/* USO      : EX 'HLQ.DEV.REXX(EBSHTDWN)'                          */
/*            EX 'HLQ.DEV.REXX(EBSHTDWN)' 'FORCE'  <- sem esperas  */
/*----------------------------------------------------------------- */
PARSE UPPER ARG MODO

FORCE = (MODO = 'FORCE')

SAY CENTER(' EMUNAH BANK - SHUTDOWN ORDENADO ',65,'-')
SAY 'DATA: ' DATE() ' HORA: ' TIME() ' USER: ' USERID()
SAY COPIES('=',65)
IF FORCE THEN
  SAY '*** MODO FORCE: TEMPOS DE ESPERA REDUZIDOS ***'
SAY ''

ERROS = 0

/* ---------------------------------------------------------------- */
/* PASSO 1 - CICS                                                   */
/* ---------------------------------------------------------------- */
CALL PASSO 1, 'CICS CICSTS61',
             'F CICSTS61,CEMT PERFORM SHUTDOWN',
             'Aguardando DFHME0116I (CICS IS SHUTDOWN)...',
             60

/* ---------------------------------------------------------------- */
/* PASSO 2 - IMS                                                     */
/* ---------------------------------------------------------------- */
CALL PASSO 2, 'IMS IVP/REGIOES',
             'F IMS15CR1,/CHECKPOINT FREEZE',
             'Aguardando DFS994I (IMS SHUTDOWN COMPLETED)...',
             45

/* ---------------------------------------------------------------- */
/* PASSO 3 - MQ                                                      */
/* ---------------------------------------------------------------- */
CALL PASSO 3, 'MQ CSQ9MSTR',
             'F CSQ9MSTR,STOP QMGR',
             'Aguardando CSQY221I (QMGR STOPPING)...',
             30

/* ---------------------------------------------------------------- */
/* PASSO 4 - DB2                                                     */
/* ---------------------------------------------------------------- */
CALL PASSO 4, 'DB2 DBD1',
             '-DBD1 STOP DB2 MODE(QUIESCE)',
             'Aguardando DSN9022I (STOP DB2 NORMAL COMPLETION)...',
             45

/* ---------------------------------------------------------------- */
/* PASSO 5 - ZOSMF                                                   */
/* ---------------------------------------------------------------- */
CALL PASSO 5, 'z/OSMF IZUSVR1',
             'F IZUSVR1,STOP',
             'Aguardando CWWKE0036I (server zosmf stopped)...',
             60

/* ---------------------------------------------------------------- */
/* PASSO 6 - RSEAPI                                                  */
/* ---------------------------------------------------------------- */
CALL PASSO 6, 'RSEAPI',
             'P RSEAPI',
             'Aguardando IEF404I RSEAPI ENDED...',
             20

/* ---------------------------------------------------------------- */
/* PASSO 7 - OMVS                                                   */
/* DEVE vir ANTES do NetView/SHUTSYS e do $PJES2.                   */
/* Omitir este passo deixa BPXAS ativos -> JES2 nao consegue parar  */
/* (BPXI061E / IEE342I STOP REJECTED-TASK BUSY).                    */
/* ---------------------------------------------------------------- */
CALL PASSO 7, 'OMVS (USS)',
             'F OMVS,SHUTDOWN',
             'Aguardando BPXF023I (OMVS SHUTDOWN COMPLETE)...',
             45

/* ---------------------------------------------------------------- */
/* PASSO 8 - NETVIEW SHUTSYS                                        */
/* NetView para todos os recursos gerenciados (TCPIP, etc.)         */
/* e depois encerra o proprio NetView                               */
/* ---------------------------------------------------------------- */
CALL PASSO 8, 'NETVIEW CNM01 (SHUTSYS)',
             '%NETV SHUTSYS',
             'Aguardando DSI008I (NETVIEW SHUTDOWN COMPLETE)...',
             60

/* ---------------------------------------------------------------- */
/* PASSO 9 - Z EOD + QUIESCE                                        */
/* ---------------------------------------------------------------- */
SAY ''
SAY COPIES('=',65)
SAY 'PASSO 9/9 - SHUTDOWN DO SISTEMA'
SAY COPIES('-',65)
SAY 'Emitindo Z EOD...'
ADDRESS CONSOLE 'Z EOD'
CALL ESPERAR 10
SAY 'Emitindo QUIESCE...'
ADDRESS CONSOLE 'QUIESCE'
SAY ''
SAY COPIES('=',65)
SAY 'SHUTDOWN INICIADO - ACOMPANHE O CONSOLE.'
SAY COPIES('=',65)
EXIT 0

/* ---------------------------------------------------------------- */
/* SUB-ROTINA: PASSO                                                 */
/* ---------------------------------------------------------------- */
PASSO:
  PARSE ARG NUM, NOME, CMD, MSGESPERA, SEGS

  SAY ''
  SAY COPIES('-',65)
  SAY 'PASSO' NUM'/9 -' NOME
  SAY 'Comando: >' CMD
  ADDRESS CONSOLE CMD
  IF RC <> 0 THEN DO
    SAY '*** AVISO: Comando retornou RC='RC'. Subsistema pode ja',
        'estar inativo.'
    ERROS = ERROS + 1
  END
  ELSE DO
    SAY MSGESPERA
    IF FORCE THEN
      CALL ESPERAR 5
    ELSE
      CALL ESPERAR SEGS
    SAY 'Continuando...'
  END
RETURN

/* ---------------------------------------------------------------- */
/* SUB-ROTINA: ESPERAR (segundos)                                    */
/* ---------------------------------------------------------------- */
ESPERAR:
  PARSE ARG SEGS
  CALL SYSCALLS 'ON'
  ADDRESS SYSCALL 'SLEEP' SEGS
  CALL SYSCALLS 'OFF'
RETURN
