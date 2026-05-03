      *===============================================================*
      * PROGRAMA : EBCLLOAD                                           *
      * FUNCAO   : CARGA INICIAL DE CLIENTES E CONTAS                 *
      * MODULO   : CL (Client Load)                                   *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le arquivo sequencial de clientes (SEED) e grava no KSDS    *
      * - Le arquivo sequencial de contas (SEED) e grava no KSDS      *
      * - Valida status basico dos registros antes de gravar          *
      * - Rejeita duplicidades detectadas pelo INVALID KEY do KSDS    *
      * - Registra rejeicoes e ocorrencias em arquivo de auditoria    *
      * - Exibe resumo final com totais processados                   *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Simular a carga inicial do ambiente bancario do laboratorio *
      * - Popular os arquivos master antes das rotinas batch do dia   *
      * - Criar massa inicial para testes e validacoes                *
      *                                                               *
      * ENTRADAS:                                                     *
      *   CLIENTIN = Z77948.EMUNAH.SEED.CLIENTES.SEQ (80 bytes)       *
      *   CONTAIN  = Z77948.EMUNAH.SEED.CONTAS.SEQ   (100 bytes)      *
      *                                                               *
      * SAIDAS:                                                       *
      *   CLIENTE  = Z77948.EMUNAH.ARQ.CLIENTE.KSDS  (master clientes)*
      *   CONTA    = Z77948.EMUNAH.ARQ.CONTA.KSDS    (master contas)  *
      *   AUDIT    = Z77948.EMUNAH.ARQ.AUDIT.SEQ     (trilha)         *
      *                                                               *
      * COPYBOOKS UTILIZADOS:                                         *
      *   CPCLI001 = layout de cliente (80 bytes)                     *
      *   CPCNT001 = layout de conta   (100 bytes)                    *
      *                                                               *
      * REGRAS DE VALIDACAO:                                          *
      *   - Status do cliente deve ser A, I ou B                      *
      *   - Status da conta deve ser A, I ou B                        *
      *   - Chave duplicada no KSDS gera rejeicao na auditoria        *
      *                                                               *
      * RETURN-CODE:                                                  *
      * CORRECAO: Passou a ser controlado - RC 8 se houver rejeitos   *
      *===============================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBCLLOAD.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * CLIENTES-IN: arquivo sequencial com massa inicial de clientes *
      * Gerado manualmente ou por REXX antes da carga                 *
      * DDNAME: CLIENTIN   LRECL: 80   RECFM: FB                      *
      *---------------------------------------------------------------*
           SELECT CLIENTES-IN
               ASSIGN TO CLIENTIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CLIENTIN.

      *---------------------------------------------------------------*
      * CONTAS-IN: arquivo sequencial com massa inicial de contas     *
      * Deve referenciar clientes ja presentes no KSDS de clientes    *
      * DDNAME: CONTAIN   LRECL: 100   RECFM: FB                      *
      *---------------------------------------------------------------*
           SELECT CONTAS-IN
               ASSIGN TO CONTAIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-CONTAIN.

      *---------------------------------------------------------------*
      * AUDIT-OUT: trilha de auditoria para rejeicoes e duplicidades  *
      * Aberto em EXTEND para acumular registros sem sobrescrever     *
      * DDNAME: AUDIT   LRECL: 128   RECFM: FB                        *
      *---------------------------------------------------------------*
           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

      *---------------------------------------------------------------*
      * CLIENTE-KSDS: arquivo master indexado de clientes (VSAM KSDS) *
      * Chave primaria: CLI-ID-CLIENTE (5 bytes numericos)            *
      * Aberto em I-O para permitir WRITE e leitura posterior         *
      * DDNAME: CLIENTE                                               *
      *---------------------------------------------------------------*
           SELECT CLIENTE-KSDS
               ASSIGN TO CLIENTE
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CLI-ID-CLIENTE OF CLIENTE-KSDS-REG
               FILE STATUS IS WS-FS-CLIENTE.

      *---------------------------------------------------------------*
      * CONTA-KSDS: arquivo master indexado de contas (VSAM KSDS)     *
      * Chave primaria: CNT-CHAVE (agencia 4 + num-conta 8 = 12 bytes)*
      * Aberto em I-O para permitir WRITE e verificacao de duplicidade*
      * DDNAME: CONTA                                                 *
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
      * Layout definido pelo copybook CPCLI001 (80 bytes)             *
      * O copybook declara apenas niveis 05 - nivel 01 fica aqui      *
      *---------------------------------------------------------------*
       FD  CLIENTES-IN
           RECORD CONTAINS 80 CHARACTERS
           RECORDING MODE IS F.
       01  CLIENTES-IN-REG.
           COPY CPCLI001.

      *---------------------------------------------------------------*
      * Arquivo de entrada de contas                                  *
      * Layout definido pelo copybook CPCNT001 (100 bytes)            *
      *---------------------------------------------------------------*
       FD  CONTAS-IN
           RECORD CONTAINS 100 CHARACTERS
           RECORDING MODE IS F.
       01  CONTAS-IN-REG.
           COPY CPCNT001.

      *---------------------------------------------------------------*
      * Arquivo de auditoria (registro generico de 128 bytes)         *
      * Gravado como texto livre via STRING para flexibilidade        *
      * CORRECAO: LRECL ajustado para 128 bytes.                      *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 128 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG                  PIC X(128).

      *---------------------------------------------------------------*
      * KSDS de clientes - mesmo layout do arquivo de entrada         *
      * A chave CLI-ID-CLIENTE e usada como RECORD KEY                *
      *---------------------------------------------------------------*
       FD  CLIENTE-KSDS.
       01  CLIENTE-KSDS-REG.
           COPY CPCLI001.

      *---------------------------------------------------------------*
      * KSDS de contas - mesmo layout do arquivo de entrada           *
      * A chave CNT-CHAVE (agencia + numero da conta) e usada         *
      * como RECORD KEY do VSAM                                       *
      *---------------------------------------------------------------*
       FD  CONTA-KSDS.
       01  CONTA-KSDS-REG.
           COPY CPCNT001.

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File Status de todos os arquivos                              *
      * '00' = OK   '10' = EOF   outros = erro de I/O                 *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-CLIENTIN          PIC XX.
           05 WS-FS-CONTAIN           PIC XX.
           05 WS-FS-AUDIT             PIC XX.
           05 WS-FS-CLIENTE           PIC XX.
           05 WS-FS-CONTA             PIC XX.

      *---------------------------------------------------------------*
      * Flags de controle de fim de arquivo                           *
      * Inicializados como 'N' (nao chegou ao fim)                    *
      * Setados para 'S' no AT END do READ                            *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-CLIENTES         PIC X VALUE 'N'.
           05 WS-EOF-CONTAS           PIC X VALUE 'N'.

      *---------------------------------------------------------------*
      * Contadores para o resumo final exibido no SYSOUT              *
      * Lidos      = total de registros lidos do arquivo de entrada   *
      * Gravados = registros aceitos e gravados no KSDS               *
      * Rejeitados = duplicados ou status invalido                    *
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
      * 0000-PRINCIPAL                                                *
      * Ponto de entrada do programa. Controla o fluxo geral:         *
      * 1. Abre os arquivos                                           *
      * 2. Processa clientes                                          *
      * 3. Processa contas                                            *
      * 4. Encerra e exibe resumo                                     *
      *===============================================================*
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR-ARQUIVOS
           PERFORM 2000-CARREGAR-CLIENTES
           PERFORM 3000-CARREGAR-CONTAS
           PERFORM 9000-ENCERRAR
           GOBACK.

      *---------------------------------------------------------------*
      * 1000-ABRIR-ARQUIVOS                                           *
      * Abre todos os arquivos necessarios para o processamento       *
      * CLIENTES-IN e CONTAS-IN em INPUT (leitura sequencial)         *
      * KSDS em I-O (permite WRITE e leitura por chave)               *
      * AUDIT-OUT em EXTEND (acumula sem sobrescrever runs anteriores)*
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT CLIENTES-IN
           OPEN INPUT CONTAS-IN
           OPEN I-O   CLIENTE-KSDS
           OPEN I-O   CONTA-KSDS
           OPEN EXTEND AUDIT-OUT.

      *---------------------------------------------------------------*
      * 2000-CARREGAR-CLIENTES                                        *
      * Loop sequencial de leitura do arquivo de clientes             *
      * Para cada registro lido, aciona a validacao e carga           *
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
      * 2100-VALIDAR-CLIENTE                                          *
      * Valida o status do cliente lido:                              *
      *   - Status invalido (nao A, I ou B): grava rejeicao na AUDIT  *
      *   - Status valido: tenta gravar no KSDS                       *
      *   - INVALID KEY no KSDS: cliente duplicado, grava na AUDIT    *
      *   - NOT INVALID KEY: cliente gravado com sucesso              *
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
      *        Copia o registro da entrada para a area do KSDS
               MOVE CLIENTES-IN-REG TO CLIENTE-KSDS-REG
      *        Tenta gravar no KSDS - INVALID KEY indica duplicidade
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
      * 3000-CARREGAR-CONTAS                                          *
      * Loop sequencial de leitura do arquivo de contas               *
      * Para cada registro lido, aciona a validacao e carga           *
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
      * 3100-VALIDAR-CONTA                                            *
      * Valida o status da conta lida:                                *
      *   - Status invalido (nao A, I ou B): grava rejeicao na AUDIT  *
      *   - Status valido: tenta gravar no KSDS                       *
      *   - INVALID KEY: conta duplicada (mesma agencia+numero)       *
      *   - NOT INVALID KEY: conta gravada com sucesso                *
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
      *        Copia o registro da entrada para a area do KSDS
               MOVE CONTAS-IN-REG TO CONTA-KSDS-REG
      *        Tenta gravar no KSDS - INVALID KEY indica duplicidade
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
      * 9000-ENCERRAR                                                 *
      * Exibe resumo final no SYSOUT e fecha todos os arquivos        *
      * O resumo permite conferencia rapida do resultado da carga     *
      * CORRECAO: Adicionada logica de RETURN-CODE = 8 para rejeitos  *
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
           CLOSE AUDIT-OUT

           IF WS-CLI-REJEITADOS > ZERO OR WS-CNT-REJEITADOS > ZERO
               MOVE 8 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.