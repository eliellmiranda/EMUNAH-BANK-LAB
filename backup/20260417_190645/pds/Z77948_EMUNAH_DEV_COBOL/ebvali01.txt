       IDENTIFICATION DIVISION.
       PROGRAM-ID. EBVALI01.
      *===============================================================*
      * PROGRAMA : EBVALI01                                           *
      * FUNCAO   : VALIDAR LANCAMENTOS DE ENTRADA                     *
      *                                                               *
      * O QUE ESTE PROGRAMA FAZ:                                      *
      * - Le um arquivo sequencial de lancamentos                     *
      * - Valida campos basicos do movimento:                         *
      *   . tipo do movimento (C ou D)                                *
      *   . agencia (maior que zero, campo numerico)                  *
      *   . conta (maior que zero, campo numerico)                    *
      *   . valor (maior que zero, campo numerico)                    *
      *   . data (diferente de zero, campo numerico)                  *
      * - Acumula TODOS os erros antes de rejeitar (nao para no 1o)   *
      * - Grava registros validos no arquivo de VALIDOS               *
      * - Grava registros invalidos no arquivo de REJEITOS            *
      * - Ao final exibe resumo e grava totais no arquivo de validos  *
      *                                                               *
      * RETURN-CODE:                                                  *
      *   RC = 0  --> Processamento OK, sem rejeitos                  *
      *   RC = 4  --> Processamento OK com rejeitos ou entrada vazia  *
      *   RC = 8  --> Erro critico de I/O                             *
      *                                                               *
      * REVISOES:                                                     *
      * - IS NUMERIC antes de qualquer comparacao numerica (evita     *
      *   S0C7 com dados sujos em EN-AGENCIA/EN-CONTA/EN-VALOR)       *
      * - Validacao acumula TODOS os erros do registro (nao apenas 1) *
      * - FILE STATUS verificado apos cada operacao I/O               *
      * - Erro fisico de READ tratado (status nao-00/10)              *
      * - RETURN-CODE definido conforme resultado                     *
      * - Contadores ampliados para PIC 9(9)                          *
      * - ON OVERFLOW no STRING de rejeicao                           *
      * - Nivel 88 para EOF e flags                                   *
      * - OPEN e CLOSE unificados                                     *
      * - Linha de totalizacao gravada no arquivo de validos          *
      *===============================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *---------------------------------------------------------------*
      * ENTRADA-IN = arquivo bruto de lancamentos                     *
      *---------------------------------------------------------------*
           SELECT ENTRADA-IN
               ASSIGN TO ENTRADA
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-ENTRADA.

      *---------------------------------------------------------------*
      * VALIDOS-OUT = arquivo com movimentos aprovados                *
      *---------------------------------------------------------------*
           SELECT VALIDOS-OUT
               ASSIGN TO VALIDOS
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-VALIDOS.

      *---------------------------------------------------------------*
      * REJEIT-OUT = arquivo com movimentos rejeitados                *
      *---------------------------------------------------------------*
           SELECT REJEIT-OUT
               ASSIGN TO REJEITOS
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJEITOS.

       DATA DIVISION.
       FILE SECTION.

      *---------------------------------------------------------------*
      * Layout do arquivo de entrada                                  *
      * Lido como raw (PIC X) para proteger contra dado sujo.         *
      * O REDEFINES permite acessar os campos de forma posicional.    *
      * Total: 4+8+8+1+13+30+10+46 = 120 bytes                        *
      *---------------------------------------------------------------*
       FD  ENTRADA-IN
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  ENTRADA-RAW                PIC X(120).

       01  ENTRADA-REG REDEFINES ENTRADA-RAW.
           05 EN-AGENCIA              PIC X(4).
           05 EN-CONTA                PIC X(8).
           05 EN-DATA                 PIC X(8).
           05 EN-TIPO                 PIC X(1).
           05 EN-VALOR                PIC X(13).
           05 EN-HISTORICO            PIC X(30).
           05 EN-CANAL                PIC X(10).
           05 FILLER                  PIC X(46).

      *---------------------------------------------------------------*
      * Arquivo de saida de validos - mesmo layout fisico da entrada  *
      * O rodape de totais sera gravado como registro textual         *
      * identificado por 'T' na primeira posicao.                     *
      *---------------------------------------------------------------*
       FD  VALIDOS-OUT
           RECORD CONTAINS 120 CHARACTERS
           RECORDING MODE IS F.
       01  VALIDOS-RAW                PIC X(120).

       01  VALIDOS-REG REDEFINES VALIDOS-RAW.
           05 VL-AGENCIA              PIC X(4).
           05 VL-CONTA                PIC X(8).
           05 VL-DATA                 PIC X(8).
           05 VL-TIPO                 PIC X(1).
           05 VL-VALOR                PIC X(13).
           05 VL-HISTORICO            PIC X(30).
           05 VL-CANAL                PIC X(10).
           05 FILLER                  PIC X(46).

      *---------------------------------------------------------------*
      * Arquivo de rejeitados com mensagem de erro (150 bytes)        *
      *---------------------------------------------------------------*
       FD  REJEIT-OUT
           RECORD CONTAINS 150 CHARACTERS
           RECORDING MODE IS F.
       01  REJEIT-REG                 PIC X(150).

       WORKING-STORAGE SECTION.

      *---------------------------------------------------------------*
      * File status dos arquivos                                      *
      * '00' = sucesso   '10' = fim de arquivo                        *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-FS-ENTRADA           PIC XX.
              88 FS-ENTRADA-OK        VALUE '00'.
              88 FS-ENTRADA-EOF       VALUE '10'.
           05 WS-FS-VALIDOS           PIC XX.
              88 FS-VALIDOS-OK        VALUE '00'.
           05 WS-FS-REJEITOS          PIC XX.
              88 FS-REJEITOS-OK       VALUE '00'.

      *---------------------------------------------------------------*
      * Controle de fim de arquivo e erros via nivel 88               *
      *---------------------------------------------------------------*
       01  WS-CONTROLES.
           05 WS-EOF-ENTRADA          PIC X VALUE 'N'.
              88 EOF-ENTRADA          VALUE 'S'.
              88 NAO-EOF-ENTRADA      VALUE 'N'.

           05 WS-ERRO-IO              PIC X VALUE 'N'.
              88 OCORREU-ERRO-IO      VALUE 'S'.
              88 NAO-OCORREU-ERRO-IO  VALUE 'N'.

      *---------------------------------------------------------------*
      * Controle de arquivos abertos                                  *
      *---------------------------------------------------------------*
       01  WS-ARQUIVOS.
           05 WS-ENTRADA-ABERTO       PIC X VALUE 'N'.
              88 ENTRADA-ABERTO       VALUE 'S'.
           05 WS-VALIDOS-ABERTO       PIC X VALUE 'N'.
              88 VALIDOS-ABERTO       VALUE 'S'.
           05 WS-REJEITOS-ABERTO      PIC X VALUE 'N'.
              88 REJEITOS-ABERTO      VALUE 'S'.

      *---------------------------------------------------------------*
      * Flag de validacao do registro atual                           *
      * Nao bloqueia as verificacoes seguintes:                       *
      * todos os erros sao acumulados antes de rejeitar               *
      *---------------------------------------------------------------*
       01  WS-FLAGS.
           05 WS-REG-VALIDO           PIC X VALUE 'S'.
              88 REGISTRO-VALIDO      VALUE 'S'.
              88 REGISTRO-INVALIDO    VALUE 'N'.

      *---------------------------------------------------------------*
      * Acumulador de motivos de rejeicao do registro atual           *
      * Permite registrar multiplos erros no mesmo registro           *
      *---------------------------------------------------------------*
       01  WS-MOTIVOS.
           05 WS-MOTIVO-CONCAT        PIC X(100) VALUE SPACES.
           05 WS-MOTIVO-AUX           PIC X(100) VALUE SPACES.
           05 WS-NOVO-MOTIVO          PIC X(25)  VALUE SPACES.

      *---------------------------------------------------------------*
      * Campos numericos de trabalho usados SOMENTE apos IS NUMERIC   *
      *---------------------------------------------------------------*
       01  WS-CAMPOS-NUMERICOS.
           05 WS-AGENCIA-NUM          PIC 9(4) VALUE ZERO.
           05 WS-CONTA-NUM            PIC 9(8) VALUE ZERO.
           05 WS-DATA-NUM             PIC 9(8) VALUE ZERO.
           05 WS-VALOR-NUM            PIC 9(11)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * Contadores de processamento                                   *
      * PIC 9(9) suporta ate 999.999.999 registros                    *
      *---------------------------------------------------------------*
       01  WS-CONTADORES.
           05 WS-LIDOS                PIC 9(9) VALUE ZERO.
           05 WS-VALIDOS              PIC 9(9) VALUE ZERO.
           05 WS-REJEITADOS           PIC 9(9) VALUE ZERO.

      *---------------------------------------------------------------*
      * Campos de edicao para o rodape de totais                      *
      *---------------------------------------------------------------*
       01  WS-EDIT-LIDOS              PIC ZZZ.ZZZ.ZZ9.
       01  WS-EDIT-VALIDOS            PIC ZZZ.ZZZ.ZZ9.
       01  WS-EDIT-REJEIT             PIC ZZZ.ZZZ.ZZ9.

       PROCEDURE DIVISION.
      *===============================================================*
      * FLUXO PRINCIPAL                                               *
      *===============================================================*
       0000-PRINCIPAL.
           PERFORM 1000-ABRIR-ARQUIVOS
           IF NOT OCORREU-ERRO-IO
               PERFORM 2000-PROCESSAR-ENTRADA
               PERFORM 3000-GRAVAR-TOTAIS
           END-IF
           PERFORM 9000-FECHAR-ARQUIVOS
           PERFORM 9100-EXIBIR-RESUMO-E-DEF-RC
           GOBACK.

      *---------------------------------------------------------------*
      * Abre os arquivos de entrada e saida                           *
      * Verifica FILE STATUS apos o OPEN                              *
      *---------------------------------------------------------------*
       1000-ABRIR-ARQUIVOS.
           OPEN INPUT  ENTRADA-IN
                OUTPUT VALIDOS-OUT
                       REJEIT-OUT

           IF FS-ENTRADA-OK
               SET ENTRADA-ABERTO TO TRUE
           ELSE
               DISPLAY '*** ERRO OPEN ENTRADA-IN - STATUS: '
                       WS-FS-ENTRADA
               SET OCORREU-ERRO-IO TO TRUE
           END-IF

           IF FS-VALIDOS-OK
               SET VALIDOS-ABERTO TO TRUE
           ELSE
               DISPLAY '*** ERRO OPEN VALIDOS-OUT - STATUS: '
                       WS-FS-VALIDOS
               SET OCORREU-ERRO-IO TO TRUE
           END-IF

           IF FS-REJEITOS-OK
               SET REJEITOS-ABERTO TO TRUE
           ELSE
               DISPLAY '*** ERRO OPEN REJEIT-OUT - STATUS: '
                       WS-FS-REJEITOS
               SET OCORREU-ERRO-IO TO TRUE
           END-IF.

      *---------------------------------------------------------------*
      * Loop principal de leitura                                     *
      *---------------------------------------------------------------*
       2000-PROCESSAR-ENTRADA.
           PERFORM UNTIL EOF-ENTRADA OR OCORREU-ERRO-IO
               READ ENTRADA-IN
                   AT END
                       SET EOF-ENTRADA TO TRUE
                   NOT AT END
                       IF FS-ENTRADA-OK
                           ADD 1 TO WS-LIDOS
                           PERFORM 2100-VALIDAR-REGISTRO
                           PERFORM 2200-DESTINAR-REGISTRO
                       ELSE
      *                     Erro fisico de leitura (status nao-00/10)
                           DISPLAY '*** ERRO READ ENTRADA-IN STATUS: '
                                   WS-FS-ENTRADA
                           SET OCORREU-ERRO-IO TO TRUE
                           SET EOF-ENTRADA TO TRUE
                       END-IF
               END-READ
           END-PERFORM.

      *---------------------------------------------------------------*
      * Valida o registro lido                                        *
      *                                                               *
      * IMPORTANTE: nao para no primeiro erro.                        *
      * Cada regra e verificada independentemente e os motivos sao    *
      * acumulados em WS-MOTIVO-CONCAT separados por ' | '.           *
      * O registro so e marcado invalido ao final se houver erros.    *
      *                                                               *
      * IS NUMERIC e testado ANTES de qualquer comparacao numerica    *
      * para evitar S0C7 com dados sujos vindos do arquivo.           *
      *---------------------------------------------------------------*
       2100-VALIDAR-REGISTRO.
           SET REGISTRO-VALIDO TO TRUE
           MOVE SPACES TO WS-MOTIVO-CONCAT
                          WS-MOTIVO-AUX

      *    Regra 1: tipo deve ser C (Credito) ou D (Debito)
           IF EN-TIPO NOT = 'C'
              AND EN-TIPO NOT = 'D'
               SET REGISTRO-INVALIDO TO TRUE
               MOVE 'TIPO INVALIDO' TO WS-NOVO-MOTIVO
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

      *    Regra 2: agencia deve ser numerica e maior que zero
           IF EN-AGENCIA IS NUMERIC
               MOVE EN-AGENCIA TO WS-AGENCIA-NUM
               IF WS-AGENCIA-NUM = ZERO
                   SET REGISTRO-INVALIDO TO TRUE
                   MOVE 'AGENCIA INVALIDA' TO WS-NOVO-MOTIVO
                   PERFORM 2300-ACUMULAR-MOTIVO
               END-IF
           ELSE
               SET REGISTRO-INVALIDO TO TRUE
               MOVE 'AGENCIA INVALIDA' TO WS-NOVO-MOTIVO
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

      *    Regra 3: conta deve ser numerica e maior que zero
           IF EN-CONTA IS NUMERIC
               MOVE EN-CONTA TO WS-CONTA-NUM
               IF WS-CONTA-NUM = ZERO
                   SET REGISTRO-INVALIDO TO TRUE
                   MOVE 'CONTA INVALIDA' TO WS-NOVO-MOTIVO
                   PERFORM 2300-ACUMULAR-MOTIVO
               END-IF
           ELSE
               SET REGISTRO-INVALIDO TO TRUE
               MOVE 'CONTA INVALIDA' TO WS-NOVO-MOTIVO
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

      *    Regra 4: valor deve ser numerico e maior que zero
           IF EN-VALOR IS NUMERIC
               MOVE EN-VALOR TO WS-VALOR-NUM
               IF WS-VALOR-NUM <= ZERO
                   SET REGISTRO-INVALIDO TO TRUE
                   MOVE 'VALOR INVALIDO' TO WS-NOVO-MOTIVO
                   PERFORM 2300-ACUMULAR-MOTIVO
               END-IF
           ELSE
               SET REGISTRO-INVALIDO TO TRUE
               MOVE 'VALOR INVALIDO' TO WS-NOVO-MOTIVO
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF

      *    Regra 5: data deve ser numerica e diferente de zero
           IF EN-DATA IS NUMERIC
               MOVE EN-DATA TO WS-DATA-NUM
               IF WS-DATA-NUM = ZERO
                   SET REGISTRO-INVALIDO TO TRUE
                   MOVE 'DATA INVALIDA' TO WS-NOVO-MOTIVO
                   PERFORM 2300-ACUMULAR-MOTIVO
               END-IF
           ELSE
               SET REGISTRO-INVALIDO TO TRUE
               MOVE 'DATA INVALIDA' TO WS-NOVO-MOTIVO
               PERFORM 2300-ACUMULAR-MOTIVO
           END-IF.

      *---------------------------------------------------------------*
      * Acumula o motivo informado em WS-NOVO-MOTIVO                 *
      * Mantem separador ' | ' entre os motivos                       *
      *---------------------------------------------------------------*
       2300-ACUMULAR-MOTIVO.
           MOVE SPACES TO WS-MOTIVO-AUX

           IF FUNCTION TRIM(WS-MOTIVO-CONCAT TRAILING) = SPACES
               STRING FUNCTION TRIM(WS-NOVO-MOTIVO TRAILING)
                      DELIMITED BY SIZE
                      INTO WS-MOTIVO-AUX
                      ON OVERFLOW
                          DISPLAY '*** OVERFLOW ACUMULANDO MOTIVO'
               END-STRING
           ELSE
               STRING FUNCTION TRIM(WS-MOTIVO-CONCAT TRAILING)
                      ' | '
                      FUNCTION TRIM(WS-NOVO-MOTIVO TRAILING)
                      DELIMITED BY SIZE
                      INTO WS-MOTIVO-AUX
                      ON OVERFLOW
                          DISPLAY '*** OVERFLOW ACUMULANDO MOTIVO'
               END-STRING
           END-IF

           MOVE WS-MOTIVO-AUX TO WS-MOTIVO-CONCAT.

      *---------------------------------------------------------------*
      * Direciona o registro para validos ou rejeitados               *
      *---------------------------------------------------------------*
       2200-DESTINAR-REGISTRO.
           IF REGISTRO-VALIDO
               MOVE ENTRADA-RAW TO VALIDOS-RAW
               WRITE VALIDOS-RAW
               IF NOT FS-VALIDOS-OK
                   DISPLAY '*** ERRO WRITE VALIDOS - STATUS: '
                           WS-FS-VALIDOS
                   SET OCORREU-ERRO-IO TO TRUE
               ELSE
                   ADD 1 TO WS-VALIDOS
               END-IF
           ELSE
               MOVE SPACES TO REJEIT-REG
               STRING 'REJEITADO | '
                      FUNCTION TRIM(WS-MOTIVO-CONCAT TRAILING)
                      ' | AG '
                      EN-AGENCIA
                      ' CTA '
                      EN-CONTA
                      ' DATA '
                      EN-DATA
                      ' TIPO '
                      EN-TIPO
                      DELIMITED BY SIZE
                      INTO REJEIT-REG
                      ON OVERFLOW
                          DISPLAY '*** OVERFLOW REJEIT AG:'
                                  EN-AGENCIA ' CTA:' EN-CONTA
               END-STRING

               WRITE REJEIT-REG
               IF NOT FS-REJEITOS-OK
                   DISPLAY '*** ERRO WRITE REJEITOS - STATUS: '
                           WS-FS-REJEITOS
                   SET OCORREU-ERRO-IO TO TRUE
               ELSE
                   ADD 1 TO WS-REJEITADOS
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Grava rodape de totalizacao no arquivo de validos             *
      * O registro e identificado por 'T' na primeira posicao.        *
      *---------------------------------------------------------------*
       3000-GRAVAR-TOTAIS.
           IF NOT OCORREU-ERRO-IO
              AND VALIDOS-ABERTO
               MOVE WS-LIDOS      TO WS-EDIT-LIDOS
               MOVE WS-VALIDOS    TO WS-EDIT-VALIDOS
               MOVE WS-REJEITADOS TO WS-EDIT-REJEIT
               MOVE SPACES TO VALIDOS-RAW
               STRING 'T*** TOTAIS - LIDOS: '
                      WS-EDIT-LIDOS
                      ' VALIDOS: '
                      WS-EDIT-VALIDOS
                      ' REJEITADOS: '
                      WS-EDIT-REJEIT
                      DELIMITED BY SIZE
                      INTO VALIDOS-RAW
               END-STRING
               WRITE VALIDOS-RAW
               IF NOT FS-VALIDOS-OK
                   DISPLAY '*** ERRO WRITE TOTAIS VALIDOS - STATUS: '
                           WS-FS-VALIDOS
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Fecha arquivos e verifica status                              *
      *---------------------------------------------------------------*
       9000-FECHAR-ARQUIVOS.
           IF ENTRADA-ABERTO
               CLOSE ENTRADA-IN
               IF NOT FS-ENTRADA-OK
                   DISPLAY '*** ERRO CLOSE ENTRADA-IN - STATUS: '
                           WS-FS-ENTRADA
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF VALIDOS-ABERTO
               CLOSE VALIDOS-OUT
               IF NOT FS-VALIDOS-OK
                   DISPLAY '*** ERRO CLOSE VALIDOS-OUT - STATUS: '
                           WS-FS-VALIDOS
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF

           IF REJEITOS-ABERTO
               CLOSE REJEIT-OUT
               IF NOT FS-REJEITOS-OK
                   DISPLAY '*** ERRO CLOSE REJEIT-OUT - STATUS: '
                           WS-FS-REJEITOS
                   SET OCORREU-ERRO-IO TO TRUE
               END-IF
           END-IF.

      *---------------------------------------------------------------*
      * Exibe resumo e define RETURN-CODE                             *
      *---------------------------------------------------------------*
       9100-EXIBIR-RESUMO-E-DEF-RC.
      *    Exibe resumo no SYSOUT
           DISPLAY '*** RESUMO VALIDACAO ***'
           DISPLAY 'REGISTROS LIDOS      : ' WS-LIDOS
           DISPLAY 'REGISTROS VALIDOS    : ' WS-VALIDOS
           DISPLAY 'REGISTROS REJEITADOS : ' WS-REJEITADOS

      *    Define RETURN-CODE conforme resultado
           EVALUATE TRUE
               WHEN OCORREU-ERRO-IO
                   MOVE 8 TO RETURN-CODE
               WHEN WS-LIDOS = ZERO
                   DISPLAY '*** ATENCAO: ARQUIVO DE ENTRADA VAZIO'
                   MOVE 4 TO RETURN-CODE
               WHEN WS-REJEITADOS > ZERO
                   MOVE 4 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.
