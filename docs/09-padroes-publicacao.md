# Padrões de Publicação — Emunah Bank Lab

## Princípio

O ambiente local é a fonte primária do projeto. O mainframe é o destino de build, execução e operação.

Toda publicação deve partir do ambiente local para o ambiente remoto. Alterações permanentes não devem ser mantidas apenas no mainframe.

---

## Mapeamento local → remoto (DEV)

| Pasta local | Dataset remoto | Tipo |
|---|---|---|
| `copybooks/layouts/` | `<HLQ>.EMUNAH.DEV.COPY` | copybook |
| `cobol/batch/` | `<HLQ>.EMUNAH.DEV.COBOL` | fonte COBOL |
| `jcl/compile/` | `<HLQ>.EMUNAH.DEV.JCL` | JCL |
| `jcl/batch/` | `<HLQ>.EMUNAH.DEV.JCL` | JCL |
| `rexx/util/` | `<HLQ>.EMUNAH.DEV.REXX` | script REXX |
| `data/entrada/` | `<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ` | dataset sequencial |

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

# Publicar arquivo sequencial de entrada
zowe files upload file-to-data-set \
  ./data/entrada/lancamentos.txt \
  "<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ" --binary
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
