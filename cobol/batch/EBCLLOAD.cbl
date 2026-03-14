       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCLLOAD.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CLIENTES-IN
               ASSIGN TO CLIENTIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CLIENTIN.

           SELECT CONTAS-IN
               ASSIGN TO CONTAIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CONTAIN.

           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

           SELECT CLIENTE-KSDS
               ASSIGN TO CLIENTE
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CLI-ID-CLIENTE
               FILE STATUS IS WS-FS-CLIENTE.

           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CNT-KEY
               FILE STATUS IS WS-FS-CONTA.

       DATA DIVISION.
       FILE SECTION.

       FD  CLIENTES-IN
           RECORD CONTAINS 80 CHARACTERS
           RECORDING MODE IS F.
       01  CLIENTES-IN-REG.
           COPY CPCLI001.

       FD  CONTAS-IN
           RECORD CONTAINS 100 CHARACTERS
           RECORDING MODE IS F.
       01  CONTAS-IN-REG.
           COPY CPCNT001.

       FD  AUDIT-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG                  PIC X(120).

       FD  CLIENTE-KSDS.
       01  CLIENTE-KSDS-REG.
           COPY CPCLI001.

       FD  CONTA-KSDS.
       01  CONTA-KSDS-REG.
           COPY CPCNT001.

       WORKING-STORAGE SECTION.

       01  WS-FILE-STATUS.
           05 WS-FS-CLIENTIN          PIC XX.
           05 WS-FS-CONTAIN           PIC XX.
           05 WS-FS-AUDIT             PIC XX.
           05 WS-FS-CLIENTE           PIC XX.
           05 WS-FS-CONTA             PIC XX.

       01  WS-CONTROLES.
           05 WS-EOF-CLIENTES         PIC X VALUE 'N'.
           05 WS-EOF-CONTAS           PIC X VALUE 'N'.

       01  WS-CONTADORES.
           05 WS-CLI-LIDOS            PIC 9(5) VALUE ZERO.
           05 WS-CLI-GRAVADOS         PIC 9(5) VALUE ZERO.
           05 WS-CLI-REJEITADOS       PIC 9(5) VALUE ZERO.
           05 WS-CNT-LIDOS            PIC 9(5) VALUE ZERO.
           05 WS-CNT-GRAVADOS         PIC 9(5) VALUE ZERO.
           05 WS-CNT-REJEITADOS       PIC 9(5) VALUE ZERO.

       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR-ARQUIVOS
           PERFORM 2000-CARREGAR-CLIENTES
           PERFORM 3000-CARREGAR-CONTAS
           PERFORM 9000-ENCERRAR
           GOBACK.

       1000-ABRIR-ARQUIVOS.
           OPEN INPUT CLIENTES-IN
           OPEN INPUT CONTAS-IN
           OPEN I-O   CLIENTE-KSDS
           OPEN I-O   CONTA-KSDS
           OPEN EXTEND AUDIT-OUT.

       2000-CARREGAR-CLIENTES.
           PERFORM UNTIL WS-EOF-CLIENTES = 'S'
               READ CLIENTES-IN
                   AT END
                       MOVE 'S' TO WS-EOF-CLIENTES
                   NOT AT END
                       ADD 1 TO WS-CLI-LIDOS
                       PERFORM 2100-VALIDAR-CLIENTE
               END-READ
           END-PERFORM.

       2100-VALIDAR-CLIENTE.
           IF CLI-STATUS NOT = 'A'
              AND CLI-STATUS NOT = 'I'
              AND CLI-STATUS NOT = 'B'
               ADD 1 TO WS-CLI-REJEITADOS
               MOVE SPACES TO AUDIT-REG
               STRING 'CLIENTE REJEITADO - STATUS INVALIDO - ID '
                      CLI-ID-CLIENTE
                      DELIMITED BY SIZE
                      INTO AUDIT-REG
               END-STRING
               WRITE AUDIT-REG
           ELSE
               MOVE CLIENTES-IN-REG TO CLIENTE-KSDS-REG
               WRITE CLIENTE-KSDS-REG
                   INVALID KEY
                       ADD 1 TO WS-CLI-REJEITADOS
                       MOVE SPACES TO AUDIT-REG
                       STRING 'CLIENTE REJEITADO - DUPLICADO - ID '
                              CLI-ID-CLIENTE
                              DELIMITED BY SIZE
                              INTO AUDIT-REG
                       END-STRING
                       WRITE AUDIT-REG
                   NOT INVALID KEY
                       ADD 1 TO WS-CLI-GRAVADOS
               END-WRITE
           END-IF.

       3000-CARREGAR-CONTAS.
           PERFORM UNTIL WS-EOF-CONTAS = 'S'
               READ CONTAS-IN
                   AT END
                       MOVE 'S' TO WS-EOF-CONTAS
                   NOT AT END
                       ADD 1 TO WS-CNT-LIDOS
                       PERFORM 3100-VALIDAR-CONTA
               END-READ
           END-PERFORM.

       3100-VALIDAR-CONTA.
           IF CNT-STATUS NOT = 'A'
              AND CNT-STATUS NOT = 'I'
              AND CNT-STATUS NOT = 'B'
               ADD 1 TO WS-CNT-REJEITADOS
               MOVE SPACES TO AUDIT-REG
               STRING 'CONTA REJEITADA - STATUS INVALIDO - AG '
                      CNT-AGENCIA ' CTA ' CNT-NUM-CONTA
                      DELIMITED BY SIZE
                      INTO AUDIT-REG
               END-STRING
               WRITE AUDIT-REG
           ELSE
               MOVE CONTAS-IN-REG TO CONTA-KSDS-REG
               WRITE CONTA-KSDS-REG
                   INVALID KEY
                       ADD 1 TO WS-CNT-REJEITADOS
                       MOVE SPACES TO AUDIT-REG
                       STRING 'CONTA REJEITADA - DUPLICADA - AG '
                              CNT-AGENCIA ' CTA ' CNT-NUM-CONTA
                              DELIMITED BY SIZE
                              INTO AUDIT-REG
                       END-STRING
                       WRITE AUDIT-REG
                   NOT INVALID KEY
                       ADD 1 TO WS-CNT-GRAVADOS
               END-WRITE
           END-IF.

       9000-ENCERRAR.
           DISPLAY '*** RESUMO CARGA INICIAL ***'
           DISPLAY 'CLIENTES LIDOS      : ' WS-CLI-LIDOS
           DISPLAY 'CLIENTES GRAVADOS   : ' WS-CLI-GRAVADOS
           DISPLAY 'CLIENTES REJEITADOS : ' WS-CLI-REJEITADOS
           DISPLAY 'CONTAS LIDAS        : ' WS-CNT-LIDOS
           DISPLAY 'CONTAS GRAVADAS     : ' WS-CNT-GRAVADOS
           DISPLAY 'CONTAS REJEITADAS   : ' WS-CNT-REJEITADOS

           CLOSE CLIENTES-IN
           CLOSE CONTAS-IN
           CLOSE CLIENTE-KSDS
           CLOSE CONTA-KSDS
           CLOSE AUDIT-OUT.
