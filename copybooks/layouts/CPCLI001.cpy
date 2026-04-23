*===============================================================*
      * COPYBOOK: CPCLI001                                            *
      * FUNCAO  : LAYOUT DE REGISTRO DE CLIENTE                       *
      * REGISTRO: 80 BYTES                                            *
      *                                                               *
      * USADO EM: EBCLLOAD (CARGA), EBVALI01 (VALIDACAO),             *
      *           EBPOST01 (POSTAGEM), EBEXTR01 (EXTRATO)             *
      * DATASET : Z77948.EMUNAH.ARQ.CLIENTE.KSDS                      *
      * DDNAME  : CLIENTE                                             *
      *                                                               *
      * FINALIDADE:                                                   *
      * - Padronizar o cadastro de clientes no laboratorio            *
      * - Reutilizar o mesmo layout em arquivo sequencial,            *
      *   KSDS, validacoes e consultas                                *
      * - Evitar repeticao de definicoes em varios programas COBOL    *
      * - Facilitar manutencao e evolucao do modelo de dados          *
      *                                                               *
      * VALORES DE STATUS DO CLIENTE:                                 *
      *   A = Ativo    — operacoes permitidas normalmente             *
      *   I = Inativo  — cliente encerrou relacionamento              *
      *   B = Bloqueado — operacoes suspensas por restricao           *
      *===============================================================*

      *---------------------------------------------------------------*
      * Identificador unico do cliente                                *
      * Campo usado como chave primaria no KSDS de clientes           *
      * Preenchido sequencialmente na carga inicial (EBCLLOAD)        *
      * Referenciado por contas via CNT-ID-CLIENTE                    *
      *---------------------------------------------------------------*
           05 CLI-ID-CLIENTE          PIC 9(05).

      *---------------------------------------------------------------*
      * Nome completo do cliente                                      *
      * Deve ser gravado em maiusculas sem acentos                    *
      * Alinhado a esquerda com brancos a direita                     *
      *---------------------------------------------------------------*
           05 CLI-NOME                PIC X(30).

      *---------------------------------------------------------------*
      * CPF do cliente sem mascara e sem separadores                  *
      * Formato: 11 digitos numericos (ex: 04567891234)               *
      * Validado pelo modulo 11 antes da carga                        *
      *---------------------------------------------------------------*
           05 CLI-CPF                 PIC 9(11).

      *---------------------------------------------------------------*
      * Data de nascimento no formato AAAAMMDD (padrao mainframe)     *
      * Usada para calculo de idade e validacoes cadastrais           *
      * Ex.: 19850315 = 15 de marco de 1985                          *
      *---------------------------------------------------------------*
           05 CLI-DATA-NASC           PIC 9(08).

      *---------------------------------------------------------------*
      * Status do cliente — controla operacoes permitidas             *
      * A = Ativo    I = Inativo    B = Bloqueado                     *
      * Validado antes de qualquer postagem ou movimentacao           *
      * Clientes com status I ou B geram rejeicao no EBVALI01         *
      *---------------------------------------------------------------*
           05 CLI-STATUS              PIC X(01).

      *---------------------------------------------------------------*
      * Data de cadastro do cliente no formato AAAAMMDD               *
      * Preenchida automaticamente na carga via EBCLLOAD              *
      * Usada em relatorios e controles de vigencia                   *
      *---------------------------------------------------------------*
           05 CLI-DATA-CAD            PIC 9(08).

      *---------------------------------------------------------------*
      * Reserva para completar o tamanho fisico do registro (80 bytes)*
      * Nao utilizar — reservado para evolucao futura do layout       *
      *---------------------------------------------------------------*
           05 CLI-FILLER              PIC X(17).