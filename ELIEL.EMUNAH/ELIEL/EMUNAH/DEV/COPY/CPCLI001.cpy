      *===============================================================*
      * COPYBOOK: CPCLI001                                            *
      * FUNCAO  : LAYOUT DE REGISTRO DE CLIENTE                       *
      * REGISTRO: 80 BYTES                                            *
      *                                                               *
      * USADO EM: EBCLLOAD (CARGA DE CLIENTES NO KSDS)                *
      * DATASET : ELIEL.EMUNAH.ARQ.CLIENTE.KSDS                       *
      *           ELIEL.EMUNAH.SEED.CLIENTES.SEQ (entrada do seed)    *
      * DDNAME  : CLIENTE / CLIIN                                     *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Define a estrutura padrao de um registro de cliente         *
      * - Permite reutilizar o mesmo layout em arquivo de entrada     *
      *   sequencial (SEED), KSDS de cadastro, validacoes e consultas *
      * - Centraliza o layout de cliente para evitar repeticao em     *
      *   programas COBOL                                             *
      *                                                               *
      * VALORES DE STATUS DO CLIENTE:                                 *
      *   A = Ativo     - cliente ativo, todas operacoes permitidas   *
      *   I = Inativo   - cliente encerrado                           *
      *   B = Bloqueado - cliente com restricao de operacoes          *
      *===============================================================*

      *---------------------------------------------------------------*
      * Identificador unico do cliente - chave do cadastro            *
      * Usado como RECORD KEY no CLIENTE.KSDS                         *
      * Relacionado a CNT-ID-CLIENTE no CPCNT001                      *
      *---------------------------------------------------------------*
           05 CLI-ID-CLIENTE         PIC 9(5).

      *---------------------------------------------------------------*
      * Nome completo do cliente                                      *
      * Padded com espacos a direita ate 30 bytes                     *
      *---------------------------------------------------------------*
           05 CLI-NOME               PIC X(30).

      *---------------------------------------------------------------*
      * CPF do cliente, sem mascara (apenas digitos)                  *
      * Ex.: 12345678901 (sem pontos nem traco)                       *
      *---------------------------------------------------------------*
           05 CLI-CPF                PIC 9(11).

      *---------------------------------------------------------------*
      * Data de nascimento no formato AAAAMMDD                        *
      * Ex.: 19900101 = 01 de janeiro de 1990                         *
      *---------------------------------------------------------------*
           05 CLI-DATA-NASC          PIC 9(8).

      *---------------------------------------------------------------*
      * Status do cliente - controla permissao de operacoes           *
      * A = Ativo     - todas as operacoes permitidas                 *
      * I = Inativo   - cliente encerrado, bloqueado para operacoes   *
      * B = Bloqueado - cliente com restricao temporaria              *
      *---------------------------------------------------------------*
           05 CLI-STATUS             PIC X(1).

      *---------------------------------------------------------------*
      * Data de cadastro do cliente no formato AAAAMMDD               *
      * Preenchida na carga inicial via EBCLLOAD                      *
      * Ex.: 20260312 = 12 de marco de 2026                           *
      *---------------------------------------------------------------*
           05 CLI-DATA-CAD           PIC 9(8).

      *---------------------------------------------------------------*
      * Completa o tamanho fisico do registro (80 bytes)              *
      * Reservado para evolucao futura (telefone, email, endereco)    *
      *---------------------------------------------------------------*
           05 CLI-FILLER             PIC X(17).
