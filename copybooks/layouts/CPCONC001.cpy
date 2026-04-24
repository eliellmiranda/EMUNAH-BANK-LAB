*===============================================================*
      * COPYBOOK: CPCONC001                                           *
      * FUNCAO  : LAYOUT ESTRUTURADO DO ARQUIVO DE CONCILIACAO        *
      * REGISTRO: 132 BYTES                                           *
      *                                                               *
      * USADO EM: EBCONC01 (CONCILIACAO DE SALDO)                     *
      *           EBJEOD01 (FECHAMENTO DO DIA — leitura do resultado) *
      * DATASET : Z77948.EMUNAH.ARQ.CONCIL.SEQ                        *
      * DDNAME  : CONCOUT (gravacao) / CONCIN (leitura)               *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Padronizar o layout do arquivo de saida da conciliacao      *
      * - Registrar cabecalho, detalhe, rodape e totalizadores        *
      * - Permitir leitura estruturada pelo EBJEOD01 no fechamento    *
      *                                                               *
      * ESTRUTURA DO ARQUIVO (por CC-TIPO-REG):                       *
      *   H11      = Cabecalho do arquivo                             *
      *   D11..D34 = Registros de detalhe (contas conciliadas)        *
      *   R11..R31 = Registros de resumo por agencia/tipo             *
      *   T98      = Totalizador de divergencias                      *
      *   T99      = Totalizador geral / rodape do arquivo            *
      *                                                               *
      * MAPA FISICO DO REGISTRO (132 bytes):                          *
      *   Bytes  1-3  : CC-TIPO-REG  (tipo do registro)               *
      *   Byte   4    : FILLER                                        *
      *   Bytes  5-54 : CC-DESCRICAO (descricao do evento/conta)      *
      *   Byte   55   : FILLER                                        *
      *   Bytes 56-70 : CC-VALOR     (valor formatado com sinal)      *
      *   Bytes 71-75 : FILLER                                        *
      *   Bytes 76-125: CC-STATUS    (resultado da conciliacao)       *
      *   Bytes 126-132: FILLER                                       *
      *===============================================================*

      *---------------------------------------------------------------*
      * Tipo do registro — controla a interpretacao do conteudo       *
      * H11      = Cabecalho: data, job, ambiente                     *
      * D11..D34 = Detalhe: uma linha por conta conciliada            *
      * R11..R31 = Resumo: totais por agencia ou tipo de conta        *
      * T98      = Total de divergencias encontradas                  *
      * T99      = Rodape geral com totalizadores finais              *
      * Preenchimento obrigatorio — nao pode ser branco               *
      *---------------------------------------------------------------*
           05 CC-TIPO-REG              PIC X(03).

           05 FILLER                   PIC X(01).

      *---------------------------------------------------------------*
      * Descricao do evento, conta ou grupo conciliado                *
      * Conteudo varia conforme CC-TIPO-REG:                          *
      * H11: nome do job e data de referencia                         *
      * D11-D34: agencia + conta + nome do titular                    *
      * R11-R31: descricao do grupo (ex: 'AGENCIA 0001 - CORRENTE')   *
      * T98/T99: descricao do totalizador                             *
      *---------------------------------------------------------------*
           05 CC-DESCRICAO             PIC X(50).

           05 FILLER                   PIC X(01).

      *---------------------------------------------------------------*
      * Valor monetario associado ao registro                         *
      * Formato editado com sinal: -Z(10)9,99                         *
      * Permite representar valores negativos (divergencias)          *
      * Nao usar para calculo — apenas para saida formatada           *
      *---------------------------------------------------------------*
           05 CC-VALOR                 PIC -Z(10)9,99.

           05 FILLER                   PIC X(05).

      *---------------------------------------------------------------*
      * Status ou resultado da conciliacao para este registro         *
      * Exemplos de conteudo:                                         *
      * 'OK'            = saldo conferido sem divergencia             *
      * 'DIVERGENCIA'   = saldo calculado difere do snapshot          *
      * 'CONTA INATIVA' = conta nao movimentada no periodo            *
      * 'SEM SNAPSHOT'  = conta sem registro no GDG anterior          *
      *---------------------------------------------------------------*
           05 CC-STATUS                PIC X(50).

      *---------------------------------------------------------------*
      * Reserva para completar o tamanho fisico do registro (132 bytes)*
      * Nao utilizar — reservado para evolucao futura do layout       *
      *---------------------------------------------------------------*
           05 FILLER                   PIC X(07).