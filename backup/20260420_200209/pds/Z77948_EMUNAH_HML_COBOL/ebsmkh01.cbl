       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBSMKH01.
      *===============================================================*
      * PROGRAMA : EBSMKH01                                           *
      * BIBLIOTECA: Z77948.EMUNAH.HML.COBOL                           *
      * FUNCAO   : SMOKE TEST DO AMBIENTE DE HOMOLOGACAO              *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Exibe identificacao do ambiente HML                         *
      * - Mostra data e hora correntes                                *
      * - Retorna RC=0 se a execucao ocorrer normalmente              *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Validar rapidamente se o ambiente HML esta operacional      *
      * - Confirmar que o JCL esta apontando para a loadlib correta   *
      * - Servir como teste basico antes de fluxos batch maiores      *
      *===============================================================*

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * FUNCTION CURRENT-DATE retorna 21 caracteres                   *
      * Formato: YYYYMMDDHHMMSScc+/-HHMM                              *
      *---------------------------------------------------------------*
       01  WS-DATA-HORA.
           05 WS-DH-TEXTO              PIC X(21).

       01  WS-DATA-HORA-R REDEFINES WS-DATA-HORA.
           05 WS-ANO                   PIC 9(4).
           05 WS-MES                   PIC 9(2).
           05 WS-DIA                   PIC 9(2).
           05 WS-HORA                  PIC 9(2).
           05 WS-MIN                   PIC 9(2).
           05 WS-SEG                   PIC 9(2).
           05 WS-CC                    PIC 9(2).
           05 WS-SINAL                 PIC X(1).
           05 WS-DIF-HORA              PIC 9(2).
           05 WS-DIF-MIN               PIC 9(2).

       PROCEDURE DIVISION.
      *===============================================================*
      * FLUXO PRINCIPAL                                               *
      *===============================================================*
       0000-PRINCIPAL.
           MOVE FUNCTION CURRENT-DATE TO WS-DH-TEXTO

           DISPLAY '*** EMUNAH BANK LAB - SMOKE TEST HML ***'
           DISPLAY 'PROGRAMA : EBSMKH01'
           DISPLAY 'AMBIENTE : HML'
           DISPLAY 'DATA     : ' WS-DIA '/' WS-MES '/' WS-ANO
           DISPLAY 'HORA     : ' WS-HORA ':' WS-MIN ':' WS-SEG
           DISPLAY 'STATUS   : EXECUCAO OK'

           MOVE 0 TO RETURN-CODE
           GOBACK.
