# [09] - PADRÕES DE PUBLICAÇÃO - EMUNAH BANK LAB

## Princípio

O ambiente local é a fonte primária do projeto. O mainframe é o destino de build, execução e operação.

Toda publicação deve partir do ambiente local para o ambiente remoto. Alterações permanentes não devem ser mantidas apenas no mainframe.

---

## Mapeamento local → remoto (DEV)

| Pasta local | Dataset remoto | Tipo |
|---|---|---|
| `copybooks/layouts/` | `<HLQ>.EMUNAH.DEV.COPY` | copybook |
| `copybooks/telas/` | `<HLQ>.EMUNAH.DEV.COPY` | mapas de tela |
| `copybooks/db2/` | `<HLQ>.EMUNAH.DEV.COPY` | DCLGEN |
| `cobol/batch/` | `<HLQ>.EMUNAH.DEV.COBOL` | fonte COBOL batch |
| `cobol/util/` | `<HLQ>.EMUNAH.DEV.COBOL` | fonte COBOL utilitário (ex.: `EBSALD01`) |
| `cobol/online/` | `<HLQ>.EMUNAH.DEV.COBOL` | fonte COBOL online (CICS) |
| `cobol/common/` | `<HLQ>.EMUNAH.DEV.COBOL` | rotinas comuns |
| `jcl/compile/` | `<HLQ>.EMUNAH.DEV.JCL` | JCL de build |
| `jcl/batch/` | `<HLQ>.EMUNAH.DEV.JCL` | JCL da cadeia batch |
| `jcl/deploy/` | `<HLQ>.EMUNAH.DEV.JCL` | JCL de alocação e deploy |
| `jcl/util/` | `<HLQ>.EMUNAH.DEV.JCL` | JCL utilitário (`EBLISTDS`, `EBRESET`) |
| `jcl/hml/` | `<HLQ>.EMUNAH.HML.JCL` | JCL de homologação |
| `jcl/prd/` | `<HLQ>.EMUNAH.PRD.JCL` | JCL de produção simulada |
| `rexx/util/` | `<HLQ>.EMUNAH.DEV.REXX` | script REXX utilitário |
| `rexx/operador/` | `<HLQ>.EMUNAH.DEV.REXX` | script REXX de operação |
| `data/normalized/lancamentos_simulados.txt` | `<HLQ>.EMUNAH.STAGE.ENTRADA.SEQ` | massa do dia (entra pelo `EBJWAIT`/`EBJLOAD`) |
| `data/normalized/clientes.txt` | `<HLQ>.EMUNAH.SEED.CLIENTES.SEQ` | seed de clientes |
| `data/normalized/contas.txt` | `<HLQ>.EMUNAH.SEED.CONTAS.SEQ` | seed de contas |

---

## Promoção entre ambientes

A promoção entre ambientes deve ser controlada e intencional.

| Origem | Destino | Momento |
|---|---|---|
| `DEV.COBOL` | `HML.COBOL` | após testes iniciais em DEV |
| `DEV.JCL` | `HML.JCL` | junto com a promoção do fonte |
| `DEV.LOADLIB` | `HML.LOADLIB` | após build aprovado em DEV |
| `HML.LOADLIB` | `PRD.LOADLIB` | após validação completa em HML |
| `HML.JCL` | `PRD.JCL` | junto com a promoção do load |

---

## Comandos padrão com Zowe CLI

```bash
# Publicar membro COBOL
zowe files upload file-to-data-set \
  ./cobol/batch/EBPOST01.cbl \
  "<HLQ>.EMUNAH.DEV.COBOL(EBPOST01)"

# Publicar copybook
zowe files upload file-to-data-set \
  ./copybooks/layouts/CPCONTA.cpy \
  "<HLQ>.EMUNAH.DEV.COPY(CPCONTA)"

# Publicar arquivo sequencial de entrada (entra por STAGE,
# não direto em ARQ — quem promove é o EBJLOAD após o EBJWAIT)
zowe files upload file-to-data-set \
  ./data/normalized/lancamentos_simulados.txt \
  "<HLQ>.EMUNAH.STAGE.ENTRADA.SEQ" --binary
```

---

## Regras de publicação

1. publicar **copybook antes do fonte** sempre que houver dependência de compilação
2. nunca publicar diretamente em **PRD** sem passar por **HML**
3. sobrescrita é aceitável em **DEV**, porque é ambiente de trabalho
4. em **HML** e **PRD**, toda publicação deve ser intencional e registrada como evidência
5. arquivos sequenciais devem ser enviados com cuidado de formato, evitando truncamento ou padding incorreto
6. o nome do membro remoto deve permanecer igual ao nome do arquivo local, preservando rastreabilidade

---

## Verificação pós-publicação

Após publicar, deve-se confirmar a presença do membro e o conteúdo remoto.

```bash
# Listar membros da biblioteca
zowe files list members "<HLQ>.EMUNAH.DEV.COBOL"

# Verificar conteúdo do membro
zowe files view member "<HLQ>.EMUNAH.DEV.COBOL(EBPOST01)"
```

---

## Papel desses padrões no laboratório

Os padrões de publicação reforçam três aspectos centrais do projeto:

- disciplina de promoção entre ambientes
- rastreabilidade entre repositório local e dataset remoto
- redução de erro operacional durante build e execução
