      *===============================================================*
      * ARQUIVO   : EBEXTR01.cbl                                       *
      * CAMINHO   : cobol/batch/EBEXTR01.cbl                           *
      *---------------------------------------------------------------*
      * FINALIDADE: Gerar o extrato diário dos movimentos processados.*
      *                                                               *
      * ENTRADAS  : MOVTIN, CONTA                                  *
      * SAIDAS    : EXTROUT, AUDIT                                 *
      *                                                               *
      * REGRAS / COMPORTAMENTO ESPERADO:                              *
      * - Formata linhas de extrato em 132 colunas.                  *
      * - Preserva ordem dos movimentos do dia.                      *
      * - Gera um artefato legível para evidência e conferência.     *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este comentario foi enriquecido para manter o laboratorio     *
      * autoexplicativo. A logica do v3 foi preservada; o objetivo    *
      * desta versao e documentar melhor o papel do programa, os      *
      * arquivos esperados e a leitura operacional do fluxo.          *
      *===============================================================*
 IDENTIFICATION DIVISION.
 PROGRAM-ID. EBEXTR01.
*===============================================================*
* PROGRAMA : EBEXTR01                                           *
* FUNCAO   : GERAR EXTRATO DO DIA                               *
*                                                               *
* ESTRATEGIA DESTA VERSAO:                                      *
* - um registro por movimento                                   *
* - usa o saldo atual da CONTA como saldo de posicao            *
*===============================================================*

 ENVIRONMENT DIVISION.
 INPUT-OUTPUT SECTION.
 FILE-CONTROL.
     SELECT MOVTO-IN
         ASSIGN TO MOVTIN
         ORGANIZATION IS SEQUENTIAL
         ACCESS MODE IS SEQUENTIAL
         FILE STATUS IS WS-FS-MOVTIN.

     SELECT CONTA-KSDS
         ASSIGN TO CONTA
         ORGANIZATION IS INDEXED
         ACCESS MODE IS DYNAMIC
         RECORD KEY IS CNT-CHAVE OF CONTA-REG
         FILE STATUS IS WS-FS-CONTA.

     SELECT EXTRATO-OUT
         ASSIGN TO EXTROUT
         ORGANIZATION IS SEQUENTIAL
         ACCESS MODE IS SEQUENTIAL
         FILE STATUS IS WS-FS-EXTROUT.

     SELECT AUDIT-OUT
         ASSIGN TO AUDIT
         ORGANIZATION IS SEQUENTIAL
         ACCESS MODE IS SEQUENTIAL
         FILE STATUS IS WS-FS-AUDIT.

 DATA DIVISION.
 FILE SECTION.
 FD  MOVTO-IN
     RECORD CONTAINS 120 CHARACTERS
     RECORDING MODE IS F.
 01  MOVTO-REG.
     COPY CPLCT001.

 FD  CONTA-KSDS.
 01  CONTA-REG.
     COPY CPCNT001.

 FD  EXTRATO-OUT
     RECORD CONTAINS 132 CHARACTERS
     RECORDING MODE IS F.
 01  EXTRATO-REG.
     COPY CPEXT001.

 FD  AUDIT-OUT
     RECORD CONTAINS 120 CHARACTERS
     RECORDING MODE IS F.
 01  AUDIT-REG.
     COPY CPAUD001.

 WORKING-STORAGE SECTION.
 01  WS-FILE-STATUS.
     05 WS-FS-MOVTIN           PIC XX VALUE SPACES.
        88 FS-MOVTIN-OK        VALUE '00'.
        88 FS-MOVTIN-EOF       VALUE '10'.
     05 WS-FS-CONTA            PIC XX VALUE SPACES.
        88 FS-CONTA-OK         VALUE '00'.
        88 FS-CONTA-NF         VALUE '23'.
     05 WS-FS-EXTROUT          PIC XX VALUE SPACES.
        88 FS-EXTROUT-OK       VALUE '00'.
     05 WS-FS-AUDIT            PIC XX VALUE SPACES.
        88 FS-AUDIT-OK         VALUE '00'.

 01  WS-FLAGS.
     05 WS-EOF-MOVTIN          PIC X VALUE 'N'.
        88 EOF-MOVTIN          VALUE 'S'.
     05 WS-ERRO                PIC X VALUE 'N'.
        88 COM-ERRO            VALUE 'S'.

 01  WS-CONTADORES.
     05 WS-LIDOS               PIC 9(9) VALUE ZERO.
     05 WS-GERADOS             PIC 9(9) VALUE ZERO.

 01  WS-DATA-SISTEMA           PIC 9(8).
 01  WS-HORA-SISTEMA           PIC 9(8).
 01  WS-CHAVE-REF              PIC X(20).

 PROCEDURE DIVISION.
 0000-PRINCIPAL.
     ACCEPT WS-DATA-SISTEMA FROM DATE YYYYMMDD
     ACCEPT WS-HORA-SISTEMA FROM TIME
     PERFORM 1000-ABRIR
     IF NOT COM-ERRO
         PERFORM 2000-PROCESSAR
         PERFORM 3000-AUDITAR-RESUMO
     END-IF
     PERFORM 9000-FECHAR
     PERFORM 9100-RC
     GOBACK.

 1000-ABRIR.
     OPEN INPUT MOVTO-IN
     IF NOT FS-MOVTIN-OK
         DISPLAY '*** EBEXTR01 ERRO OPEN MOVTIN - ' WS-FS-MOVTIN
         SET COM-ERRO TO TRUE
     END-IF

     IF NOT COM-ERRO
         OPEN INPUT CONTA-KSDS
         IF NOT FS-CONTA-OK
             DISPLAY '*** EBEXTR01 ERRO OPEN CONTA - ' WS-FS-CONTA
             SET COM-ERRO TO TRUE
         END-IF
     END-IF

     IF NOT COM-ERRO
         OPEN OUTPUT EXTRATO-OUT
         IF NOT FS-EXTROUT-OK
             DISPLAY '*** EBEXTR01 ERRO OPEN EXTROUT - '
                     WS-FS-EXTROUT
             SET COM-ERRO TO TRUE
         END-IF
     END-IF

     IF NOT COM-ERRO
         OPEN EXTEND AUDIT-OUT
         IF NOT FS-AUDIT-OK
             DISPLAY '*** EBEXTR01 ERRO OPEN AUDIT - ' WS-FS-AUDIT
             SET COM-ERRO TO TRUE
         END-IF
     END-IF.

 2000-PROCESSAR.
     PERFORM UNTIL EOF-MOVTIN OR COM-ERRO
         READ MOVTO-IN
             AT END
                 SET EOF-MOVTIN TO TRUE
             NOT AT END
                 IF FS-MOVTIN-OK
                     ADD 1 TO WS-LIDOS
                     PERFORM 2100-GERAR-LINHA
                 ELSE
                     DISPLAY '*** EBEXTR01 ERRO READ MOVTIN - '
                             WS-FS-MOVTIN
                     SET COM-ERRO TO TRUE
                 END-IF
         END-READ
     END-PERFORM.

 2100-GERAR-LINHA.
     MOVE LCT-CHAVE-CONTA OF MOVTO-REG TO CNT-CHAVE OF CONTA-REG
     READ CONTA-KSDS
         INVALID KEY
             MOVE ZERO TO CNT-SALDO OF CONTA-REG
         NOT INVALID KEY
             CONTINUE
     END-READ

     MOVE SPACES TO EXTRATO-REG
     MOVE LCT-AGENCIA   OF MOVTO-REG TO EXT-AGENCIA
     MOVE LCT-NUM-CONTA OF MOVTO-REG TO EXT-NUM-CONTA
     MOVE LCT-DATA      OF MOVTO-REG TO EXT-DATA-MOVTO
     MOVE LCT-NSEQ      OF MOVTO-REG TO EXT-NSEQ
     MOVE LCT-TIPO      OF MOVTO-REG TO EXT-TIPO
     MOVE LCT-HISTORICO OF MOVTO-REG TO EXT-DESCRICAO
     MOVE LCT-VALOR     OF MOVTO-REG TO EXT-VALOR
     MOVE CNT-SALDO     OF CONTA-REG TO EXT-SALDO-POSICAO
     MOVE LCT-CANAL     OF MOVTO-REG TO EXT-CANAL
     WRITE EXTRATO-REG
     IF FS-EXTROUT-OK
         ADD 1 TO WS-GERADOS
     ELSE
         DISPLAY '*** EBEXTR01 ERRO WRITE EXTROUT - ' WS-FS-EXTROUT
         SET COM-ERRO TO TRUE
     END-IF.

 3000-AUDITAR-RESUMO.
     MOVE SPACES TO AUDIT-REG
     MOVE 'OK'       TO AU-TIPO-EVENTO
     MOVE 'EBEXTR01' TO AU-PROGRAMA
     MOVE WS-DATA-SISTEMA TO AU-DATA-EVENTO
     MOVE WS-HORA-SISTEMA TO AU-HORA-EVENTO
     MOVE 'EXTOK001' TO AU-COD-EVENTO
     MOVE 'EXTRATO-DIA' TO AU-CHAVE-REF
     MOVE 'EXTRATO GERADO COM SUCESSO' TO AU-MENSAGEM
     MOVE WS-GERADOS TO AU-COMPLEMENTO
     WRITE AUDIT-REG.

 9000-FECHAR.
     CLOSE MOVTO-IN CONTA-KSDS EXTRATO-OUT AUDIT-OUT.

 9100-RC.
     DISPLAY '*** EBEXTR01 LIDOS   : ' WS-LIDOS
     DISPLAY '*** EBEXTR01 GERADOS : ' WS-GERADOS
     EVALUATE TRUE
         WHEN COM-ERRO
             MOVE 8 TO RETURN-CODE
         WHEN WS-LIDOS = ZERO
             MOVE 4 TO RETURN-CODE
         WHEN OTHER
             MOVE 0 TO RETURN-CODE
     END-EVALUATE.
