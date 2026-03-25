# Mapa de Datasets — Emunah Bank Lab

## Convenção de Nomenclatura

Todos os datasets seguem o padrão:
```
<HLQ>.<PROJETO>.<AMBIENTE>.<TIPO/FUNÇÃO>
```

- **HLQ:** `Z77948` (userid no zXplore)
- **PROJETO:** `EMUNAH`
- **AMBIENTE:** `DEV`, `HML`, `PRD` ou `ARQ` (arquivos de negócio)

---

## Bibliotecas de Desenvolvimento (DEV)

| Dataset                      | Tipo    | Finalidade                              |
|------------------------------|---------|-----------------------------------------|
| `Z77948.EMUNAH.DEV.COBOL`    | PDS/PDSE | Fontes COBOL de desenvolvimento        |
| `Z77948.EMUNAH.DEV.COPY`     | PDS/PDSE | Copybooks e layouts                    |
| `Z77948.EMUNAH.DEV.JCL`      | PDS/PDSE | JCLs de compilação e execução em DEV   |
| `Z77948.EMUNAH.DEV.REXX`     | PDS/PDSE | Scripts REXX e automações              |
| `Z77948.EMUNAH.DEV.LOADLIB`  | PDS/PDSE | Executáveis gerados no build DEV       |

---

## Bibliotecas de Homologação (HML)

| Dataset                      | Tipo    | Finalidade                              |
|------------------------------|---------|-----------------------------------------|
| `Z77948.EMUNAH.HML.COBOL`    | PDS/PDSE | Fontes promovidos de DEV para HML      |
| `Z77948.EMUNAH.HML.JCL`      | PDS/PDSE | JCLs de execução em HML                |
| `Z77948.EMUNAH.HML.LOADLIB`  | PDS/PDSE | Executáveis compilados em HML          |

---

## Bibliotecas de Produção Simulada (PRD)

| Dataset                      | Tipo    | Finalidade                              |
|------------------------------|---------|-----------------------------------------|
| `Z77948.EMUNAH.PRD.JCL`      | PDS/PDSE | JCLs de execução em PRD                |
| `Z77948.EMUNAH.PRD.LOADLIB`  | PDS/PDSE | Executáveis de produção                |
| `Z77948.EMUNAH.PRD.PARMLIB`  | PDS/PDSE | Parâmetros e membros de configuração   |

---

## Arquivos de Seed (Carga Inicial)

| Dataset                           | Tipo | DDNAME     | Finalidade                  |
|-----------------------------------|------|------------|-----------------------------|
| `Z77948.EMUNAH.SEED.CLIENTES.SEQ` | PS   | `CLIENTIN` | Massa inicial de clientes   |
| `Z77948.EMUNAH.SEED.CONTAS.SEQ`   | PS   | `CONTAIN`  | Massa inicial de contas     |

---

## Arquivos de Negócio (ARQ)

| Dataset                            | Tipo      | Org.  | DDNAME    | Finalidade                                     |
|------------------------------------|-----------|-------|-----------|------------------------------------------------|
| `Z77948.EMUNAH.ARQ.CLIENTE.KSDS`   | VSAM      | KSDS  | `CLIENTE` | Cadastro master de clientes                    |
| `Z77948.EMUNAH.ARQ.CONTA.KSDS`     | VSAM      | KSDS  | `CONTA`   | Cadastro master de contas                      |
| `Z77948.EMUNAH.ARQ.SALDO.KSDS`     | VSAM      | KSDS  | `SALDO`   | Saldo consolidado por conta                    |
| `Z77948.EMUNAH.ARQ.LANCTO.ESDS`    | VSAM      | ESDS  | `VALIDOS` | Lançamentos aprovados (append-only)            |
| `Z77948.EMUNAH.ARQ.ENTRADA.SEQ`    | PS        | SEQ   | `ENTRADA` | Arquivo de entrada batch do dia                |
| `Z77948.EMUNAH.ARQ.REJEITO.SEQ`    | PS        | SEQ   | `REJEITO` | Registros rejeitados na validação/aplicação    |
| `Z77948.EMUNAH.ARQ.AUDIT.SEQ`      | PS        | SEQ   | `AUDIT`   | Trilha de auditoria e mensagens de log         |
| `Z77948.EMUNAH.ARQ.EXTRATO.GDG`    | GDG Base  | —     | —         | Base GDG para histórico de extratos            |

---

## Observações

- O arquivo `ARQ.LANCTO.ESDS` usa organização ESDS (sequential
  append-only) por design — representa o histórico imutável de
  movimentos do dia
- `ARQ.EXTRATO.GDG` gera uma nova geração (`G000xV00`) a cada
  execução do job `EBJEXTR`
- Os arquivos KSDS devem ser alocados via IDCAMS antes da
  primeira execução de qualquer job que os utilize
- O prefixo `Z77948` corresponde ao userid do ambiente zXplore
  e deve ser ajustado se o lab migrar para outro ambiente