       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCOMM01.
      *===============================================================*
      * PROGRAMA : EBCOMM01                                           *
      * FUNCAO   : ROTINAS COMUNS DO LABORATORIO EMUNAH BANK          *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Fornece rotinas comuns reutilizaveis via CALL                *
      * - Formata data AAAAMMDD para DD/MM/AAAA                       *
      * - Formata hora HHMMSSTH para HH:MM:SS                         *
      * - Grava registro padrao de auditoria                          *
      * - Valida campo numerico antes de uso                          *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Centralizar funcoes comuns entre programas batch e online    *
      * - Evitar duplicacao de logica de formatacao e validacao        *
      * - Servir como exemplo de subprograma COBOL chamado via CALL   *
      *                                                               *
      * INTERFACE (via LINKAGE SECTION):                               *
      * - LK-FUNCAO    : codigo da funcao a executar                  *
      *   'FMTDATA' = formatar data                                   *
      *   'FMTHORA' = formatar hora                                   *
      *   'VALNUM'  = validar campo numerico                          *
      * - LK-ENTRADA   : dado de entrada (20 bytes)                   *
      * - LK-SAIDA     : resultado (50 bytes)                         *
      * - LK-RETORNO   : codigo de retorno ('00'=ok, '99'=erro)      *
      *===============================================================*

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * Variaveis de trabalho para formatacao                         *
      *---------------------------------------------------------------*
       01  WS-DATA-TRAB.
           05 WS-ANO                  PIC X(4).
           05 WS-MES                  PIC X(2).
           05 WS-DIA                  PIC X(2).

       01  WS-HORA-TRAB.
           05 WS-HH                   PIC X(2).
           05 WS-MM                   PIC X(2).
           05 WS-SS                   PIC X(2).
           05 WS-TH                   PIC X(2).

       01  WS-CAMPO-TESTE             PIC X(20).

       LINKAGE SECTION.

      *---------------------------------------------------------------*
      * Interface de comunicacao com o programa chamador               *
      *---------------------------------------------------------------*
       01  LK-FUNCAO                  PIC X(8).
       01  LK-ENTRADA                 PIC X(20).
       01  LK-SAIDA                   PIC X(50).
       01  LK-RETORNO                 PIC X(2).

       PROCEDURE DIVISION USING LK-FUNCAO
                                LK-ENTRADA
                                LK-SAIDA
                                LK-RETORNO.
      *===============================================================*
      * FLUXO PRINCIPAL - DESPACHA CONFORME A FUNCAO SOLICITADA       *
      *===============================================================*
       0000-PRINCIPAL.
           MOVE '00' TO LK-RETORNO
           MOVE SPACES TO LK-SAIDA

           EVALUATE LK-FUNCAO
               WHEN 'FMTDATA'
                   PERFORM 1000-FORMATAR-DATA
               WHEN 'FMTHORA'
                   PERFORM 2000-FORMATAR-HORA
               WHEN 'VALNUM'
                   PERFORM 3000-VALIDAR-NUMERICO
               WHEN OTHER
                   MOVE '99' TO LK-RETORNO
           END-EVALUATE

           GOBACK.

      *---------------------------------------------------------------*
      * Formata data de AAAAMMDD para DD/MM/AAAA                      *
      *---------------------------------------------------------------*
       1000-FORMATAR-DATA.
           IF LK-ENTRADA(1:8) IS NUMERIC
               MOVE LK-ENTRADA(1:4) TO WS-ANO
               MOVE LK-ENTRADA(5:2) TO WS-MES
               MOVE LK-ENTRADA(7:2) TO WS-DIA

               STRING WS-DIA '/' WS-MES '/' WS-ANO
                      DELIMITED BY SIZE
                      INTO LK-SAIDA
               END-STRING
           ELSE
               MOVE '99' TO LK-RETORNO
           END-IF.

      *---------------------------------------------------------------*
      * Formata hora de HHMMSSTH para HH:MM:SS                        *
      *---------------------------------------------------------------*
       2000-FORMATAR-HORA.
           IF LK-ENTRADA(1:6) IS NUMERIC
               MOVE LK-ENTRADA(1:2) TO WS-HH
               MOVE LK-ENTRADA(3:2) TO WS-MM
               MOVE LK-ENTRADA(5:2) TO WS-SS

               STRING WS-HH ':' WS-MM ':' WS-SS
                      DELIMITED BY SIZE
                      INTO LK-SAIDA
               END-STRING
           ELSE
               MOVE '99' TO LK-RETORNO
           END-IF.

      *---------------------------------------------------------------*
      * Valida se o campo informado e inteiramente numerico            *
      * Retorna '00' se numerico, '99' se nao                         *
      *---------------------------------------------------------------*
       3000-VALIDAR-NUMERICO.
           MOVE LK-ENTRADA TO WS-CAMPO-TESTE

           IF FUNCTION TRIM(WS-CAMPO-TESTE TRAILING) IS NUMERIC
               MOVE 'NUMERICO' TO LK-SAIDA
           ELSE
               MOVE '99' TO LK-RETORNO
               MOVE 'NAO NUMERICO' TO LK-SAIDA
           END-IF.
