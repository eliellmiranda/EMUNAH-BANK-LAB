*===============================================================*
      * COPYBOOK: CPSNP001                                            *
      * FUNCAO  : LAYOUT DO SNAPSHOT DIARIO DE SALDO                  *
      * REGISTRO: 120 BYTES                                           *
      *                                                               *
      * USADO EM: EBSNAP01 (GERACAO DO SNAPSHOT),                     *
      *           EBCONC01 (CONCILIACAO — leitura do dia anterior),   *
      *           EBJEOD01 (FECHAMENTO DO DIA)                        *
      * DATASET : Z77948.EMUNAH.ARQ.SALDO.GDG                         *
      * DDNAME  : SALDOIN (leitura) / SALDOUT (gravacao)              *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Registrar a posicao de saldo de cada conta ao fim do dia    *
      * - Alimentar a conciliacao diaria executada pelo EBCONC01      *
      * - Gerar nova geracao do GDG a cada fechamento de dia          *
      *                                                               *
      * RELACAO COM CPSLD001:                                         *
      * CPSNP001 e CPSLD001 tem estrutura identica (mesmos campos,    *
      * mesmo tamanho, mesmo dataset). A distincao e funcional:       *
      * - CPSNP001: usado pelos programas de snapshot e conciliacao   *
      * - CPSLD001: usado pelos programas de consulta e saida de saldo*
      * Manter prefixos separados (SNP- / SLD-) evita conflito de     *
      * nomes quando ambos os copybooks sao incluidos no mesmo fonte  *
      *                                                               *
      * NOTA SOBRE O GDG:                                             *
      * GDG(0)  = geracao mais recente (saldo fechado hoje)           *
      * GDG(-1) = geracao anterior (saldo de ontem)                   *
      * O EBCONC01 le GDG(-1) via SALDOIN e compara com o saldo       *
      * atual do KSDS de contas para detectar divergencias            *
      *===============================================================*

      *---------------------------------------------------------------*
      * Agencia da conta — parte da chave de identificacao            *
      * Compativel com CNT-AGENCIA (CPCNT001) e SLD-AGENCIA           *
      *---------------------------------------------------------------*
           05 SNP-AGENCIA              PIC 9(04).

      *---------------------------------------------------------------*
      * Numero da conta — complemento da chave de identificacao       *
      * Combinado com SNP-AGENCIA identifica unicamente a conta       *
      * Compativel com CNT-NUM-CONTA (CPCNT001) e SLD-NUM-CONTA       *
      *---------------------------------------------------------------*
           05 SNP-NUM-CONTA            PIC 9(08).

      *---------------------------------------------------------------*
      * Saldo da conta no momento do snapshot (fechamento do dia)     *
      * Sinalizado para suportar posicao negativa (uso de limite)     *
      * Lido pelo EBCONC01 como referencia do dia anterior via GDG(-1)*
      * Para calculos internos mover para WS com PIC S9(13)V99 COMP-3 *
      *---------------------------------------------------------------*
           05 SNP-SALDO                PIC S9(11)V99.

      *---------------------------------------------------------------*
      * Data de referencia do snapshot no formato AAAAMMDD            *
      * Preenchida pelo EBSNAP01/EBJEOD01 no fechamento do dia        *
      * Validada pelo EBCONC01 para garantir leitura da geracao certa *
      * Ex.: 20240315 = snapshot gerado ao final de 15/03/2024        *
      *---------------------------------------------------------------*
           05 SNP-DATA                 PIC 9(08).

      *---------------------------------------------------------------*
      * Reserva para completar o tamanho fisico do registro (120 bytes)*
      * Nao utilizar — reservado para evolucao futura do layout       *
      *---------------------------------------------------------------*
           05 FILLER                   PIC X(87).