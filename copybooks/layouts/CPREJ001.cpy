      *===============================================================*
      * GRAVACAO DO REGISTRO DE REJEICAO (EBPOST01)                   *
      *===============================================================*
      * 1. Copia a imagem exata e completa do lancamento (120 bytes)
           MOVE MOVTO-REG           TO REJ-REGISTRO-ORIG
           
      * 2. Preenche os metadados do erro
           MOVE WS-REJ-COD          TO REJ-COD-MOTIVO
           MOVE WS-REJ-DESC         TO REJ-TXT-MOTIVO
           
      * 3. Move o Timestamp unificado (AAAAMMDDHHMMSS)
           MOVE WS-TIMESTAMP        TO REJ-TIMESTAMP
           
      * 4. Define quem rejeitou usando o Nivel 88 do copybook
           SET REJ-ORIGEM-POST      TO TRUE