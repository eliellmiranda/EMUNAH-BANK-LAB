# Emunah Core Patchset Unified v4 Commented

Esta versão mantém a lógica do patch unificado v3 e adiciona cabeçalhos/comentários
mais didáticos nos JCLs, COBOLs e copybooks.

## Objetivo
Preservar o comportamento técnico do patch já consolidado, mas restaurar o padrão
de laboratório didático: arquivos autoexplicativos, com propósito, fluxo resumido
e observações operacionais.

## O que mudou em relação ao v3
- Comentários de cabeçalho enriquecidos em todos os JCLs do pacote
- Comentários didáticos adicionados aos COBOLs da cadeia principal e utilitários
- Comentários de contexto adicionados aos copybooks entregues no patch
- Nenhuma mudança intencional de lógica em relação ao v3

## Escopo
- `jcl/deploy/EBDEPLOY.jcl`
- `jcl/batch/*.jcl` incluídos no v3
- `cobol/batch/*.cbl` incluídos no v3
- `copybooks/layouts/*.cpy` incluídos no v3

## Observação
Os cabeçalhos evitam fixar a ideia de “padrão Oracle FLEXCUBE” para layouts que são,
na prática, layouts internos do Emunah Bank Lab inspirados no modelo operacional
do ciclo EOTI/EOFI.

## Ordem de aplicação
1. subir `copybooks`
2. subir `cobol`
3. subir `jcl`
4. rodar `EBDEPLOY`
5. validar a cadeia principal
