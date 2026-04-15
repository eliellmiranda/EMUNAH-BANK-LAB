      *===============================================================*
      * COPYBOOK: EBMEXT                                              *
      * FUNCAO  : MAPA BMS - TELA DE CONSULTA DE EXTRATO             *
      * TRANSACAO: EEXT                                               *
      *                                                               *
      * ESTE COPYBOOK SIMULA O LAYOUT GERADO PELO BMS ASSEMBLER      *
      * PARA USO NOS PROGRAMAS CICS ONLINE DO LABORATORIO             *
      *===============================================================*

      *---------------------------------------------------------------*
      * AREA DE ENTRADA (INPUT) - dados recebidos da tela             *
      *---------------------------------------------------------------*
       01  EBMEXTI.
           05 FILLER                  PIC X(12).
           05 AGENCIAL                PIC S9(4) COMP.
           05 AGENCIAF                PIC X.
           05 FILLER REDEFINES AGENCIAF.
              10 AGENCIAA             PIC X.
           05 AGENCIAI                PIC X(4).
           05 CONTAL                  PIC S9(4) COMP.
           05 CONTAF                  PIC X.
           05 FILLER REDEFINES CONTAF.
              10 CONTAA               PIC X.
           05 CONTAI                  PIC X(8).

      *---------------------------------------------------------------*
      * AREA DE SAIDA (OUTPUT) - dados enviados para a tela           *
      * Inclui 15 linhas de detalhe para movimentos                   *
      *---------------------------------------------------------------*
       01  EBMEXTO.
           05 FILLER                  PIC X(12).
           05 AGENCIAO                PIC X(4).
           05 CONTAO                  PIC X(8).
           05 LINHAS-EXTRATO OCCURS 15 TIMES.
              10 DATAO                PIC X(10).
              10 TIPOO                PIC X(1).
              10 VALORO               PIC X(16).
              10 HISTORICOO           PIC X(30).
              10 CANALO               PIC X(10).
           05 TOTALCREDO              PIC X(16).
           05 TOTALDEBO               PIC X(16).
           05 MSGO                    PIC X(50).
