      *===============================================================*
      * PROGRAMA : EBPOST01                                           *
      * FUNCAO   : POSTAGEM DE LANCAMENTOS VALIDOS                    *
      * MODULO   : POST (Postagem)                                    *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le lancamentos validados pelo EBVALI01                      *
      * - Localiza a conta no KSDS e valida status                    *
      * - Aplica credito (soma) ou debito (subtrai) no CNT-SALDO      *
      * - Para debitos, verifica saldo + limite antes de postar       *
      * - Atualiza a conta via REWRITE no KSDS                        *
      * - Grava rejeitos de negocio em REJEITOS com motivo            *
      * - Registra cada evento na trilha de auditoria                 *
      *                                                               *
      * ENTRADAS:                                                     *
      *   MOVTIN   = Z77948.EMUNAH.ARQ.LANCTO.ESDS  (lancamentos val) *
      *   CONTA    = Z77948.EMUNAH.ARQ.CONTA.KSDS   (master contas)   *
      *                                                               *
      * SAIDAS:                                                       *
      *   CONTA    = Z77948.EMUNAH.ARQ.CONTA.KSDS   (saldo atualizado)*
      *   REJEITOS = Z77948.EMUNAH.ARQ.REJEITO.SEQ  (rejeitos negocio)*
      *   AUDIT    = Z77948.EMUNAH.ARQ.AUDIT.SEQ    (trilha)          *
      *                                                               *
      * COPYBOOKS UTILIZADOS:                                         *
      *   CPLCT001 = layout de lancamento (120 bytes)                 *
      *   CPCNT001 = layout de conta      (100 bytes)                 *
      *   CPREJ001 = layout de rejeito    (120 bytes)                 *
      *   CPAUD001 = layout de auditoria  (120 bytes)                 *
      *                                                               *
      * CODIGOS DE REJEICAO:                                          *
      *   P001 = conta nao encontrada no KSDS                         *
      *   P002 = conta inativa ou bloqueada (status != A)             *
      *   P003 = saldo + limite insuficiente para debito              *
      *   P004 = tipo de movimento invalido (nao C nem D)             *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Postagem OK sem rejeicoes                       *
      *   RC = 4  --> Postagem OK com rejeicoes de negocio            *
      *   RC = 8  --> Erro critico de I/O                             *
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBPOST01.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * MOVTO-IN: lancamentos aprovados pelo EBVALI01                 *
      * Lido sequencialmente - um registro por iteracao do loop       *
      * DDNAME: MOVTIN   LRECL: 120   RECFM: FB                       *
      *---------------------------------------------------------------*
           SELECT MOVTO-IN
               ASSIGN TO AS-MOVTIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-MOVTIN.

      *---------------------------------------------------------------*
      * CONTA-KSDS: master de contas aberto em I-O para REWRITE       *
      * Consultado por chave (CNT-CHAVE) e atualizado apos postagem   *
      * DDNAME: CONTA                                                 *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CNT-CHAVE OF CONTA-REG
               FILE STATUS IS WS-FS-CONTA.

      *---------------------------------------------------------------*
      * REJEITOS-OUT: rejeitos de negocio gerados pela postagem       *
      * Aberto em EXTEND para acumular com rejeitos do EBVALI01       *
      * DDNAME: REJEITOS   LRECL: 120   RECFM: FB                     *
      *---------------------------------------------------------------*
           SELECT REJEITOS-OUT
               ASSIGN TO REJEITOS
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJEITOS.

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
      * Arquivo de movimentos validados - layout via CPLCT001         *
      *---------------------------------------------------------------*
       FD  MOVTO-IN
           RECORD CONTAINS 120 CHARACTERS.
       01  MOVTO-REG.
           COPY CPLCT001.

      *---------------------------------------------------------------*
      * KSDS de contas - layout via CPCNT001                          *
      * Lido por chave e atualizado via REWRITE apos cada postagem    *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Arquivo de rejeitos - layout via CPREJ001                     *
      *---------------------------------------------------------------*
       FD  REJEITOS-OUT
           RECORD CONTAINS 156 CHARACTERS
           RECORDING MODE IS F.
       01  REJEITOS-REG.
           COPY CPREJ001.

      *---------------------------------------------------------------*
      * Arquivo de auditoria - layout via CPAUD001                    *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 128 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG.
           COPY CPAUD001.

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File Status de todos os arquivos                              *
      * '00' = OK   '10' = EOF   '23' = nao encontrado (KSDS)         *
      *---------------------------------------------------------------*
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

      *---------------------------------------------------------------*
      * Flags de controle do processamento                            *
      * WS-EOF-MOVTIN  : controla o loop principal de leitura         *
      * WS-ERRO        : sinaliza erro critico que aborta o programa   *
      * WS-MOV-VALIDO  : indica se o movimento passou nas verificacoes*
      *---------------------------------------------------------------*
       01  WS-FLAGS.
           05 WS-EOF-MOVTIN          PIC X VALUE 'N'.
              88 EOF-MOVTIN          VALUE 'S'.
           05 WS-ERRO                PIC X VALUE 'N'.
              88 COM-ERRO            VALUE 'S'.
           05 WS-MOV-VALIDO          PIC X VALUE 'S'.
              88 MOV-VALIDO          VALUE 'S'.
              88 MOV-INVALIDO        VALUE 'N'.

      *---------------------------------------------------------------*
      * Contadores para o resumo final exibido no SYSOUT              *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-LIDOS               PIC 9(9) VALUE ZERO.
           05 WS-PROCESSADOS         PIC 9(9) VALUE ZERO.
           05 WS-REJEITADOS          PIC 9(9) VALUE ZERO.

      *---------------------------------------------------------------*
      * Data e hora do sistema capturadas no inicio do programa       *
      *---------------------------------------------------------------*
       01 WS-TIMESTAMP.
           05  WS-DATA-SISTEMA           PIC 9(8).
           05  WS-HORA-SISTEMA           PIC 9(8).

      *---------------------------------------------------------------*
      * Codigo e descricao do motivo de rejeicao de negocio           *
      *---------------------------------------------------------------*
       01  WS-REJ-COD                PIC X(4) VALUE SPACES.
       01  WS-REJ-DESC               PIC X(32) VALUE SPACES.

      *---------------------------------------------------------------*
      * Saldo disponivel = CNT-SALDO + CNT-LIMITE                     *
      * Calculado antes de cada debito para verificar cobertura        *
      * Declarado com precisao maior que o saldo para evitar overflow  *
      *---------------------------------------------------------------*
       01  WS-SALDO-DISPONIVEL       PIC S9(15)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Chave de referencia para o registro de auditoria              *
      *---------------------------------------------------------------*
       01  WS-CHAVE-REF              PIC X(20).

       PROCEDURE DIVISION.

      *===============================================================*
      * 0000-PRINCIPAL                                                *
      * Ponto de entrada. Captura data/hora, abre arquivos,           *
      * processa movimentos e encerra com RETURN-CODE adequado        *
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
      * Abre todos os arquivos verificando FILE STATUS                *
      * CONTA-KSDS aberto em I-O para permitir REWRITE                *
      * Arquivos de saida abertos em EXTEND                           *
      *---------------------------------------------------------------*
       1000-ABRIR.
                  OPEN INPUT MOVTO-IN
                  EVALUATE WS-FS-MOVTIN
                      WHEN '00'
                          CONTINUE
                      WHEN '37'
                          DISPLAY '*** EBPOST01 AVISO: MOVTIN VAZIO - '
                                  'NENHUM REPROCESSADO PENDENTE'
                          SET EOF-MOVTIN TO TRUE
                      WHEN OTHER
                          DISPLAY '*** EBPOST01 ERRO OPEN MOVTIN - '
                                  WS-FS-MOVTIN
                          SET COM-ERRO TO TRUE
                  END-EVALUATE
                          
            IF NOT COM-ERRO
                OPEN I-O CONTA-KSDS
                IF NOT FS-CONTA-OK
                   DISPLAY '*** EBPOST01 ERRO OPEN CONTA - ' WS-FS-CONTA
                    SET COM-ERRO TO TRUE
                END-IF
            END-IF
 
            IF NOT COM-ERRO
                OPEN EXTEND REJEITOS-OUT
                IF WS-FS-REJEITOS = '35'
                    OPEN OUTPUT REJEITOS-OUT
                END-IF
 
                IF NOT FS-REJEITOS-OK
                    DISPLAY '*** EBPOST01 ERRO OPEN REJEITOS - '
                            WS-FS-REJEITOS
                    SET COM-ERRO TO TRUE
                END-IF
            END-IF
 
            IF NOT COM-ERRO
                OPEN EXTEND AUDIT-OUT
                IF WS-FS-AUDIT = '35'
                    OPEN OUTPUT AUDIT-OUT
                END-IF
 
                IF NOT FS-AUDIT-OK
                   DISPLAY '*** EBPOST01 ERRO OPEN AUDIT - ' WS-FS-AUDIT
                    SET COM-ERRO TO TRUE
                END-IF
            END-IF.
 
      *---------------------------------------------------------------*
      * 2000-PROCESSAR                                                *
      * Loop principal: le um movimento por vez e aciona tratamento   *
      * Interrompido por EOF ou erro critico de I/O                   *
      *---------------------------------------------------------------*
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

      *---------------------------------------------------------------*
      * 2100-TRATAR-MOVIMENTO                                         *
      * Aplica as regras de negocio da postagem:                      *
      *   P001: conta deve existir no KSDS                            *
      *   P002: conta deve estar ativa (status A)                     *
      *   P003: debito exige saldo + limite suficiente                 *
      *   P004: tipo deve ser C ou D (redundante com EBVALI01)        *
      * Se aprovado: atualiza saldo e executa REWRITE                 *
      * Se rejeitado: aciona gravacao do rejeito de negocio           *
      *---------------------------------------------------------------*
       2100-TRATAR-MOVIMENTO.
           SET MOV-VALIDO TO TRUE
           MOVE SPACES TO WS-REJ-COD WS-REJ-DESC

      *    Localiza a conta no KSDS pelo grupo de chave
           MOVE LCT-CHAVE-CONTA OF MOVTO-REG TO CNT-CHAVE OF CONTA-REG
           READ CONTA-KSDS
               INVALID KEY
                   MOVE 'P001' TO WS-REJ-COD
                   MOVE 'CONTA NAO ENCONTRADA' TO WS-REJ-DESC
                   SET MOV-INVALIDO TO TRUE
               NOT INVALID KEY
                   CONTINUE
           END-READ

      *    Verifica se a conta esta ativa para receber movimentacao
           IF MOV-VALIDO AND CNT-STATUS OF CONTA-REG NOT = 'A'
               MOVE 'P002' TO WS-REJ-COD
               MOVE 'CONTA INATIVA OU BLOQUEADA' TO WS-REJ-DESC
               SET MOV-INVALIDO TO TRUE
           END-IF

      *    Para debitos, verifica cobertura de saldo + limite
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

      *    Aplica o movimento no saldo conforme tipo
           IF MOV-VALIDO
               EVALUATE LCT-TIPO OF MOVTO-REG
                   WHEN 'C'
                       ADD LCT-VALOR OF MOVTO-REG
                           TO CNT-SALDO OF CONTA-REG
                   WHEN 'D'
                       SUBTRACT LCT-VALOR OF MOVTO-REG
                           FROM CNT-SALDO OF CONTA-REG
                   WHEN OTHER
                       MOVE 'P004' TO WS-REJ-COD
                       MOVE 'TIPO DE MOVIMENTO INVALIDO' TO WS-REJ-DESC
                       SET MOV-INVALIDO TO TRUE
               END-EVALUATE
           END-IF

      *    Persiste o saldo atualizado no KSDS via REWRITE
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

      *---------------------------------------------------------------*
      * 4000-GRAVAR-REJEITO                                           *
      * Monta registro de rejeito de negocio e grava em REJEITOS      *
      * Preserva dados originais do lancamento para rastreabilidade   *
      *---------------------------------------------------------------*
       4000-GRAVAR-REJEITO.
           MOVE SPACES TO REJEITOS-REG

      * 1. Copia a imagem exata e completa do lancamento (120 bytes)
           MOVE MOVTO-REG       TO REJ-REGISTRO-ORIG

      * 2. Preenche os metadados do erro
           MOVE WS-REJ-COD      TO REJ-COD-MOTIVO
           MOVE WS-REJ-DESC     TO REJ-TXT-MOTIVO

      * 3. Move o Timestamp unificado (AAAAMMDDHHMMSS)
           MOVE WS-TIMESTAMP    TO REJ-TIMESTAMP

      * 4. Define quem rejeitou usando o Nivel 88 do copybook
           SET REJ-ORIGEM-POST  TO TRUE

           WRITE REJEITOS-REG
           IF FS-REJEITOS-OK
               ADD 1 TO WS-REJEITADOS
               PERFORM 5100-AUDITAR-REJEITO
           ELSE
               DISPLAY '*** EBPOST01 ERRO WRITE REJEITOS - '
                       WS-FS-REJEITOS
               SET COM-ERRO TO TRUE
           END-IF.
      *---------------------------------------------------------------*
      * 5000-AUDITAR-SUCESSO                                          *
      * Grava auditoria de postagem bem-sucedida                      *
      * Complemento indica o tipo do movimento postado (C ou D)       *
      *---------------------------------------------------------------*
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

      *---------------------------------------------------------------*
      * 5100-AUDITAR-REJEITO                                          *
      * Grava auditoria de rejeicao de negocio                        *
      * Complemento identifica a etapa responsavel pela rejeicao      *
      *---------------------------------------------------------------*
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

      *---------------------------------------------------------------*
      * 9000-FECHAR                                                   *
      * Fecha todos os arquivos abertos                               *
      *---------------------------------------------------------------*
       9000-FECHAR.
           CLOSE MOVTO-IN CONTA-KSDS REJEITOS-OUT AUDIT-OUT.

      *---------------------------------------------------------------*
      * 9100-RC                                                       *
      * Exibe resumo no SYSOUT e define RETURN-CODE                   *
      * RC=0: tudo OK sem rejeicoes                                   *
      * RC=4: houve rejeicoes de negocio                              *
      * RC=8: erro critico de I/O                                     *
      *---------------------------------------------------------------*
       9100-RC.
           DISPLAY '*** EBPOST01 LIDOS       : ' WS-LIDOS
           DISPLAY '*** EBPOST01 PROCESSADOS : ' WS-PROCESSADOS
           DISPLAY '*** EBPOST01 REJEITADOS  : ' WS-REJEITADOS
           EVALUATE TRUE
               WHEN COM-ERRO
                   MOVE 8 TO RETURN-CODE
               WHEN WS-REJEITADOS > ZERO
                   MOVE 4 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.