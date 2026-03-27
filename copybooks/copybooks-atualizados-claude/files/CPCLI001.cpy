      *===============================================================*
      * COPYBOOK: CPCLI001                                            *
      * FUNCAO  : LAYOUT DE CLIENTE                                   *
      * REGISTRO: 80 BYTES                                            *
      *                                                               *
      * USADO EM: EBCLLOAD (CARGA), EBVALI01 (VALIDACAO),             *
      *           EBPOST01 (CONSULTA)                                 *
      * DATASET : Z77948.EMUNAH.ARQ.CLIENTE.KSDS                      *
      * DDNAME  : CLIENTE                                             *
      * CHAVE   : CLI-ID-CLIENTE (POSICAO 1, TAMANHO 5)               *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Padronizar o cadastro de clientes no laboratorio            *
      * - Reutilizar o mesmo layout em arquivo sequencial, KSDS,      *
      *   validacoes e consultas                                      *
      * - Facilitar manutencao e evolucao do modelo de dados          *
      *===============================================================*

      *---------------------------------------------------------------*
      * Identificador unico do cliente                                *
      * Chave primaria do KSDS de clientes                            *
      *---------------------------------------------------------------*
           05 CLI-ID-CLIENTE         PIC 9(05).

      *---------------------------------------------------------------*
      * Nome completo do cliente                                      *
      *---------------------------------------------------------------*
           05 CLI-NOME               PIC X(30).

      *---------------------------------------------------------------*
      * CPF do cliente, sem mascara (11 digitos)                      *
      *---------------------------------------------------------------*
           05 CLI-CPF                PIC 9(11).

      *---------------------------------------------------------------*
      * Data de nascimento no formato AAAAMMDD                        *
      *---------------------------------------------------------------*
           05 CLI-DATA-NASC          PIC 9(08).

      *---------------------------------------------------------------*
      * Status do cliente                                             *
      * A = Ativo   I = Inativo   B = Bloqueado                       *
      *---------------------------------------------------------------*
           05 CLI-STATUS             PIC X(01).

      *---------------------------------------------------------------*
      * Data de cadastro no formato AAAAMMDD                          *
      *---------------------------------------------------------------*
           05 CLI-DATA-CAD           PIC 9(08).

      *---------------------------------------------------------------*
      * Reserva para evolucao do layout                               *
      *---------------------------------------------------------------*
           05 FILLER                 PIC X(17).
