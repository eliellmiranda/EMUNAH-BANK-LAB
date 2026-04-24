      *===============================================================*
      * COPYBOOK: EBMTRF                                              *
      * FUNCAO  : MAPA BMS - TELA DE TRANSFERENCIA ENTRE CONTAS      *
      * TRANSACAO: ETRF                                               *
      *                                                               *
      * ESTE COPYBOOK SIMULA O LAYOUT GERADO PELO BMS ASSEMBLER      *
      * PARA USO NOS PROGRAMAS CICS ONLINE DO LABORATORIO             *
      *===============================================================*

      *---------------------------------------------------------------*
      * AREA DE ENTRADA (INPUT) - dados recebidos da tela             *
      *---------------------------------------------------------------*
       01  EBMTRFI.
           05 FILLER                  PIC X(12).
           05 AGORIGL                 PIC S9(4) COMP.
           05 AGORIGF                 PIC X.
           05 FILLER REDEFINES AGORIGF.
              10 AGORIGA              PIC X.
           05 AGORIGI                 PIC X(4).
           05 CTORIGL                 PIC S9(4) COMP.
           05 CTORIGF                 PIC X.
           05 FILLER REDEFINES CTORIGF.
              10 CTORIGA              PIC X.
           05 CTORIGI              sd   PIC X(8).
           05 AGDESTL                 PIC S9(4) COMP.
           05 AGDESTF                 PIC X.
           05 FILLER REDEFINES AGDESTF.
              10 AGDESTA              PIC X.
           05 AGDESTI                 PIC X(4).
           05 CTDESTL                 PIC S9(4) COMP.
           05 CTDESTF                 PIC X.
           05 FILLER REDEFINES CTDESTF.
              10 CTDESTA              PIC X.
           05 CTDESTI                 PIC X(8).
           05 VALORL                  PIC S9(4) COMP.
           05 VALORF                  PIC X.
           05 FILLER REDEFINES VALORF.
              10 VALORA               PIC X.
           05 VALORI                  PIC X(13).

      *---------------------------------------------------------------*
      * AREA DE SAIDA (OUTPUT) - dados enviados para a tela           *
      *---------------------------------------------------------------*
       01  EBMTRFO.
           05 FILLER                  PIC X(12).
           05 AGORIGO                 PIC X(4).
           05 CTORIGO                 PIC X(8).
           05 AGDESTO                 PIC X(4).
           05 CTDESTO                 PIC X(8).
           05 VALORO                  PIC X(16).
           05 SLDORIGO                PIC X(18).
           05 SLDDESTO                PIC X(18).
           05 MSGO                    PIC X(60).
