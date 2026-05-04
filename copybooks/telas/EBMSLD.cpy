      *===============================================================*
      * COPYBOOK: EBMSLD                                              *
      * FUNCAO  : MAPA BMS - TELA DE CONSULTA DE SALDO                *
      * TRANSACAO CICS: ESLD                                          *
      * PROGRAMA ASSOCIADO: EBCSSLD                                   *
      *                                                               *
      * ESTE COPYBOOK SIMULA O LAYOUT GERADO PELO BMS ASSEMBLER       *
      * COM O PADRAO DE REDEFINICAO (I/O COMPARTILHANDO MEMORIA).     *
      *===============================================================*

      *---------------------------------------------------------------*
      * AREA DE ENTRADA (EBMSLDI) - populada por EXEC CICS RECEIVE MAP*
      *---------------------------------------------------------------*
       01  EBMSLDI.
      *-- 12 bytes de controle interno BMS -------------------------*
           05 FILLER                  PIC X(12).

      *-- Campo AGENCIA: agencia da conta (4 digitos) --------------*
           05 AGENCIAL                PIC S9(4) COMP.    *> comprimento
           05 AGENCIAF                PIC X.             *> atributo
           05 FILLER REDEFINES AGENCIAF.
              10 AGENCIAA             PIC X.
           05 AGENCIAI                PIC X(4).          *> dado input

      *-- Campo CONTA: numero de conta (8 digitos) -----------------*
           05 CONTAL                  PIC S9(4) COMP.
           05 CONTAF                  PIC X.
           05 FILLER REDEFINES CONTAF.
              10 CONTAA               PIC X.
           05 CONTAI                  PIC X(8).

      *---------------------------------------------------------------*
      * AREA DE SAIDA (EBMSLDO) - REDEFINES EBMSLDI                   *
      * Os FILLERS de 3 bytes simulam os atributos (Length + Flag)    *
      * que o CICS gera fisicamente para cada campo na tela.          *
      *---------------------------------------------------------------*
       01  EBMSLDO REDEFINES EBMSLDI.
      *-- 12 bytes de controle interno BMS -------------------------*
           05 FILLER                  PIC X(12).

      *-- Eco da agencia e conta consultadas -----------------------*
           05 FILLER                  PIC X(3).
           05 AGENCIAO                PIC X(4).
           05 FILLER                  PIC X(3).
           05 CONTAO                  PIC X(8).

      *-- Tipo de conta: C=Corrente / P=Poupanca / S=Salario -------*
           05 FILLER                  PIC X(3).
           05 TIPOO                   PIC X(1).

      *-- Status da conta: A=Ativa / I=Inativa / B=Bloqueada -------*
           05 FILLER                  PIC X(3).
           05 STATUSO                 PIC X(1).

      *-- Saldo atual editado (ex: '    1.234,56') -----------------*
           05 FILLER                  PIC X(3).
           05 SALDOO                  PIC X(16).

      *-- Limite de credito editado --------------------------------*
           05 FILLER                  PIC X(3).
           05 LIMITEO                 PIC X(16).

      *-- Saldo disponivel = saldo + limite (editado) --------------*
           05 FILLER                  PIC X(3).
           05 DISPON                  PIC X(16).

      *-- Mensagem de retorno ao operador --------------------------*
           05 FILLER                  PIC X(3).
           05 MSGO                    PIC X(50).