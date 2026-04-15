      *===============================================================*
      * COPYBOOK: EBMSLD                                              *
      * FUNCAO  : MAPA BMS - TELA DE CONSULTA DE SALDO               *
      * TRANSACAO: ESLD                                               *
      *                                                               *
      * ESTE COPYBOOK SIMULA O LAYOUT GERADO PELO BMS ASSEMBLER      *
      * PARA USO NOS PROGRAMAS CICS ONLINE DO LABORATORIO             *
      *===============================================================*

      *---------------------------------------------------------------*
      * AREA DE ENTRADA (INPUT) - dados recebidos da tela             *
      *---------------------------------------------------------------*
       01  EBMSLDI.
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
      *---------------------------------------------------------------*
       01  EBMSLDO.
           05 FILLER                  PIC X(12).
           05 AGENCIAO                PIC X(4).
           05 CONTAO                  PIC X(8).
           05 TIPOO                   PIC X(1).
           05 STATUSO                 PIC X(1).
           05 SALDOO                  PIC X(16).
           05 LIMITEO                 PIC X(16).
           05 DISPON                  PIC X(16).
           05 MSGO                    PIC X(50).
