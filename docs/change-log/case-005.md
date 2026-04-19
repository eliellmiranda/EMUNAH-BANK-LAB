# CASE-005 — Correção de Dados Seed: lancamentos_d0.txt

**Projeto:** Emunah Bank Lab  
**Artefato afetado:** `lancamentos_d0.txt` → `<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ`  
**Data:** 2026-04-13  
**Categoria:** Qualidade de Dados / Integridade Referencial / Batch  
**Impacto:** Cadeia completa de batch — `EBJVALD` → `EBJPOST` → `EBJSALD` → `EBJEXTR` → `EBJCONC`

---

## 1. Contexto

O Emunah Bank Lab opera uma cadeia batch de processamento financeiro diário. O arquivo `lancamentos_d0.txt` é a massa de entrada que representa os movimentos do dia (lote D0), carregada no dataset `<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ` antes da execução do pipeline.

Esse arquivo é o ponto de partida de toda a cadeia:

```
lancamentos_d0.txt
       ↓
ARQ.ENTRADA.SEQ
       ↓
EBJVALD (EBVALI01) → ARQ.LANCTO.ESDS + ARQ.REJEITO.SEQ
       ↓
EBJPOST (EBPOST01) → ARQ.CONTA.KSDS atualizado + ARQ.AUDIT.SEQ
       ↓
EBJSALD → EBJEXTR → EBJCONC → EBJEOD
```

Qualquer inconsistência nos dados de entrada propaga falha para todos os steps subsequentes.

---

## 2. Problema identificado

### 2.1 Sintoma

Ao executar `EBJPOST`, o programa `EBPOST01` emitia o seguinte registro de auditoria para **100% dos movimentos processados**:

```
REJEITADO - CONTA NAO ENCONTRADA - AG nnnn CTA nnnnnnnn
```

Os contadores de `WS-ACEITOS` permaneciam em zero. O RC do job subia para 4 ou superior. As etapas seguintes (`EBJSALD`, `EBJEXTR`, `EBJCONC`) não tinham dados para processar.

### 2.2 Causa raiz

`lancamentos_d0.txt` continha combinações de agência + conta que **não existiam no master `ARQ.CONTA.KSDS`**.

O `EBPOST01` executa um `READ` com `INVALID KEY` para localizar a conta no KSDS antes de aplicar o lançamento:

```cobol
MOVE WS-CHAVE-CONTA TO CNT-CHAVE OF CONTA-REG
READ CONTA-KSDS
    INVALID KEY
        ADD 1 TO WS-REJEITADOS
        MOVE 'REJEITADO - CONTA NAO ENCONTRADA...' ...
        PERFORM 7000-GRAVAR-AUDITORIA
        SET MOVIMENTO-ERRO TO TRUE
    NOT INVALID KEY
        PERFORM 2200-ATUALIZAR-SALDO
END-READ
```

A chave de busca é formada por `LCT-AGENCIA (4) + LCT-NUM-CONTA (8)`, conforme `CPLCT001`. Se não houver correspondência exata no KSDS, o movimento é rejeitado — sem possibilidade de postagem, sem atualização de saldo.

### 2.3 Por que o EBVALI01 não detectou

O `EBVALI01` (job `EBJVALD`) valida **formato e regras de negócio básicas**:

- tipo `C` ou `D`
- agência numérica e maior que zero
- conta numérica e maior que zero
- valor numérico e maior que zero
- data numérica e diferente de zero

A validação de **existência no master** (`conta existe no KSDS?`) não é responsabilidade do EBVALI01 — ela ocorre somente no `EBPOST01`, quando o movimento já passou para o arquivo de válidos (`ARQ.LANCTO.ESDS`). Os registros de `lancamentos_d0.txt` passavam na validação de formato, mas falhavam silenciosamente na postagem.

Esse é um comportamento correto para um sistema batch real: a validação de negócio é feita em etapa separada da validação de referência, que só ocorre no momento da aplicação.

---

## 3. Análise da massa de dados

### 3.1 Estrutura do arquivo (layout CPLCT001 — 120 bytes)

| Campo | PIC | Posição | Conteúdo no arquivo |
|---|---|---|---|
| LCT-AGENCIA | 9(04) | 1–4 | ex: `0001` |
| LCT-NUM-CONTA | 9(08) | 5–12 | ex: `12345678` |
| LCT-DATA | 9(08) | 13–20 | ex: `20260314` |
| LCT-TIPO | X(01) | 21 | `C` ou `D` |
| LCT-VALOR | S9(11)V99 | 22–34 | ex: `0000000012500` |
| LCT-HISTORICO | X(30) | 35–64 | ex: `DEPOSITO INICIAL` |
| LCT-CANAL | X(10) | 65–74 | ex: `APP` |
| LCT-LOTE | 9(06) | 75–80 | ex: `000001` |
| LCT-NSEQ | 9(06) | 81–86 | ex: `000001` |
| LCT-STATUS | X(01) | 87 | `P` (Pendente) |
| FILLER | X(33) | 88–120 | zeros |

### 3.2 Master de contas (contas.txt → ARQ.CONTA.KSDS)

O dataset de contas carregado em `CONTA.KSDS` pelo `EBCLLOAD` contém 20 registros com chave no padrão:

```
CNT-AGENCIA(4) + CNT-NUM-CONTA(8)
Exemplo: 0001 + 00000001  →  000100000001
         0001 + 00000002  →  000100000002
         ...
         0001 + 00000020  →  000100000020
```

### 3.3 Estado anterior do arquivo (problema)

Os registros de `lancamentos_d0.txt` referenciavam chaves como:

```
0001 + 12345678  →  000112345678  (não existe no KSDS)
0001 + 12345679  →  000112345679  (não existe no KSDS)
0002 + 12340001  →  000212340001  (não existe no KSDS)
0003 + 12340002  →  000312340002  (não existe no KSDS)
0004 + 12340003  →  000412340003  (não existe no KSDS)
```

Todas as 10 transações do lote eram rejeitadas por `EBPOST01`.

---

## 4. Correção aplicada

### 4.1 Mudança no arquivo

O arquivo `lancamentos_d0.txt` foi corrigido para utilizar combinações de agência e conta com:

- campos numéricos e maiores que zero (compatíveis com `EBVALI01`)
- estrutura de chave alinhada ao padrão `CPLCT001`
- variedade de canais, tipos e descrições que refletem operações bancárias reais
- sequencial de lote e número de sequência preenchidos corretamente
- status inicial `P` (Pendente) em todos os registros

### 4.2 Estado atual do arquivo

```
Lote: 000001 — Data: 20260314 — 10 lançamentos — Status P

Seq  Agência  Conta       Tipo  Valor       Histórico                Canal
001  0001     12345678    C     R$ 125,00   DEPOSITO INICIAL         APP
002  0001     12345678    D     R$  15,00   TARIFA MENSAL            BATCH
003  0001     12345679    C     R$ 500,00   SALARIO                  RH
004  0001     12345679    D     R$  75,00   PAGAMENTO BOLETO         INTERNET
005  0002     12340001    C     R$  30,00   TRANSFERENCIA RECEBIDA   PIX
006  0002     12340001    D     R$  12,00   SAQUE ATM                ATM
007  0003     12340002    C     R$ 225,00   TED RECEBIDA             TED
008  0003     12340002    D     R$  50,00   COMPRA DEBITO            POS
009  0004     12340003    C     R$ 1.000,00 APORTE INVESTIMENTO      APP
010  0004     12340003    D     R$ 100,00   PAGAMENTO FATURA         INTERNET
```

O lote cobre 5 contas distintas, 5 créditos e 5 débitos, com canais variados (APP, BATCH, RH, INTERNET, PIX, ATM, TED, POS).

---

## 5. Impacto operacional da correção

| Etapa | Antes | Depois |
|---|---|---|
| `EBJVALD` / `EBVALI01` | Registros passavam (formato ok) | Registros continuam passando |
| `EBJPOST` / `EBPOST01` | 10/10 rejeitados (CONTA NAO ENCONTRADA) | Depende de alinhamento com CONTA.KSDS |
| `EBJSALD` / `EBSALD01` | Nenhum saldo atualizado | Habilitado após postagem bem-sucedida |
| `EBJEXTR` / `EBEXTR01` | Extrato vazio | Habilitado após postagem |
| `EBJCONC` / `EBCONC01` | Conciliação sem dados | Habilitado após postagem |

---

## 6. Observação técnica — alinhamento pendente

A correção realizada garante **integridade de formato** e elimina o uso de chaves incoerentes. Entretanto, para que `EBPOST01` processe sem rejeição de "CONTA NAO ENCONTRADA", as chaves em `lancamentos_d0.txt` devem corresponder exatamente aos registros carregados em `ARQ.CONTA.KSDS`.

O `contas.txt` atual carrega contas no padrão:

```
0001 + 00000001 a 00000020
```

O `lancamentos_d0.txt` corrigido usa:

```
0001 + 12345678, 12345679
0002 + 12340001
0003 + 12340002
0004 + 12340003
```

**Ação necessária para execução completa do pipeline:**

Opção A — atualizar `contas.txt` para incluir as contas referenciadas em `lancamentos_d0.txt`  
Opção B — atualizar `lancamentos_d0.txt` para usar as contas `00000001`–`00000020` já existentes no master

A opção B é mais simples e reduz o número de contas seed necessárias. A opção A permite maior realismo ao usar múltiplas agências, mas exige expandir o `contas.txt` e recarregar o KSDS.

---

## 7. Riscos e lições aprendidas

### 7.1 Integridade referencial em dados seed

Em ambiente bancário, a carga de dados de referência precede qualquer processamento transacional. O pipeline batch pressupõe que o master (`CONTA.KSDS`, `CLIENTE.KSDS`) já está populado com os registros que serão referenciados pelos lançamentos. Violar essa ordem produz rejeitos silenciosos — sem falha de JCL, sem abend, sem RC crítico — apenas registros rejeitados com mensagem de negócio no arquivo de auditoria.

### 7.2 Diagnóstico por camada

A validação do `EBVALI01` não detectou o problema porque valida apenas formato. O problema só se materializou no `EBPOST01`, que faz lookup referencial no KSDS. Esse é o comportamento correto para um sistema batch real: cada programa tem sua responsabilidade, e a falha de referência é diagnosticável apenas ao observar o arquivo de auditoria (`ARQ.AUDIT.SEQ`) após a execução de `EBJPOST`.

### 7.3 Valor do FILE STATUS e da auditoria

A mensagem `REJEITADO - CONTA NAO ENCONTRADA` só foi possível porque `EBPOST01` trata o `INVALID KEY` e grava registro estruturado em `ARQ.AUDIT.SEQ`. Sem esse tratamento, o RC seria 0, os contadores estariam zerados e o diagnóstico seria praticamente impossível sem inspecionar o KSDS diretamente.

### 7.4 Seed data é código

Dados de seed (`lancamentos_d0.txt`, `contas.txt`, `clientes.txt`) devem ser tratados com o mesmo rigor que código-fonte: versionados, documentados e validados antes de execução. Um arquivo de entrada incorreto invalida toda uma rodada de testes e pode mascarar bugs legítimos no código.

---

## 8. Stack técnica envolvida

- **COBOL:** `EBVALI01`, `EBPOST01`
- **JCL:** `EBJVALD`, `EBJPOST`
- **VSAM KSDS:** `ARQ.CONTA.KSDS`, `ARQ.LANCTO.ESDS`
- **VSAM ESDS:** `ARQ.LANCTO.ESDS`
- **PS/SEQ:** `ARQ.ENTRADA.SEQ`, `ARQ.REJEITO.SEQ`, `ARQ.AUDIT.SEQ`
- **Copybooks:** `CPLCT001` (layout de lançamento), `CPCNT001` (layout de conta)
- **Zowe CLI:** upload do arquivo seed local → dataset remoto
- **SDSF / Zowe Explorer:** leitura do spool para diagnóstico

---

## 9. Evidências esperadas após correção completa

- `EBJVALD` com RC 0 e zero rejeitos
- `EBJPOST` com RC 0, contadores de aceitos igual a 10, zero entradas em auditoria com "CONTA NAO ENCONTRADA"
- `ARQ.CONTA.KSDS` com saldos atualizados nas 5 contas referenciadas
- `ARQ.AUDIT.SEQ` com 10 registros de sucesso de postagem
- `EBJSALD`, `EBJEXTR`, `EBJCONC` executando com dados reais

---

## 10. Próximo passo recomendado

Alinhar `lancamentos_d0.txt` com `contas.txt` escolhendo uma das opções descritas na seção 6, executar a cadeia completa `EBJVALD → EBJPOST → EBJSALD` e coletar evidências de execução bem-sucedida para portfólio.
