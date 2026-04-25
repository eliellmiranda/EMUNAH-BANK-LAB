      *================================================================*
      * COPYBOOK: CPREJ001                                             *
      * FINALIDADE:                                                    *
      *   Layout fisico dos registros em ARQ.REJEITOS.SEQ — cada       *
      *   linha guarda UM registro que foi rejeitado em algum ponto    *
      *   da cadeia batch, junto com os metadados que explicam por     *
      *   que ele foi rejeitado e quando.                              *
      *                                                                *
      * DATASET: Z77948.EMUNAH.ARQ.REJEITOS.SEQ                        *
      * DCB    : RECFM=FB, LRECL=150                                   *
      *                                                                *
      * LAYOUT (150 bytes):                                            *
      *   Posicoes  1-120  = imagem do registro original (LCT-REG)     *
      *   Posicoes  121-124 = codigo do motivo (4 bytes)               *
      *   Posicoes  125-138 = texto livre do motivo (14 bytes)         *
      *   Posicoes  139-146 = timestamp da rejeicao (8 bytes)          *
      *   Posicoes  147-150 = origem: programa que rejeitou (4 bytes)  *
      *                                                                *
      * QUEM GRAVA:                                                    *
      *   EBVALI01 - rejeita na validacao (tipo, agencia, conta,       *
      *              valor invalidos; acentos corrompidos; etc.)       *
      *   EBPOST01 - rejeita na postagem (conta not found no KSDS,     *
      *              regra de negocio falha, KSDS travado).            *
      *   EBREPR01 - le REJIN (este mesmo layout), tenta reprocessar,  *
      *              e regrava os que falharam novamente em REJOUT.    *
      *                                                                *
      * QUEM LE:                                                       *
      *   EBCONC01 - usa na secao S1 (entrada vs validos+rejeitos).    *
      *   EBREPR01 - reprocessamento off-cycle.                        *
      *   EBJHKREJ - arquivamento periodico para BKP.REJEITOS.GDG.     *
      *                                                                *
      * CONVENCAO DE CODIGOS DE MOTIVO (4 bytes, justificados a        *
      * esquerda, padding com espaco a direita):                       *
      *   'TIPO'  - Campo tipo fora de (C, D).                         *
      *   'AGEN'  - Agencia nao numerica ou fora de faixa.             *
      *   'CONT'  - Conta nao existe no ARQ.CONTA.KSDS.                *
      *   'VALR'  - Valor invalido (nao numerico, zero, negativo).     *
      *   'DATA'  - Data do lancamento invalida ou fora de D-0.        *
      *   'TRNC'  - Registro truncado (menos de 120 bytes).            *
      *   'SALD'  - Saldo insuficiente (regra de negocio).             *
      *   'DUPL'  - Lancamento duplicado.                              *
      *   'TRVD'  - KSDS travado / recurso indisponivel.               *
      *                                                                *
      * USO:                                                           *
      *   Incluir na FILE SECTION de qualquer programa que abra        *
      *   REJEITOS-OUT ou REJIN. Os niveis 88 permitem testes          *
      *   legiveis tipo:                                               *
      *     IF REJ-MOTIVO-TIPO    THEN ...                             *
      *     IF REJ-ORIGEM-VALI    THEN ...                             *
      *================================================================*
           05 REJ-REGISTRO-ORIG     PIC X(120).
      *    Imagem do registro que foi rejeitado, exatamente como
      *    chegou na entrada. Permite auditar o conteudo bruto
      *    sem precisar voltar ao ARQ.ENTRADA.SEQ.

           05 REJ-MOTIVO.
              10 REJ-COD-MOTIVO     PIC X(04).
                 88 REJ-MOTIVO-TIPO VALUE 'TIPO'.
                 88 REJ-MOTIVO-AGEN VALUE 'AGEN'.
                 88 REJ-MOTIVO-CONT VALUE 'CONT'.
                 88 REJ-MOTIVO-VALR VALUE 'VALR'.
                 88 REJ-MOTIVO-DATA VALUE 'DATA'.
                 88 REJ-MOTIVO-TRNC VALUE 'TRNC'.
                 88 REJ-MOTIVO-SALD VALUE 'SALD'.
                 88 REJ-MOTIVO-DUPL VALUE 'DUPL'.
                 88 REJ-MOTIVO-TRVD VALUE 'TRVD'.
              10 REJ-TXT-MOTIVO     PIC X(14).
      *       Texto curto e legivel (ex: 'CONTA NOT FND ',
      *       'VALOR INVALIDO', 'TIPO INVALIDO ').

           05 REJ-TIMESTAMP         PIC X(08).
      *    Momento em que o registro foi rejeitado.
      *    Formato sugerido: HHMMSSCC (hora, minuto, segundo,
      *    centesimos). Cada programa grava via ACCEPT FROM TIME.

           05 REJ-ORIGEM            PIC X(04).
              88 REJ-ORIGEM-VALI    VALUE 'VALI'.
              88 REJ-ORIGEM-POST    VALUE 'POST'.
              88 REJ-ORIGEM-REPR    VALUE 'REPR'.
      *    Programa que detectou a rejeicao. Util para rastrear
      *    em que ponto da cadeia o registro caiu e para o
      *    EBREPR01 decidir se tenta reprocessar ou se a rejeicao
      *    e permanente.