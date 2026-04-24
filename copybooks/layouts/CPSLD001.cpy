      *===============================================================*
      * COPYBOOK: CPSLD001                                            *
      * FUNCAO  : LAYOUT DE POSICAO DE SALDO / SNAPSHOT               *
      * REGISTRO: 120 BYTES                                           *
      *                                                               *
      * USADO EM: EBSNAP01 (SNAPSHOT DE SALDO), EBCONC01 (CONCILIACAO)*
      *           EBSALD01 (CONSULTA DE SALDO), EBJEOD01 (EOD)        *
      * DATASET : Z77948.EMUNAH.ARQ.SALDO.GDG                         *
      * DDNAME  : SALDOIN / SALDOUT                                   *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Padronizar o registro de posicao de saldo por conta         *
      * - Alimentar o snapshot diario gerado no fechamento do dia     *
      * - Servir como entrada para conciliacao e consulta de saldo    *
      * - Cada execucao do EBJEOD01 gera nova geracao do GDG          *
      *                                                               *
      * NOTA SOBRE O GDG:                                             *
      * O dataset ARQ.SALDO.GDG e versionado por geracao              *
      * GDG(0) = geracao mais recente (saldo do dia atual)            *
      * GDG(-1) = geracao anterior (saldo do dia anterior)            *
      * Usado pelo EBCONC01 para comparar posicoes entre dias         *
      *===============================================================*

      *---------------------------------------------------------------*
      * Agencia da conta — parte da chave de identificacao            *
      * Compativel com CNT-AGENCIA (CPCNT001) e LCT-AGENCIA           *
      *---------------------------------------------------------------*
           05 SLD-AGENCIA             PIC 9(04).

      *---------------------------------------------------------------*
      * Numero da conta — complemento da chave de identificacao       *
      * Combinado com SLD-AGENCIA identifica unicamente a conta       *
      * Compativel com CNT-NUM-CONTA (CPCNT001) e LCT-NUM-CONTA       *
      *---------------------------------------------------------------*
           05 SLD-NUM-CONTA           PIC 9(08).

      *---------------------------------------------------------------*
      * Saldo da conta na data do snapshot                            *
      * Sinalizado para refletir posicao real (pode ser negativo      *
      * quando ha uso de limite/cheque especial)                      *
      * Para calculos internos mover para WS com PIC S9(13)V99 COMP-3 *
      *---------------------------------------------------------------*
           05 SLD-SALDO               PIC S9(11)V99.

      *---------------------------------------------------------------*
      * Data de referencia do snapshot no formato AAAAMMDD            *
      * Preenchida pelo EBJEOD01 no fechamento do dia operacional     *
      * Usada pelo EBCONC01 para validar a geracao correta do GDG     *
      * Ex.: 20240315 = posicao de saldo ao final de 15/03/2024       *
      *---------------------------------------------------------------*
           05 SLD-DATA                PIC 9(08).

      *---------------------------------------------------------------*
      * Reserva para completar o tamanho fisico do registro (120 bytes)*
      * Nao utilizar — reservado para evolucao futura do layout       *
      *---------------------------------------------------------------*
           05 FILLER                  PIC X(87).