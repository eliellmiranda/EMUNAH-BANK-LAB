      *===============================================================*
      * ARQUIVO   : EBPOST01.cbl                                       *
      * CAMINHO   : cobol/batch/EBPOST01.cbl                           *
      *---------------------------------------------------------------*
      * FINALIDADE: Aplicar lançamentos válidos nas contas do laboratório.*
      *                                                               *
      * ENTRADAS  : MOVTIN, CONTA, CLIENTE                         *
      * SAIDAS    : CONTA atualizada, LANCTO/validos históricos, REJEITOS, AUDIT*
      *                                                               *
      * REGRAS / COMPORTAMENTO ESPERADO:                              *
      * - Atualiza o saldo da conta conforme crédito/débito.         *
      * - Registra rejeito quando a conta não pode receber a         *
      *   postagem.                                                  *
      * - Mantém trilha de auditoria para troubleshooting.           *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este comentario foi enriquecido para manter o laboratorio     *
      * autoexplicativo. A logica do v3 foi preservada; o objetivo    *
      * desta versao e documentar melhor o papel do programa, os      *
      * arquivos esperados e a leitura operacional do fluxo.          *
      *===============================================================*
 IDENTIFICATION DIVISION.
 PROGRAM-ID. EBPOST01.
*===============================================================*
* PROGRAMA : EBPOST01                                           *
* FUNCAO   : POSTAR LANCAMENTOS VALIDOS                         *
*                                                               *
* REGRAS PRINCIPAIS:                                            *
* - localiza conta                                              *
* - credito soma no saldo                                       *
* - debito verifica saldo + limite                              *
* - rejeitos de negocio sao gravados em REJEITOS.SEQ            *
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

     SELECT REJEITOS-OUT
         ASSIGN TO REJEITOS
         ORGANIZATION IS SEQUENTIAL
         ACCESS MODE IS SEQUENTIAL
         FILE STATUS IS WS-FS-REJEITOS.

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

 FD  REJEITOS-OUT
     RECORD CONTAINS 120 CHARACTERS
     RECORDING MODE IS F.
 01  REJEITOS-REG.
     COPY CPREJ001.

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
     05 WS-FS-REJEITOS         PIC XX VALUE SPACES.
        88 FS-REJEITOS-OK      VALUE '00'.
     05 WS-FS-AUDIT            PIC XX VALUE SPACES.
        88 FS-AUDIT-OK         VALUE '00'.

 01  WS-FLAGS.
     05 WS-EOF-MOVTIN          PIC X VALUE 'N'.
        88 EOF-MOVTIN          VALUE 'S'.
     05 WS-ERRO                PIC X VALUE 'N'.
        88 COM-ERRO            VALUE 'S'.
     05 WS-MOV-VALIDO          PIC X VALUE 'S'.
        88 MOV-VALIDO          VALUE 'S'.
        88 MOV-INVALIDO        VALUE 'N'.

 01  WS-CONTADORES.
     05 WS-LIDOS               PIC 9(9) VALUE ZERO.
     05 WS-PROCESSADOS         PIC 9(9) VALUE ZERO.
     05 WS-REJEITADOS          PIC 9(9) VALUE ZERO.

 01  WS-DATA-SISTEMA           PIC 9(8).
 01  WS-HORA-SISTEMA           PIC 9(8).
 01  WS-REJ-COD                PIC X(4) VALUE SPACES.
 01  WS-REJ-DESC               PIC X(32) VALUE SPACES.
 01  WS-SALDO-DISPONIVEL       PIC S9(15)V99 VALUE ZERO.
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
     OPEN INPUT MOVTO-IN
     IF NOT FS-MOVTIN-OK
         DISPLAY '*** EBPOST01 ERRO OPEN MOVTIN - ' WS-FS-MOVTIN
         SET COM-ERRO TO TRUE
     END-IF

     IF NOT COM-ERRO
         OPEN I-O CONTA-KSDS
         IF NOT FS-CONTA-OK
             DISPLAY '*** EBPOST01 ERRO OPEN CONTA - ' WS-FS-CONTA
             SET COM-ERRO TO TRUE
         END-IF
     END-IF

     IF NOT COM-ERRO
         OPEN EXTEND REJEITOS-OUT
         IF NOT FS-REJEITOS-OK
             DISPLAY '*** EBPOST01 ERRO OPEN REJEITOS - '
                     WS-FS-REJEITOS
             SET COM-ERRO TO TRUE
         END-IF
     END-IF

     IF NOT COM-ERRO
         OPEN EXTEND AUDIT-OUT
         IF NOT FS-AUDIT-OK
             DISPLAY '*** EBPOST01 ERRO OPEN AUDIT - ' WS-FS-AUDIT
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
                     PERFORM 2100-TRATAR-MOVIMENTO
                 ELSE
                     DISPLAY '*** EBPOST01 ERRO READ MOVTIN - '
                             WS-FS-MOVTIN
                     SET COM-ERRO TO TRUE
                 END-IF
         END-READ
     END-PERFORM.

 2100-TRATAR-MOVIMENTO.
     SET MOV-VALIDO TO TRUE
     MOVE SPACES TO WS-REJ-COD WS-REJ-DESC

     MOVE LCT-CHAVE-CONTA OF MOVTO-REG TO CNT-CHAVE OF CONTA-REG
     READ CONTA-KSDS
         INVALID KEY
             MOVE 'P001' TO WS-REJ-COD
             MOVE 'CONTA NAO ENCONTRADA' TO WS-REJ-DESC
             SET MOV-INVALIDO TO TRUE
         NOT INVALID KEY
             CONTINUE
     END-READ

     IF MOV-VALIDO AND CNT-STATUS OF CONTA-REG NOT = 'A'
         MOVE 'P002' TO WS-REJ-COD
         MOVE 'CONTA INATIVA OU BLOQUEADA' TO WS-REJ-DESC
         SET MOV-INVALIDO TO TRUE
     END-IF

     IF MOV-VALIDO
         COMPUTE WS-SALDO-DISPONIVEL =
             CNT-SALDO OF CONTA-REG + CNT-LIMITE OF CONTA-REG
         IF LCT-TIPO OF MOVTO-REG = 'D'
            AND LCT-VALOR OF MOVTO-REG > WS-SALDO-DISPONIVEL
             MOVE 'P003' TO WS-REJ-COD
             MOVE 'SALDO/LIMITE INSUFICIENTE' TO WS-REJ-DESC
             SET MOV-INVALIDO TO TRUE
         END-IF
     END-IF

     IF MOV-VALIDO
         EVALUATE LCT-TIPO OF MOVTO-REG
             WHEN 'C'
                 ADD LCT-VALOR OF MOVTO-REG TO CNT-SALDO OF CONTA-REG
             WHEN 'D'
                 SUBTRACT LCT-VALOR OF MOVTO-REG
                     FROM CNT-SALDO OF CONTA-REG
             WHEN OTHER
                 MOVE 'P004' TO WS-REJ-COD
                 MOVE 'TIPO DE MOVIMENTO INVALIDO' TO WS-REJ-DESC
                 SET MOV-INVALIDO TO TRUE
         END-EVALUATE
     END-IF

     IF MOV-VALIDO
         REWRITE CONTA-REG
         IF FS-CONTA-OK
             ADD 1 TO WS-PROCESSADOS
             PERFORM 5000-AUDITAR-SUCESSO
         ELSE
             DISPLAY '*** EBPOST01 ERRO REWRITE CONTA - '
                     WS-FS-CONTA
             SET COM-ERRO TO TRUE
         END-IF
     ELSE
         PERFORM 4000-GRAVAR-REJEITO
     END-IF.

 4000-GRAVAR-REJEITO.
     MOVE SPACES TO REJEITOS-REG
     MOVE LCT-AGENCIA   OF MOVTO-REG TO REJ-AGENCIA
     MOVE LCT-NUM-CONTA OF MOVTO-REG TO REJ-NUM-CONTA
     MOVE LCT-DATA      OF MOVTO-REG TO REJ-DATA-LANCTO
     MOVE LCT-TIPO      OF MOVTO-REG TO REJ-TIPO-LANCTO
     MOVE LCT-VALOR     OF MOVTO-REG TO REJ-VALOR
     MOVE LCT-NSEQ      OF MOVTO-REG TO REJ-NSEQ-ORIG
     MOVE WS-REJ-COD                  TO REJ-COD-MOTIVO
     MOVE WS-REJ-DESC                 TO REJ-DESC-MOTIVO
     MOVE 'EBPOST01'                  TO REJ-PROGRAMA
     MOVE WS-DATA-SISTEMA             TO REJ-DATA-REJEITO
     MOVE WS-HORA-SISTEMA             TO REJ-HORA-REJEITO
     WRITE REJEITOS-REG
     IF FS-REJEITOS-OK
         ADD 1 TO WS-REJEITADOS
         PERFORM 5100-AUDITAR-REJEITO
     ELSE
         DISPLAY '*** EBPOST01 ERRO WRITE REJEITOS - '
                 WS-FS-REJEITOS
         SET COM-ERRO TO TRUE
     END-IF.

 5000-AUDITAR-SUCESSO.
     MOVE SPACES TO AUDIT-REG WS-CHAVE-REF
     MOVE LCT-AGENCIA   OF MOVTO-REG TO WS-CHAVE-REF(1:4)
     MOVE LCT-NUM-CONTA OF MOVTO-REG TO WS-CHAVE-REF(5:8)
     MOVE 'OK'       TO AU-TIPO-EVENTO
     MOVE 'EBPOST01' TO AU-PROGRAMA
     MOVE WS-DATA-SISTEMA TO AU-DATA-EVENTO
     MOVE WS-HORA-SISTEMA TO AU-HORA-EVENTO
     MOVE 'POSTOK001' TO AU-COD-EVENTO
     MOVE WS-CHAVE-REF TO AU-CHAVE-REF
     MOVE 'MOVIMENTO POSTADO' TO AU-MENSAGEM
     MOVE LCT-TIPO OF MOVTO-REG TO AU-COMPLEMENTO
     WRITE AUDIT-REG.

 5100-AUDITAR-REJEITO.
     MOVE SPACES TO AUDIT-REG WS-CHAVE-REF
     MOVE LCT-AGENCIA   OF MOVTO-REG TO WS-CHAVE-REF(1:4)
     MOVE LCT-NUM-CONTA OF MOVTO-REG TO WS-CHAVE-REF(5:8)
     MOVE 'REJT'     TO AU-TIPO-EVENTO
     MOVE 'EBPOST01' TO AU-PROGRAMA
     MOVE WS-DATA-SISTEMA TO AU-DATA-EVENTO
     MOVE WS-HORA-SISTEMA TO AU-HORA-EVENTO
     MOVE WS-REJ-COD  TO AU-COD-EVENTO
     MOVE WS-CHAVE-REF TO AU-CHAVE-REF
     MOVE WS-REJ-DESC TO AU-MENSAGEM
     MOVE 'POSTAGEM'  TO AU-COMPLEMENTO
     WRITE AUDIT-REG.

 9000-FECHAR.
     CLOSE MOVTO-IN CONTA-KSDS REJEITOS-OUT AUDIT-OUT.

 9100-RC.
     DISPLAY '*** EBPOST01 LIDOS      : ' WS-LIDOS
     DISPLAY '*** EBPOST01 PROCESSADOS : ' WS-PROCESSADOS
     DISPLAY '*** EBPOST01 REJEITADOS : ' WS-REJEITADOS
     EVALUATE TRUE
         WHEN COM-ERRO
             MOVE 8 TO RETURN-CODE
         WHEN WS-REJEITADOS > ZERO
             MOVE 4 TO RETURN-CODE
         WHEN OTHER
             MOVE 0 TO RETURN-CODE
     END-EVALUATE.
