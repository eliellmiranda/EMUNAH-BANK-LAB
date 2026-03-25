# Padrões de Publicação — Emunah Bank Lab

## Princípio

O ambiente local é a fonte primária. O mainframe é o destino de
execução. Toda publicação parte do local para o remoto — nunca
o contrário de forma permanente.

---

## Mapeamento Local → Remoto (DEV)

| Pasta local           | Dataset remoto               | Tipo de membro |
|-----------------------|------------------------------|----------------|
| `copybooks/layouts/`  | `Z77948.EMUNAH.DEV.COPY`     | Copybook (.cpy)|
| `cobol/batch/`        | `Z77948.EMUNAH.DEV.COBOL`    | Fonte COBOL    |
| `jcl/compile/`        | `Z77948.EMUNAH.DEV.JCL`      | JCL            |
| `jcl/batch/`          | `Z77948.EMUNAH.DEV.JCL`      | JCL            |
| `rexx/util/`          | `Z77948.EMUNAH.DEV.REXX`     | Script REXX    |
| `data/entrada/`       | `Z77948.EMUNAH.ARQ.ENTRADA.SEQ` | Dataset SEQ |

---

## Promoção entre Ambientes

A promoção de DEV para HML e de HML para PRD deve ser feita
de forma controlada, copiando apenas membros testados e
aprovados.

| Origem              | Destino               | Quando                         |
|---------------------|-----------------------|--------------------------------|
| `DEV.COBOL`         | `HML.COBOL`           | Após testes iniciais em DEV    |
| `DEV.JCL`           | `HML.JCL`             | Junto com a promoção do fonte  |
| `DEV.LOADLIB`       | `HML.LOADLIB`         | Após build aprovado em DEV     |
| `HML.LOADLIB`       | `PRD.LOADLIB`         | Após validação completa em HML |
| `HML.JCL`           | `PRD.JCL`             | Junto com a promoção do load   |

---

## Comando Padrão de Publicação (Zowe CLI)
```bash
# Publicar membro COBOL
zowe files upload file-to-data-set \
  ./cobol/batch/EBPOST01.cbl \
  "Z77948.EMUNAH.DEV.COBOL(EBPOST01)"

# Publicar copybook
zowe files upload file-to-data-set \
  ./copybooks/layouts/CPCONTA.cpy \
  "Z77948.EMUNAH.DEV.COPY(CPCONTA)"

# Publicar arquivo sequencial de entrada
zowe files upload file-to-data-set \
  ./data/entrada/lancamentos.txt \
  "Z77948.EMUNAH.ARQ.ENTRADA.SEQ" --binary
```

---

## Regras

1. **Sempre publicar copybook antes do fonte** — o compilador
   resolve COPY no momento da compilação
2. **Nunca publicar diretamente em PRD** sem passar por HML
3. **Sobrescrita é permitida em DEV** — é ambiente de trabalho
4. **Em HML e PRD, toda publicação deve ser intencional** e
   registrada como evidência
5. **Arquivos de entrada (SEQ) devem ser publicados com
   `--binary` ou `--record-length` adequado** para evitar
   truncamento ou padding incorreto
6. **O nome do membro remoto deve ser idêntico ao nome do
   arquivo local** (sem extensão), mantendo rastreabilidade

---

## Verificação Pós-Publicação

Após publicar, confirme:
```bash
# Listar membros da biblioteca
zowe files list members "Z77948.EMUNAH.DEV.COBOL"

# Verificar conteúdo do membro
zowe files view member "Z77948.EMUNAH.DEV.COBOL(EBPOST01)"
```