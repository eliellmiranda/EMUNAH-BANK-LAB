       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCLLOAD.
      *===============================================================*
      * PROGRAMA: EBCLLOAD                                            *
      * FUNCAO : CARGA INICIAL DE CLIENTES E CONTAS                   *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le arquivo sequencial de clientes (SEED.CLIENTES.SEQ)       *
      * - Le arquivo sequencial de contas (SEED.CONTAS.SEQ)           *
      * - Valida status basico dos registros (A, I ou B)              *
      * - Grava clientes no KSDS de clientes (ARQ.CLIENTE.KSDS)      *
      * - Grava contas no KSDS de contas (ARQ.CONTA.KSDS)            *
      * - Registra rejeicoes no arquivo de auditoria (ARQ.AUDIT.SEQ) *
      * - Exibe resumo final com totais processados                   *
      *                                                               *
      * PRE-REQUISITOS:                                               *
      * - Os KSDS devem estar vazios (DELETE/DEFINE via IDCAMS)       *
      * - Os arquivos seed devem existir e estar populados            *
      * - O JCL deve usar DISP=OLD nos KSDS (acesso exclusivo)       *
      *                                                               *
      * DECISOES DE PROJETO:                                          *
      * - Os FDs dos KSDS usam nomes proprios (KCLI-*, KCNT-*)       *
      *   em vez de COPY do mesmo copybook da entrada, para evitar    *
      *   referencia ambigua nos campos de chave                      *
      * - OPEN OUTPUT porque e carga inicial em arquivo vazio         *
      * - ACCESS MODE SEQUENTIAL porque a carga e sempre em lote     *
      * - File status verificado apos cada OPEN e cada WRITE          *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

      *---------------------------------------------------------------*
      * Arquivo sequencial de entrada com clientes                    *
      * Origem: Z77948.EMUNAH.SEED.CLIENTES.SEQ                      *
      * DDNAME: CLIENTIN                                              *
      * LRECL: 80 bytes (layout definido em CPCLI001)                 *
      *---------------------------------------------------------------*
           SELECT CLIENTES-IN
               ASSIGN TO CLIENTIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CLIENTIN.

      *---------------------------------------------------------------*
      * Arquivo sequencial de entrada com contas                      *
      * Origem: Z77948.EMUNAH.SEED.CONTAS.SEQ                        *
      * DDNAME: CONTAIN                                               *
      * LRECL: 100 bytes (layout definido em CPCNT001)                *
      *---------------------------------------------------------------*
           SELECT CONTAS-IN
               ASSIGN TO CONTAIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CONTAIN.

      *---------------------------------------------------------------*
      * Arquivo de auditoria para registrar rejeicoes                 *
      * Destino: Z77948.EMUNAH.ARQ.AUDIT.SEQ                         *
      * DDNAME: AUDIT                                                 *
      * LRECL: 120 bytes                                              *
      *---------------------------------------------------------------*
           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

      *---------------------------------------------------------------*
      * KSDS de clientes                                              *
      * Destino: Z77948.EMUNAH.ARQ.CLIENTE.KSDS                      *
      * DDNAME: CLIENTE                                               *
      * CHAVE: KCLI-CHAVE (5 bytes, posicao 0)                       *
      * LRECL: 80 bytes                                               *
      *                                                               *
      * ACCESS MODE SEQUENTIAL porque carga inicial so grava          *
      * em ordem de chave, sem necessidade de acesso randomico.       *
      * Nao usa COPY CPCLI001 para evitar ambiguidade de nomes        *
      * com o FD de entrada que tambem usa o mesmo copybook.          *
      *---------------------------------------------------------------*
           SELECT CLIENTE-KSDS
               ASSIGN TO CLIENTE
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS KCLI-CHAVE
               FILE STATUS IS WS-FS-CLIENTE.

      *---------------------------------------------------------------*
      * KSDS de contas                                                *
      * Destino: Z77948.EMUNAH.ARQ.CONTA.KSDS                        *
      * DDNAME: CONTA                                                 *
      * CHAVE: KCNT-CHAVE (12 bytes, posicao 0)                      *
      *        composta por agencia (4) + numero da conta (8)         *
      * LRECL: 100 bytes                                              *
      *                                                               *
      * Mesma logica do KSDS de clientes: ACCESS SEQUENTIAL,          *
      * nomes proprios no FD, sem COPY CPCNT001.                      *
      *---------------------------------------------------------------*
           SELECT CONTA-KSDS
               ASSIGN TO CONTA
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS KCNT-CHAVE
               FILE STATUS IS WS-FS-CONTA.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Arquivo de entrada de clientes                                *
      * Layout resolvido pelo copybook CPCLI001                       *
      * Campos disponiveis: CLI-ID-CLIENTE, CLI-NOME, CLI-CPF,       *
      *                     CLI-DATA-NASC, CLI-STATUS, CLI-DATA-CAD   *
      *---------------------------------------------------------------*
       FD  CLIENTES-IN
           RECORD CONTAINS 80 CHARACTERS
           RECORDING MODE IS F.
       01  CLIENTES-IN-REG.
           COPY CPCLI001.

      *---------------------------------------------------------------*
      * Arquivo de entrada de contas                                  *
      * Layout resolvido pelo copybook CPCNT001                       *
      * Campos disponiveis: CNT-CHAVE (CNT-AGENCIA + CNT-NUM-CONTA), *
      *                     CNT-ID-CLIENTE, CNT-TIPO, CNT-STATUS,    *
      *                     CNT-DATA-ABERTURA, CNT-SALDO, CNT-LIMITE *
      *---------------------------------------------------------------*
       FD  CONTAS-IN
           RECORD CONTAINS 100 CHARACTERS
           RECORDING MODE IS F.
       01  CONTAS-IN-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Arquivo de auditoria                                          *
      * Registro livre de 120 bytes para mensagens de rejeicao        *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG                  PIC X(120).

      *---------------------------------------------------------------*
      * KSDS de clientes  layout proprio                             *
      * KCLI-CHAVE corresponde a CLI-ID-CLIENTE do copybook           *
      * KCLI-RESTO recebe os demais 75 bytes via MOVE do registro     *
      *---------------------------------------------------------------*
       FD  CLIENTE-KSDS
           RECORD CONTAINS 80 CHARACTERS.
       01  CLIENTE-KSDS-REG.
           05 KCLI-CHAVE              PIC 9(05).
           05 KCLI-RESTO              PIC X(75).

      *---------------------------------------------------------------*
      * KSDS de contas  layout proprio                               *
      * KCNT-CHAVE corresponde a CNT-CHAVE do copybook (AG + CTA)    *
      * KCNT-RESTO recebe os demais 88 bytes via MOVE do registro     *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS
           RECORD CONTAINS 100 CHARACTERS.
       01  CONTA-KSDS-REG.
           05 KCNT-CHAVE.
              10 KCNT-AGENCIA         PIC 9(04).
              10 KCNT-NUM-CONTA       PIC 9(08).
           05 KCNT-RESTO              PIC X(88).

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File status dos arquivos                                      *
      * Verificados apos cada OPEN e cada WRITE                       *
      * 00 = sucesso, qualquer outro valor = erro                     *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-CLIENTIN          PIC XX.
           05 WS-FS-CONTAIN           PIC XX.
           05 WS-FS-AUDIT             PIC XX.
           05 WS-FS-CLIENTE           PIC XX.
           05 WS-FS-CONTA             PIC XX.

      *---------------------------------------------------------------*
      * Controle de fim de arquivo                                    *
      * N = ainda ha registros, S = fim de arquivo atingido           *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-CLIENTES         PIC X VALUE 'N'.
           05 WS-EOF-CONTAS           PIC X VALUE 'N'.

      *---------------------------------------------------------------*
      * Contadores para resumo final                                  *
      * Exibidos no spool para conferencia operacional                *
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
      * 1. Abre todos os arquivos e valida file status                *
      * 2. Le e grava clientes                                        *
      * 3. Le e grava contas                                          *
      * 4. Exibe resumo e fecha arquivos                              *
      *===============================================================*
       0000-PRINCIPAL.
           DISPLAY '*** EBCLLOAD VERSAO 4 ***'
           PERFORM 1000-ABRIR-ARQUIVOS
           PERFORM 2000-CARREGAR-CLIENTES
           PERFORM 3000-CARREGAR-CONTAS
           PERFORM 9000-ENCERRAR
           GOBACK.

      *---------------------------------------------------------------*
      * Abre os arquivos de entrada, os KSDS e a auditoria            *
      * Os KSDS sao abertos como OUTPUT porque este programa faz      *
      * carga inicial em arquivo vazio (DELETE/DEFINE antes no JCL)   *
      * Se qualquer OPEN falhar, exibe o file status, seta RC=8       *
      * e encerra imediatamente para evitar processamento parcial     *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT  CLIENTES-IN
           IF WS-FS-CLIENTIN NOT = '00'
               DISPLAY 'ERRO OPEN CLIENTES-IN FS=' WS-FS-CLIENTIN
               MOVE 8 TO RETURN-CODE
               GOBACK
           END-IF

           OPEN INPUT  CONTAS-IN
           IF WS-FS-CONTAIN NOT = '00'
               DISPLAY 'ERRO OPEN CONTAS-IN FS=' WS-FS-CONTAIN
               MOVE 8 TO RETURN-CODE
               GOBACK
           END-IF

           OPEN OUTPUT CLIENTE-KSDS
           IF WS-FS-CLIENTE NOT = '00'
               DISPLAY 'ERRO OPEN CLIENTE-KSDS FS=' WS-FS-CLIENTE
               MOVE 8 TO RETURN-CODE
               GOBACK
           END-IF

           OPEN OUTPUT CONTA-KSDS
           IF WS-FS-CONTA NOT = '00'
               DISPLAY 'ERRO OPEN CONTA-KSDS FS=' WS-FS-CONTA
               MOVE 8 TO RETURN-CODE
               GOBACK
           END-IF

           OPEN EXTEND AUDIT-OUT
           IF WS-FS-AUDIT NOT = '00'
               DISPLAY 'ERRO OPEN AUDIT-OUT FS=' WS-FS-AUDIT
               MOVE 8 TO RETURN-CODE
               GOBACK
           END-IF.

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
      * Valida o cliente e grava no KSDS                              *
      *                                                               *
      * Regra de negocio:                                             *
      * - Status aceitos: A (Ativo), I (Inativo), B (Bloqueado)       *
      * - Qualquer outro status rejeita o registro                    *
      *                                                               *
      * O WRITE nao usa INVALID KEY  a verificacao e feita via       *
      * file status apos a gravacao. Isso evita problemas de          *
      * resolucao de branch quando ha nomes ambiguos entre FDs.       *
      *                                                               *
      * FS=00 apos o WRITE indica gravacao bem-sucedida.              *
      * Qualquer outro FS (ex: 21=duplicado, 24=overflow)             *
      * e tratado como rejeicao e registrado na auditoria.            *
      *---------------------------------------------------------------*
       2100-VALIDAR-CLIENTE.
           IF CLI-STATUS NOT = 'A'
              AND CLI-STATUS NOT = 'I'
              AND CLI-STATUS NOT = 'B'
               ADD 1 TO WS-CLI-REJEITADOS
               MOVE SPACES TO AUDIT-REG
               STRING 'CLIENTE REJEITADO - STATUS INVALIDO - ID '
                      CLI-ID-CLIENTE
                      DELIMITED BY SIZE
                      INTO AUDIT-REG
               END-STRING
               WRITE AUDIT-REG
           ELSE
               MOVE CLIENTES-IN-REG TO CLIENTE-KSDS-REG
               WRITE CLIENTE-KSDS-REG
               IF WS-FS-CLIENTE NOT = '00'
                   ADD 1 TO WS-CLI-REJEITADOS
                   MOVE SPACES TO AUDIT-REG
                   STRING 'CLIENTE REJEITADO - FS='
                          WS-FS-CLIENTE
                          ' ID '
                          CLI-ID-CLIENTE
                          DELIMITED BY SIZE
                          INTO AUDIT-REG
                   END-STRING
                   WRITE AUDIT-REG
               ELSE
                   ADD 1 TO WS-CLI-GRAVADOS
               END-IF
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
      * Valida a conta e grava no KSDS                                *
      *                                                               *
      * Regra de negocio:                                             *
      * - Status aceitos: A (Ativa), I (Inativa), B (Bloqueada)       *
      * - Qualquer outro status rejeita o registro                    *
      *                                                               *
      * Mesma abordagem do cliente: WRITE sem INVALID KEY,            *
      * verificacao via file status.                                  *
      *---------------------------------------------------------------*
       3100-VALIDAR-CONTA.
           IF CNT-STATUS NOT = 'A'
              AND CNT-STATUS NOT = 'I'
              AND CNT-STATUS NOT = 'B'
               ADD 1 TO WS-CNT-REJEITADOS
               MOVE SPACES TO AUDIT-REG
               STRING 'CONTA REJEITADA - STATUS INVALIDO - AG '
                      CNT-AGENCIA
                      ' CTA '
                      CNT-NUM-CONTA
                      DELIMITED BY SIZE
                      INTO AUDIT-REG
               END-STRING
               WRITE AUDIT-REG
           ELSE
               MOVE CONTAS-IN-REG TO CONTA-KSDS-REG
               WRITE CONTA-KSDS-REG
               IF WS-FS-CONTA NOT = '00'
                   ADD 1 TO WS-CNT-REJEITADOS
                   MOVE SPACES TO AUDIT-REG
                   STRING 'CONTA REJEITADA - FS='
                          WS-FS-CONTA
                          ' AG '
                          CNT-AGENCIA
                          ' CTA '
                          CNT-NUM-CONTA
                          DELIMITED BY SIZE
                          INTO AUDIT-REG
                   END-STRING
                   WRITE AUDIT-REG
               ELSE
                   ADD 1 TO WS-CNT-GRAVADOS
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Exibe resumo final e fecha os arquivos                        *
      * O resumo e a principal ferramenta de conferencia operacional  *
      * Se gravados = 0 com RC=0, ha problema no programa ou dados   *
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
