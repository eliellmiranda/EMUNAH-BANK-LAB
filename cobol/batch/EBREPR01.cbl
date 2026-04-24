IDENTIFICATION DIVISION.
       PROGRAM-ID. EBREPR01.
      *===============================================================*
      * PROGRAMA : EBREPR01                                           *
      * BIBLIOTECA: Z77948.EMUNAH.BATCH.COBOL                         *
      * FUNCAO   : REPROCESSAMENTO DE LANCAMENTOS REJEITADOS          *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le o arquivo sequencial de rejeitos gerado pelo EBVALI01    *
      * - Reaplica as 5 regras de validacao sobre cada registro       *
      * - Registros que passam voltam ao fluxo normal (LANCTO-OUT)    *
      * - Registros que falham sao mantidos no arquivo de rejeitos    *
      *   com motivo acumulado (separador ' | ')                      *
      * - Registra cada decisao no arquivo de auditoria               *
      *                                                               *
      * ARQUIVOS:                                                      *
      * - REJIN    : Z77948.EMUNAH.ARQ.REJEIT.SEQ  (INPUT , 120 bytes)*
      * - LCTOUT   : Z77948.EMUNAH.ARQ.LANCTO.ESDS (OUTPUT, 120 bytes)*
      * - REJOUT   : Z77948.EMUNAH.ARQ.REJEIT2.SEQ (OUTPUT, 150 bytes)*
      * - AUDIT    : Z77948.EMUNAH.ARQ.AUDIT.SEQ   (EXTEND, 120 bytes)*
      *                                                               *
      * CODIGOS DE RETORNO (RETURN-CODE):                             *
      *   RC=0  : todos os rejeitos foram recuperados                 *
      *   RC=4  : ha rejeitos permanentes remanescentes ou            *
      *           arquivo de entrada estava vazio                     *
      *   RC=8  : erro de I/O em algum arquivo                       *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * REJIN = arquivo de rejeitos gerado pelo EBVALI01              *
      * Organizacao sequencial, leitura direta registro a registro    *
      *---------------------------------------------------------------*
           SELECT REJEIT-IN
               ASSIGN TO REJIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJIN.

      *---------------------------------------------------------------*
      * LCTOUT = ESDS de lancamentos para receber registros           *
      * recuperados. OPEN OUTPUT grava a partir do inicio da          *
      * extensao; para ambiente real usar EXTEND para append           *
      *---------------------------------------------------------------*
           SELECT LANCTO-OUT
               ASSIGN TO LCTOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-LCTOUT.

      *---------------------------------------------------------------*
      * REJOUT = arquivo de saida para rejeitos permanentes           *
      * 150 bytes: 120 do original + 30 de motivo acumulado          *
      *---------------------------------------------------------------*
           SELECT REJEIT-OUT
               ASSIGN TO REJOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJOUT.

      *---------------------------------------------------------------*
      * AUDIT = arquivo de auditoria, aberto em EXTEND (append)       *
      * Recebe um registro de auditoria para cada decisao             *
      *---------------------------------------------------------------*
           SELECT AUDIT-OUT
               ASSIGN TO AUDIT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-AUDIT.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Registro de entrada com REDEFINES para acesso por campo       *
      * O arquivo de rejeitos carrega o mesmo layout de 120 bytes     *
      * dos lancamentos, facilitando a revalidacao com o mesmo codigo *
      *---------------------------------------------------------------*
       FD  REJEIT-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  REJEIT-IN-RAW              PIC X(120).
       01  REJEIT-IN-REG REDEFINES REJEIT-IN-RAW.
           05 RJ-AGENCIA              PIC 9(4).
           05 RJ-NUM-CONTA            PIC 9(8).
           05 RJ-DATA                 PIC 9(8).
           05 RJ-TIPO                 PIC X(1).
           05 RJ-VALOR                PIC 9(11)V99.
           05 RJ-HISTORICO            PIC X(30).
           05 RJ-CANAL                PIC X(10).
           05 FILLER                  PIC X(46).

      *---------------------------------------------------------------*
      * Registro de saida para lancamentos recuperados                *
      * Layout identico ao CPLCT001 (120 bytes)                       *
      *---------------------------------------------------------------*
       FD  LANCTO-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  LANCTO-OUT-REG.
           COPY CPLCT001.

      *---------------------------------------------------------------*
      * Registro de saida para rejeitos permanentes                   *
      * 150 bytes: 120 bytes do registro original + 30 bytes de       *
      * motivo acumulado, para rastreabilidade do historico de         *
      * validacao                                                     *
      *---------------------------------------------------------------*
       FD  REJEIT-OUT
           RECORD CONTAINS 150 CHARACTERS
           RECORDING MODE IS F.
       01  REJEIT-OUT-REG.
           05 RO-DADOS-ORIG           PIC X(120).
           05 RO-MOTIVO               PIC X(30).

      *---------------------------------------------------------------*
      * Registro de auditoria - layout padrao CPAUD001 (120 bytes)    *
      *---------------------------------------------------------------*
       FD  AUDIT-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  AUDIT-REG.
           COPY CPAUD001.

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * FILE STATUS dos quatro arquivos                               *
      * '00' = operacao OK                                            *
      * '10' = fim de arquivo (apenas leitura sequencial)             *
      * '35' = arquivo nao encontrado no OPEN                         *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-REJIN             PIC XX.
           05 WS-FS-LCTOUT            PIC XX.
           05 WS-FS-REJOUT            PIC XX.
           05 WS-FS-AUDIT             PIC XX.

      *---------------------------------------------------------------*
      * Flags de controle de fluxo                                    *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-REJIN            PIC X VALUE 'N'.
               88 FIM-REJIN           VALUE 'S'.
           05 WS-ERRO-IO              PIC X VALUE 'N'.
               88 ERRO-IO-DETECTADO   VALUE 'S'.

      *---------------------------------------------------------------*
      * Contadores de processamento para DISPLAY final                *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-LIDOS                PIC 9(5) VALUE ZERO.
           05 WS-RECUPERADOS          PIC 9(5) VALUE ZERO.
           05 WS-MANTIDOS-REJ         PIC 9(5) VALUE ZERO.

      *---------------------------------------------------------------*
      * Campo auxiliar para acumular motivos de rejeito               *
      * Cada falha de validacao adiciona texto + ' | '                *
      *---------------------------------------------------------------*
       01  WS-MOTIVO-ACUM             PIC X(120) VALUE SPACES.
       01  WS-MOTIVO-TEMP             PIC X(30)  VALUE SPACES.

      *---------------------------------------------------------------*
      * Flags de validacao (uma por regra, nivel 88 para legibilidade)*
      *---------------------------------------------------------------*
       01  WS-FLAGS-VALID.
           05 WS-TIPO-VALIDO          PIC X VALUE 'S'.
               88 TIPO-INVALIDO       VALUE 'N'.
           05 WS-AG-VALIDA            PIC X VALUE 'S'.
               88 AG-INVALIDA         VALUE 'N'.
           05 WS-CT-VALIDA            PIC X VALUE 'S'.
               88 CT-INVALIDA         VALUE 'N'.
           05 WS-VALOR-VALIDO         PIC X VALUE 'S'.
               88 VALOR-INVALIDO      VALUE 'N'.
           05 WS-DATA-VALIDA          PIC X VALUE 'S'.
               88 DATA-INVALIDA       VALUE 'N'.

      *---------------------------------------------------------------*
      * Campos de data e hora para gravar na auditoria                *
      *---------------------------------------------------------------*
       01  WS-DATA-PROC               PIC X(8).
       01  WS-HORA-PROC               PIC X(8).

       PROCEDURE DIVISION.
      *===============================================================*
      * 0000-PRINCIPAL                                                *
      * Orquestra o fluxo completo de reprocessamento                 *
      *===============================================================*
       0000-PRINCIPAL.
           ACCEPT WS-DATA-PROC FROM DATE YYYYMMDD
           ACCEPT WS-HORA-PROC FROM TIME

           PERFORM 1000-ABRIR-ARQUIVOS
           IF NOT ERRO-IO-DETECTADO
               PERFORM 2000-REPROCESSAR-REJEITOS
               PERFORM 9000-ENCERRAR
           ELSE
               MOVE 12 TO RETURN-CODE
           END-IF

           GOBACK.

      *===============================================================*
      * 1000-ABRIR-ARQUIVOS                                           *
      * Abre os 4 arquivos. AUDIT em EXTEND para nao sobrescrever     *
      * o historico ja gravado por execucoes anteriores do fluxo.     *
      * Se qualquer OPEN falhar, seta ERRO-IO e encerra com RC=12.    *
      *===============================================================*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT  REJEIT-IN
           IF WS-FS-REJIN NOT = '00'
               DISPLAY 'ERRO OPEN REJEIT-IN FS=' WS-FS-REJIN
               MOVE 'S' TO WS-ERRO-IO
               STOP RUN
           END-IF

           OPEN OUTPUT LANCTO-OUT
           IF WS-FS-LCTOUT NOT = '00'
               DISPLAY 'ERRO OPEN LANCTO-OUT FS=' WS-FS-LCTOUT
               MOVE 'S' TO WS-ERRO-IO
               STOP RUN
           END-IF

           OPEN OUTPUT REJEIT-OUT
           IF WS-FS-REJOUT NOT = '00'
               DISPLAY 'ERRO OPEN REJEIT-OUT FS=' WS-FS-REJOUT
               MOVE 'S' TO WS-ERRO-IO
               STOP RUN
           END-IF

           OPEN EXTEND AUDIT-OUT
           IF WS-FS-AUDIT NOT = '00'
               DISPLAY 'ERRO OPEN AUDIT-OUT FS=' WS-FS-AUDIT
               MOVE 'S' TO WS-ERRO-IO
               STOP RUN
           END-IF.

      *===============================================================*
      * 2000-REPROCESSAR-REJEITOS                                     *
      * Loop principal: le cada rejeito e decide seu destino          *
      *===============================================================*
       2000-REPROCESSAR-REJEITOS.
           PERFORM UNTIL FIM-REJIN
               READ REJEIT-IN
                   AT END
                       MOVE 'S' TO WS-EOF-REJIN
                   NOT AT END
                       ADD 1 TO WS-LIDOS
                       PERFORM 2100-VALIDAR-REGISTRO
               END-READ
           END-PERFORM.

      *===============================================================*
      * 2100-VALIDAR-REGISTRO                                         *
      * Reaplica as 5 regras de validacao do EBVALI01.                *
      * Inicializa flags e acumulador antes de cada registro.         *
      *===============================================================*
       2100-VALIDAR-REGISTRO.
           MOVE SPACES TO WS-MOTIVO-ACUM
           MOVE 'S'    TO WS-TIPO-VALIDO
           MOVE 'S'    TO WS-AG-VALIDA
           MOVE 'S'    TO WS-CT-VALIDA
           MOVE 'S'    TO WS-VALOR-VALIDO
           MOVE 'S'    TO WS-DATA-VALIDA

      *-- R1: tipo deve ser 'C' (credito) ou 'D' (debito) --------*
           IF RJ-TIPO NOT = 'C' AND RJ-TIPO NOT = 'D'
               MOVE 'N' TO WS-TIPO-VALIDO
               MOVE 'TIPO INVALIDO' TO WS-MOTIVO-TEMP
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

      *-- R2: agencia numerica e maior que zero -------------------*
           IF RJ-AGENCIA NOT NUMERIC OR RJ-AGENCIA = ZEROS
               MOVE 'N' TO WS-AG-VALIDA
               MOVE 'AGENCIA INVALIDA' TO WS-MOTIVO-TEMP
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

      *-- R3: numero de conta numerico e maior que zero -----------*
           IF RJ-NUM-CONTA NOT NUMERIC OR RJ-NUM-CONTA = ZEROS
               MOVE 'N' TO WS-CT-VALIDA
               MOVE 'CONTA INVALIDA' TO WS-MOTIVO-TEMP
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

      *-- R4: valor numerico e maior que zero ---------------------*
           IF RJ-VALOR NOT NUMERIC OR RJ-VALOR = ZEROS
               MOVE 'N' TO WS-VALOR-VALIDO
               MOVE 'VALOR INVALIDO' TO WS-MOTIVO-TEMP
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

      *-- R5: data numerica e maior que zero ----------------------*
           IF RJ-DATA NOT NUMERIC OR RJ-DATA = ZEROS
               MOVE 'N' TO WS-DATA-VALIDA
               MOVE 'DATA INVALIDA' TO WS-MOTIVO-TEMP
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

           PERFORM 2200-DESTINAR-REGISTRO.

      *===============================================================*
      * 2200-DESTINAR-REGISTRO                                        *
      * Se passou em todas as regras -> LANCTO-OUT (recuperado)       *
      * Se falhou em alguma -> REJEIT-OUT (permanente)                *
      *===============================================================*
       2200-DESTINAR-REGISTRO.
           IF WS-TIPO-VALIDO  = 'S'
           AND WS-AG-VALIDA   = 'S'
           AND WS-CT-VALIDA   = 'S'
           AND WS-VALOR-VALIDO = 'S'
           AND WS-DATA-VALIDA  = 'S'
               ADD 1 TO WS-RECUPERADOS
               MOVE REJEIT-IN-RAW TO LCT-CHAVE-CONTA OF LANCTO-OUT-REG
               WRITE LANCTO-OUT-REG
               PERFORM 5000-AUDITAR-RECUPERADO
           ELSE
               ADD 1 TO WS-MANTIDOS-REJ
               MOVE REJEIT-IN-RAW TO RO-DADOS-ORIG
               MOVE FUNCTION TRIM(WS-MOTIVO-ACUM TRAILING)
                   TO RO-MOTIVO
               WRITE REJEIT-OUT-REG
               PERFORM 5100-AUDITAR-PERMANENTE
           END-IF.

      *===============================================================*
      * 2300-ACUMULAR-MOTIVO                                          *
      * Adiciona WS-MOTIVO-TEMP ao acumulador usando STRING.          *
      * O separador ' | ' e acrescentado entre motivos consecutivos. *
      * FUNCTION TRIM elimina espacos finais antes de concatenar.     *
      * Exemplo resultado: 'TIPO INVALIDO | VALOR INVALIDO'           *
      *===============================================================*
       2300-ACUMULAR-MOTIVO.
           IF WS-MOTIVO-ACUM = SPACES
               STRING FUNCTION TRIM(WS-MOTIVO-TEMP TRAILING)
                      DELIMITED BY SIZE
                      INTO WS-MOTIVO-ACUM
               END-STRING
           ELSE
               STRING FUNCTION TRIM(WS-MOTIVO-ACUM TRAILING)
                      ' | '
                      FUNCTION TRIM(WS-MOTIVO-TEMP TRAILING)
                      DELIMITED BY SIZE
                      INTO WS-MOTIVO-ACUM
               END-STRING
           END-IF.

      *===============================================================*
      * 5000-AUDITAR-RECUPERADO                                       *
      * Grava evento de auditoria para registro que voltou ao fluxo  *
      *===============================================================*
       5000-AUDITAR-RECUPERADO.
           MOVE SPACES            TO AUDIT-REG
           MOVE 'EBREPR01'        TO AU-PROGRAMA  OF AUDIT-REG
           MOVE WS-DATA-PROC      TO AU-DATA-EVENTO OF AUDIT-REG
           MOVE WS-HORA-PROC      TO AU-HORA-EVENTO OF AUDIT-REG
           MOVE 'OK'              TO AU-TIPO-EVENTO OF AUDIT-REG
           MOVE 'REGISTRO RECUPERADO'
                                  TO AU-MENSAGEM  OF AUDIT-REG
           WRITE AUDIT-REG.

      *===============================================================*
      * 5100-AUDITAR-PERMANENTE                                       *
      * Grava evento de auditoria para rejeito permanente             *
      * Inclui o motivo acumulado no campo de mensagem                *
      *===============================================================*
       5100-AUDITAR-PERMANENTE.
           MOVE SPACES            TO AUDIT-REG
           MOVE 'EBREPR01'        TO AU-PROGRAMA  OF AUDIT-REG
           MOVE WS-DATA-PROC      TO AU-DATA-EVENTO OF AUDIT-REG
           MOVE WS-HORA-PROC      TO AU-HORA-EVENTO OF AUDIT-REG
           MOVE 'REJT'            TO AU-TIPO-EVENTO OF AUDIT-REG
           MOVE WS-MOTIVO-ACUM    TO AU-MENSAGEM  OF AUDIT-REG
           WRITE AUDIT-REG.

      *===============================================================*
      * 9000-ENCERRAR                                                 *
      * Exibe totais no SYSOUT, fecha arquivos e define RETURN-CODE.  *
      * RC=0 : todos os rejeitos foram recuperados                    *
      * RC=4 : ha rejeitos permanentes remanescentes, ou              *
      *        arquivo entrou vazio (WS-LIDOS = ZERO)                 *
      * RC=8 : erro de I/O detectado durante processamento            *
      *===============================================================*
       9000-ENCERRAR.
           DISPLAY '*** RESUMO EBREPR01 ***'
           DISPLAY 'REGISTROS LIDOS       : ' WS-LIDOS
           DISPLAY 'REGISTROS RECUPERADOS : ' WS-RECUPERADOS
           DISPLAY 'REJEITOS PERMANENTES  : ' WS-MANTIDOS-REJ

           CLOSE REJEIT-IN
           CLOSE LANCTO-OUT
           CLOSE REJEIT-OUT
           CLOSE AUDIT-OUT

           EVALUATE TRUE
               WHEN ERRO-IO-DETECTADO
                   MOVE 8 TO RETURN-CODE
               WHEN WS-MANTIDOS-REJ > ZERO OR WS-LIDOS = ZERO
                   MOVE 4 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.