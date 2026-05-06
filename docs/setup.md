# Setup — Reproduzindo o EMUNAH-BANK-LAB do zero

Este guia cobre a configuração completa do lab em uma máquina nova, do clone até a execução da cadeia batch no mainframe e o EBOPS rodando localmente.

---

## Pré-requisitos

| Ferramenta | Versão mínima | Finalidade |
| :--- | :--- | :--- |
| **Git** | 2.40+ | Clonar e versionar o lab |
| **Python** | 3.11+ | Rodar `ebops.py` e `ebops_server.py` |
| **Java (JDK)** | 17+ (AdoptOpenJDK/Temurin) | IBM Z Open Editor, Zowe CLI |
| **Node.js** | 18+ | Zowe CLI |
| **VS Code** | 1.85+ | Editor principal |
| **IBM Z Open Editor** | Última | Suporte a COBOL, JCL, REXX |
| **Zowe CLI** | 7+ | Submeter JCLs e transferir datasets |
| **Zowe Explorer** | Última | Integração visual com mainframe (Extensão VS Code) |

---

## 1. Clonar o repositório

```bash
git clone https://github.com/eliel-miranda-silva/EMUNAH-BANK-LAB.git
cd EMUNAH-BANK-LAB
```

---

## 2. Configurar o ambiente Python (EBOPS)

**Variáveis de ambiente (opcional):**
Configure as variáveis de ambiente necessárias para o seu sistema aqui, como caminhos de rede ou credenciais locais.

**Rodar o EBOPS:**

```bash
python ebops.py
# ou para iniciar o servidor
python ebops_server.py
```

---

## 3. Configurar o Zowe CLI

O lab usa o mainframe da Marist College via zXplore (IBM Z Learning). Verifique a conexão com o seu perfil Zowe configurado:

```bash
zowe zosmf check status
```

---

## 4. Configurar o VS Code

Abra o workspace do lab no VS Code. Instale as extensões recomendadas quando o editor perguntar (IBM Z Open Editor, Zowe Explorer).

> ⚠️ **Atenção:** O arquivo `.vscode/settings.json` contém o path `copybooks.localPath` apontando para `C:\Users\Eliel...`. Se o seu usuário do Windows for diferente, atualize a entrada `zopeneditor.cobol.copybookPaths` com o caminho correto do seu clone local.

---

## Conceitos: Build, Deploy e Carga Inicial

Antes de executar as próximas seções, é fundamental entender três termos que guiam a operação do lab:

- **Build:** Transformar código-fonte em módulo executável. O processo pega o COBOL escrito (ex.: `EBCLLOAD.cbl` no PDS `DEV.COBOL`) e roda dois passos: o compilador (`IGYCRCTL`) traduz para código-objeto, e o link-editor (`IEWBLINK`) junta com bibliotecas externas para gerar o módulo binário. É o que o `EBBUILD` faz para um único programa. Resultado: arquivo executável na `DEV.LOADLIB`.

- **Deploy:** Colocar o sistema em condições de rodar num ambiente. Inclui o build, mas cobre a cadeia inteira: compila vários programas, promove os módulos para a LOADLIB alvo (DEV, HML, PRD), atualiza copybooks e valida a integridade. É o que o `EBDEPLOY` faz — compila os 13 programas COBOL em sequência num único job.

- **Carga inicial (Seed/Load):** Popular datasets vazios com dados de partida. Os datasets alocados pelo `EBALLALL` (como `CLIENTE.KSDS`) têm 0 registros. A carga inicial roda o programa já compilado que lê os sequenciais de seed e escreve no VSAM. É o que o `EBSEED` faz — invoca o `EBCLLOAD` para popular os arquivos.

### Comparativo Rápido

|  | Build | Deploy | Carga inicial |
| :--- | :--- | :--- | :--- |
| **O que processa** | Código-fonte | Código-fonte (vários) | Dados |
| **Entrada** | `.cbl` em `DEV.COBOL` | Múltiplos `.cbl` + copybooks | Seeds em `SEED.*.SEQ` |
| **Saída** | Módulo `.LOAD` em LOADLIB | Vários módulos em LOADLIB | Registros em VSAM |
| **Escopo** | Um módulo | Sistema / conjunto | Dados, não código |
| **Job associado** | `EBBUILD` | `EBDEPLOY` | `EBSEED` |
| **Frequência** | Quando muda 1 programa | Muda copybook ou release | Setup inicial / após reset |

### Ordem Obrigatória no Setup do Zero

A partir da **Etapa 6**, todos os JCLs já vivem no `DEV.JCL` e podem ser submetidos por referência:

```bash
zowe jobs submit data-set "Z77948.EMUNAH.DEV.JCL(EBDEPLOY)"
```

Antes disso, qualquer JCL precisa ser submetido via arquivo local (`local-file`), pois o PDS de destino ainda não existe no host (é o caso do `EBALLALL` na etapa 5).

> **Relação essencial:** A carga inicial só funciona depois do deploy, porque executa um módulo que precisa estar compilado na LOADLIB. Se ocorrerem erros de layout (ex.: VSAM File Status `37`), corrija o copybook → re-builde (`EBBUILD`/`EBDEPLOY`) → rode a carga inicial (`EBSEED`).

---

## 5. Alocar os datasets no mainframe

Esta é a etapa 1 da "Ordem obrigatória". Submeta o JCL de bootstrap via arquivo local (o `DEV.JCL` do host ainda não existe):

```bash
zowe jobs submit local-file "jcl/util/EBALLALL.jcl"
```

O `EBALLALL` cria os **35 datasets** do laboratório: 3 VSAMs, 6 GDG bases, 12 PDS/PDSE e 14 sequenciais.

> **Nota:** O job é idempotente para os VSAMs (`DELETE+DEFINE`), mas não para os PDS/sequenciais. Para recriar tudo do zero, rode o `EBRESET` antes. Verifique no Zowe Explorer se todos os datasets foram criados vazios sob o filtro `Z77948.EMUNAH.*`.

---

## 6. Upload de fontes, copybooks e JCLs

Com os PDSs criados, suba os artefatos versionados no clone local.

| Pasta local | Dataset destino (PDS) |
| :--- | :--- |
| `jcl/batch/`, `jcl/compile/`, `jcl/deploy/`, `jcl/util/` | `Z77948.EMUNAH.DEV.JCL` |
| `cobol/batch/`, `cobol/util/`, `cobol/online/`, `cobol/common/` | `Z77948.EMUNAH.DEV.COBOL` |
| `copybooks/layouts/`, `copybooks/telas/`, `copybooks/db2/` | `Z77948.EMUNAH.DEV.COPY` |
| `rexx/util/`, `rexx/operador/` | `Z77948.EMUNAH.DEV.REXX` |
| `jcl/hml/`, `jcl/prd/` | `Z77948.EMUNAH.HML.JCL` / `PRD.JCL` |

Use seu script de automação para subir tudo, ou faça manualmente via Zowe Explorer (arrastando as pastas para os PDSs). A partir daqui, submeta os JCLs por referência ao dataset.

---

## 7. Deploy: compilar e link-editar programas

Com fontes e copybooks no host, submeta o `EBDEPLOY` para compilar os 13 programas e gravar os executáveis na `DEV.LOADLIB`:

```bash
zowe jobs submit data-set "Z77948.EMUNAH.DEV.JCL(EBDEPLOY)"
```

A LOADLIB ficará populada com módulos como `EBCLLOAD`, `EBVALI01`, `EBPOST01`, etc. Verifique se todos os steps (`CL01` a `CL13`) terminaram com `RC=0` ou `RC=4`. Um `RC >= 8` abortará os steps subsequentes.

---

## 8. Carga inicial dos VSAMs

### 8.1 Upload dos seeds

Suba os arquivos de carga.

> ⚠️ **Importante:** Utilize os arquivos da pasta `data/normalized/` (já com o padding correto e formatados com LF). Arquivos da pasta `raw/` podem causar falhas de layout (LRECL).

### 8.2 Submeter a carga inicial

O `EBSEED` invocará o `EBCLLOAD` para popular `CLIENTE.KSDS` e `CONTA.KSDS`:

```bash
zowe jobs submit data-set "Z77948.EMUNAH.DEV.JCL(EBSEED)"
```

RC esperado: `0`. Se retornar `RC=8` com `FS=37`, o módulo na LOADLIB está incompatível com o cluster. Recompile e tente novamente.

---

## 9. Inicializar controle e abrir o primeiro ciclo

O Start of Day (`EBJSOD`) só roda se o status estiver `CLOSED`. No primeiro uso, isso deve ser inicializado.

### 9.1 Gravar `CLOSED` no CTL.STATUS

O `EBRESET` (em `jcl/util/`) já faz isso. Para rodar a inicialização:

```bash
zowe jobs submit data-set "Z77948.EMUNAH.DEV.JCL(EBRESET)"
```

> Alternativa: usar um `IEBGENER` pontual via arquivo local gravando o literal `CLOSED`.

### 9.2 Abrir o primeiro ciclo

Grava `OPEN` no status e libera a cadeia diária:

```bash
zowe jobs submit data-set "Z77948.EMUNAH.DEV.JCL(EBJSOD)"
```

---

## 10. Executar a cadeia batch diária

Com o ciclo aberto (`CTL.STATUS = OPEN`), você pode processar o movimento do dia. Antes de cada execução, faça o upload do arquivo de movimento para a área de STAGE. Em seguida, submeta a cadeia (via script de automação ou via interface EBOPS).

---

## 11. Validar saídas

Compare os resultados gerados no mainframe baixando-os para a sua pasta `tests/actual/` e confrontando com os arquivos da pasta `tests/expected/` para identificar divergências.

---

## 12. Configurar o VS Code na sua máquina (Troubleshooting Java)

O arquivo `.vscode/settings.json` do repositório contém caminhos do Java específicos da máquina original. Se o VS Code apresentar erros, siga os passos:

1. **Descubra o caminho local do Java:** Localize onde o JDK 17+ está instalado no seu computador.
2. **Abra o `settings.json` do workspace:** Pressione `Ctrl+Shift+P` → digite `Open Workspace Settings JSON` e selecione a opção.
3. **Atualize as entradas:** Altere os caminhos do Java para refletir a sua instalação.
   > Como essas configurações estão no `settingsSync.ignoredSettings`, não serão sobrescritas na sincronização com a nuvem.
4. **Valide os Copybooks:** Abra um arquivo `.cbl` na pasta `cobol/batch/`. Se o IBM Z Open Editor acusar "copybook não encontrado", verifique a chave `zopeneditor.cobol.copybookPaths` e garanta que o caminho base aponta para o diretório correto do seu clone.

---

## Referências

- [IBM Z Learning / zXplore](https://ibmzxplore.influitive.com/)
- [Zowe CLI Docs](https://docs.zowe.org/)
- [IBM Z Open Editor](https://ibm.github.io/zopeneditor-about/)
- Manuais IBM: `docs/ibm/` (JCL Reference, DB2 SQL Reference, REXX Guide)