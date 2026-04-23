      *===============================================================*
      * ARQUIVO   : EBCLLOAD.cbl                                       *
      * CAMINHO   : cobol/batch/EBCLLOAD.cbl                           *
      *---------------------------------------------------------------*
      * FINALIDADE: Executar a carga inicial de clientes e contas do laboratório.*
      *                                                               *
      * ENTRADAS  : CLIENTIN, CONTAIN                              *
      * SAIDAS    : CLIENTE, CONTA, AUDIT                          *
      *                                                               *
      * REGRAS / COMPORTAMENTO ESPERADO:                              *
      * - Carrega os arquivos seed.                                  *
      * - Rejeita duplicidade e status inválido.                     *
      * - Prepara os masters para o primeiro ciclo do dia.           *
      *                                                               *
      * NOTA DIDATICA:                                                *
      * Este comentario foi enriquecido para manter o laboratorio     *
      * autoexplicativo. A logica do v3 foi preservada; o objetivo    *
      * desta versao e documentar melhor o papel do programa, os      *
      * arquivos esperados e a leitura operacional do fluxo.          *
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCLLOAD.
      *===============================================================*
      * PROGRAMA: EBCLLOAD                                            *
      * FUNCAO : CARGA INICIAL DE CLIENTES E CONTAS                   *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le arquivo sequencial de clientes                           *
      * - Le arquivo sequencial de contas                             *
      * - Valida status basico dos registros                          *
      * - Grava clientes em um KSDS de clientes                       *
      * - Grava contas em um KSDS de contas                           *
      * - Registra rejeicoes e duplicidades em arquivo de auditoria   *
      * - Exibe resumo final com totais processados                   *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Simular a carga inicial do ambiente bancario                *
      * - Popular arquivos master antes das rotinas batch             *
      * - Criar massa inicial para testes do laboratorio              *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * CLIENTES-IN = arquivo sequencial de entrada com clientes      *
      *---------------------------------------------------------------*
           SELECT CLIENTES-IN
               ASSIGN TO CLIENTIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CLIENTIN.

      *---------------------------------------------------------------*
      * CONTAS-IN = arquivo sequencial de entrada com contas          *
      *---------------------------------------------------------------*
           SELECT CONTAS-IN
               ASSIGN TO CONTAIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CONTAIN.

      *---------------------------------------------------------------*
      * AUDIT-OUT = arquivo de auditoria para registrar rejeicoes     *
      * e ocorrencias de duplicidade                                  *
      *---------------------------------------------------------------*
           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

      *---------------------------------------------------------------*
      * CLIENTE-KSDS = arquivo master indexado de clientes            *
      * A chave do arquivo e o id do cliente                          *
      *---------------------------------------------------------------*
           SELECT CLIENTE-KSDS
               ASSIGN TO CLIENTE
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CLI-ID-CLIENTE OF CLIENTE-KSDS-REG
               FILE STATUS IS WS-FS-CLIENTE.

      *---------------------------------------------------------------*
      * CONTA-KSDS = arquivo master indexado de contas                *
      * A chave e definida no copybook como CNT-CHAVE                *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CNT-CHAVE OF CONTA-KSDS-REG
               FILE STATUS IS WS-FS-CONTA.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Arquivo de entrada de clientes                                *
      * O copybook CPCLI001 deve conter apenas os campos 05...        *
      *---------------------------------------------------------------*
       FD  CLIENTES-IN
           RECORD CONTAINS 80 CHARACTERS
           RECORDING MODE IS F.
       01  CLIENTES-IN-REG.
           COPY CPCLI001.

      *---------------------------------------------------------------*
      * Arquivo de entrada de contas                                  *
      * O copybook CPCNT001 deve conter apenas os campos 05...        *
      *---------------------------------------------------------------*
       FD  CONTAS-IN
           RECORD CONTAINS 100 CHARACTERS
           RECORDING MODE IS F.
       01  CONTAS-IN-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Arquivo de auditoria                                          *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG                  PIC X(120).

      *---------------------------------------------------------------*
      * KSDS de clientes                                              *
      *---------------------------------------------------------------*
       FD  CLIENTE-KSDS.
       01  CLIENTE-KSDS-REG.
           COPY CPCLI001.

      *---------------------------------------------------------------*
      * KSDS de contas                                                *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-KSDS-REG.
           COPY CPCNT001.

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File status dos arquivos                                      *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-CLIENTIN          PIC XX.
           05 WS-FS-CONTAIN           PIC XX.
           05 WS-FS-AUDIT             PIC XX.
           05 WS-FS-CLIENTE           PIC XX.
           05 WS-FS-CONTA             PIC XX.

      *---------------------------------------------------------------*
      * Controle de fim de arquivo                                    *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-CLIENTES         PIC X VALUE 'N'.
           05 WS-EOF-CONTAS           PIC X VALUE 'N'.

      *---------------------------------------------------------------*
      * Contadores para resumo final                                  *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-CLI-LIDOS            PIC 9(5) VALUE ZERO.
           05 WS-CLI-GRAVADOS         PIC 9(5) VALUE ZERO.
           05 WS-CLI-REJEITADOS       PIC 9(5) VALUE ZERO.
           05 WS-CNT-LIDOS            PIC 9(5) VALUE ZERO.
           05 WS-CNT-GRAVADOS         PIC 9(5) VALUE ZERO.
           05 WS-CNT-REJEITADOS       PIC 9(5) VALUE ZERO.

       PROCEDURE DIVISION.
      *===============================================================*
      * FLUXO PRINCIPAL                                               *
      *===============================================================*
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR-ARQUIVOS
           PERFORM 2000-CARREGAR-CLIENTES
           PERFORM 3000-CARREGAR-CONTAS
           PERFORM 9000-ENCERRAR
           GOBACK.

      *---------------------------------------------------------------*
      * Abre os arquivos de entrada, os arquivos master e a auditoria *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT CLIENTES-IN
           OPEN INPUT CONTAS-IN
           OPEN I-O   CLIENTE-KSDS
           OPEN I-O   CONTA-KSDS
           OPEN EXTEND AUDIT-OUT.

      *---------------------------------------------------------------*
      * Le todos os clientes da entrada e envia para validacao        *
      *---------------------------------------------------------------*
       2000-CARREGAR-CLIENTES.
           PERFORM UNTIL WS-EOF-CLIENTES = 'S'
               READ CLIENTES-IN
                   AT END
                       MOVE 'S' TO WS-EOF-CLIENTES
                   NOT AT END
                       ADD 1 TO WS-CLI-LIDOS
                       PERFORM 2100-VALIDAR-CLIENTE
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Valida o cliente e tenta gravar no KSDS                       *
      * Regras de status aceitas: A, I ou B                           *
      * Se o status for invalido, rejeita                             *
      * Se a chave ja existir, rejeita como duplicado                 *
      *---------------------------------------------------------------*
       2100-VALIDAR-CLIENTE.
           IF CLI-STATUS OF CLIENTES-IN-REG NOT = 'A'
              AND CLI-STATUS OF CLIENTES-IN-REG NOT = 'I'
              AND CLI-STATUS OF CLIENTES-IN-REG NOT = 'B'
               ADD 1 TO WS-CLI-REJEITADOS
               MOVE SPACES TO AUDIT-REG
               STRING 'CLIENTE REJEITADO - STATUS INVALIDO - ID '
                      CLI-ID-CLIENTE OF CLIENTES-IN-REG
                      DELIMITED BY SIZE
                      INTO AUDIT-REG
               END-STRING
               WRITE AUDIT-REG
           ELSE
      *        Move o registro da entrada para a area do KSDS
               MOVE CLIENTES-IN-REG TO CLIENTE-KSDS-REG

      *        Tenta gravar o cliente no arquivo indexado
               WRITE CLIENTE-KSDS-REG
                   INVALID KEY
                       ADD 1 TO WS-CLI-REJEITADOS
                       MOVE SPACES TO AUDIT-REG
                       STRING 'CLIENTE REJEITADO - DUPLICADO - ID '
                              CLI-ID-CLIENTE OF CLIENTES-IN-REG
                              DELIMITED BY SIZE
                              INTO AUDIT-REG
                       END-STRING
                       WRITE AUDIT-REG
                   NOT INVALID KEY
                       ADD 1 TO WS-CLI-GRAVADOS
               END-WRITE
           END-IF.

      *---------------------------------------------------------------*
      * Le todas as contas da entrada e envia para validacao          *
      *---------------------------------------------------------------*
       3000-CARREGAR-CONTAS.
           PERFORM UNTIL WS-EOF-CONTAS = 'S'
               READ CONTAS-IN
                   AT END
                       MOVE 'S' TO WS-EOF-CONTAS
                   NOT AT END
                       ADD 1 TO WS-CNT-LIDOS
                       PERFORM 3100-VALIDAR-CONTA
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Valida a conta e tenta gravar no KSDS                         *
      * Regras de status aceitas: A, I ou B                           *
      * Se a chave ja existir, rejeita como duplicada                 *
      *---------------------------------------------------------------*
       3100-VALIDAR-CONTA.
           IF CNT-STATUS OF CONTAS-IN-REG NOT = 'A'
              AND CNT-STATUS OF CONTAS-IN-REG NOT = 'I'
              AND CNT-STATUS OF CONTAS-IN-REG NOT = 'B'
               ADD 1 TO WS-CNT-REJEITADOS
               MOVE SPACES TO AUDIT-REG
               STRING 'CONTA REJEITADA - STATUS INVALIDO - AG '
                      CNT-AGENCIA OF CONTAS-IN-REG
                      ' CTA '
                      CNT-NUM-CONTA OF CONTAS-IN-REG
                      DELIMITED BY SIZE
                      INTO AUDIT-REG
               END-STRING
               WRITE AUDIT-REG
           ELSE
      *        Move o registro da entrada para a area do KSDS
               MOVE CONTAS-IN-REG TO CONTA-KSDS-REG

      *        Tenta gravar a conta no arquivo indexado
               WRITE CONTA-KSDS-REG
                   INVALID KEY
                       ADD 1 TO WS-CNT-REJEITADOS
                       MOVE SPACES TO AUDIT-REG
                       STRING 'CONTA REJEITADA - DUPLICADA - AG '
                              CNT-AGENCIA OF CONTAS-IN-REG
                              ' CTA '
                              CNT-NUM-CONTA OF CONTAS-IN-REG
                              DELIMITED BY SIZE
                              INTO AUDIT-REG
                       END-STRING
                       WRITE AUDIT-REG
                   NOT INVALID KEY
                       ADD 1 TO WS-CNT-GRAVADOS
               END-WRITE
           END-IF.

      *---------------------------------------------------------------*
      * Exibe resumo final e fecha os arquivos                        *
      *---------------------------------------------------------------*
       9000-ENCERRAR.
           DISPLAY '*** RESUMO CARGA INICIAL ***'
           DISPLAY 'CLIENTES LIDOS      : ' WS-CLI-LIDOS
           DISPLAY 'CLIENTES GRAVADOS   : ' WS-CLI-GRAVADOS
           DISPLAY 'CLIENTES REJEITADOS : ' WS-CLI-REJEITADOS
           DISPLAY 'CONTAS LIDAS        : ' WS-CNT-LIDOS
           DISPLAY 'CONTAS GRAVADAS     : ' WS-CNT-GRAVADOS
           DISPLAY 'CONTAS REJEITADAS   : ' WS-CNT-REJEITADOS

           CLOSE CLIENTES-IN
           CLOSE CONTAS-IN
           CLOSE CLIENTE-KSDS
           CLOSE CONTA-KSDS
           CLOSE AUDIT-OUT.
