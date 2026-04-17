# EBOPS — Emunah Bank Operations Simulator

## Guia Completo de Implantação e Uso

---

## 1. O que é o EBOPS

O EBOPS é um simulador de dia-a-dia de um desenvolvedor mainframe. Ele gera automaticamente demandas, incidentes e tarefas operacionais que reproduzem o que um profissional encontra ao abrir o computador em um banco que roda aplicações em z/OS.

---

## 2. O que o EBOPS simula

O simulador reproduz 7 ferramentas corporativas usadas diariamente em ambientes mainframe bancários. Cada uma tem um papel específico no dia-a-dia, e o EBOPS mapeia como essa ferramenta aparece no laboratório.

### 2.1. Control-M (Scheduler)

**O que é na empresa:** Control-M é o scheduler corporativo da BMC. Ele agenda, monitora e gerencia a execução de milhares de jobs batch por dia. Controla dependências entre jobs, janelas de execução, SLAs e alertas automáticos. Todo banco de grande porte no Brasil usa Control-M ou similar (Tivoli Workload Scheduler, CA7).

**O que o desenvolvedor faz com ele no dia-a-dia:**
- Verifica se a cadeia batch do sistema está verde (todos os jobs executaram com sucesso)
- Identifica jobs que falharam, ficaram em HOLD ou estouraram SLA
- Analisa dependências: qual job depende de qual, qual é predecessor de qual
- Libera jobs manualmente quando necessário (após resolução de incidente)
- Monitora tempo de execução versus janela permitida

**Como o EBOPS simula:** O painel "Control-M" mostra a grade batch de 9 jobs encadeados (PRECHECK → EBJEOD) com status visual por job. Botões de "Simular Normal" e "Simular Falha" geram cenários realistas onde jobs ficam com status OK, WARNING, ERROR, HOLD ou PENDING. O encadeamento visual mostra a dependência entre jobs.

**Artefatos do lab relacionados:** EBBATCHP.txt (grade batch documentada), cada JCL de execução (EBJVALD, EBJPOST, etc.), EBCHKLAB.rexx (precheck).

---

### 2.2. Jira / ServiceNow (Gestão de Demandas e Incidentes)

**O que é na empresa:** Jira é usado para gestão de demandas de desenvolvimento (tasks, stories, bugs). ServiceNow é usado para incidentes de produção (chamados de suporte, falhas operacionais). Em muitos bancos, os dois coexistem: Jira para o time de desenvolvimento, ServiceNow para operação e suporte.

**O que o desenvolvedor faz com ele no dia-a-dia:**
- Ao chegar, abre o board para ver quais tasks estão atribuídas
- Pega uma task do backlog e move para "Em Andamento"
- Registra anotações de progresso, impedimentos e descobertas
- Quando incidente de produção acontece, o chamado chega como ticket de severidade
- Ao concluir, move para "Em Revisão" e anexa evidência

**Como o EBOPS simula:** O sistema de tickets funciona como um board Jira. Cada "novo dia" sorteia 2-4 tickets do pool de templates. O desenvolvedor gerencia status (Backlog → Em Andamento → Em Revisão → Concluído), filtra por categoria/severidade/dificuldade, e registra notas de trabalho. Cada ticket tem contexto bancário, passos esperados e entregável definido.

**Artefatos do lab relacionados:** Cada programa, JCL, copybook e dataset envolvido na demanda. O ticket é o ponto de entrada; o lab é o ambiente de execução.

---

### 2.3. Changeman / Endevor (Change Management)

**O que é na empresa:** Changeman (Micro Focus/Serena) e Endevor (Broadcom/CA) são ferramentas de gerenciamento de mudanças em mainframe. Controlam o ciclo de vida de cada programa: checkout → alteração → compilação → teste → promoção DEV → HML → PRD. Cada versão é rastreada. Nenhuma mudança vai para produção sem aprovação formal.

**O que o desenvolvedor faz com ele no dia-a-dia:**
- Faz checkout de um programa para alteração (o fonte é travado para ele)
- Altera o código e compila dentro da ferramenta
- Submete para teste em ambiente de homologação
- Após aprovação do analista/coordenador, a ferramenta promove para PRD
- Se der problema em PRD, faz rollback para a versão anterior

**Como o EBOPS simula:** Templates de categoria "change" reproduzem o fluxo completo: promoção DEV→HML→PRD, rollback de versão com bug, análise de impacto antes de alterar copybook, teste de regressão. No lab, o Git funciona como controle de versão, e datasets separados por ambiente (`DEV.COBOL`, `HML.COBOL`, `PRD.COBOL`) simulam a separação do Changeman.

**Artefatos do lab relacionados:** EBSUBJCL.rexx (submit com ambiente parametrizado), branches Git, datasets `DEV.*` / `HML.*` / `PRD.*`, EBCOMP.jcl e EBLINK.jcl por ambiente.

---

### 2.4. File Manager (Visualização e Edição de Dados)

**O que é na empresa:** IBM File Manager permite visualizar, editar e comparar dados em datasets mainframe (sequenciais, VSAM, DB2). Ele aplica o layout do copybook sobre os dados brutos, mostrando cada campo com nome, tipo e valor formatado. Sem File Manager, o desenvolvedor vê bytes hexadecimais; com ele, vê "NOME: ABRAÃO, CPF: 12345678901, SALDO: 1.500,00".

**O que o desenvolvedor faz com ele no dia-a-dia:**
- Abre um VSAM e visualiza registros com layout do copybook
- Compara estado de um dataset antes e depois de um job
- Edita um registro manualmente para teste ou correção emergencial
- Verifica se campos estão preenchidos corretamente após alteração de copybook
- Analisa arquivo de rejeito para entender motivos de erro

**Como o EBOPS simula:** Templates de investigação envolvem comparação de VSAM antes/depois, análise de registros com layout, verificação de campos específicos. No lab, a simulação é feita com IDCAMS PRINT, REPRO para exportação, Zowe CLI para download e Notepad++ com régua de colunas fixa. O processo é manual mas a lógica é idêntica.

**Artefatos do lab relacionados:** Todos os VSAM (ARQ.CLIENTE.KSDS, ARQ.CONTA.KSDS, ARQ.SALDO.KSDS, ARQ.LANCTO.ESDS), copybooks (CPCLI001, CPCNT001, CPSLD001, CPLCT001), sequenciais (ARQ.REJEITO.SEQ, ARQ.AUDIT.SEQ).

---

### 2.5. Abendaid / Fault Analyzer (Diagnóstico de Abends)

**O que é na empresa:** Abendaid (Compuware/Broadcom) e IBM Fault Analyzer interceptam abends COBOL em tempo real e mostram automaticamente: a linha COBOL que causou o abend, os campos envolvidos, o conteúdo dos registros no momento do erro e um diagnóstico sugerido. Transformam uma análise de horas em minutos.

**O que o desenvolvedor faz com ele no dia-a-dia:**
- Quando um job abenda (S0C7, S0C4, S806, etc.), abre o Abendaid no spool
- Vê a linha COBOL exata que causou o problema
- Vê o conteúdo dos campos (ex: campo numérico continha "ABCD")
- Identifica causa raiz sem precisar analisar offset manualmente

**Como o EBOPS simula:** Templates de incidente com abend incluem o offset do spool e exigem que o desenvolvedor cruze manualmente com o listing de compilação para encontrar a instrução COBOL. No lab, o processo é feito assim:

1. Obter o offset do abend no spool (mensagem do sistema)
2. Abrir o listing de compilação (SYSPRINT do EBCOMP)
3. Localizar a seção "PROCEDURE DIVISION MAP" ou "OFFSET MAP"
4. Encontrar o offset do abend no mapa
5. Identificar a instrução COBOL e os campos envolvidos

Esse processo manual é exatamente o que o Abendaid automatiza — e saber fazer manualmente é diferencial.

**Artefatos do lab relacionados:** Listing de compilação de cada programa (SYSPRINT), spool de execução com mensagens de abend, programas COBOL com DISPLAY de diagnóstico.

---

### 2.6. SDSF (System Display and Search Facility)

**O que é na empresa:** SDSF é a ferramenta nativa do z/OS para visualizar output de jobs. Todo troubleshooting mainframe começa no SDSF. É através dele que o desenvolvedor vê:
- JESMSGLG — mensagens do JES (alocação, execução, RC)
- JESJCL — o JCL que foi submetido
- SYSOUT — saída do programa (DISPLAYs, relatórios)
- Mensagens de erro do sistema

**O que o desenvolvedor faz com ele no dia-a-dia:**
- Verifica RC de cada step de cada job
- Lê mensagens de erro para diagnóstico
- Confirma que o job alocou os datasets corretos
- Verifica contadores e totalizações do programa
- Salva spool como evidência

**Como o EBOPS simula:** Praticamente 100% dos templates envolvem análise de spool. No lab, o SDSF é acessível de duas formas: via TSO/ISPF (sessão 3270 no zXplore) ou via Zowe Explorer (VS Code). Ambos mostram as mesmas informações.

**Artefatos do lab relacionados:** Todo job EBJ* gera spool. O SDSF é o primeiro lugar a olhar em qualquer incidente.

---

### 2.7. Confluence / Wiki (Base de Conhecimento)

**O que é na empresa:** Confluence (Atlassian) é a wiki corporativa onde ficam documentados: runbooks operacionais, arquiteturas de sistema, fluxos funcionais, convenções de código, decisões técnicas, postmortems de incidentes. Todo time mainframe tem um "espaço" no Confluence com documentação atualizada.

**O que o desenvolvedor faz com ele no dia-a-dia:**
- Consulta runbook quando incidente acontece
- Documenta novos procedimentos após resolver problemas
- Consulta arquitetura antes de alterar um programa
- Consulta convenções de código antes de criar artefato novo
- Escreve postmortem após incidente grave

**Como o EBOPS simula:** Os knowledge files do projeto Emunah Lab são a base de conhecimento do desenvolvedor. Cada documento tem papel equivalente a uma página de Confluence:

| Knowledge File | Equivalente no Confluence |
|---|---|
| `02-MERCADO-MAINFRAME-APLICADO-AO-LAB.md` | Página de referência de mercado |
| `03-CORE-BANCARIO-APLICADO-AO-LAB.md` | Documentação funcional do sistema |
| `04-MAINFRAME-NA-PRATICA.md` | Guia de práticas operacionais |
| `05-MODELO-FUNCIONAL-DO-EMUNAH-LAB.md` | Arquitetura do sistema |
| `06-ROADMAP-DE-IMPLEMENTACAO.md` | Roadmap de produto |
| `06-runbooks.md` | Runbooks operacionais |
| `07-cenarios-incidente.md` | Base de cenários de teste |
| `08-CONVENCOES-DE-CODIGO.md` | Padrões de desenvolvimento |

---

## 3. Categorias de Demandas e Problemas

O EBOPS gera 5 tipos de demandas, cada uma mapeada para um tipo de trabalho que o desenvolvedor mainframe faz na prática.

### 3.1. Incidentes de Produção (🔥)

Simulam falhas que acontecem durante a execução batch. O desenvolvedor recebe o chamado e precisa diagnosticar, corrigir e documentar.

**Exemplos incluídos no pacote:**
- Abend S0C7 em EBPOST01 (dado inválido em campo numérico)
- Abend S0C4 em EBSALD01 (referência inválida de memória)
- Abend S806 em EBJPOST (módulo não encontrado na LOADLIB)
- RC=08 em EBJVALD (rejeição acima de 30%)
- FILE STATUS 35 ao abrir VSAM (dataset não catalogado)
- Arquivo de entrada ausente (cadeia bloqueada)
- Conciliação divergente (diferença de R$ 150,00)
- Job em HOLD (não executou na janela)
- Layout divergente (copybook alterado, massa não ajustada)
- Saldo negativo detectado (regra de negócio violada)
- GDG sem nova geração (limite atingido)
- REGION insuficiente S878 (memória esgotada)
- Dataset locked por outro job (ENQ concorrente)
- JCL ERROR antes da execução (sintaxe inválida)
- Sequencial de auditoria cheia B37 (sem espaço)
- SORT com RC=16 (arquivo de entrada vazio)
- Timestamp gravando zeros (ACCEPT incorreto)
- I/O error em VSAM (CI/CA split ou definição errada)
- SQLCODE -805 (DBRM não encontrado no PLAN DB2)
- SQLCODE -911 (deadlock na tabela DB2)
- SQLCODE -811 (SELECT INTO retornou múltiplas linhas)
- Encoding corrompido após upload (EBCDIC vs UTF-8)

### 3.2. Demandas de Desenvolvimento (⚙️)

Simulam tasks de evolução do sistema. O desenvolvedor recebe o requisito e implementa.

**Exemplos incluídos:**
- Incluir campo CPF no copybook CPCLI001 com análise de impacto
- Criar validação de dígito verificador módulo 11
- Implementar novo tipo de lançamento TED
- Criar relatório de contas sem movimento no dia
- Adicionar flag de conta bloqueada (ativa/bloqueada/encerrada)
- Corrigir cálculo de tarifa (erro de PIC 9 vs PIC 9V99)
- Criar programa COBOL-DB2 com cursor (EBAUDB01)
- Implementar UPDATE de saldo via DB2 com COMMIT controlado
- Criar DCLGEN para tabela TB_CLIENTE
- Documentar transação CICS de consulta de saldo
- Documentar transação CICS de depósito com SYNCPOINT
- Criar script REXX EBRESET para reset completo
- Expandir EBCHKLAB para healthcheck de 15+ datasets
- Implementar validação de Pix com regras do BACEN
- Criar programa de verificação de limite de crédito
- Padronizar DISPLAY/log em todos os programas
- Criar JCL parametrizado para cadeia completa (COND + PARM)
- Criar PROC catalogada para compilação COBOL
- Implementar GDG para arquivo de rejeitos
- Criar smoke test automatizado (EBSMKH01)
- Documentar integração conceitual Pix com cadeia batch

### 3.3. Operação Batch (📋)

Simulam tarefas operacionais rotineiras que o desenvolvedor executa para manter o ambiente saudável.

**Exemplos incluídos:**
- Reprocessar rejeitos do dia anterior
- Verificar spool de job com RC=04 e decidir se aceita
- Executar backup pré-carga especial com REPRO
- Gerar evidência de teste para homologação
- Executar cadeia completa e documentar end-to-end
- Simular cenário missing-input e executar runbook
- Simular cenário saldo-inconsistente e investigar divergência
- Gerar massa de 1000 registros e testar performance
- Criar documento de SLA da cadeia batch
- Documentar procedimento de contingência para falha total
- Configurar Zowe CLI profiles para múltiplos ambientes

### 3.4. Change Management (🔄)

Simulam o fluxo de gestão de mudanças entre ambientes.

**Exemplos incluídos:**
- Promover EBPOST01 de DEV para HML com teste de regressão
- Rollback de versão com bug em EBVALI01
- Análise de impacto para alteração de copybook CPCNT001
- Criar fluxo documentado DEV → HML → PRD com Git
- Executar teste de regressão após alteração

### 3.5. Investigação / Ferramentas (🔍)

Simulam tarefas de análise e verificação que desenvolvem habilidade de troubleshooting.

**Exemplos incluídos:**
- Comparar VSAM antes/depois de EBJPOST
- Analisar dump S0C7 com offset no listing de compilação
- Verificar integridade após reprocessamento
- Mapear todos os FILE STATUS dos programas do lab
- Analisar warnings de compilação COBOL (IGYWS*)
- Rastrear lançamento do início ao fim da cadeia (auditoria end-to-end)
- Criar estudo de caso de incidente para portfólio

---

## 4. Passo a Passo de Implantação

### 4.1. Acessar o EBOPS

O EBOPS é um artefato React que roda diretamente no Claude. Para usá-lo:

1. Abra o artefato `ebops-simulator.jsx` gerado na conversa
2. A aplicação abre no painel lateral com o dashboard principal
3. Os dados persistem entre sessões via storage do artefato

### 4.2. Gerar o Primeiro Dia

1. No Dashboard, clique em **▶ GERAR NOVO DIA**
2. O sistema sorteia 2-4 tickets do pool de 27 templates embutidos
3. A grade batch é gerada com status aleatório (normal ou com falha)
4. Os tickets aparecem na aba "Tickets"

### 4.3. Importar o Pacote Extra (35 templates adicionais)

1. No Dashboard, clique em **⬆ IMPORTAR TEMPLATES**
2. Cole o conteúdo do arquivo `ebops-pack-extra.json`
3. Clique em **IMPORTAR**
4. Os templates são adicionados ao pool de sorteio
5. O pool total passa de 27 para 62 templates

### 4.4. Trabalhar com um Ticket

1. Vá para aba **Tickets**
2. Clique em um ticket para ver detalhes
3. Leia: descrição, contexto bancário/mainframe, passos esperados, entregável
4. Mude o status para **Em Andamento**
5. Execute os passos no Emunah Bank Lab (z/OS via Zowe CLI ou ISPF)
6. Registre notas de trabalho no campo de texto do ticket
7. Quando terminar, mude para **Concluído**

### 4.5. Usar Filtros

Na aba Tickets, os filtros permitem focar:
- **Por categoria:** só incidentes, só desenvolvimento, etc.
- **Por severidade:** crítica, alta, média, baixa
- **Por dificuldade:** junior ou pleno
- **Por status:** backlog, em andamento, em revisão, concluído

### 4.6. Criar Templates Personalizados

Para criar seus próprios cenários, use o formato JSON:

```json
[
  {
    "titulo": "Nome do cenário",
    "categoria": "incidente",
    "descricao": "O que aconteceu e qual é o sintoma",
    "contexto": "Por que isso importa em banco/mainframe",
    "severidade": "alta",
    "ferramenta": "SDSF / File Manager",
    "dificuldade": "pleno",
    "tempo_estimado": "30min",
    "tags": ["vsam", "troubleshooting"],
    "o_que_investigar": [
      "Passo 1 de investigação",
      "Passo 2 de investigação"
    ],
    "entregavel": "O que deve ser entregue ao final"
  }
]
```

**Campos obrigatórios:** titulo, categoria, descricao

**Campos recomendados:** contexto, severidade (critica/alta/media/baixa), ferramenta, dificuldade (junior/pleno), tempo_estimado, tags (array), entregavel

**Campos de passos (usar um dos dois):**
- `o_que_investigar` — para incidentes (o que analisar)
- `passos_esperados` — para desenvolvimento/operação (o que fazer)

**Valores de categoria:** incidente, desenvolvimento, operação, change, investigação

### 4.7. Resetar o Ambiente

O botão **↺ RESETAR TUDO** apaga todos os tickets gerados, templates customizados e o contador de dias. Útil para recomeçar do zero.

---

## 5. Rotina de Uso Recomendada

### Rotina diária (1-2 horas)

1. Abrir EBOPS e clicar em **GERAR NOVO DIA**
2. Analisar a grade batch: algum job falhou? Qual?
3. Olhar os tickets gerados: priorizar por severidade
4. Escolher o ticket mais urgente e iniciar
5. Executar no lab (z/OS via Zowe CLI ou ISPF)
6. Registrar notas de trabalho no ticket
7. Ao concluir, mover para "Concluído"
8. Se sobrar tempo, pegar outro ticket

### Rotina semanal

1. Revisar quantos tickets foram concluídos na semana
2. Analisar distribuição: estou fazendo mais incidentes ou mais desenvolvimento?
3. Se concentrando demais em uma categoria, filtrar outra para a próxima semana
4. Criar 2-3 templates personalizados baseados em situações novas que encontrou

### Rotina mensal

1. Escolher o melhor ticket concluído e transformar em estudo de caso
2. Atualizar README do GitHub com evidências
3. Importar novos templates se houver temas novos a praticar

---

## 6. Mapeamento: Dificuldade × Mercado

### Templates marcados como JUNIOR

São tarefas que todo desenvolvedor Jr deve saber fazer:
- Verificar spool e RC no SDSF
- Ler e corrigir JCL com erro de sintaxe
- Resubmeter job após correção
- Fazer upload de arquivo via Zowe CLI
- Analisar arquivo de rejeito
- Executar IDCAMS LISTCAT e PRINT
- Reprocessar rejeitos seguindo runbook
- Gerar evidência de teste
- Corrigir REGION no JCL

### Templates marcados como PLENO

São tarefas que demonstram maturidade profissional:
- Analisar dump com offset no listing
- Alterar copybook com análise de impacto
- Implementar cursor DB2 com tratamento de SQLCODE
- Investigar divergência de conciliação cruzando múltiplas fontes
- Documentar transação CICS conceitual
- Criar PROC catalogada
- Implementar COMMIT controlado em batch DB2
- Resolver deadlock DB2
- Criar documento de SLA e contingência
- Rastrear lançamento end-to-end por toda a cadeia

---

## 7. Como o EBOPS Fortalece o Portfólio

Cada ticket concluído com evidência real vira item de portfólio:

| Categoria | O que prova para o recrutador |
|---|---|
| Incidentes resolvidos | Capacidade de troubleshooting sob pressão |
| Demandas de desenvolvimento | Capacidade de implementar código com qualidade |
| Operação batch | Disciplina operacional e visão de produção |
| Change management | Entendimento de processos corporativos |
| Investigação | Capacidade analítica e raciocínio técnico |

O ideal é transformar pelo menos 3 tickets completos em estudos de caso para o README do GitHub, com: contexto → problema → investigação → solução → evidência → lições aprendidas.

---

## 8. Referência de Status de Job (Control-M)

| Status | Significado | Ação |
|---|---|---|
| ✓ OK (verde) | Job executou com sucesso, RC=0000 | Nenhuma |
| ▶ RUNNING (azul) | Job em execução | Aguardar |
| ⚠ WARNING (laranja) | Job terminou com RC=0004 | Analisar spool, decidir se aceita |
| ✗ ERROR (vermelho) | Job falhou, RC=0008 ou RC=0012 | Investigar, corrigir, reexecutar |
| ⏸ HOLD (roxo) | Job bloqueado, não executou | Verificar dependência, liberar |
| ◌ PENDING (cinza) | Job aguardando predecessor | Resolver predecessor primeiro |

---

## 9. Referência de Severidades

| Severidade | Significado | Tempo esperado de resolução |
|---|---|---|
| CRÍTICA | Cadeia bloqueada, risco financeiro ou regulatório | Até 1 hora |
| ALTA | Impacto em processamento, requer ação imediata | Até 2 horas |
| MÉDIA | Impacto moderado, pode aguardar priorização | Até 1 dia |
| BAIXA | Melhoria, documentação ou tarefa programada | Até 1 semana |

---

## 10. Glossário de Abends Comuns

| Abend | Causa | Diagnóstico |
|---|---|---|
| S0C7 | Dado não numérico em campo numérico | Offset no listing, campo com valor inválido |
| S0C4 | Referência a memória não alocada | Tabela OCCURS com índice fora do limite |
| S0C1 | Operação inválida (ex: CALL de programa inexistente) | Verificar CALL/LOADLIB |
| S806 | Módulo não encontrado na LOADLIB | Verificar STEPLIB, religar módulo |
| S878 | REGION insuficiente | Aumentar REGION no JCL |
| S913 | Acesso não autorizado ao dataset | Verificar permissões RACF |
| B37 | Sem espaço para estender dataset | Realocar com SPACE maior |
| D37 | Sem espaço no volume para novo dataset | Alocar em outro volume |

---

## 11. Glossário de SQLCODEs Comuns (DB2)

| SQLCODE | Significado | Ação |
|---|---|---|
| 0 | Sucesso | Nenhuma |
| +100 | Fim dos dados (no FETCH) ou registro não encontrado | Tratar como fim normal |
| -805 | DBRM não encontrado no PLAN/PACKAGE | Executar BIND |
| -811 | SELECT INTO retornou mais de uma linha | Usar CURSOR ou corrigir WHERE |
| -803 | Violação de UNIQUE INDEX (duplicidade) | Verificar dados |
| -911 | Deadlock ou timeout | Implementar retry, ajustar COMMIT |
| -904 | Recurso indisponível | Aguardar, verificar DB2 status |
| -180 | Data/hora inválida | Verificar formato do campo |

---

## 12. Glossário de FILE STATUS Comuns (VSAM)

| Status | Significado | Causa provável |
|---|---|---|
| 00 | Operação bem-sucedida | — |
| 10 | Fim de arquivo (EOF) | READ sequencial chegou ao final |
| 22 | Chave duplicada em WRITE | Registro já existe no KSDS |
| 23 | Registro não encontrado em READ | Chave não existe |
| 35 | Arquivo não encontrado no OPEN | Dataset não catalogado |
| 39 | Incompatibilidade de atributos | RECORDSIZE diferente da definição |
| 41 | OPEN de arquivo já aberto | Verificar lógica de OPEN |
| 46 | READ sem posicionamento (KSDS) | START não executado antes |
| 47 | READ em arquivo não aberto para INPUT | Verificar OPEN mode |
| 48 | WRITE em arquivo não aberto para OUTPUT | Verificar OPEN mode |
| 92 | Conflito de acesso (arquivo locked) | Outro job com DISP=OLD |

---

## 13. Inventário Completo de Templates

### Embutidos no EBOPS (27)

| ID | Categoria | Dificuldade | Tempo |
|---|---|---|---|
| INC-001 | Incidente — Abend S0C7 em EBPOST01 | Pleno | 45min |
| INC-002 | Incidente — RC=08 em EBJVALD | Junior | 30min |
| INC-003 | Incidente — Arquivo ausente | Junior | 20min |
| INC-004 | Incidente — Conciliação divergente | Pleno | 60min |
| INC-005 | Incidente — FILE STATUS 35 | Junior | 25min |
| INC-006 | Incidente — Job em HOLD | Junior | 15min |
| INC-007 | Incidente — Layout divergente | Pleno | 40min |
| INC-008 | Incidente — Abend S806 | Junior | 20min |
| INC-009 | Incidente — Saldo negativo | Pleno | 50min |
| INC-010 | Incidente — GDG sem geração | Junior | 25min |
| DEV-001 | Desenvolvimento — CPF no copybook | Pleno | 90min |
| DEV-002 | Desenvolvimento — DV módulo 11 | Junior | 45min |
| DEV-003 | Desenvolvimento — Tipo TED | Pleno | 120min |
| DEV-004 | Desenvolvimento — Relatório sem movimento | Junior | 60min |
| DEV-005 | Desenvolvimento — Conta bloqueada | Pleno | 90min |
| DEV-006 | Desenvolvimento — Correção de tarifa | Junior | 30min |
| OPS-001 | Operação — Reprocessar rejeitos | Junior | 35min |
| OPS-002 | Operação — Verificar spool RC=04 | Junior | 20min |
| OPS-003 | Operação — Backup pré-carga | Junior | 30min |
| OPS-004 | Operação — Evidência para HML | Junior | 40min |
| CHG-001 | Change — Promover DEV→HML | Pleno | 45min |
| CHG-002 | Change — Rollback de versão | Pleno | 40min |
| CHG-003 | Change — Análise de impacto | Pleno | 30min |
| INV-001 | Investigação — Comparar VSAM | Junior | 25min |
| INV-002 | Investigação — Dump com offset | Pleno | 40min |
| INV-003 | Investigação — Integridade pós-reprocessamento | Pleno | 35min |

### Pacote Extra para Importação (35)

| ID | Categoria | Dificuldade | Tempo |
|---|---|---|---|
| INC-011 | Incidente — Abend S0C4 | Pleno | 50min |
| INC-012 | Incidente — REGION S878 | Junior | 15min |
| INC-013 | Incidente — Dataset locked (ENQ) | Pleno | 25min |
| INC-014 | Incidente — JCL ERROR sintaxe | Junior | 10min |
| INC-015 | Incidente — Auditoria cheia B37 | Junior | 20min |
| INC-016 | Incidente — SORT RC=16 | Junior | 20min |
| INC-017 | Incidente — Timestamp com zeros | Junior | 25min |
| INC-018 | Incidente — VSAM I/O error | Pleno | 45min |
| INC-019 | Incidente — SQLCODE -805 | Pleno | 35min |
| INC-020 | Incidente — SQLCODE -911 deadlock | Pleno | 50min |
| INC-021 | Incidente — SQLCODE -811 | Junior | 25min |
| INC-022 | Incidente — Encoding corrompido | Junior | 25min |
| DEV-007 | Desenvolvimento — Programa COBOL-DB2 | Pleno | 120min |
| DEV-008 | Desenvolvimento — UPDATE DB2 com COMMIT | Pleno | 90min |
| DEV-009 | Desenvolvimento — DCLGEN | Junior | 30min |
| DEV-010 | Desenvolvimento — CICS consulta saldo | Pleno | 90min |
| DEV-011 | Desenvolvimento — CICS depósito | Pleno | 75min |
| DEV-012 | Desenvolvimento — REXX EBRESET | Junior | 45min |
| DEV-013 | Desenvolvimento — REXX EBCHKLAB ampliado | Junior | 40min |
| DEV-014 | Desenvolvimento — Validação Pix | Pleno | 90min |
| DEV-015 | Desenvolvimento — Limite de crédito | Junior | 60min |
| DEV-016 | Desenvolvimento — DISPLAY padronizado | Junior | 60min |
| DEV-017 | Desenvolvimento — JCL parametrizado COND | Pleno | 60min |
| DEV-018 | Desenvolvimento — PROC catalogada | Pleno | 45min |
| DEV-019 | Desenvolvimento — GDG para rejeitos | Junior | 35min |
| DEV-020 | Desenvolvimento — Smoke test EBSMKH01 | Junior | 50min |
| DEV-021 | Desenvolvimento — Documento Pix × batch | Pleno | 75min |
| OPS-005 | Operação — Cadeia end-to-end | Junior | 90min |
| OPS-006 | Operação — Cenário missing-input + runbook | Junior | 30min |
| OPS-007 | Operação — Cenário saldo-inconsistente | Pleno | 45min |
| OPS-008 | Operação — Massa 1000 registros | Junior | 45min |
| OPS-009 | Operação — Documento de SLA | Pleno | 40min |
| OPS-010 | Operação — Contingência batch | Pleno | 50min |
| OPS-011 | Operação — Zowe profiles por ambiente | Junior | 20min |
| CHG-004 | Change — Fluxo DEV→HML→PRD com Git | Pleno | 60min |
| CHG-005 | Change — Teste de regressão | Pleno | 60min |
| INV-004 | Investigação — Mapear FILE STATUS | Junior | 35min |
| INV-005 | Investigação — Warnings de compilação | Junior | 40min |
| INV-006 | Investigação — Rastrear lançamento end-to-end | Pleno | 50min |
| INV-007 | Investigação — Estudo de caso para portfólio | Pleno | 90min |

### Totais

| Métrica | Valor |
|---|---|
| Templates embutidos | 27 |
| Templates do pacote extra | 35 |
| Total de templates | 62 |
| Incidentes | 22 |
| Desenvolvimento | 21 |
| Operação | 11 |
| Change Management | 5 |
| Investigação | 7 |
| Dificuldade Junior | 30 |
| Dificuldade Pleno | 32 |

---

## 14. Encaixe no Roadmap do Emunah Lab

O EBOPS se encaixa na **Fase 9 — Automação e Portfólio** do roadmap, mas seus templates cobrem e reforçam todas as fases anteriores:

| Fase do Roadmap | Templates que exercitam |
|---|---|
| Fase 2 — Carga inicial | INC-003, INC-005, INC-008, OPS-003 |
| Fase 3 — Movimentação | INC-001, INC-004, INC-009, DEV-003, DEV-014 |
| Fase 4 — Fechamento | INC-004, INC-006, INC-010, OPS-005, OPS-009 |
| Fase 5 — DB2 | DEV-007, DEV-008, DEV-009, INC-019, INC-020, INC-021 |
| Fase 6 — Troubleshooting | Todos os INC-*, INV-*, OPS-006, OPS-007 |
| Fase 7 — CICS | DEV-010, DEV-011 |
| Fase 8 — Pagamentos | DEV-014, DEV-021 |
| Fase 9 — Automação | DEV-012, DEV-013, DEV-016, DEV-020, INV-007 |
