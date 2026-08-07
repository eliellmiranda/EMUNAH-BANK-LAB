       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBTESTE2.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

           SELECT CLIENTES-IN
               ASSIGN TO CLIENTIN
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS-CLIENTIN.

           SELECT CONTAS-IN
               ASSIGN TO CONTAIN
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS-CONTAIN.

           SELECT CLIENTE-KSDS
               ASSIGN TO CLIENTE
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CLI-ID-CLIENTE OF CLIENTE-KSDS-REG
               FILE STATUS IS WS-FS-CLIENTE.

           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CNT-CHAVE OF CONTA-KSDS-REG
               FILE STATUS IS WS-FS-CONTA.

           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

       DATA DIVISION.

       FILE SECTION.

       FD  CLIENTES-IN
           RECORD CONTAINS 80 CHARACTERS
           RECORDING MODE IS F.

       01  CLIENTES-IN-REG.
           05 CLIENTES-IN-DADOS         PIC X(80).

       FD  CONTAS-IN
           RECORD CONTAINS 100 CHARACTERS
           RECORDING MODE IS F.

       01  CONTAS-IN-REG.
           05 CONTAS-IN-DADOS           PIC X(100).

       FD  AUDIT-OUT
           RECORD CONTAINS 128 CHARACTERS
           RECORDING MODE IS F.

       01  AUDIT-REG.
           05 AUDIT-DADOS               PIC X(128).

       FD  CLIENTE-KSDS.

       01  CLIENTE-KSDS-REG.
           05 CLI-ID-CLIENTE            PIC 9(5).
           05 FILLER                    PIC X(75).

       FD  CONTA-KSDS.

       01  CONTA-KSDS-REG.
           05 CNT-CHAVE                 PIC X(12).
           05 FILLER                    PIC X(88).

       WORKING-STORAGE SECTION.

       01  WS-FS-CLIENTIN              PIC XX.
       01  WS-FS-CONTAIN               PIC XX.
       01  WS-FS-CLIENTE               PIC XX.
       01  WS-FS-CONTA                 PIC XX.
       01  WS-FS-AUDIT                 PIC XX.

       PROCEDURE DIVISION.

           OPEN INPUT CLIENTES-IN
           DISPLAY 'FS OPEN CLIENTES-IN  = ' WS-FS-CLIENTIN

           OPEN INPUT CONTAS-IN
           DISPLAY 'FS OPEN CONTAS-IN    = ' WS-FS-CONTAIN

           OPEN I-O CLIENTE-KSDS
           DISPLAY 'FS OPEN CLIENTE-KSDS = ' WS-FS-CLIENTE

           OPEN I-O CONTA-KSDS
           DISPLAY 'FS OPEN CONTA-KSDS   = ' WS-FS-CONTA

           OPEN EXTEND AUDIT-OUT
           DISPLAY 'FS OPEN AUDIT        = ' WS-FS-AUDIT

           CLOSE CLIENTES-IN
                 CONTAS-IN
                 CLIENTE-KSDS
                 CONTA-KSDS
                 AUDIT-OUT

           GOBACK.
