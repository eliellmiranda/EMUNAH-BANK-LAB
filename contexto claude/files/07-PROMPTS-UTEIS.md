# Prompts Úteis para usar no Claude dentro do Emunah Lab

Cada prompt abaixo já instrui o Claude a consultar a base de conhecimento do projeto (mercado, core bancário, mainframe na prática, modelo funcional, convenções de código). Use diretamente.

---

## 1. Revisão de programa COBOL

```
Use como base os documentos de mercado, core bancário, mainframe na prática e convenções de código do projeto.

Revise este programa COBOL como se ele fizesse parte do Emunah Bank Lab.
Analise sob três perspectivas:
1. aderência ao mercado de aplicações mainframe
2. coerência com core bancário
3. realismo de ambiente mainframe

Verifique também se o código segue as convenções de nomenclatura, campos e estrutura do projeto.

Quero a resposta em português, separando:
- resumo executivo
- o que está correto
- problemas encontrados
- impacto no laboratório
- risco operacional
- correção sugerida
- checklist final
```

---

## 2. Revisão de JCL

```
Use como base os documentos de mainframe na prática, modelo funcional, grade batch e convenções de código do projeto.

Revise este JCL como se ele fosse usado em produção no Emunah Bank Lab.
Verifique especialmente:
- JOB, EXEC e DD
- datasets de entrada, saída, rejeito e auditoria (nomes conforme mapa de datasets do projeto)
- DISP
- RC esperado
- riscos de execução
- coerência com o programa chamado e com a cadeia batch
- impacto operacional

No final, gere uma versão corrigida se necessário.
```

---

## 3. Documentação funcional de fluxo

```
Use como base os documentos de core bancário e modelo funcional do projeto.

Documente este fluxo do Emunah Bank Lab em estilo técnico-corporativo.
Quero:
- objetivo do fluxo
- entidades envolvidas (com datasets e DDNAMEs reais do projeto)
- regras de negócio
- entradas
- saídas
- validações
- rejeitos
- auditoria
- impacto em batch ou online
- riscos operacionais
- evidências esperadas
```

---

## 4. Transformar ideia em backlog do laboratório

```
Use como base os documentos de mercado, roadmap e modelo funcional do projeto.

Transforme este tema em backlog do Emunah Bank Lab.
Separe em:
- objetivo
- valor para o laboratório
- aderência ao mercado
- aderência ao core bancário
- aderência ao mainframe prático
- módulos e datasets afetados
- artefatos a criar
- critérios de aceitação
- riscos
- fase do roadmap em que se encaixa
- próxima implementação recomendada
```

---

## 5. Criar runbook de incidente

```
Use como base os documentos de mainframe na prática e modelo funcional do projeto.

Crie um runbook de incidente para o Emunah Bank Lab com base neste problema.
Siga a estrutura dos runbooks existentes do projeto:
- sintoma observado
- causa provável
- como confirmar o diagnóstico
- ação corretiva
- necessidade de reprocessamento
- evidências a preservar
- impacto na cadeia batch
- impacto em auditoria e rastreabilidade
```

---

## 6. Criar caso de teste

```
Use como base os documentos de core bancário, modelo funcional e convenções de código do projeto.

Crie casos de teste para este programa ou fluxo do Emunah Bank Lab.
Quero:
- cenário (com nome no padrão dos cenários de incidente do projeto)
- massa de entrada (com layout conforme copybooks do projeto)
- jobs envolvidos
- resultado esperado
- rejeitos esperados
- evidência esperada
- risco coberto pelo teste
```

---

## 7. Relacionar negócio e técnica

```
Use como base os documentos de mercado, core bancário e mainframe na prática do projeto.

Explique este tema em duas camadas:
1. visão bancária
2. visão mainframe

Depois mostre:
- como isso aparece no Emunah Lab (com módulos, programas e datasets reais)
- erros comuns
- sinais de maturidade profissional ligados a esse tema
```

---

## 8. Escrever documentação de portfólio

```
Use como base todos os documentos de knowledge do projeto.

Transforme este artefato do Emunah Bank Lab em texto de portfólio profissional.
Quero:
- contexto
- problema
- solução
- tecnologias envolvidas (stack real do projeto)
- fluxo funcional
- fluxo técnico (com jobs, programas e datasets)
- evidências
- aprendizados
- relação com mercado de vagas mainframe
```

---

## 9. Planejar estudo orientado ao laboratório

```
Use como base os documentos de mercado, roadmap e modelo funcional do projeto.

Monte um plano de estudo com foco no Emunah Bank Lab.
Use esta lógica:
- desenvolver
- executar
- manter
- evoluir

Priorize o que mais aparece em vagas reais e o que mais fortalece o laboratório.
Relacione cada item com módulos, programas ou datasets reais do projeto.
```

---

## 10. Julgar prioridade de um tema

```
Use como base os documentos de mercado, roadmap e modelo funcional do projeto.

Analise se este tema deve entrar agora no Emunah Bank Lab.
Julgue usando os critérios:
- ajuda a desenvolver aplicações mainframe?
- ajuda a executar aplicações mainframe?
- ajuda a manter aplicações mainframe?
- ajuda a evoluir aplicações mainframe?
- fortalece o realismo bancário?
- fortalece empregabilidade?
- em qual fase do roadmap se encaixa?
- depende de algo que ainda não está implementado?

No final, classifique como:
- entrar agora
- entrar depois
- não priorizar
```

---

## 11. Criar cenário de incidente

```
Use como base os documentos de mainframe na prática e modelo funcional do projeto.

Crie um cenário de incidente controlado para o Emunah Bank Lab.
Siga a estrutura dos cenários existentes:
- nome do cenário (em kebab-case)
- descrição
- setup necessário
- jobs afetados
- resultado esperado
- runbook relacionado
- evidências a coletar
```

---

## 12. Revisar consistência de dataset

```
Use como base o mapa de datasets e as convenções de código do projeto.

Verifique se este dataset ou conjunto de datasets está consistente com o projeto:
- nome segue a convenção Z77948.EMUNAH.<AMB>.<TIPO>?
- DDNAME está correto conforme o mapa de datasets?
- organização (KSDS/ESDS/SEQ/GDG) é adequada para o uso?
- há referência correta no JCL?
- há copybook correspondente?
```
