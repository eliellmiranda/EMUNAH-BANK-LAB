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

## 5. Alocar os datasets no mainframe

Execute o JCL de alocação inicial via Zowe:

```powershell
zowe jobs submit local-file "jcl/deploy/EBALLOC.jcl" --wfo
```

Depois popule os dados seed:

```powershell
zowe jobs submit local-file "jcl/batch/EBSEED.jcl" --wfo
```

---

## 6. Carregar os membros nos PDSs

Use o script de upload Zowe para enviar COBOLs, JCLs, copybooks e REXXs:

```powershell
# Submeter a cadeia de upload (lê automation/submit/submit_cadeia.sh)
bash automation/submit/submit_cadeia.sh
```

Ou manualmente via Zowe Explorer no VS Code: arraste os arquivos para o PDS correspondente.

---

## 7. Compilar e link-editar

```powershell
zowe jobs submit local-file "jcl/compile/EBCOMP.jcl" --wfo
zowe jobs submit local-file "jcl/compile/EBLINK.jcl" --wfo
```

Verifique RC=0 em ambos antes de prosseguir.

---

## 8. Executar a cadeia batch diária

A cadeia completa segue esta ordem:

```
EBJLOAD → EBJVALD → EBJPOST → EBJCONC → EBJSNAP → EBJEOD
```

Para submeter via automação:

```powershell
python automation/submit/submit_cadeia.sh
```

Ou use o EBOPS:

```powershell
python ebops/ebops.py dia
```

---

## 9. Validar saídas

```powershell
bash automation/valida/valida_saida.sh
```

Compara `tests/actual/` com `tests/expected/` e reporta divergências.

---

## 10. Configurar o VS Code na sua máquina

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
