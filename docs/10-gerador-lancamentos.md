# [10] - GERADOR DE LANÇAMENTOS - EMUNAH BANK LAB

## Objetivo

O utilitário `automation/geracao/gerar_lancamentos.py` cria arquivos de entrada (massa de dados) compatíveis com o layout de 120 bytes exigido pela cadeia batch do laboratório.

## O que ele gera (Layout CPLCT001)

Cada registro sai estritamente neste formato posicional, totalizando 120 bytes:

- `AGENCIA(4)`   - Numérico
- `CONTA(8)`     - Numérico
- `DATA(8)`      - Formato AAAAMMDD
- `TIPO(1)`      - `C` (Crédito) ou `D` (Débito)
- `VALOR(13)`    - Em centavos, sem separador decimal (ex: 10000 = R$ 100,00)
- `HISTORICO(30)`- Alfanumérico, alinhado à esquerda
- `CANAL(10)`    - Alfanumérico (ex: 'ATM', 'APP', 'AGENCIA')
- `LOTE(6)`      - Numérico
- `NSEQ(6)`      - Numérico (Número Sequencial)
- `STATUS(1)`    - Branco (espaço) para novos lançamentos
- `FILLER(33)`   - Preenchimento com espaços em branco

## Fontes usadas (Seed)

O gerador lê os cadastros existentes na camada local:

- `data/seed/clientes.txt`
- `data/seed/contas.txt`

Assim, quando você filtra por cliente, a saída usa contas reais e válidas já conhecidas pelo lab. Isso é crucial para que os lançamentos gerados passem na regra de negócio **V006 (Existência da Conta no KSDS)** do programa `EBVALI01`.

## Exemplos de Uso

Geração simples:

```bash
python automation/geracao/gerar_lancamentos.py --quantidade 20 --data 20260423 --output data/entrada/lancamentos_teste.txt