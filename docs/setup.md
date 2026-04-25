# Setup — Reproduzindo o EMUNAH-BANK-LAB do zero

Este guia cobre a configuração completa do lab em uma máquina nova, do clone até a execução da cadeia batch no mainframe e o EBOPS rodando localmente.

---

## Pré-requisitos

| Ferramenta | Versão mínima | Finalidade |
|---|---|---|
| Git | 2.40+ | Clonar e versionar o lab |
| Python | 3.11+ | Rodar ebops.py e ebops_server.py |
| Java (JDK) | 17+ (AdoptOpenJDK/Temurin) | IBM Z Open Editor, Zowe CLI |
| Node.js | 18+ | Zowe CLI |
| VS Code | 1.85+ | Editor principal |
| IBM Z Open Editor | última | Suporte a COBOL, JCL, REXX |
| Zowe CLI | 7+ | Submeter JCLs e transferir datasets |
| Zowe Explorer (VS Code) | última | Integração visual com mainframe |

---

## 1. Clonar o repositório

```powershell
git clone https://github.com/eliel-miranda-silva/EMUNAH-BANK-LAB.git
cd EMUNAH-BANK-LAB
```

---

## 2. Configurar o ambiente Python (EBOPS)

```powershell
# Criar ambiente virtual
python -m venv .venv

# Ativar (Windows PowerShell)
.\.venv\Scripts\Activate.ps1

# Instalar dependências
pip install -r requirements.txt
```

### Variáveis de ambiente (opcional)

```powershell
# Copiar o template
Copy-Item .env.example .env

# Editar .env com seu editor e preencher EMUNAH_ROOT
```

### Rodar o EBOPS

```powershell
# Interface de linha de comando
python ebops/ebops.py

# Servidor web (abre em http://localhost:5000)
python ebops/ebops_server.py
```

---

## 3. Configurar o Zowe CLI

O lab usa o mainframe da **Marist College** via zXplore (IBM Z Learning).

```powershell
# Instalar Zowe CLI globalmente
npm install -g @zowe/cli

# Inicializar perfil interativo
zowe config init

# Preencher quando solicitado:
#   host:     204.90.115.200
#   port:     10443  (z/OSMF)
#   usuário:  seu-usuario-marist
#   senha:    sua-senha-marist
#   rejeitar certificado autoassinado: false
```

Verifique a conexão:

```powershell
zowe zosmf check status
```

---

## 4. Configurar o VS Code

Abra o workspace do lab:

```powershell
code EMUNAH-BANK-LAB.code-workspace
```

Instale as extensões recomendadas quando o VS Code perguntar (IBM Z Open Editor, Zowe Explorer).

> **Atenção:** o arquivo `.vscode/settings.json` contém o path `copybooks.localPath` apontando para `C:\Users\Eliel\...`. Se seu usuário Windows for diferente, atualize a entrada `zopeneditor.cobol.copybookPaths` com o caminho correto do seu clone.

---

## Conceitos: build, deploy e carga inicial

Antes de executar as próximas seções, vale entender três termos que aparecem o tempo todo na operação do lab e são frequentemente confundidos.

**Build** = transformar código-fonte em módulo executável.

Pega o COBOL escrito (ex.: `EBCLLOAD.cbl` no PDS `DEV.COBOL`) e roda dois processos: o **compilador** (IGYCRCTL) traduz COBOL para código-objeto, e o **link-editor** (IEWBLINK) junta esse objeto com bibliotecas externas e gera o módulo binário pronto pra rodar, gravado em `DEV.LOADLIB`. É o que o `EBBUILD` faz para um único programa. Resultado: arquivo executável na LOADLIB.

**Deploy** = colocar o sistema (ou parte dele) em condições de rodar num ambiente.

É um conceito mais amplo que normalmente **inclui o build**, mas cobre a cadeia inteira: compila vários programas de uma vez, promove os módulos para a LOADLIB do ambiente alvo (DEV, HML, PRD), atualiza copybooks correlatos e valida que nada quebrou. É o que o `EBDEPLOY` faz — compila os 13 programas COBOL do laboratório em sequência via `IGYWCL` e grava todos os módulos na `DEV.LOADLIB` num único job.

**Carga inicial** (também chamada de *seed* ou *load*) = popular datasets vazios com dados de partida.

Os datasets foram alocados vazios pelo `EBALLALL`/`EBALLOC` (`CLIENTE.KSDS` existe mas tem 0 registros). A carga inicial roda um programa **já compilado** que lê os arquivos de seed (`SEED.CLIENTES.SEQ`, `SEED.CONTAS.SEQ`) e escreve os registros no VSAM. É o que o `EBSEED` faz — invoca o `EBCLLOAD` (que já está buildado na LOADLIB) pra ler os seeds sequenciais e gravar nos KSDS. Resultado: dados iniciais nos arquivos do laboratório.

### Comparativo rápido

| | Build | Deploy | Carga inicial |
|---|---|---|---|
| **O que processa** | Código-fonte | Código-fonte (vários) | Dados |
| **Entrada** | `.cbl` em `DEV.COBOL` | múltiplos `.cbl` + copybooks | seeds em `SEED.*.SEQ` |
| **Saída** | Módulo `.LOAD` em LOADLIB | Vários módulos em LOADLIB | Registros em VSAM |
| **Escopo** | Um módulo | Sistema / conjunto | Dados, não código |
| **Job** | `EBBUILD` | `EBDEPLOY` | `EBSEED` |
| **Frequência** | Quando muda 1 programa | Quando muda copybook ou release completo | Setup inicial / após reset |

### Ordem obrigatória no setup do zero

```
1. EBALLALL (local-file)  → aloca todos os datasets vazios:
                              PDSs (DEV.JCL, DEV.COBOL, DEV.COPY,
                              DEV.REXX, DEV.LOADLIB...), VSAMs,
                              GDGs e sequenciais. LOADLIB e PDSs
                              de fonte ficam vazios.
2. Upload de fontes       → sobe para DEV.JCL todos os JCLs
                              (jcl/batch, jcl/compile, jcl/deploy,
                              jcl/util...), para DEV.COBOL os
                              fontes COBOL, para DEV.COPY os
                              copybooks e para DEV.REXX os scripts.
3. EBDEPLOY (data-set)    → DEPLOY: compila os 13 programas COBOL
                              e popula a DEV.LOADLIB com os
                              modulos executaveis.
4. Upload de seeds        → sobe SEED.CLIENTES.SEQ, SEED.CONTAS.SEQ
                              e demais arquivos de carga inicial.
5. EBSEED                 → CARGA INICIAL: invoca EBCLLOAD (ja
                              buildado) para popular CLIENTE.KSDS
                              e CONTA.KSDS.
6. Inicializar CTL.STATUS → grava "CLOSED" em ARQ.CTL.STATUS via
                              IEBGENER (pre-condicao do EBJSOD).
7. EBJSOD                 → abre o primeiro ciclo batch
                              (CTL.STATUS = OPEN, sistema "no ar").
```

A partir da etapa 2, todos os JCLs ja vivem no `DEV.JCL` e podem ser submetidos por referencia (`zowe jobs submit data-set "Z77948.EMUNAH.DEV.JCL(EBDEPLOY)"`). Antes da etapa 2, qualquer JCL precisa ser submetido via `local-file` porque o PDS de destino ainda nao existe — e e exatamente esse o caso do `EBALLALL` na etapa 1, que se auto-inicia sem depender de nada no host.

A relação essencial: **a carga inicial só funciona depois do deploy**, porque ela executa um módulo que precisa estar buildado na LOADLIB. Se o `EBCLLOAD` na LOADLIB foi compilado com um copybook desatualizado, o `EBSEED` vai falhar com erros de layout (ex.: VSAM File Status 37 = atributos conflitantes), mesmo que o copybook local esteja correto. Fluxo de correção nesse caso: corrigir copybook → re-buildar (`EBBUILD` ou `EBDEPLOY`) → rodar carga inicial (`EBSEED`).

### Para mudanças incrementais durante o desenvolvimento

- Mudou **um** programa COBOL → **`EBBUILD`** (build pontual)
- Mudou **um copybook** (afeta vários programas) → **`EBDEPLOY`** (deploy completo, recompila tudo que usa o copy)
- Quer **resetar dados** sem mexer em código → **`EBSEED`** (só carga inicial)

---

## 5. Alocar os datasets no mainframe

Esta é a etapa 1 da "Ordem obrigatória" descrita acima. Submeta o JCL de bootstrap **via local-file** (o `DEV.JCL` do host ainda não existe nesse momento, então não dá pra referenciar por dataset):

```powershell
zowe jobs submit local-file "jcl/deploy/EBALLALL.jcl" --wfo
```

O `EBALLALL` cria em um único job os 35 datasets do laboratório: 3 VSAM (CLIENTE.KSDS, CONTA.KSDS, LANCTO.ESDS), 6 GDG bases, 12 PDS/PDSE (DEV.JCL, DEV.COBOL, DEV.COPY, DEV.REXX, DEV.LOADLIB, DEV.MAPLIB, DEV.DCLGEN, HML.\*, PRD.\*) e 14 sequenciais (ARQ.\*, CTL.\*, SEED.\*, STAGE.\*, BAK.\*).

> **Observação:** o `EBALLALL` é idempotente para os VSAMs (faz `DELETE+DEFINE`) mas **não** para os PDS/sequenciais (usa `NEW,CATLG,DELETE` — falha se o dataset já existir). Para recriar tudo do zero, rode `EBRESET` antes.

Verifique no Zowe Explorer que o filtro `Z77948.EMUNAH.*` mostra todos os datasets criados, todos vazios (`used: 0`).

---

## 6. Upload de fontes, copybooks e JCLs para os PDSs

Etapa 2 da Ordem obrigatória. Agora que o `DEV.JCL`, `DEV.COBOL`, `DEV.COPY` e `DEV.REXX` existem vazios, é hora de subir todos os artefatos versionados no clone local. O mapeamento completo está em [`docs/09-padroes-publicacao.md`](09-padroes-publicacao.md), mas a regra geral é:

| Pasta local | Dataset destino |
|---|---|
| `jcl/batch/`, `jcl/compile/`, `jcl/deploy/`, `jcl/util/` | `Z77948.EMUNAH.DEV.JCL` |
| `cobol/batch/`, `cobol/util/`, `cobol/online/`, `cobol/common/` | `Z77948.EMUNAH.DEV.COBOL` |
| `copybooks/layouts/`, `copybooks/telas/`, `copybooks/db2/` | `Z77948.EMUNAH.DEV.COPY` |
| `rexx/util/`, `rexx/operador/` | `Z77948.EMUNAH.DEV.REXX` |
| `jcl/hml/`, `jcl/prd/` | `Z77948.EMUNAH.HML.JCL`, `Z77948.EMUNAH.PRD.JCL` |

Use o script de automação para subir tudo de uma vez:

```powershell
bash automation/submit/submit_cadeia.sh
```

Ou manualmente via Zowe Explorer no VS Code: arraste cada pasta local para o PDS correspondente.

A partir desta etapa, todos os JCLs podem ser submetidos por referência a dataset, sem precisar mais do `local-file`:

```powershell
zowe jobs submit data-set "Z77948.EMUNAH.DEV.JCL(EBDEPLOY)" --wfo
```

---

## 7. Deploy: compilar e link-editar todos os programas

Etapa 3 da Ordem obrigatória. Com os COBOLs e copybooks no host, o `EBDEPLOY` compila os 13 programas em sequência via `IGYWCL` (compilador + link-editor) e grava os módulos executáveis na `DEV.LOADLIB`:

```powershell
zowe jobs submit data-set "Z77948.EMUNAH.DEV.JCL(EBDEPLOY)" --wfo
```

A LOADLIB sai vazia da etapa 5 e fica populada com 13 módulos depois desta etapa: `EBCLLOAD`, `EBVALI01`, `EBPOST01`, `EBACCR01`, `EBSNAP01`, `EBCONC01`, `EBREPR01`, `EBCTL01`, `EBPCHK01`, `EBJEOD01`, `EBEXTR01`, `EBCOMM01`, `EBSALD01`.

> **Para builds pontuais** (recompilar só um programa, ex.: após mudar o `EBCLLOAD`), use o `EBBUILD` em vez do `EBDEPLOY`. Veja a seção conceitual acima sobre quando usar cada um.

Verifique RC=0 ou RC=4 em todos os steps `CL01..CL13` antes de prosseguir. Se algum step retornar RC ≥ 8, o `COND=(4,LT)` aborta os subsequentes para evitar gravar módulos defeituosos na LOADLIB.

---

## 8. Carga inicial dos VSAMs

Etapas 4 e 5 da Ordem obrigatória. Agora que o `EBCLLOAD` está buildado na LOADLIB, sobe os arquivos de seed e roda a carga inicial.

**8.1 Upload dos seeds:**

```powershell
zowe files upload file-to-data-set "data/normalized/clientes.txt" "Z77948.EMUNAH.SEED.CLIENTES.SEQ"
zowe files upload file-to-data-set "data/normalized/contas.txt"   "Z77948.EMUNAH.SEED.CONTAS.SEQ"
```

> **Importante:** use os arquivos de `data/normalized/` (já com padding correto e LF-only). Os arquivos de `data/raw/` podem ter CRLF ou LRECL diferente do esperado e causam falhas no `EBCLLOAD`.

**8.2 Submeter a carga inicial:**

```powershell
zowe jobs submit data-set "Z77948.EMUNAH.DEV.JCL(EBSEED)" --wfo
```

O `EBSEED` invoca o `EBCLLOAD` que lê os seeds sequenciais e popula `CLIENTE.KSDS` e `CONTA.KSDS`. RC esperado: 0. Se vier RC=8 com `FS=37` (VSAM File Status 37), significa que o módulo na LOADLIB tem layout incompatível com o cluster — recompile via `EBBUILD` ou `EBDEPLOY` e tente de novo.

---

## 9. Inicializar controle e abrir o primeiro ciclo

Etapas 6 e 7 da Ordem obrigatória. O `EBJSOD` (Start of Day) só roda se o `ARQ.CTL.STATUS` contiver "CLOSED" — então no primeiro uso do laboratório, esse status precisa ser inicializado.

**9.1 Gravar "CLOSED" no CTL.STATUS:**

O `EBRESET` (em `jcl/util/`) já faz essa inicialização entre outras tarefas de reset. Para o primeiro uso do laboratório, submeta:

```powershell
zowe jobs submit data-set "Z77948.EMUNAH.DEV.JCL(EBRESET)" --wfo
```

Alternativamente, para inicializar **só** o `CTL.STATUS` sem mexer em mais nada, submeta um IEBGENER pontual via `local-file` gravando o literal `CLOSED` em `ARQ.CTL.STATUS` (DISP=OLD).

**9.2 Abrir o primeiro ciclo:**

```powershell
zowe jobs submit data-set "Z77948.EMUNAH.DEV.JCL(EBJSOD)" --wfo
```

O `EBJSOD` grava "OPEN" em `ARQ.CTL.STATUS` e libera a cadeia diária para executar.

---

## 10. Executar a cadeia batch diária

Com o ciclo aberto (`CTL.STATUS = OPEN`), a cadeia diária completa segue esta ordem:

```
EBJSOD   → abre o ciclo (STATUS=OPEN)             [executado na seção 9]
EBJPRECK → valida pré-condições do CTL.STATUS
EBJWAIT  → file-watcher: aguarda STAGE.ENTRADA.SEQ chegar
EBJLOAD  → IEBGENER copia STAGE para ARQ.ENTRADA.SEQ
EBJVALD  → valida lançamentos (gera REJEITOS.SEQ)
EBJPOST  → posta lançamentos no LANCTO.ESDS
EBJACCR  → calcula accruals (juros, encargos)
EBJSNAP  → snapshot de saldos (GDG SALDO.G+1)
EBJCONC  → conciliação três-vias
EBJEXTR  → gera extrato (GDG EXTRATO.G+1)
EBJEOD   → fechamento do dia (STATUS=CLOSED)
```

Antes de cada execução diária, suba o arquivo de movimento do dia para o STAGE:

```powershell
zowe files upload file-to-data-set "data/normalized/lancamentos_simulados.txt" "Z77948.EMUNAH.STAGE.ENTRADA.SEQ"
```

Para submeter a cadeia completa via automação local:

```powershell
bash automation/submit/submit_cadeia.sh
```

Ou via EBOPS (interface unificada):

```powershell
python ebops/ebops.py dia
```

---

## 11. Validar saídas

```powershell
bash automation/valida/valida_saida.sh
```

Compara `tests/actual/` com `tests/expected/` e reporta divergências.

---

## 12. Configurar o VS Code na sua máquina

O arquivo `.vscode/settings.json` versionado no repositório contém paths de Java específicos da máquina original (`C:\Program Files\Java\jdk-21`). Se esses paths não existirem na sua máquina, o VS Code vai reclamar. Siga os passos abaixo para ajustar:

**1. Descubra onde o Java está instalado na sua máquina:**

```powershell
where java
# Exemplo de saída: C:\Program Files\Eclipse Adoptium\jdk-21.0.5.11-hotspot\bin\java.exe
# O JAVA_HOME seria: C:\Program Files\Eclipse Adoptium\jdk-21.0.5.11-hotspot
```

**2. Abra o settings.json do workspace no VS Code:**

`Ctrl+Shift+P` → digite `Open Workspace Settings JSON` → selecione a opção

**3. Atualize as três entradas de Java com o path da sua máquina:**

```json
"zopeneditor.JAVA_HOME": "C:\\SEU\\PATH\\PARA\\JAVA",
"java.jdt.ls.java.home": "C:\\SEU\\PATH\\PARA\\JAVA",
"db2forzosdeveloperextension.java.home": "C:\\SEU\\PATH\\PARA\\JAVA"
```

> Essas configurações estão em `settingsSync.ignoredSettings`, então o VS Code não vai sobrescrever as suas quando sincronizar com outro dispositivo.

**4. Verifique se o IBM Z Open Editor reconhece os copybooks:**

Abra qualquer arquivo `.cbl` em `cobol/batch/`. Se aparecer erro de copybook não encontrado, confirme que o path em `zopeneditor.cobol.copybookPaths` aponta para a pasta correta do seu clone, por exemplo:

```json
"zopeneditor.cobol.copybookPaths": [
    "C:\\Users\\SEU-USUARIO\\EMUNAH-BANK-LAB\\copybooks\\layouts",
    "C:\\Users\\SEU-USUARIO\\EMUNAH-BANK-LAB\\copybooks\\db2",
    "C:\\Users\\SEU-USUARIO\\EMUNAH-BANK-LAB\\copybooks\\telas"
]
```

---

## Referências

- [IBM Z Learning / zXplore](https://www.ibm.com/academic/home)
- [Zowe CLI Docs](https://docs.zowe.org/stable/user-guide/cli-using-usingcli/)
- [IBM Z Open Editor](https://ibm.github.io/zopeneditor-about/)
- Manuais IBM: `docs/ibm/` (JCL Reference, DB2 SQL Reference, REXX Guide)
