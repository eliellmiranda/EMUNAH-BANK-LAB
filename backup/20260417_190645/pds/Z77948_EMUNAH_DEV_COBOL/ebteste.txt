       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBTESTE.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ARQ-IN
               ASSIGN TO CLIENTIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-IN.
           SELECT ARQ-KSDS
               ASSIGN TO CLIENTE
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS KSDS-CHAVE
               FILE STATUS IS WS-FS-KSDS.
       DATA DIVISION.
       FILE SECTION.
       FD  ARQ-IN
           RECORD CONTAINS 80 CHARACTERS
           RECORDING MODE IS F.
       01  ARQ-IN-REG.
           COPY CPCLI001.
       FD  ARQ-KSDS
           RECORD CONTAINS 80 CHARACTERS.
       01  ARQ-KSDS-REG.
           05 KSDS-CHAVE       PIC 9(05).
           05 FILLER           PIC X(75).
       WORKING-STORAGE SECTION.
       01  WS-FS-IN            PIC XX.
       01  WS-FS-KSDS          PIC XX.
       01  WS-EOF              PIC X VALUE 'N'.
       01  WS-LIDOS            PIC 9(5) VALUE ZERO.
       01  WS-GRAVADOS         PIC 9(5) VALUE ZERO.
       PROCEDURE DIVISION.
           OPEN INPUT  ARQ-IN
           DISPLAY 'OPEN IN FS=' WS-FS-IN
           OPEN OUTPUT ARQ-KSDS
           DISPLAY 'OPEN KSDS FS=' WS-FS-KSDS
           PERFORM UNTIL WS-EOF = 'S'
               READ ARQ-IN
                   AT END
                       MOVE 'S' TO WS-EOF
                   NOT AT END
                       ADD 1 TO WS-LIDOS
                       MOVE ARQ-IN-REG TO ARQ-KSDS-REG
                       WRITE ARQ-KSDS-REG
                       DISPLAY 'WRITE FS=' WS-FS-KSDS
                       ADD 1 TO WS-GRAVADOS
               END-READ
           END-PERFORM
           DISPLAY 'LIDOS=' WS-LIDOS ' GRAVADOS=' WS-GRAVADOS
           CLOSE ARQ-IN
           CLOSE ARQ-KSDS
           GOBACK.
