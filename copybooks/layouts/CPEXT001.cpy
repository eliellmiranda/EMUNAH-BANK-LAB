      *----------------------------------------------------------------
      * ARQUIVO      : CPEXT001.cpy
      * CAMINHO LOCAL: copybooks/layouts/CPEXT001.cpy
      * HOST / PDS   : Z77948.EMUNAH.DEV.CPY(CPEXT001)
      *
      * FINALIDADE:
      *   Layout do registro de EXTRATO bancario gerado pela cadeia
      *   batch. Representa uma linha do extrato do cliente (header,
      *   detalhe ou trailer) no formato consumido por downstream
      *   (impressao, entrega eletronica, data-mart de extratos).
      *
      * DATASET ALVO:
      *   Z77948.EMUNAH.ARQ.EXTRATO.GDG(+1)         (sequencial GDG)
      *   Alocado por EBALLOC (gerando base GDG) e escrito a cada
      *   execucao pelo job EBJEXTR -> programa EBEXTR01.
      *
      * DCB:
      *   RECFM=FB  LRECL=132  BLKSIZE=0 (system-determined)
      *
      * QUEM GRAVA : EBEXTR01.cbl   (DD EXTROUT)
      * QUEM LE    : processos downstream (fora do escopo do lab
      *              hoje; placeholder para futuros jobs de entrega).
      *
      * LAYOUT (soma = 132):
      *   TIPO-REG (1) + AGENCIA (4) + CONTA (10) + DATA-MOV (8) +
      *   TIPO-LCTO (2) + COD-HIST (4) + VALOR (13) + SALDO-APOS (13)
      *   + DESCRICAO (40) + TIMESTAMP (14) + ORIGEM (4) + FILLER (19)
      *
      * CONVENCAO:
      *   - TIPO-REG = 'H' cabecalho / 'D' detalhe / 'T' trailer.
      *     Cabecalho e trailer sao opcionais mas reservados aqui
      *     para que EBEXTR01 possa evoluir sem mudar o layout.
      *   - DATA-MOV em AAAAMMDD, string (PIC X) para facilitar
      *     comparacao lexicografica com PROCDATE.
      *   - VALOR e SALDO-APOS em PIC S9(11)V99 DISPLAY (sinal
      *     zonado na ultima posicao). Escolha didatica: permanece
      *     legivel em dump / HEX sem precisar decodificar COMP-3.
      *   - TIPO-LCTO: 'CR' credito, 'DB' debito, 'SI' saldo inicial,
      *     'SF' saldo final. SI/SF aparecem em linhas de resumo.
      *   - ORIGEM: 'POST' (vindo de EBPOST01), 'ACCR' (juros),
      *     'SNAP' (ajuste de saldo), 'MANU' (lancamento manual
      *     futuro). Ajuda auditoria a rastrear de onde veio.
      *   - TIMESTAMP: AAAAMMDDHHMMSS, preenchido no momento da
      *     gravacao pelo programa (ACCEPT FROM DATE/TIME).
      *
      * USO:
      *   EBEXTR01 varre MOVTIN (movimentos postados do dia) e
      *   produz um registro detalhe por lancamento. Opcionalmente
      *   emite linhas SI/SF usando o VSAM CONTA (saldo antes/apos)
      *   quando disponivel.
      *
      * HISTORICO:
      *   2026-04  Criacao com 132 bytes. Layout unificado para
      *            substituir a versao embutida que existia solta
      *            no EBEXTR01.cbl.
      *----------------------------------------------------------------

       01  REG-EXTRATO.
           05  EXT-TIPO-REG          PIC X(01).
               88  EXT-E-HEADER           VALUE 'H'.
               88  EXT-E-DETALHE          VALUE 'D'.
               88  EXT-E-TRAILER          VALUE 'T'.
               88  EXT-TIPO-REG-VALIDO    VALUES 'H' 'D' 'T'.

           05  EXT-AGENCIA           PIC X(04).
           05  EXT-CONTA             PIC X(10).

           05  EXT-DATA-MOV          PIC X(08).
      *        Formato AAAAMMDD. Em registros H/T pode ser a data
      *        de referencia do extrato (PROCDATE daquela execucao).

           05  EXT-TIPO-LCTO         PIC X(02).
               88  EXT-E-CREDITO          VALUE 'CR'.
               88  EXT-E-DEBITO           VALUE 'DB'.
               88  EXT-E-SALDO-INIC       VALUE 'SI'.
               88  EXT-E-SALDO-FINAL      VALUE 'SF'.
               88  EXT-TIPO-LCTO-VALIDO   VALUES 'CR' 'DB' 'SI' 'SF'.

           05  EXT-COD-HIST          PIC X(04).
      *        Codigo de historico / natureza contabil. Ex: 'TRF1'
      *        (transferencia), 'DEP1' (deposito), 'ACCR' (juros
      *        provisionados), 'AJST' (ajuste manual). Texto livre
      *        controlado por tabela futura (PARM.HISTORICO).

           05  EXT-VALOR             PIC S9(11)V99 SIGN LEADING.
      *        Valor do lancamento. Em SI/SF carrega o saldo da
      *        conta (e EXT-SALDO-APOS repete o mesmo valor).

           05  EXT-SALDO-APOS        PIC S9(11)V99 SIGN LEADING.
      *        Saldo da conta APOS aplicacao do lancamento. Permite
      *        que o extrato seja lido linearmente sem recalculo.

           05  EXT-DESCRICAO         PIC X(40).
      *        Descricao humana do lancamento. Pode citar origem
      *        (ex: 'DEPOSITO EM AGENCIA 0001 CAIXA 02').

           05  EXT-TIMESTAMP         PIC X(14).
      *        AAAAMMDDHHMMSS. Util para ordenar dois lancamentos
      *        do mesmo dia por ordem cronologica de processamento.

           05  EXT-ORIGEM            PIC X(04).
               88  EXT-ORG-POST           VALUE 'POST'.
               88  EXT-ORG-ACCR           VALUE 'ACCR'.
               88  EXT-ORG-SNAP           VALUE 'SNAP'.
               88  EXT-ORG-MANU           VALUE 'MANU'.
               88  EXT-ORIGEM-VALIDA      VALUES 'POST' 'ACCR'
                                                  'SNAP' 'MANU'.

           05  EXT-FILLER            PIC X(19).
      *        Reserva para evolucao (ex: codigo de canal, id de
      *        sessao, checksum). Sempre preencher com SPACES.