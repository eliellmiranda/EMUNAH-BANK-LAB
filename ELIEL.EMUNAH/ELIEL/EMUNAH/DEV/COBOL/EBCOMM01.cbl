       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCOMM01.
      *===============================================================*
      * PROGRAMA : EBCOMM01                                           *
      * BIBLIOTECA: ELIEL.EMUNAH.BATCH.COBOL                         *
      * FUNCAO   : SUBPROGRAMA DE ROTINAS COMUNS DO EMUNAH BANK LAB   *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Fornece funcoes reutilizaveis chamadas via CALL estatico    *
      *   ou dinamico por qualquer programa batch ou online           *
      * - FMTDATA : formata data AAAAMMDD -> DD/MM/AAAA              *
      * - FMTHORA : formata hora HHMMSSTH -> HH:MM:SS                *
      * - VALNUM  : valida se campo e inteiramente numerico           *
      *                                                               *
      * COMO CHAMAR:                                                  *
      *   CALL 'EBCOMM01' USING WS-FUNCAO                             *
      *                         WS-ENTRADA                            *
      *                         WS-SAIDA                              *
      *                         WS-RETORNO                            *
      *                                                               *
      * CODIGOS DE RETORNO (LK-RETORNO):                              *
      *   '00' : funcao executada com sucesso                         *
      *   '99' : erro - funcao desconhecida, dado nao numerico,       *
      *          ou entrada fora do formato esperado                  *
      *                                                               *
      * IMPORTANTE: usa GOBACK (nao STOP RUN) para retornar ao        *
      * chamador sem encerrar toda a run unit do programa principal.  *
      *===============================================================*

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * Areas de trabalho internas para decompor data e hora          *
      * Usadas pelos paragrafos 1000 e 2000                           *
      *---------------------------------------------------------------*
       01  WS-DATA-TRAB.
           05 WS-ANO                  PIC X(4).
           05 WS-MES                  PIC X(2).
           05 WS-DIA                  PIC X(2).

       01  WS-HORA-TRAB.
           05 WS-HH                   PIC X(2).
           05 WS-MM                   PIC X(2).
           05 WS-SS                   PIC X(2).
           05 WS-TH                   PIC X(2).   *> Centesimos - nao
                                                   *> incluidos na saida

      *---------------------------------------------------------------*
      * Buffer auxiliar para testar numeridade em 3000-VALIDAR         *
      *---------------------------------------------------------------*
       01  WS-CAMPO-TESTE             PIC X(20).

       LINKAGE SECTION.

      *---------------------------------------------------------------*
      * Interface de comunicacao (USING no PROCEDURE DIVISION)        *
      *                                                               *
      * LK-FUNCAO  (8 bytes) : codigo da funcao solicitada            *
      *   'FMTDATA' -> formatar data                                  *
      *   'FMTHORA' -> formatar hora                                  *
      *   'VALNUM'  -> validar numerico                               *
      *                                                               *
      * LK-ENTRADA (20 bytes): dado a processar                       *
      *   Para FMTDATA: primeiros 8 bytes = AAAAMMDD                  *
      *   Para FMTHORA: primeiros 6 bytes = HHMMSS                    *
      *   Para VALNUM : ate 20 bytes a verificar                      *
      *                                                               *
      * LK-SAIDA   (50 bytes): resultado                              *
      *   FMTDATA -> 'DD/MM/AAAA'                                     *
      *   FMTHORA -> 'HH:MM:SS'                                       *
      *   VALNUM  -> 'NUMERICO' ou 'NAO NUMERICO'                     *
      *                                                               *
      * LK-RETORNO  (2 bytes): codigo de retorno                      *
      *   '00' = OK | '99' = erro                                     *
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
      * 0000-PRINCIPAL                                                *
      * Inicializa retorno como OK e despacha pela funcao solicitada. *
      * Qualquer codigo nao previsto retorna '99'.                    *
      *===============================================================*
       0000-PRINCIPAL.
           MOVE '00'   TO LK-RETORNO
           MOVE SPACES TO LK-SAIDA

           EVALUATE LK-FUNCAO
               WHEN 'FMTDATA'
                   PERFORM 1000-FORMATAR-DATA
               WHEN 'FMTHORA'
                   PERFORM 2000-FORMATAR-HORA
               WHEN 'VALNUM'
                   PERFORM 3000-VALIDAR-NUMERICO
               WHEN OTHER
      *-- Funcao desconhecida: retorna erro sem processamento ------*
                   MOVE '99' TO LK-RETORNO
           END-EVALUATE

           GOBACK.

      *===============================================================*
      * 1000-FORMATAR-DATA                                            *
      * Entrada : LK-ENTRADA(1:8) no formato AAAAMMDD                 *
      * Saida   : LK-SAIDA no formato DD/MM/AAAA                      *
      * Erro    : '99' se a entrada nao for numerica                  *
      *===============================================================*
       1000-FORMATAR-DATA.
           IF LK-ENTRADA(1:8) IS NUMERIC
               MOVE LK-ENTRADA(1:4) TO WS-ANO
               MOVE LK-ENTRADA(5:2) TO WS-MES
               MOVE LK-ENTRADA(7:2) TO WS-DIA

      *-- Monta string no formato brasileiro DD/MM/AAAA ------------*
               STRING WS-DIA '/' WS-MES '/' WS-ANO
                      DELIMITED BY SIZE
                      INTO LK-SAIDA
               END-STRING
           ELSE
               MOVE '99' TO LK-RETORNO
           END-IF.

      *===============================================================*
      * 2000-FORMATAR-HORA                                            *
      * Entrada : LK-ENTRADA(1:6) no formato HHMMSS                   *
      * Saida   : LK-SAIDA no formato HH:MM:SS                        *
      * Os centesimos (bytes 7-8) sao ignorados na saida             *
      * Erro    : '99' se a entrada nao for numerica                  *
      *===============================================================*
       2000-FORMATAR-HORA.
           IF LK-ENTRADA(1:6) IS NUMERIC
               MOVE LK-ENTRADA(1:2) TO WS-HH
               MOVE LK-ENTRADA(3:2) TO WS-MM
               MOVE LK-ENTRADA(5:2) TO WS-SS

      *-- Monta string HH:MM:SS ------------------------------------*
               STRING WS-HH ':' WS-MM ':' WS-SS
                      DELIMITED BY SIZE
                      INTO LK-SAIDA
               END-STRING
           ELSE
               MOVE '99' TO LK-RETORNO
           END-IF.

      *===============================================================*
      * 3000-VALIDAR-NUMERICO                                         *
      * Entrada : LK-ENTRADA (ate 20 bytes)                           *
      * Saida   : 'NUMERICO' ou 'NAO NUMERICO'                        *
      * FUNCTION TRIM remove espacos a direita antes do teste,         *
      * evitando falsos negativos para campos parcialmente preenchidos.*
      *===============================================================*
       3000-VALIDAR-NUMERICO.
           MOVE LK-ENTRADA TO WS-CAMPO-TESTE

           IF FUNCTION TRIM(WS-CAMPO-TESTE TRAILING) IS NUMERIC
               MOVE 'NUMERICO'     TO LK-SAIDA
           ELSE
               MOVE '99'           TO LK-RETORNO
               MOVE 'NAO NUMERICO' TO LK-SAIDA
           END-IF.
