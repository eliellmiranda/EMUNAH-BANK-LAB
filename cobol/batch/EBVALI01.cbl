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
      *   REJEITOS = Z77948.EMUNAH.ARQ.REJEITO.SEQ   (reprovados)     *
      *   AUDIT    = Z77948.EMUNAH.ARQ.AUDIT.SEQ      (trilha)        *
      *                                                               *
      * COPYBOOKS UTILIZADOS:                                         *
      *   CPLCT001 = layout de lancamento (120 bytes)                 *
      *   CPCNT001 = layout de conta      (100 bytes)                 *
      *   CPREJ001 = layout de rejeito    (120 bytes)                 *
      *   CPAUD001 = layout de auditoria  (120 bytes)                 *
      *                                                               *
      * CODIGOS DE REJEICAO:                                          *
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
               ASSIGN TO VALIDOS
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-VALIDOS.

      *---------------------------------------------------------------*
      * REJEITOS-OUT: lancamentos reprovados com motivo               *
      * Aberto em EXTEND para acumular sem sobrescrever               *
      * DDNAME: REJEITOS   LRECL: 120   RECFM: FB                     *
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
      * Arquivo de entrada — layout via CPLCT001                      *
      * Lido sequencialmente, um registro por iteracao do loop        *
      *---------------------------------------------------------------*
       FD  ENTRADA-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  ENTRADA-REG.
           COPY CPLCT001.

      *---------------------------------------------------------------*
      * Arquivo de lancamentos validos — mesmo layout de entrada      *
      * Gravado com LCT-STATUS = 'V' apos aprovacao                   *
      *---------------------------------------------------------------*
       FD  VALIDOS-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  VALIDOS-REG.
           COPY CPLCT001.

      *---------------------------------------------------------------*
      * Arquivo de rejeitos — layout via CPREJ001                     *
      * Preserva dados do lancamento original + motivo da rejeicao    *
      *---------------------------------------------------------------*
       FD  REJEITOS-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  REJEITOS-REG.
           COPY CPREJ001.

      *---------------------------------------------------------------*
      * KSDS de contas — layout via CPCNT001                          *
      * Consultado por chave CNT-CHAVE (agencia + numero da conta)    *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Arquivo de auditoria — layout via CPAUD001                    *
      * Recebe um registro para cada lancamento (sucesso ou rejeicao) *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG.
           COPY CPAUD001.

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File Status de todos os arquivos                              *
      * Niveis 88 facilitam leitura do codigo sem comparacao literal  *
      * '00' = OK   '10' = EOF   '23' = registro nao encontrado (KSDS)*
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
      * WS-EOF-ENTRADA : controla o loop principal de leitura         *
      * WS-ERRO        : sinaliza erro critico que aborta o programa   *
      * WS-REG-VALIDO  : indica se o registro atual passou em todas   *
      *                  as validacoes ate o momento                  *
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
      * Usadas em todos os registros de rejeito e auditoria           *
      *---------------------------------------------------------------*
       01  WS-DATA-SISTEMA           PIC 9(8).
       01  WS-HORA-SISTEMA           PIC 9(8).

      *---------------------------------------------------------------*
      * Codigo e descricao do motivo de rejeicao                      *
      * Preenchidos pela validacao e transferidos para CPREJ001        *
      *---------------------------------------------------------------*
       01  WS-REJ-COD                PIC X(4) VALUE SPACES.
       01  WS-REJ-DESC               PIC X(32) VALUE SPACES.

      *---------------------------------------------------------------*
      * Chave de referencia para o registro de auditoria              *
      * Montada com agencia (pos 1-4) + num-conta (pos 5-12)          *
      *---------------------------------------------------------------*
       01  WS-CHAVE-REF              PIC X(20).

       PROCEDURE DIVISION.

      *===============================================================*
      * 0000-PRINCIPAL                                                *
      * Ponto de entrada. Captura data/hora, abre arquivos,           *
      * processa lancamentos e encerra com RETURN-CODE adequado       *
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
      * Abre todos os arquivos verificando FILE STATUS apos cada OPEN *
      * Qualquer falha seta COM-ERRO e interrompe a cadeia de aberturas*
      * Todos os arquivos de saida usam EXTEND para preservar dados   *
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
      * Loop principal: le um lancamento por vez e aciona validacao   *
      * Interrompido por EOF ou erro critico de I/O                   *
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
      * Aplica validacoes em sequencia — a primeira falha encerra     *
      * o ciclo de checks e aciona gravacao do rejeito                *
      *                                                               *
      * Ordem das validacoes:                                         *
      *   1. Tipo do lancamento (V001): deve ser C ou D               *
      *   2. Valor do lancamento (V002): deve ser maior que zero      *
      *   3. Agencia (V003): nao pode ser zero                        *
      *   4. Numero da conta (V004): nao pode ser zero                *
      *   5. Existencia da conta no KSDS (V005)                       *
      *   6. Status da conta (V006): deve ser A (ativa)               *
      *---------------------------------------------------------------*
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

      *    Consulta a conta no KSDS pelo grupo LCT-CHAVE-CONTA
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

      *    Se conta encontrada, verifica se esta ativa
           IF REG-VALIDO AND CNT-STATUS OF CONTA-REG NOT = 'A'
               MOVE 'V006' TO WS-REJ-COD
               MOVE 'CONTA INATIVA OU BLOQUEADA' TO WS-REJ-DESC
               SET REG-INVALIDO TO TRUE
           END-IF

      *    Encaminha para gravacao de valido ou rejeito
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
      * Monta o registro de rejeito via CPREJ001 e grava em REJEITOS  *
      * Preserva todos os dados do lancamento original para analise   *
      * Aciona auditoria de rejeicao apos gravacao bem-sucedida       *
      *---------------------------------------------------------------*
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

      *---------------------------------------------------------------*
      * 5000-AUDITAR-SUCESSO                                          *
      * Grava registro de auditoria para lancamentos aprovados        *
      * Tipo de evento: OK   Codigo: VALOK001                         *
      * Chave de referencia: agencia(1-4) + num-conta(5-12)           *
      *---------------------------------------------------------------*
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

      *---------------------------------------------------------------*
      * 5100-AUDITAR-REJEITO                                          *
      * Grava registro de auditoria para lancamentos rejeitados       *
      * Tipo de evento: REJT   Codigo: mesmo codigo de rejeicao       *
      * Mensagem: descricao do motivo                                 *
      * Complemento: etapa onde ocorreu a rejeicao                    *
      *---------------------------------------------------------------*
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

      *---------------------------------------------------------------*
      * 9000-FECHAR                                                   *
      * Fecha todos os arquivos abertos                               *
      *---------------------------------------------------------------*
       9000-FECHAR.
           CLOSE ENTRADA-IN VALIDOS-OUT REJEITOS-OUT
                 CONTA-KSDS AUDIT-OUT.

      *---------------------------------------------------------------*
      * 9100-RC                                                       *
      * Exibe resumo no SYSOUT e define RETURN-CODE                   *
      * RC=0: tudo OK sem rejeicoes                                   *
      * RC=4: houve rejeicoes ou nenhum registro processado           *
      * RC=8: erro critico de I/O                                     *
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