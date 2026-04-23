# Gerador de Lancamentos

O utilitario `automation/geracao/gerar_lancamentos.py` cria arquivos de entrada compativeis com o layout de 120 bytes usado pelo laboratorio.

## O que ele gera

Cada registro sai neste formato:

- `AGENCIA(4)`
- `CONTA(8)`
- `DATA(8)`
- `TIPO(1)`
- `VALOR(13)` em centavos, sem separador
- `HISTORICO(30)`
- `CANAL(10)`
- `LOTE(6)`
- `NSEQ(6)`
- `STATUS(1)`
- `FILLER(33)`

## Fontes usadas

O gerador le os cadastros existentes em:

- `data/seed/clientes.txt`
- `data/seed/contas.txt`

Assim, quando voce filtra cliente, a saida usa contas reais ja conhecidas pelo lab.

## Exemplos

Geracao simples:

```bash
python automation/geracao/gerar_lancamentos.py --quantidade 20 --data 20260423 --output data/entrada/lancamentos_teste.txt
```

Geracao filtrando clientes e faixa de valor:

```bash
python automation/geracao/gerar_lancamentos.py --quantidade 15 --clientes 1,5,10 --tipos C,D --valor-min 100.00 --valor-max 900.00 --output data/entrada/lancamentos_filtrados.txt
```

Geracao via JSON:

```bash
python automation/geracao/gerar_lancamentos.py --config automation/geracao/exemplo_config.json
```

## Observacoes

- O filtro `clientes` aceita ID ou trecho do nome.
- O programa gera somente contas com status `A`.
- O arquivo de saida fica pronto para ser enviado ao dataset de entrada do laboratorio.
