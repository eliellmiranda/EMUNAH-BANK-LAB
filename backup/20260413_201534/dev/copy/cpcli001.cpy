      *===============================================================*
      * COPYBOOK: CPCLI001                                            *
      * FUNCAO  : LAYOUT DE CLIENTE                                   *
      *                                                               *
      * O QUE ESTE COPYBOOK FAZ:                                      *
      * - Define a estrutura padrao de um registro de cliente         *
      * - Permite reutilizar o mesmo layout em arquivo de entrada     *
      *   sequencial, KSDS, validacoes e consultas                    *
      *                                                               *
      * PARA QUE ELE SERVE:                                           *
      * - Padronizar o cadastro de clientes no laboratorio            *
      * - Evitar repeticao de layout em varios programas COBOL        *
      * - Facilitar manutencao e evolucao do modelo de dados          *
      *===============================================================*

      *---------------------------------------------------------------*
      * Identificador unico do cliente                                *
      * Campo usado como chave do cadastro de clientes                *
      *---------------------------------------------------------------*
           05 CLI-ID-CLIENTE         PIC 9(5).

      *---------------------------------------------------------------*
      * Nome do cliente                                               *
      *---------------------------------------------------------------*
           05 CLI-NOME               PIC X(30).

      *---------------------------------------------------------------*
      * CPF do cliente, sem mascara                                  *
      *---------------------------------------------------------------*
           05 CLI-CPF                PIC 9(11).

      *---------------------------------------------------------------*
      * Data de nascimento no formato AAAAMMDD                        *
      *---------------------------------------------------------------*
           05 CLI-DATA-NASC          PIC 9(8).

      *---------------------------------------------------------------*
      * Status do cliente                                             *
      * Exemplos de uso no laboratorio:                               *
      * A = Ativo                                                     *
      * I = Inativo                                                   *
      * B = Bloqueado                                                 *
      *---------------------------------------------------------------*
           05 CLI-STATUS             PIC X(1).

      *---------------------------------------------------------------*
      * Data de cadastro do cliente no formato AAAAMMDD               *
      *---------------------------------------------------------------*
           05 CLI-DATA-CAD           PIC 9(8).

      *---------------------------------------------------------------*
      * Completa o tamanho fisico do registro                         *
      *---------------------------------------------------------------*
           05 CLI-FILLER             PIC X(17).
