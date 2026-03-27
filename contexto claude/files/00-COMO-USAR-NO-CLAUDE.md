# Como usar este pacote no Claude

Este pacote configura o projeto Emunah Bank Lab no Claude com três eixos:

1. mercado — o que as empresas mais exigem em vagas de aplicações mainframe
2. bancário — como o core bancário funciona na prática
3. mainframe — como o ambiente opera em desenvolvimento, execução, sustentação e evolução

O pacote também incorpora a documentação técnica real do projeto: módulos, datasets, grade batch, runbooks, cenários de incidente, fluxo Zowe e padrões de publicação.

---

## Passo 1 — Custom Instructions

Copie o conteúdo de `01-PROJECT-INSTRUCTIONS.md` para o campo **Custom Instructions** do projeto no Claude.

Este arquivo foi escrito para ser enxuto. Não cole os outros arquivos nesse campo.

---

## Passo 2 — Knowledge / Files

Suba estes arquivos como base de conhecimento do projeto:

- `02-MERCADO-MAINFRAME-APLICADO-AO-LAB.md`
- `03-CORE-BANCARIO-APLICADO-AO-LAB.md`
- `04-MAINFRAME-NA-PRATICA.md`
- `05-MODELO-FUNCIONAL-DO-EMUNAH-LAB.md`
- `06-ROADMAP-DE-IMPLEMENTACAO.md`
- `07-PROMPTS-UTEIS.md`
- `08-CONVENCOES-DE-CODIGO.md`

---

## Passo 3 — Validação rápida

Depois de configurar, envie este prompt de teste:

```
Resuma o que você sabe sobre o Emunah Bank Lab: eixos do projeto, módulos do sistema, grade batch, convenções de nomenclatura e fase atual do roadmap.
```

Se o Claude responder com os três eixos, os módulos reais (cliente, conta, lançamentos, saldo, extrato, conciliação, fechamento, rejeito, reprocessamento), a cadeia batch com os jobs corretos e as convenções, o setup está funcionando.

---

## Estrutura lógica do pacote

| Arquivo | Papel |
|---|---|
| `01-PROJECT-INSTRUCTIONS.md` | Comportamento do Claude: tom, prioridades, estrutura de resposta |
| `02-MERCADO-MAINFRAME-APLICADO-AO-LAB.md` | O que o mercado mais pede e como aplicar no lab |
| `03-CORE-BANCARIO-APLICADO-AO-LAB.md` | Visão funcional do banco e dos fluxos do core |
| `04-MAINFRAME-NA-PRATICA.md` | Visão operacional: desenvolver, executar, manter, evoluir |
| `05-MODELO-FUNCIONAL-DO-EMUNAH-LAB.md` | Módulos, datasets, grade batch, arquitetura e escopo real do lab |
| `06-ROADMAP-DE-IMPLEMENTACAO.md` | Ordem de construção com critérios de conclusão por fase |
| `07-PROMPTS-UTEIS.md` | Prompts prontos com referência ao knowledge do projeto |
| `08-CONVENCOES-DE-CODIGO.md` | Padrões de nomenclatura, código, campos e glossário técnico |

---

## Regra de ouro

Não use este pacote como material acadêmico. Use como base operacional do laboratório.

O objetivo é ajudar o Claude a:
- pensar como um ambiente bancário real
- priorizar o que o mercado pede
- manter coerência com os módulos, datasets e jobs reais do projeto
- manter realismo de fluxo batch, online, dados, auditoria e sustentação
- manter consistência de nomenclatura e padrões de código

---

## Como expandir depois

Crie novos arquivos específicos e curtos conforme o projeto avançar:

- `09-COBOL-FILE-STATUS-E-REJEITOS.md`
- `10-JCL-DD-DISP-RC-SPOOL.md`
- `11-DB2-SQL-PARA-BATCH-E-ONLINE.md`
- `12-CICS-TRANSACOES-E-FLUXOS.md`
- `13-VSAM-KSDS-ESDS-E-CARGA.md`
- `14-RUNBOOKS-DETALHADOS.md`
- `15-PIX-E-PAGAMENTOS-NO-LAB.md`
- `16-ANTI-PADROES-E-ERROS-COMUNS.md`

---

## Dica de manutenção

Prefira:
- arquivos curtos e focados
- nomes claros
- contexto operacional do próprio lab
- referência às convenções do arquivo 08

Evite:
- manuais gigantes sem aplicação no lab
- arquivos repetidos
- nomes ou formatos que contradigam as convenções
