# Estudo de Caso — Divergência de LRECL no Arquivo de Lançamentos

## Emunah Bank Lab | Fase 3 — Movimentação Financeira

**Autor:** Eliel  
**Data:** Abril 2026  
**Ambiente:** IBM z/OS (zXplore) · COBOL · JCL · VSAM · Zowe CLI  
**Classificação:** Troubleshooting / Integridade de Dados / Sustentação Batch

---

## 1. Resumo Executivo

Durante a transição da Fase 2 (carga inicial) para a Fase 3 (processamento de lançamentos financeiros) do Emunah Bank Lab, foi identificada uma divergência crítica entre o layout declarado no copybook `CPLCT001` (120 bytes) e o LRECL real do dataset de entrada `<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ` (100 bytes). A divergência, se não tratada, causaria desalinhamento de campos em toda a cadeia batch — da validação (`EBVALI01`) até a conciliação (`EBCONC01`) — com risco de corrupção silenciosa de dados financeiros.

O caso também expôs um segundo problema: a massa de lançamentos referenciava contas inexistentes no VSAM master (`ARQ.CONTA.KSDS`), o que provocaria rejeições em cascata durante a validação.

Ambos os problemas foram resolvidos em um único ciclo de correção, sem necessidade de reprocessamento, por se tratar de ambiente de desenvolvimento.

---

## 2. Contexto Operacional

### 2.1 A cadeia batch do Emunah Bank Lab

O lab simula um ciclo bancário de fim de dia com a seguinte cadeia de processamento:

```
PRECHECK → EBBACKUP → EBJLOAD → EBJVALD → EBJPOST → EBJSALD → EBJEXTR → EBJCONC → EBJEOD
```

O arquivo de entrada (`ARQ.ENTRADA.SEQ`) é o ponto de partida de toda a cadeia. Ele alimenta o programa de validação (`EBVALI01`), que lê cada registro usando o layout do copybook `CPLCT001`. Se o layout do copybook não coincidir com o LRECL do dataset, todos os campos a partir do ponto de divergência ficam deslocados — e o programa interpreta dados errados como se fossem válidos.

### 2.2 Artefatos envolvidos

| Artefato | Tipo | Papel |
|---|---|---|
| `CPLCT001` | Copybook COBOL | Layout do registro de lançamento |
| `ARQ.ENTRADA.SEQ` | Dataset PS (FB) | Arquivo de entrada do dia |
| `lancamentos_d0.txt` | Arquivo texto local | Massa de lançamentos para upload |
| `EBVALI01` | Programa COBOL | Validação de lançamentos |
| `EBPOST01` | Programa COBOL | Postagem de lançamentos |
| `EBSALD01` | Programa COBOL | Consolidação de saldo |
| `EBEXTR01` | Programa COBOL | Geração de extrato |
| `EBCONC01` | Programa COBOL | Conciliação |
| `ARQ.CONTA.KSDS` | VSAM KSDS | Cadastro master de contas |

### 2.3 Programas que referenciam o CPLCT001

Todos os programas abaixo fazem `COPY CPLCT001` e seriam afetados pela divergência:

- `EBVALI01` — validação de layout e regras de negócio
- `EBPOST01` — aplicação de lançamentos no VSAM
- `EBSALD01` — consolidação de saldo por conta
- `EBEXTR01` — geração de extrato diário
- `EBCONC01` — conciliação de totais
- `EBREPR01` — reprocessamento de rejeitos

---

## 3. Problema Identificado

### 3.1 Sintoma

Ao preparar a massa de lançamentos para a Fase 3, foi consultada a definição real do dataset de entrada no mainframe:

```
Data Set Name  : <HLQ>.EMUNAH.ARQ.ENTRADA.SEQ
Record Format  : FB
Logical Record Length : 100
Block Size     : 6200
```

O copybook `CPLCT001`, porém, declarava um registro de **120 bytes**:

| Campo | PIC | Bytes |
|---|---|---|
| LCT-AGENCIA | 9(04) | 4 |
| LCT-NUM-CONTA | 9(08) | 8 |
| LCT-DATA | 9(08) | 8 |
| LCT-TIPO | X(01) | 1 |
| LCT-VALOR | S9(11)V99 | 13 |
| LCT-HISTORICO | X(30) | 30 |
| LCT-CANAL | X(10) | 10 |
| LCT-LOTE | 9(06) | 6 |
| LCT-NSEQ | 9(06) | 6 |
| LCT-STATUS | X(01) | 1 |
| FILLER | X(33) | **33** |
| **Total** | | **120** |

**Divergência: 120 bytes (copybook) vs. 100 bytes (dataset) = 20 bytes de diferença.**

### 3.2 Segundo problema: contas inexistentes

O arquivo `lancamentos_d0.txt` original usava contas como `12345678`, `12345679`, `12340001`, `12340002` e `12340003`. Nenhuma delas existe no VSAM master de contas (`ARQ.CONTA.KSDS`), que contém apenas contas `00000001` a `00000020`, todas na agência `0001`.

---

## 4. Análise de Impacto

### 4.1 Impacto técnico da divergência de LRECL

Em COBOL com RECFM=FB, o sistema z/OS lê exatamente `LRECL` bytes por registro. Se o copybook declara 120 bytes mas o dataset tem registros de 100, ocorre uma de duas situações:

**Cenário A — Arquivo com 120 bytes, dataset com LRECL=100:**
O z/OS lê apenas 100 bytes por registro. Os últimos 20 bytes do copybook (parte do FILLER) ficam com lixo de memória ou dados do próximo registro. Campos como `LCT-STATUS` e `LCT-NSEQ` podem ser lidos corretamente, mas o FILLER fica inconsistente. Em registros subsequentes, o deslocamento acumula.

**Cenário B — Arquivo com 100 bytes, dataset com LRECL=100, copybook com 120:**
O COBOL tenta mover 120 bytes do buffer de leitura para a área de WORKING-STORAGE, mas o buffer só tem 100 bytes. Os últimos 20 bytes ficam com conteúdo indefinido. Dependendo da implementação, pode causar ABEND S0C4 (violação de acesso) ou leitura silenciosa de lixo.

Em ambos os cenários, o resultado é **corrupção silenciosa de dados financeiros** — o tipo mais perigoso de falha em ambiente bancário.

### 4.2 Impacto funcional

| Módulo | Consequência |
|---|---|
| Validação (`EBVALI01`) | Campos desalinhados fazem registros válidos serem rejeitados e registros inválidos passarem |
| Postagem (`EBPOST01`) | Valores e contas errados podem ser aplicados ao VSAM KSDS |
| Saldo (`EBSALD01`) | Consolidação com valores corrompidos gera posição incorreta |
| Extrato (`EBEXTR01`) | Histórico do cliente com dados ilegíveis |
| Conciliação (`EBCONC01`) | Totais não fecham — divergência sistêmica sem causa aparente |

### 4.3 Impacto em auditoria e rastreabilidade

O registro de auditoria (`ARQ.AUDIT.SEQ`) herdaria os dados corrompidos, comprometendo a trilha de rastreabilidade. Em um banco real, isso pode resultar em achados de auditoria interna, exposição regulatória e dificuldade de conciliação contábil.

### 4.4 Impacto das contas inexistentes

Mesmo com LRECL correto, lançamentos referenciando contas que não existem no KSDS seriam rejeitados pelo `EBVALI01` (se a validação de existência da conta estiver implementada) ou causariam `INVALID KEY` no `EBPOST01` durante o READ da conta — ambos impedindo o processamento.

---

## 5. Decisão Técnica

Duas opções foram avaliadas:

| Opção | Ação | Impacto |
|---|---|---|
| **A — Ajustar copybook e arquivo** | Reduzir FILLER de 33 para 13 bytes, gerar arquivo com 100 bytes | Requer recompilação de todos os programas que usam CPLCT001 |
| **B — Realocar o dataset** | Deletar e redefinir `ARQ.ENTRADA.SEQ` com LRECL=120 | Requer IDCAMS DELETE+DEFINE, nenhuma mudança em código |

**Decisão: Opção A** — ajustar copybook e arquivo para 100 bytes.

**Justificativa:** o dataset já estava alocado com LRECL=100 e BLKSIZE=6200. Alterar o dataset significaria realocar com novo BLKSIZE (que precisa ser múltiplo do LRECL), e o FILLER de 33 bytes era excessivo para um layout que já contém todos os campos funcionais necessários. Reduzir para 13 bytes de reserva é suficiente para futuras evoluções do layout.

---

## 6. Correção Aplicada

### 6.1 Copybook CPLCT001 — antes e depois

| Campo | Antes | Depois |
|---|---|---|
| Cabeçalho | `REGISTRO: 120 BYTES` | `REGISTRO: 100 BYTES` |
| FILLER | `PIC X(33)` | `PIC X(13)` |
| Total do registro | 120 bytes | 100 bytes |

Todos os demais campos permanecem inalterados.

### 6.2 Arquivo lancamentos_d0.txt — recriado

O arquivo foi regenerado com:

- **10 registros** de exatamente **100 bytes** cada (FB, sem delimitador)
- Contas válidas: `00000001`, `00000002`, `00000003`, `00000005`, `00000010` — todas na agência `0001`, existentes no KSDS
- Tipos diversificados: crédito (C) e débito (D) para cada conta
- Canais variados: APP, BATCH, RH, INTERNET, PIX, ATM, TED, POS
- Operações representativas: depósito, tarifa, salário, boleto, transferência, saque, TED, compra, aporte, fatura
- Status inicial: P (pendente) — pronto para validação

**Layout do registro gerado (100 bytes):**

```
Pos 01-04  LCT-AGENCIA       9(04)       Ex: 0001
Pos 05-12  LCT-NUM-CONTA     9(08)       Ex: 00000001
Pos 13-20  LCT-DATA          9(08)       Ex: 20260314
Pos 21     LCT-TIPO          X(01)       Ex: C
Pos 22-34  LCT-VALOR         S9(11)V99   Ex: 0000000012500
Pos 35-64  LCT-HISTORICO     X(30)       Ex: DEPOSITO INICIAL
Pos 65-74  LCT-CANAL         X(10)       Ex: APP
Pos 75-80  LCT-LOTE          9(06)       Ex: 000001
Pos 81-86  LCT-NSEQ          9(06)       Ex: 000001
Pos 87     LCT-STATUS        X(01)       Ex: P
Pos 88-100 FILLER            X(13)       Espaços
```

### 6.3 Ações de deploy necessárias

1. Atualizar membro `CPLCT001` em `<HLQ>.EMUNAH.DEV.COPY`
2. Fazer upload do `lancamentos_d0.txt` para `<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ`
3. Recompilar **todos** os programas que referenciam `CPLCT001`:
   - `EBVALI01`, `EBPOST01`, `EBSALD01`, `EBEXTR01`, `EBCONC01`, `EBREPR01`
4. Verificar que os módulos na `LOADLIB` foram atualizados (usar DISPLAY versionado como confirmação)
5. Executar a cadeia a partir de `EBJVALD` para validação end-to-end

---

## 7. Verificação e Evidências

### 7.1 Validação do arquivo gerado

```
Registros gerados: 10
Tamanho por registro: 100 bytes
Contas utilizadas: 00000001, 00000002, 00000003, 00000005, 00000010
Agência: 0001 (todas)
Tipos: 5 créditos (C) + 5 débitos (D)
Status: P (pendente) — todos
Lote: 000001 (único)
Sequenciais: 000001 a 000010
```

### 7.2 Checklist de verificação pós-deploy

- [ ] CPLCT001 atualizado no mainframe com FILLER PIC X(13)
- [ ] lancamentos_d0.txt carregado em ARQ.ENTRADA.SEQ
- [ ] EBVALI01 recompilado e módulo atualizado na LOADLIB
- [ ] EBPOST01 recompilado e módulo atualizado na LOADLIB
- [ ] EBSALD01 recompilado e módulo atualizado na LOADLIB
- [ ] EBEXTR01 recompilado e módulo atualizado na LOADLIB
- [ ] EBCONC01 recompilado e módulo atualizado na LOADLIB
- [ ] EBREPR01 recompilado e módulo atualizado na LOADLIB
- [ ] EBJVALD executado com RC=0000 e sem rejeitos inesperados
- [ ] EBJPOST executado com RC=0000 e lançamentos aplicados
- [ ] Spool revisado para cada job da cadeia

---

## 8. Lições Aprendidas

### 8.1 Sempre validar LRECL antes de gerar massa

O copybook é a **declaração de intenção** do layout. O dataset é a **realidade física**. Se os dois divergem, o dataset vence — e o programa falha. Antes de criar qualquer arquivo de entrada, consultar os atributos reais do dataset no mainframe (via ISPF 3.4, LISTCAT ou Zowe CLI).

### 8.2 Copybook é contrato — mudança exige recompilação

Alterar um copybook compartilhado sem recompilar todos os programas consumidores cria uma janela de inconsistência. O módulo na LOADLIB continua com o layout antigo até que seja explicitamente recompilado. Em ambiente corporativo, isso exige análise de impacto formal e deploy coordenado.

### 8.3 Massa de teste deve usar dados que existem

Criar lançamentos para contas inexistentes é um erro de teste que mascara problemas reais. A massa deve sempre referenciar chaves que existam nos VSAM masters, respeitando a integridade referencial do sistema.

### 8.4 FILLER não é desperdício — é reserva controlada

O campo FILLER em layouts COBOL existe para duas finalidades: alinhamento de registro e reserva para evoluções futuras. Reduzir de 33 para 13 bytes ainda deixa margem para adicionar campos ao layout sem precisar realocar o dataset. Eliminar totalmente o FILLER é arriscado.

### 8.5 Corrupção silenciosa é o pior tipo de falha

Divergências de layout não necessariamente causam ABEND. Em muitos casos, o programa executa com RC=0000 mas processa dados incorretos. Isso é pior que um ABEND S0C7, porque o erro só é descoberto quando o cliente reclama, o saldo está errado, ou a auditoria encontra divergência — potencialmente dias ou semanas depois.

### 8.6 Resolver tudo em um único ciclo de correção

Diagnosticar um problema, corrigir parcialmente, executar, encontrar outro problema, corrigir novamente — esse ciclo iterativo consome tempo e mainframe. A abordagem correta é fazer uma varredura completa antes de qualquer correção: verificar copybook, dataset, massa, contas, JCL e programas em uma única análise, e aplicar todas as correções de uma vez.

---

## 9. Conexão com o Mercado

Este estudo de caso demonstra capacidades que empresas exigem em profissionais mainframe:

| Competência | Como foi demonstrada |
|---|---|
| **Troubleshooting** | Identificação de divergência LRECL antes da execução |
| **Análise de impacto** | Mapeamento de todos os programas e módulos afetados |
| **Integridade de dados** | Validação de massa contra VSAM master existente |
| **Conhecimento de VSAM** | Entendimento de KSDS, chaves, LRECL, RECFM |
| **Copybook management** | Alteração controlada com plano de recompilação |
| **Visão batch** | Rastreamento do impacto ao longo de toda a cadeia |
| **Documentação** | Registro estruturado de problema, decisão e resolução |
| **Sustentação** | Postura preventiva, não reativa |
| **Auditoria e rastreabilidade** | Consciência do impacto em trilha de auditoria |
| **Ferramenta moderna** | Uso de Zowe CLI e scripts Python para geração controlada de massa |

---

## 10. Próximos Passos

1. Aplicar as correções no mainframe (copybook + arquivo + recompilação)
2. Executar a cadeia `EBJVALD → EBJPOST → EBJSALD` e coletar evidências
3. Implementar os JCLs pendentes (`EBJEXTR`, `EBJEOD`) que ainda são placeholders
4. Alocar os datasets sequenciais que faltam para a cadeia completa
5. Criar cenário de teste com lançamento para conta inexistente (rejeição esperada)
6. Documentar o spool de cada job como evidência de portfólio

---

*Emunah Bank Lab — laboratório bancário mainframe para estudo, prática e portfólio profissional.*
