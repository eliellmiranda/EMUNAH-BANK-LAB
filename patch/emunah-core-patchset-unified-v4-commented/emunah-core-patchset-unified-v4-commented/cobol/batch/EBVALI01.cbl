      *===============================================================*
      * ARQUIVO   : EBVALI01.cbl                                       *
      * CAMINHO   : cobol/batch/EBVALI01.cbl                           *
      *---------------------------------------------------------------*
      * FINALIDADE: Validar layout e regras de negócio dos lançamentos de entrada.*
      *                                                               *
      * ENTRADAS  : ENTRADA, CONTA                                 *
      * SAIDAS    : VALIDOS, REJEITOS, AUDIT                       *
      *                                                               *
      * REGRAS / COMPORTAMENTO ESPERADO:                              *
      * - Valida tipo de lançamento e valor.                         *
      * - Confere existência e status da conta.                      *
      * - Separa movimentos aprovados de rejeitos com motivo.        *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este comentario foi enriquecido para manter o laboratorio     *
      * autoexplicativo. A logica do v3 foi preservada; o objetivo    *
      * desta versao e documentar melhor o papel do programa, os      *
      * arquivos esperados e a leitura operacional do fluxo.          *
      *===============================================================*
 IDENTIFICATION DIVISION.
 PROGRAM-ID. EBVALI01.
*===============================================================*
* PROGRAMA : EBVALI01                                           *
* FUNCAO   : VALIDAR LANCAMENTOS DE ENTRADA                     *
*                                                               *
* REGRAS PRINCIPAIS:                                            *
* - tipo C/D                                                    *
* - valor maior que zero                                        *
* - conta existente e ativa                                     *
* - registro valido sai com STATUS = V                          *
* - rejeitos sao gravados em REJEITOS.SEQ                       *
*===============================================================*

 ENVIRONMENT DIVISION.
 INPUT-OUTPUT SECTION.
 FILE-CONTROL.
     SELECT ENTRADA-IN
         ASSIGN TO ENTRADA
         ORGANIZATION IS SEQUENTIAL
         ACCESS MODE IS SEQUENTIAL
         FILE STATUS IS WS-FS-ENTRADA.

     SELECT VALIDOS-OUT
         ASSIGN TO VALIDOS
         ORGANIZATION IS SEQUENTIAL
         ACCESS MODE IS SEQUENTIAL
         FILE STATUS IS WS-FS-VALIDOS.

     SELECT REJEITOS-OUT
         ASSIGN TO REJEITOS
         ORGANIZATION IS SEQUENTIAL
         ACCESS MODE IS SEQUENTIAL
         FILE STATUS IS WS-FS-REJEITOS.

     SELECT CONTA-KSDS
         ASSIGN TO CONTA
         ORGANIZATION IS INDEXED
         ACCESS MODE IS DYNAMIC
         RECORD KEY IS CNT-CHAVE OF CONTA-REG
         FILE STATUS IS WS-FS-CONTA.

     SELECT AUDIT-OUT
         ASSIGN TO AUDIT
         ORGANIZATION IS SEQUENTIAL
         ACCESS MODE IS SEQUENTIAL
         FILE STATUS IS WS-FS-AUDIT.

 DATA DIVISION.
 FILE SECTION.
 FD  ENTRADA-IN
     RECORD CONTAINS 120 CHARACTERS
     RECORDING MODE IS F.
 01  ENTRADA-REG.
     COPY CPLCT001.

 FD  VALIDOS-OUT
     RECORD CONTAINS 120 CHARACTERS
     RECORDING MODE IS F.
 01  VALIDOS-REG.
     COPY CPLCT001.

 FD  REJEITOS-OUT
     RECORD CONTAINS 120 CHARACTERS
     RECORDING MODE IS F.
 01  REJEITOS-REG.
     COPY CPREJ001.

 FD  CONTA-KSDS.
 01  CONTA-REG.
     COPY CPCNT001.

 FD  AUDIT-OUT
     RECORD CONTAINS 120 CHARACTERS
     RECORDING MODE IS F.
 01  AUDIT-REG.
     COPY CPAUD001.

 WORKING-STORAGE SECTION.
 01  WS-FILE-STATUS.
     05 WS-FS-ENTRADA          PIC XX VALUE SPACES.
        88 FS-ENTRADA-OK       VALUE '00'.
        88 FS-ENTRADA-EOF      VALUE '10'.
     05 WS-FS-VALIDOS          PIC XX VALUE SPACES.
        88 FS-VALIDOS-OK       VALUE '00'.
     05 WS-FS-REJEITOS         PIC XX VALUE SPACES.
        88 FS-REJEITOS-OK      VALUE '00'.
     05 WS-FS-CONTA            PIC XX VALUE SPACES.
        88 FS-CONTA-OK         VALUE '00'.
        88 FS-CONTA-NF         VALUE '23'.
     05 WS-FS-AUDIT            PIC XX VALUE SPACES.
        88 FS-AUDIT-OK         VALUE '00'.

 01  WS-FLAGS.
     05 WS-EOF-ENTRADA         PIC X VALUE 'N'.
        88 EOF-ENTRADA         VALUE 'S'.
     05 WS-ERRO                PIC X VALUE 'N'.
        88 COM-ERRO            VALUE 'S'.
     05 WS-REG-VALIDO          PIC X VALUE 'S'.
        88 REG-VALIDO          VALUE 'S'.
        88 REG-INVALIDO        VALUE 'N'.

 01  WS-CONTADORES.
     05 WS-LIDOS               PIC 9(9) VALUE ZERO.
     05 WS-VALIDOS             PIC 9(9) VALUE ZERO.
     05 WS-REJEITADOS          PIC 9(9) VALUE ZERO.

 01  WS-DATA-SISTEMA           PIC 9(8).
 01  WS-HORA-SISTEMA           PIC 9(8).
 01  WS-REJ-COD                PIC X(4) VALUE SPACES.
 01  WS-REJ-DESC               PIC X(32) VALUE SPACES.
 01  WS-CHAVE-REF              PIC X(20).

 PROCEDURE DIVISION.
 0000-PRINCIPAL.
     ACCEPT WS-DATA-SISTEMA FROM DATE YYYYMMDD
     ACCEPT WS-HORA-SISTEMA FROM TIME
     PERFORM 1000-ABRIR
     IF NOT COM-ERRO
         PERFORM 2000-PROCESSAR
     END-IF
     PERFORM 9000-FECHAR
     PERFORM 9100-RC
     GOBACK.

 1000-ABRIR.
     OPEN INPUT ENTRADA-IN
     IF NOT FS-ENTRADA-OK
         DISPLAY '*** EBVALI01 ERRO OPEN ENTRADA - ' WS-FS-ENTRADA
         SET COM-ERRO TO TRUE
     END-IF

     IF NOT COM-ERRO
         OPEN EXTEND VALIDOS-OUT
         IF NOT FS-VALIDOS-OK
             DISPLAY '*** EBVALI01 ERRO OPEN VALIDOS - ' WS-FS-VALIDOS
             SET COM-ERRO TO TRUE
         END-IF
     END-IF

     IF NOT COM-ERRO
         OPEN EXTEND REJEITOS-OUT
         IF NOT FS-REJEITOS-OK
             DISPLAY '*** EBVALI01 ERRO OPEN REJEITOS - '
                     WS-FS-REJEITOS
             SET COM-ERRO TO TRUE
         END-IF
     END-IF

     IF NOT COM-ERRO
         OPEN INPUT CONTA-KSDS
         IF NOT FS-CONTA-OK
             DISPLAY '*** EBVALI01 ERRO OPEN CONTA - ' WS-FS-CONTA
             SET COM-ERRO TO TRUE
         END-IF
     END-IF

     IF NOT COM-ERRO
         OPEN EXTEND AUDIT-OUT
         IF NOT FS-AUDIT-OK
             DISPLAY '*** EBVALI01 ERRO OPEN AUDIT - ' WS-FS-AUDIT
             SET COM-ERRO TO TRUE
         END-IF
     END-IF.

 2000-PROCESSAR.
     PERFORM UNTIL EOF-ENTRADA OR COM-ERRO
         READ ENTRADA-IN
             AT END
                 SET EOF-ENTRADA TO TRUE
             NOT AT END
                 IF FS-ENTRADA-OK
                     ADD 1 TO WS-LIDOS
                     PERFORM 2100-VALIDAR-REGISTRO
                 ELSE
                     DISPLAY '*** EBVALI01 ERRO READ ENTRADA - '
                             WS-FS-ENTRADA
                     SET COM-ERRO TO TRUE
                 END-IF
         END-READ
     END-PERFORM.

 2100-VALIDAR-REGISTRO.
     SET REG-VALIDO TO TRUE
     MOVE SPACES TO WS-REJ-COD WS-REJ-DESC

     IF LCT-TIPO NOT = 'C' AND LCT-TIPO NOT = 'D'
         MOVE 'V001' TO WS-REJ-COD
         MOVE 'TIPO DE LANCAMENTO INVALIDO' TO WS-REJ-DESC
         SET REG-INVALIDO TO TRUE
     END-IF

     IF REG-VALIDO AND LCT-VALOR <= ZERO
         MOVE 'V002' TO WS-REJ-COD
         MOVE 'VALOR DEVE SER MAIOR QUE ZERO' TO WS-REJ-DESC
         SET REG-INVALIDO TO TRUE
     END-IF

     IF REG-VALIDO AND LCT-AGENCIA = ZERO
         MOVE 'V003' TO WS-REJ-COD
         MOVE 'AGENCIA INVALIDA' TO WS-REJ-DESC
         SET REG-INVALIDO TO TRUE
     END-IF

     IF REG-VALIDO AND LCT-NUM-CONTA = ZERO
         MOVE 'V004' TO WS-REJ-COD
         MOVE 'CONTA INVALIDA' TO WS-REJ-DESC
         SET REG-INVALIDO TO TRUE
     END-IF

     IF REG-VALIDO
         MOVE LCT-CHAVE-CONTA TO CNT-CHAVE OF CONTA-REG
         READ CONTA-KSDS
             INVALID KEY
                 MOVE 'V005' TO WS-REJ-COD
                 MOVE 'CONTA NAO ENCONTRADA' TO WS-REJ-DESC
                 SET REG-INVALIDO TO TRUE
             NOT INVALID KEY
                 CONTINUE
         END-READ
     END-IF

     IF REG-VALIDO AND CNT-STATUS OF CONTA-REG NOT = 'A'
         MOVE 'V006' TO WS-REJ-COD
         MOVE 'CONTA INATIVA OU BLOQUEADA' TO WS-REJ-DESC
         SET REG-INVALIDO TO TRUE
     END-IF

     IF REG-VALIDO
         MOVE ENTRADA-REG TO VALIDOS-REG
         MOVE 'V' TO LCT-STATUS OF VALIDOS-REG
         WRITE VALIDOS-REG
         IF FS-VALIDOS-OK
             ADD 1 TO WS-VALIDOS
             MOVE 'VALOK001' TO WS-REJ-COD
             MOVE 'LANCAMENTO VALIDADO' TO WS-REJ-DESC
             PERFORM 5000-AUDITAR-SUCESSO
         ELSE
             DISPLAY '*** EBVALI01 ERRO WRITE VALIDOS - '
                     WS-FS-VALIDOS
             SET COM-ERRO TO TRUE
         END-IF
     ELSE
         PERFORM 4000-GRAVAR-REJEITO
     END-IF.

 4000-GRAVAR-REJEITO.
     MOVE SPACES TO REJEITOS-REG
     MOVE LCT-AGENCIA   OF ENTRADA-REG TO REJ-AGENCIA
     MOVE LCT-NUM-CONTA OF ENTRADA-REG TO REJ-NUM-CONTA
     MOVE LCT-DATA      OF ENTRADA-REG TO REJ-DATA-LANCTO
     MOVE LCT-TIPO      OF ENTRADA-REG TO REJ-TIPO-LANCTO
     MOVE LCT-VALOR     OF ENTRADA-REG TO REJ-VALOR
     MOVE LCT-NSEQ      OF ENTRADA-REG TO REJ-NSEQ-ORIG
     MOVE WS-REJ-COD                   TO REJ-COD-MOTIVO
     MOVE WS-REJ-DESC                  TO REJ-DESC-MOTIVO
     MOVE 'EBVALI01'                   TO REJ-PROGRAMA
     MOVE WS-DATA-SISTEMA              TO REJ-DATA-REJEITO
     MOVE WS-HORA-SISTEMA              TO REJ-HORA-REJEITO
     WRITE REJEITOS-REG
     IF FS-REJEITOS-OK
         ADD 1 TO WS-REJEITADOS
         PERFORM 5100-AUDITAR-REJEITO
     ELSE
         DISPLAY '*** EBVALI01 ERRO WRITE REJEITOS - '
                 WS-FS-REJEITOS
         SET COM-ERRO TO TRUE
     END-IF.

 5000-AUDITAR-SUCESSO.
     MOVE SPACES TO AUDIT-REG WS-CHAVE-REF
     MOVE LCT-AGENCIA   OF ENTRADA-REG TO WS-CHAVE-REF(1:4)
     MOVE LCT-NUM-CONTA OF ENTRADA-REG TO WS-CHAVE-REF(5:8)
     MOVE 'OK'       TO AU-TIPO-EVENTO
     MOVE 'EBVALI01' TO AU-PROGRAMA
     MOVE WS-DATA-SISTEMA TO AU-DATA-EVENTO
     MOVE WS-HORA-SISTEMA TO AU-HORA-EVENTO
     MOVE 'VALOK001' TO AU-COD-EVENTO
     MOVE WS-CHAVE-REF TO AU-CHAVE-REF
     MOVE 'LANCAMENTO VALIDADO' TO AU-MENSAGEM
     MOVE LCT-STATUS OF VALIDOS-REG TO AU-COMPLEMENTO
     WRITE AUDIT-REG.

 5100-AUDITAR-REJEITO.
     MOVE SPACES TO AUDIT-REG WS-CHAVE-REF
     MOVE LCT-AGENCIA   OF ENTRADA-REG TO WS-CHAVE-REF(1:4)
     MOVE LCT-NUM-CONTA OF ENTRADA-REG TO WS-CHAVE-REF(5:8)
     MOVE 'REJT'     TO AU-TIPO-EVENTO
     MOVE 'EBVALI01' TO AU-PROGRAMA
     MOVE WS-DATA-SISTEMA TO AU-DATA-EVENTO
     MOVE WS-HORA-SISTEMA TO AU-HORA-EVENTO
     MOVE WS-REJ-COD  TO AU-COD-EVENTO
     MOVE WS-CHAVE-REF TO AU-CHAVE-REF
     MOVE WS-REJ-DESC TO AU-MENSAGEM
     MOVE 'VALIDACAO' TO AU-COMPLEMENTO
     WRITE AUDIT-REG.

 9000-FECHAR.
     CLOSE ENTRADA-IN VALIDOS-OUT REJEITOS-OUT CONTA-KSDS AUDIT-OUT.

 9100-RC.
     DISPLAY '*** EBVALI01 LIDOS      : ' WS-LIDOS
     DISPLAY '*** EBVALI01 VALIDOS    : ' WS-VALIDOS
     DISPLAY '*** EBVALI01 REJEITADOS : ' WS-REJEITADOS
     EVALUATE TRUE
         WHEN COM-ERRO
             MOVE 8 TO RETURN-CODE
         WHEN WS-REJEITADOS > ZERO OR WS-LIDOS = ZERO
             MOVE 4 TO RETURN-CODE
         WHEN OTHER
             MOVE 0 TO RETURN-CODE
     END-EVALUATE.
