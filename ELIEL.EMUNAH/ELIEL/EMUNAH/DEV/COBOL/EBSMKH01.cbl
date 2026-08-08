       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBSMKH01.
      *===============================================================*
      * PROGRAMA : EBSMKH01                                           *
      * BIBLIOTECA: ELIEL.EMUNAH.HML.COBOL                           *
      * FUNCAO   : SMOKE TEST DO AMBIENTE DE HOMOLOGACAO              *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Exibe identificacao do ambiente HML no SYSOUT               *
      * - Captura data e hora correntes via FUNCTION CURRENT-DATE     *
      * - Exibe data formatada (DD/MM/AAAA) e hora (HH:MM:SS)         *
      * - Retorna RC=0 se a execucao ocorreu sem erros                *
      *                                                               *
      * PARA QUE SERVE:                                               *
      * - Validar rapidamente que o ambiente HML esta operacional     *
      * - Confirmar que o JCL aponta para a loadlib correta           *
      * - Executar como primeiro passo de qualquer JCL de teste       *
      *   antes de acionar programas que acessam VSAM                 *
      *                                                               *
      * EXECUCAO:                                                      *
      *   Nao requer DD cards adicionais. Saida apenas no SYSOUT.     *
      *   RC=0 = ambiente OK.                                         *
      *===============================================================*

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * FUNCTION CURRENT-DATE retorna 21 caracteres no formato:       *
      *   Pos  1- 4 : AAAA (ano)                                      *
      *   Pos  5- 6 : MM   (mes)                                      *
      *   Pos  7- 8 : DD   (dia)                                      *
      *   Pos  9-10 : HH   (hora)                                     *
      *   Pos 11-12 : MM   (minutos)                                  *
      *   Pos 13-14 : SS   (segundos)                                 *
      *   Pos 15-16 : cc   (centesimos)                               *
      *   Pos 17    : +/-  (sinal diferenca UTC)                      *
      *   Pos 18-19 : HH   (diferenca hora UTC)                       *
      *   Pos 20-21 : MM   (diferenca minutos UTC)                    *
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
           05 WS-CC                    PIC 9(2).   *> centesimos
           05 WS-SINAL                 PIC X(1).   *> diferenca UTC
           05 WS-DIF-HORA              PIC 9(2).
           05 WS-DIF-MIN               PIC 9(2).

       PROCEDURE DIVISION.
      *===============================================================*
      * 0000-PRINCIPAL                                                *
      * Captura data/hora, exibe identificacao no SYSOUT e encerra.   *
      * RC=0 indica que a execucao do smoke test foi bem-sucedida.    *
      *===============================================================*
       0000-PRINCIPAL.
      *-- Carrega data e hora atuais do sistema -------------------*
           MOVE FUNCTION CURRENT-DATE TO WS-DH-TEXTO

      *-- Identifica programa e ambiente no SYSOUT -----------------*
           DISPLAY '*** EMUNAH BANK LAB - SMOKE TEST HML ***'
           DISPLAY 'PROGRAMA : EBSMKH01'
           DISPLAY 'AMBIENTE : HML'
      *-- Exibe data no formato DD/MM/AAAA e hora HH:MM:SS ---------*
           DISPLAY 'DATA     : ' WS-DIA '/' WS-MES '/' WS-ANO
           DISPLAY 'HORA     : ' WS-HORA ':' WS-MIN ':' WS-SEG
           DISPLAY 'STATUS   : EXECUCAO OK'

           MOVE 0 TO RETURN-CODE
           GOBACK.
