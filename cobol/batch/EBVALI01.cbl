      *===============================================================*
      * PROGRAMA : EBVALI01                                           *
      * FUNCAO   : VALIDACAO DE LANCAMENTOS DE ENTRADA                *
      * MODULO   : VALI (Validacao)                                   *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le lancamentos do arquivo de entrada sequencial             *
      * - Valida tipo, valor, agencia, conta e status da conta        *
      * - Grava lancamentos aprovados em VALIDOS com STATUS = 'V'     *
      * - Grava lancamentos reprovados em REJEITOS via CPREJ001       *
      * - Registra cada evento na trilha de auditoria (CPAUD001)      *
      *                                                               *
      * ENTRADAS:                                                     *
      *   ENTRADA  = Z77948.EMUNAH.ARQ.ENTRADA.SEQ   (lancamentos)    *
      *   CONTA    = Z77948.EMUNAH.ARQ.CONTA.KSDS    (master contas)  *
      *                                                               *
      * SAIDAS:                                                       *
      *   VALIDOS  = Z77948.EMUNAH.ARQ.LANCTO.ESDS   (aprovados)      *
      *   REJEITOS = Z77948.EMUNAH.ARQ.REJEITOS.SEQ  (reprovados)     *
      *   AUDIT    = Z77948.EMUNAH.ARQ.AUDIT.SEQ      (trilha)        *
      *                                                               *
      * COPYBOOKS UTILIZADOS:                                         *
      *   CPLCT001 = layout de lancamento (120 bytes)                 *
      *   CPCNT001 = layout de conta      (100 bytes)                 *
      *   CPREJ001 = layout de rejeito    (150 bytes)                 *
      *   CPAUD001 = layout de auditoria  (120 bytes)                 *
      *                                                               *
      * CODIGOS DE REJEICAO (REJ-COD-MOTIVO 4 bytes):                *
      *   V001 = tipo de lancamento invalido (nao C nem D)            *
      *   V002 = valor zerado ou negativo                             *
      *   V003 = agencia zerada (campo invalido)                      *
      *   V004 = numero de conta zerado (campo invalido)              *
      *   V005 = conta nao encontrada no KSDS                         *
      *   V006 = conta inativa ou bloqueada (status != A)             *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Processamento OK sem rejeicoes                  *
      *   RC = 4  --> Processamento OK com rejeicoes ou sem registros *
      *   RC = 8  --> Erro critico de I/O                             *
      *                                                               *
      * HISTORICO DE CORRECOES:                                       *
      *   [C1] Campos LCT-* em 2100 qualificados com OF ENTRADA-REG  *
      *        para eliminar ambiguidade com VALIDOS-REG              *
      *   [C2] Chave do KSDS montada campo a campo sem LCT-CHAVE-CONTA*
      *   [C3] WRITE AUDIT-REG protegido com FILE STATUS em 5000/5100 *
      *   [C4] FD REJEITOS-OUT corrigido para LRECL=150 (CPREJ001)   *
      *   [C5] 4000-GRAVAR-REJEITO reescrito conforme campos reais    *
      *        do CPREJ001: REJ-REGISTRO-ORIG, REJ-COD-MOTIVO,        *
      *        REJ-TXT-MOTIVO, REJ-TIMESTAMP e REJ-ORIGEM             *
      *   [C6] WS-REJ-DESC reduzido para 14 bytes (= REJ-TXT-MOTIVO) *
      *        e literais de rejeicao ajustadas para caber em 14 bytes*
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBVALI01.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * ENTRADA-IN: lancamentos do dia a serem validados              *
      * DDNAME: ENTRADA   LRECL: 120   RECFM: FB                      *
      *---------------------------------------------------------------*
           SELECT ENTRADA-IN
               ASSIGN TO ENTRADA
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-ENTRADA.

      *---------------------------------------------------------------*
      * VALIDOS-OUT: lancamentos aprovados com STATUS = 'V'           *
      * Aberto em EXTEND para acumular sem sobrescrever               *
      * DDNAME: VALIDOS   LRECL: 120   RECFM: FB                      *
      *---------------------------------------------------------------*
           SELECT VALIDOS-OUT
               ASSIGN TO AS-VALIDOS
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-VALIDOS.

      *---------------------------------------------------------------*
      * REJEITOS-OUT: lancamentos reprovados com motivo               *
      * Aberto em EXTEND para acumular sem sobrescrever               *
      * DDNAME: REJEITOS   LRECL: 150   RECFM: FB  (CPREJ001=150)     *
      *---------------------------------------------------------------*
           SELECT REJEITOS-OUT
               ASSIGN TO REJEITOS
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJEITOS.

      *---------------------------------------------------------------*
      * CONTA-KSDS: master de contas consultado por chave             *
      * Acesso DYNAMIC permite leitura direta por CNT-CHAVE           *
      * DDNAME: CONTA                                                 *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

      *---------------------------------------------------------------*
      * AUDIT-OUT: trilha de auditoria de todos os eventos            *
      * Aberto em EXTEND para preservar registros anteriores          *
      * DDNAME: AUDIT   LRECL: 120   RECFM: FB                        *
      *---------------------------------------------------------------*
           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Arquivo de entrada  layout via CPLCT001                      *
      * Lido sequencialmente, um registro por iteracao do loop        *
      *---------------------------------------------------------------*
       FD  ENTRADA-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  ENTRADA-REG.
           COPY CPLCT001.

      *---------------------------------------------------------------*
      * Arquivo de lancamentos validos  mesmo layout de entrada      *
      * Gravado com LCT-STATUS = 'V' apos aprovacao                   *
      * NOTA: por compartilhar o mesmo COPY CPLCT001, todos os        *
      *       campos LCT-* devem ser qualificados com OF ENTRADA-REG  *
      *       ou OF VALIDOS-REG conforme o contexto de uso [C1]       *
      *---------------------------------------------------------------*
       FD  VALIDOS-OUT.
       01  VALIDOS-REG.
           COPY CPLCT001.

      *---------------------------------------------------------------*
      * Arquivo de rejeitos  layout via CPREJ001                     *
      * [C4] LRECL corrigido para 150 conforme DCB do CPREJ001:       *
      *   01-120 = REJ-REGISTRO-ORIG (imagem do lancamento original)  *
      *   121-124 = REJ-COD-MOTIVO                                    *
      *   125-138 = REJ-TXT-MOTIVO                                    *
      *   139-146 = REJ-TIMESTAMP                                     *
      *   147-150 = REJ-ORIGEM                                        *
      *---------------------------------------------------------------*
       FD  REJEITOS-OUT
           RECORD CONTAINS 156 CHARACTERS
           RECORDING MODE IS F.
       01  REJEITOS-REG.
           COPY CPREJ001.

      *---------------------------------------------------------------*
      * KSDS de contas  layout via CPCNT001                          *
      * Consultado por chave CNT-CHAVE (agencia + numero da conta)    *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Arquivo de auditoria  layout via CPAUD001                    *
      * Recebe um registro para cada lancamento (sucesso ou rejeicao) *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 128 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG.
           COPY CPAUD001.

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File Status de todos os arquivos                              *
      * Niveis 88 facilitam leitura do codigo sem comparacao literal  *
      * '00' = OK   '10' = EOF   '23' = nao encontrado (KSDS)         *
      *---------------------------------------------------------------*
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

      *---------------------------------------------------------------*
      * Flags de controle do processamento                            *
      *---------------------------------------------------------------*
       01  WS-FLAGS.
           05 WS-EOF-ENTRADA         PIC X VALUE 'N'.
              88 EOF-ENTRADA         VALUE 'S'.
           05 WS-ERRO                PIC X VALUE 'N'.
              88 COM-ERRO            VALUE 'S'.
           05 WS-REG-VALIDO          PIC X VALUE 'S'.
              88 REG-VALIDO          VALUE 'S'.
              88 REG-INVALIDO        VALUE 'N'.

      *---------------------------------------------------------------*
      * Contadores para o resumo final exibido no SYSOUT              *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-LIDOS               PIC 9(9) VALUE ZERO.
           05 WS-VALIDOS             PIC 9(9) VALUE ZERO.
           05 WS-REJEITADOS          PIC 9(9) VALUE ZERO.

      *---------------------------------------------------------------*
      * Data e hora do sistema capturadas no inicio do programa       *
      *---------------------------------------------------------------*
       01  WS-DATA-SISTEMA           PIC 9(8).
       01  WS-HORA-SISTEMA           PIC 9(8).

      *---------------------------------------------------------------*
      * Codigo e texto do motivo de rejeicao                          *
      * [C6] WS-REJ-DESC ajustado para 14 bytes = REJ-TXT-MOTIVO      *
      *      Literais de rejeicao em 2100 ajustadas para <= 14 bytes  *
      *---------------------------------------------------------------*
       01  WS-REJ-COD                PIC X(4)  VALUE SPACES.
       01  WS-REJ-DESC               PIC X(14) VALUE SPACES.

      *---------------------------------------------------------------*
      * Chave de referencia para o registro de auditoria              *
      *---------------------------------------------------------------*
       01  WS-CHAVE-REF              PIC X(20).

       PROCEDURE DIVISION.

      *===============================================================*
      * 0000-PRINCIPAL                                                *
      *===============================================================*
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

      *---------------------------------------------------------------*
      * 1000-ABRIR                                                    *
      *---------------------------------------------------------------*
       1000-ABRIR.
           OPEN INPUT ENTRADA-IN
           IF NOT FS-ENTRADA-OK
               DISPLAY '*** EBVALI01 ERRO OPEN ENTRADA - ' WS-FS-ENTRADA
               SET COM-ERRO TO TRUE
           END-IF

           IF NOT COM-ERRO
               OPEN EXTEND VALIDOS-OUT
               IF NOT FS-VALIDOS-OK
                   DISPLAY '*** EBVALI01 ERRO OPEN VALIDOS - '
                           WS-FS-VALIDOS
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

      *---------------------------------------------------------------*
      * 2000-PROCESSAR                                                *
      *---------------------------------------------------------------*
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

      *---------------------------------------------------------------*
      * 2100-VALIDAR-REGISTRO                                         *
      * [C1] Todos os LCT-* qualificados com OF ENTRADA-REG           *
      * [C2] Chave do KSDS montada campo a campo                      *
      * [C6] Literais de rejeicao ajustadas para <= 14 bytes          *
      *---------------------------------------------------------------*
       2100-VALIDAR-REGISTRO.
           SET REG-VALIDO TO TRUE
           MOVE SPACES TO WS-REJ-COD WS-REJ-DESC

      *--- V001: tipo deve ser C ou D ----------------------------------*
           IF LCT-TIPO OF ENTRADA-REG NOT = 'C'
              AND LCT-TIPO OF ENTRADA-REG NOT = 'D'
               MOVE 'V001'           TO WS-REJ-COD
               MOVE 'TIPO INVALIDO ' TO WS-REJ-DESC
               SET REG-INVALIDO TO TRUE
           END-IF

      *--- V002: valor deve ser maior que zero -------------------------*
           IF REG-VALIDO AND
              LCT-VALOR OF ENTRADA-REG <= ZERO
               MOVE 'V002'           TO WS-REJ-COD
               MOVE 'VALOR INVALIDO' TO WS-REJ-DESC
               SET REG-INVALIDO TO TRUE
           END-IF

      *--- V003: agencia nao pode ser zero -----------------------------*
           IF REG-VALIDO AND
              LCT-AGENCIA OF ENTRADA-REG = ZERO
               MOVE 'V003'           TO WS-REJ-COD
               MOVE 'AGENCIA INVALI' TO WS-REJ-DESC
               SET REG-INVALIDO TO TRUE
           END-IF

      *--- V004: numero de conta nao pode ser zero ---------------------*
           IF REG-VALIDO AND
              LCT-NUM-CONTA OF ENTRADA-REG = ZERO
               MOVE 'V004'           TO WS-REJ-COD
               MOVE 'CONTA INVALIDA' TO WS-REJ-DESC
               SET REG-INVALIDO TO TRUE
           END-IF

      *--- V005: conta deve existir no KSDS ----------------------------*
      *    [C2] Chave montada campo a campo, sem LCT-CHAVE-CONTA       *
           IF REG-VALIDO
               MOVE LCT-AGENCIA   OF ENTRADA-REG
                                  TO CNT-AGENCIA   OF CONTA-REG
               MOVE LCT-NUM-CONTA OF ENTRADA-REG
                                  TO CNT-NUM-CONTA OF CONTA-REG
               READ CONTA-KSDS
                   INVALID KEY
                       MOVE 'V005'           TO WS-REJ-COD
                       MOVE 'CONTA NOT FOUND' TO WS-REJ-DESC
                       SET REG-INVALIDO TO TRUE
                   NOT INVALID KEY
                       CONTINUE
               END-READ
           END-IF

      *--- V006: conta deve estar ativa --------------------------------*
           IF REG-VALIDO AND CNT-STATUS OF CONTA-REG NOT = 'A'
               MOVE 'V006'           TO WS-REJ-COD
               MOVE 'CONTA INATIVA  ' TO WS-REJ-DESC
               SET REG-INVALIDO TO TRUE
           END-IF

      *--- Encaminha para valido ou rejeito ----------------------------*
           IF REG-VALIDO
               MOVE ENTRADA-REG TO VALIDOS-REG
               MOVE 'V' TO LCT-STATUS OF VALIDOS-REG
               WRITE VALIDOS-REG
               IF FS-VALIDOS-OK
                   ADD 1 TO WS-VALIDOS
                   PERFORM 5000-AUDITAR-SUCESSO
               ELSE
                   DISPLAY '*** EBVALI01 ERRO WRITE VALIDOS - '
                           WS-FS-VALIDOS
                   SET COM-ERRO TO TRUE
               END-IF
           ELSE
               PERFORM 4000-GRAVAR-REJEITO
           END-IF.

      *---------------------------------------------------------------*
      * 4000-GRAVAR-REJEITO                                           *
      * [C5] Reescrito conforme estrutura real do CPREJ001 (150 bytes)*
      *                                                               *
      *   REJ-REGISTRO-ORIG (120) <- imagem completa de ENTRADA-REG   *
      *   REJ-COD-MOTIVO    (  4) <- codigo de rejeicao (V001..V006)  *
      *   REJ-TXT-MOTIVO    ( 14) <- descricao curta do motivo        *
      *   REJ-TIMESTAMP     (  8) <- hora do sistema via ACCEPT TIME  *
      *   REJ-ORIGEM        (  4) <- 'VALI' identifica este programa  *
      *                                                               *
      * NOTA: a data de rejeicao nao e armazenada no CPREJ001.        *
      * Correlacionar pela data de execucao do job no SYSOUT/JES2.    *
      *---------------------------------------------------------------*
       4000-GRAVAR-REJEITO.
           MOVE SPACES          TO REJEITOS-REG
           MOVE ENTRADA-REG     TO REJ-REGISTRO-ORIG
           MOVE WS-REJ-COD      TO REJ-COD-MOTIVO
           MOVE WS-REJ-DESC     TO REJ-TXT-MOTIVO
           MOVE WS-HORA-SISTEMA TO REJ-TIMESTAMP
           MOVE 'VALI'          TO REJ-ORIGEM
           WRITE REJEITOS-REG
           IF FS-REJEITOS-OK
               ADD 1 TO WS-REJEITADOS
               PERFORM 5100-AUDITAR-REJEITO
           ELSE
               DISPLAY '*** EBVALI01 ERRO WRITE REJEITOS - '
                       WS-FS-REJEITOS
               SET COM-ERRO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * 5000-AUDITAR-SUCESSO                                          *
      * [C3] WRITE AUDIT-REG protegido com FILE STATUS                *
      *---------------------------------------------------------------*
       5000-AUDITAR-SUCESSO.
           MOVE SPACES TO AUDIT-REG WS-CHAVE-REF
           MOVE LCT-AGENCIA   OF ENTRADA-REG TO WS-CHAVE-REF(1:4)
           MOVE LCT-NUM-CONTA OF ENTRADA-REG TO WS-CHAVE-REF(5:8)
           MOVE 'OK'          TO AU-TIPO-EVENTO
           MOVE 'EBVALI01'    TO AU-PROGRAMA
           MOVE WS-DATA-SISTEMA TO AU-DATA-EVENTO
           MOVE WS-HORA-SISTEMA TO AU-HORA-EVENTO
           MOVE 'VALOK001'    TO AU-COD-EVENTO
           MOVE WS-CHAVE-REF  TO AU-CHAVE-REF
           MOVE 'LANCAMENTO VALIDADO' TO AU-MENSAGEM
           MOVE LCT-STATUS OF VALIDOS-REG TO AU-COMPLEMENTO
           WRITE AUDIT-REG
           IF NOT FS-AUDIT-OK
               DISPLAY '*** EBVALI01 ERRO WRITE AUDIT SUCESSO - '
                       WS-FS-AUDIT
               SET COM-ERRO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * 5100-AUDITAR-REJEITO                                          *
      * [C3] WRITE AUDIT-REG protegido com FILE STATUS                *
      *---------------------------------------------------------------*
       5100-AUDITAR-REJEITO.
           MOVE SPACES TO AUDIT-REG WS-CHAVE-REF
           MOVE LCT-AGENCIA   OF ENTRADA-REG TO WS-CHAVE-REF(1:4)
           MOVE LCT-NUM-CONTA OF ENTRADA-REG TO WS-CHAVE-REF(5:8)
           MOVE 'REJT'        TO AU-TIPO-EVENTO
           MOVE 'EBVALI01'    TO AU-PROGRAMA
           MOVE WS-DATA-SISTEMA TO AU-DATA-EVENTO
           MOVE WS-HORA-SISTEMA TO AU-HORA-EVENTO
           MOVE WS-REJ-COD    TO AU-COD-EVENTO
           MOVE WS-CHAVE-REF  TO AU-CHAVE-REF
           MOVE WS-REJ-DESC   TO AU-MENSAGEM
           MOVE 'VALIDACAO'   TO AU-COMPLEMENTO
           WRITE AUDIT-REG
           IF NOT FS-AUDIT-OK
               DISPLAY '*** EBVALI01 ERRO WRITE AUDIT REJEITO - '
                       WS-FS-AUDIT
               SET COM-ERRO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * 9000-FECHAR                                                   *
      *---------------------------------------------------------------*
       9000-FECHAR.
           CLOSE ENTRADA-IN VALIDOS-OUT REJEITOS-OUT
                 CONTA-KSDS AUDIT-OUT.

      *---------------------------------------------------------------*
      * 9100-RC                                                       *
      *---------------------------------------------------------------*
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
