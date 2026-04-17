       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBEXTR01.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT MOVTO-IN
               ASSIGN TO MOVTIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-MOVTIN.

           SELECT EXTRATO-OUT
               ASSIGN TO EXTROUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-EXTROUT.

       DATA DIVISION.
       FILE SECTION.

       FD  MOVTO-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  MOVTO-IN-REG.
           05 MV-AGENCIA              PIC 9(4).
           05 MV-CONTA                PIC 9(8).
           05 MV-DATA                 PIC 9(8).
           05 MV-TIPO                 PIC X(1).
           05 MV-VALOR                PIC 9(11)V99.
           05 MV-HISTORICO            PIC X(30).
           05 MV-CANAL                PIC X(10).
           05 FILLER                  PIC X(46).

       FD  EXTRATO-OUT
           RECORD CONTAINS 132 CHARACTERS
           RECORDING MODE IS F.
       01  EXTRATO-REG                PIC X(132).

       WORKING-STORAGE SECTION.

       01  WS-FILE-STATUS.
           05 WS-FS-MOVTIN            PIC XX.
           05 WS-FS-EXTROUT           PIC XX.

       01  WS-CONTROLES.
           05 WS-EOF-MOVTO            PIC X VALUE 'N'.

       01  WS-CONTADORES.
           05 WS-TOTAL-LIDOS          PIC 9(5) VALUE ZERO.
           05 WS-TOTAL-CREDITOS       PIC 9(5) VALUE ZERO.
           05 WS-TOTAL-DEBITOS        PIC 9(5) VALUE ZERO.
           05 WS-TOTAL-INVALIDOS      PIC 9(5) VALUE ZERO.

       01  WS-AREA-TRABALHO.
           05 WS-DATA-FMT.
              10 WS-DATA-ANO          PIC X(4).
              10 FILLER               PIC X VALUE '-'.
              10 WS-DATA-MES          PIC X(2).
              10 FILLER               PIC X VALUE '-'.
              10 WS-DATA-DIA          PIC X(2).
           05 WS-VALOR-EDIT           PIC ZZZ.ZZZ.ZZ9,99.
           05 WS-TIPO-DESC            PIC X(8).

       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR-ARQUIVOS
           PERFORM 2000-GERAR-EXTRATO
           PERFORM 9000-ENCERRAR
           GOBACK.

       1000-ABRIR-ARQUIVOS.
           OPEN INPUT  MOVTO-IN
           OPEN OUTPUT EXTRATO-OUT.

       2000-GERAR-EXTRATO.
           PERFORM 2100-GERAR-CABECALHO
           PERFORM UNTIL WS-EOF-MOVTO = 'S'
               READ MOVTO-IN
                   AT END
                       MOVE 'S' TO WS-EOF-MOVTO
                   NOT AT END
                       ADD 1 TO WS-TOTAL-LIDOS
                       PERFORM 2200-TRATAR-MOVIMENTO
               END-READ
           END-PERFORM.

       2100-GERAR-CABECALHO.
           MOVE ALL '-' TO EXTRATO-REG
           WRITE EXTRATO-REG
           MOVE SPACES TO EXTRATO-REG
           STRING 'EXTRATO DE MOVIMENTOS - EMUNAH BANK LAB'
                  DELIMITED BY SIZE
                  INTO EXTRATO-REG
           END-STRING
           WRITE EXTRATO-REG
           MOVE SPACES TO EXTRATO-REG
           STRING 'DATA       AG   CONTA      TIPO   VALOR HISTORICO'
                  DELIMITED BY SIZE
                  INTO EXTRATO-REG
           END-STRING
           WRITE EXTRATO-REG
           MOVE ALL '-' TO EXTRATO-REG
           WRITE EXTRATO-REG.

       2200-TRATAR-MOVIMENTO.
           EVALUATE MV-TIPO
               WHEN 'C'
                   MOVE 'CREDITO' TO WS-TIPO-DESC
                   ADD 1 TO WS-TOTAL-CREDITOS
                   PERFORM 2300-ESCREVER-LINHA
               WHEN 'D'
                   MOVE 'DEBITO ' TO WS-TIPO-DESC
                   ADD 1 TO WS-TOTAL-DEBITOS
                   PERFORM 2300-ESCREVER-LINHA
               WHEN OTHER
                   ADD 1 TO WS-TOTAL-INVALIDOS
           END-EVALUATE.

       2300-ESCREVER-LINHA.
           MOVE MV-DATA (1:4) TO WS-DATA-ANO
           MOVE MV-DATA (5:2) TO WS-DATA-MES
           MOVE MV-DATA (7:2) TO WS-DATA-DIA
           MOVE MV-VALOR      TO WS-VALOR-EDIT

           MOVE SPACES TO EXTRATO-REG
           STRING WS-DATA-FMT
                  '   '
                  MV-AGENCIA
                  '   '
                  MV-CONTA
                  '   '
                  WS-TIPO-DESC
                  '   '
                  WS-VALOR-EDIT
                  '   '
                  MV-HISTORICO
                  DELIMITED BY SIZE
                  INTO EXTRATO-REG
           END-STRING
           WRITE EXTRATO-REG.

       9000-ENCERRAR.
           MOVE ALL '-' TO EXTRATO-REG
           WRITE EXTRATO-REG

           MOVE SPACES TO EXTRATO-REG
           STRING 'TOTAL LIDOS     : '
                  WS-TOTAL-LIDOS
                  DELIMITED BY SIZE
                  INTO EXTRATO-REG
           END-STRING
           WRITE EXTRATO-REG

           MOVE SPACES TO EXTRATO-REG
           STRING 'TOTAL CREDITOS  : '
                  WS-TOTAL-CREDITOS
                  DELIMITED BY SIZE
                  INTO EXTRATO-REG
           END-STRING
           WRITE EXTRATO-REG

           MOVE SPACES TO EXTRATO-REG
           STRING 'TOTAL DEBITOS   : '
                  WS-TOTAL-DEBITOS
                  DELIMITED BY SIZE
                  INTO EXTRATO-REG
           END-STRING
           WRITE EXTRATO-REG

           MOVE SPACES TO EXTRATO-REG
           STRING 'TOTAL INVALIDOS : '
                  WS-TOTAL-INVALIDOS
                  DELIMITED BY SIZE
                  INTO EXTRATO-REG
           END-STRING
           WRITE EXTRATO-REG

           DISPLAY '*** RESUMO EXTRATO ***'
           DISPLAY 'MOVIMENTOS LIDOS    : ' WS-TOTAL-LIDOS
           DISPLAY 'CREDITOS            : ' WS-TOTAL-CREDITOS
           DISPLAY 'DEBITOS             : ' WS-TOTAL-DEBITOS
           DISPLAY 'INVALIDOS           : ' WS-TOTAL-INVALIDOS

           CLOSE MOVTO-IN
           CLOSE EXTRATO-OUT.
