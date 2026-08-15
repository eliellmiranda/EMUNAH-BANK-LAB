# JES2 SPOOL no z/OS 3.1 - Operação, Housekeeping e Monitoramento

**Ambiente:** z/OS 3.1 emulado / Hercules Hyperion  
**Sistema:** VS01  
**Data do procedimento:** 14/08/2026  
**Objetivo:** documentar a criação do segundo volume JES2 SPOOL no DASD existente e estabelecer um procedimento operacional para diagnosticar, limpar e monitorar o spool.

---

## 1. Estado final alcançado

O ambiente passou de um único volume de spool para dois volumes ativos:

```text
JSPVS1  -> ACTIVE -> ~90%
JSPVS2  -> ACTIVE -> 0%
TOTAL   -> 88.3164%
```

Configuração relevante do JES2:

```text
SPOOLDEF
  DSNAME=VSPROV.VS01.HASPACE
  DSNMASK=VSPROV.VS01.HASPACE*
  SPOOLNUM=32
  TGSIZE=36
  TGSPACE=(MAX=504928,DEFINED=17178,ACTIVE=17178,FREE=2007)
  WARN=90
  VOLUME=JSPVS
```

O evento de recuperação foi confirmado por:

```text
$HASP055 JES2 Resource shortage of TGS relieved
```

Antes da expansão havia 16.678 TGs definidos/ativos; depois, 17.178. O acréscimo foi de 500 TGs. Com `TGSIZE=36`, isso representa aproximadamente 18.000 tracks adicionais de capacidade de spool.

---

## 2. O que realmente aconteceu

O objetivo inicial era usar o DASD `DE34`, já disponível no Hercules, sem criar outro DASD.

```text
DE34 -> JSPVS2
```

Verificações feitas:

```text
D M=DEV(DE34)
```

retornou o dispositivo `0DE34` como `ONLINE`, com caminho online e operacional.

O volume `JSPVS2` possuía VTOC indexada:

```text
SYS1.VTOCIX.JSPVS2
```

O SMS também mostrava o volume como `JSPVS2 / DE34 / ONRW` no `SGBASE`. Na consulta pelo ISMF da configuração ativa, o volume apareceu como:

```text
Physical Volume Status : NONSMS
MB-free : 16211
% Free  : 99
VS01 -> ENABLE / ONLINE / ENABLE
```

O problema não era o DASD, nem a VTOC. O problema era a alocação dinâmica do novo dataset do spool.

---

## 3. Por que os primeiros comandos falharam

O `SPOOLDEF` original tinha:

```text
DSNAME=VSPROV.VS01.HASPACE
DSNMASK=
```

O dataset `VSPROV.VS01.HASPACE` já existia e estava catalogado no `STGVS1`. Portanto, tentar criar `HASPACE2` usando a configuração sem `DSNMASK` não permitia o novo nome.

Depois foi configurado:

```text
$T SPOOLDEF,DSNMASK=VSPROV.VS01.HASPACE*
```

Isso permitiu nomes como:

```text
VSPROV.VS01.HASPACE2
VSPROV.VS01.HASPACE3
```

Mesmo assim, o JCL de alocação do `HASPACE2` continuou passando pelas rotinas ACS e falhando com `IGD301I`/`IGD17273I`.

A investigação da ACS revelou que o membro:

```text
VSPROV.DFSMS.CNTL(STORCLAS)
```

já tinha uma exceção para o spool original:

```text
WHEN (&DSN = 'VSPROV.VS01.HASPACE')
  DO
    SET &STORCLAS = ''
    EXIT CODE(0)
  END
```

O `HASPACE2` não estava nessa exceção. Assim, a rotina caía no `OTHERWISE` e recebia `SCBASE`.

A correção foi adicionar, imediatamente antes da exceção do `HASPACE`:

```text
WHEN (&DSN = 'VSPROV.VS01.HASPACE2')
  DO
    SET &STORCLAS = ''
    EXIT CODE(0)
  END
```

Depois foi feito:

1. validação da ACS: **SUCCESSFUL VALIDATION**;
2. tradução: **TRANSLATION SUCCESSFUL**;
3. ativação do `VSPROV.DFSMS.SCDS`;
4. confirmação no console de `IGD008I NEW CONFIGURATION ACTIVATED`.

A seguir o dataset foi criado com JCL e colocado explicitamente no `JSPVS2`:

```jcl
//ALLOCSP  JOB MSGCLASS=X,MSGLEVEL=(1,1)
//ALLOC    EXEC PGM=IEFBR14
//SPDATA   DD DSN=VSPROV.VS01.HASPACE2,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=3390,
//            VOL=SER=JSPVS2,
//            SPACE=(CYL,(100,0))
```

O resultado foi:

```text
IEF142I ... STEP WAS EXECUTED - COND CODE 0000
IEF285I VSPROV.VS01.HASPACE2 CATALOGED
IEF285I VOL SER NOS= JSPVS2.
```

Só depois disso foi solicitado ao JES2 que usasse o dataset existente:

```text
$S SPL(JSPVS2),DSNAME=VSPROV.VS01.HASPACE2
```

O JES2 respondeu:

```text
$HASP423 JSPVS2 IS BEING FORMATTED
$HASP630 VOLUME JSPVS2 ACTIVE 0 PERCENT UTILIZATION
```

E finalmente:

```text
$HASP055 JES2 Resource shortage of TGS relieved
```

---

## 4. Procedimento reproduzível para adicionar um novo spool em DASD existente

### 4.1. Pré-requisitos

1. Confirmar que o DASD está online:

```text
D M=DEV(DE34)
```

2. Confirmar volume/estado no SMS, se necessário:

```text
D SMS,VOLUME(JSPVS2)
```

3. Confirmar configuração JES2:

```text
$D SPOOLDEF
$D SPOOL
```

4. Confirmar que o prefixo do VOLSER é compatível com `VOLUME=` no `SPOOLDEF`. Neste ambiente:

```text
VOLUME=JSPVS
```

logo `JSPVS2` é válido.

### 4.2. Permitir um nome novo de spool dataset

Se `DSNMASK=` estiver vazio e o dataset-base já existir, configurar uma máscara que permita o novo nome:

```text
$T SPOOLDEF,DSNMASK=VSPROV.VS01.HASPACE*
```

Conferir:

```text
$D SPOOLDEF
```

### 4.3. Verificar a ACS STORCLAS

Localizar o membro da rotina, neste laboratório:

```text
VSPROV.DFSMS.CNTL(STORCLAS)
```

Adicionar uma exceção para o novo spool dataset, se a rotina estiver atribuindo uma Storage Class:

```text
WHEN (&DSN = 'VSPROV.VS01.HASPACE2')
  DO
    SET &STORCLAS = ''
    EXIT CODE(0)
  END
```

Validar e traduzir a rotina pelo ISMF. Em seguida ativar o SCDS apropriado.

### 4.4. Criar o dataset

Como foi feito com sucesso neste laboratório:

```jcl
//ALLOCSP  JOB MSGCLASS=X,MSGLEVEL=(1,1)
//ALLOC    EXEC PGM=IEFBR14
//SPDATA   DD DSN=VSPROV.VS01.HASPACE2,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=3390,
//            VOL=SER=JSPVS2,
//            SPACE=(CYL,(100,0))
```

Confirmar:

```text
LISTCAT ENT('VSPROV.VS01.HASPACE2') ALL
```

### 4.5. Entregar o dataset ao JES2

Como o dataset já existe, iniciar o spool sem `SPACE=`:

```text
$S SPL(JSPVS2),DSNAME=VSPROV.VS01.HASPACE2
```

Não usar `SPACE=` nessa etapa. Com `SPACE=` o JES2 tenta uma alocação nova; sem `SPACE=` ele usa o dataset existente. [IBM JES2 `$S SPOOL`]

---

# 5. Housekeeping: como descobrir de onde está vindo o consumo

O ponto central é separar três conceitos:

**Spool físico:** track groups (`TG`) nos datasets JES2.  
**Job/SYSOUT:** saída de jobs, STCs e TSUs que permanece no spool.  
**Dados externos:** arquivos de DB2, CICS, USS, LOGREC, logs em DASD etc. não consomem JES2 spool a menos que sua saída esteja sendo direcionada para SYSOUT/JES.

Portanto, não devemos assumir que "log grande" = "spool cheio".

A IBM recomenda usar `$D SPL` para spool e `$D LIMITS(SPOOL),LONG` para identificar os principais consumidores por track groups. [IBM JES2]

---

## 6. Primeiro diagnóstico: visão geral

Use:

```text
$D SPOOL
```

Para todos os volumes:

```text
$D SPOOL,ALL
```

Para um volume específico:

```text
$D SPOOL,V=JSPVS1
$D SPOOL,V=JSPVS2
```

Também é útil:

```text
$D SPOOL,V=JSPVS1,TGINUSE
$D SPOOL,V=JSPVS1,TGNUM
```

Esses displays permitem enxergar percentual e quantidade de track groups. [IBM JES2 `$D SPOOL`]

---

## 7. Segundo diagnóstico: quem está consumindo o spool

### 7.1. Top consumidores de SPOOL

No z/OS 3.1, a melhor primeira ferramenta para investigação é:

```text
$D LIMITS(SPOOL),LONG
```

ou, para uma visão MAS-wide:

```text
$D LIMITS(SPOOL),MASVIEW
```

Esses displays mostram o uso do recurso `SPOOL` em track groups e os top 10 consumidores por quantidade total e por taxa de alocação. [IBM JES2 `$D LIMITS`]

Isso responde perguntas como:

- qual STC está crescendo rapidamente?
- qual job está segurando muito spool?
- quem tem muito TG alocado mesmo depois de terminar?
- quem está consumindo spool neste momento?

### 7.2. Encontrar jobs que usam um volume específico

Exemplo para procurar consumidores significativos do `JSPVS1`:

```text
$D JQ,SPOOL=(V=JSPVS1,PERCENT>1)
```

Você pode baixar o limiar conforme necessário:

```text
$D JQ,SPOOL=(V=JSPVS1,PERCENT>0.5)
```

O comando `$D JOB`/`$D JQ` pode mostrar volume de spool, TGs e percentual por job. [IBM JES2 `$D JOB`]

### 7.3. Inspecionar um job específico

Depois de identificar um consumidor:

```text
$D J1234,LONG
```

O display longo mostra os volumes de spool usados pelo job e, quando disponível, a quantidade de TGs e percentual. [IBM JES2 `$D JOB`]

---

# 8. O que pode estar ocupando JSPVS1

## 8.1. SYSOUT de jobs batch

É a primeira categoria a verificar. Jobs concluídos podem continuar no JES2 até que o output seja processado/purgado.

Pergunta operacional:

> Há muita saída antiga em WRITE, HOLD, KEEP ou LEAVE?

A IBM alerta especificamente que output mantido/held pode desperdiçar spool e JQEs. [IBM JES2 - held output]

## 8.2. SYSOUT de Started Tasks

Started Tasks como DB2, CICS, TCP/IP, MQ e outros podem gerar SYSOUT continuamente ou deixar output retido.

Isto é importante porque o consumidor não precisa ser um JOB batch normal. O próprio JES2 considera JOBs, STCs e TSUs entre os consumidores dos recursos. [IBM JES2 `$D LIMITS`]

Use:

```text
$D LIMITS(SPOOL),LONG
```

ou filtre `JQ` para analisar STCs.

## 8.3. TSO/TSU

Sessões TSO também podem manter saída no spool. Elas entram na mesma análise de consumidores de JES2.

## 8.4. SYSLOG / hardcopy log

O log que chega ao JES/SYSOUT pode consumir spool. Entretanto, um dataset grande em DASD, como um LOGREC dedicado, é outra coisa: seu tamanho no DASD não significa automaticamente ocupação de JES2 spool.

## 8.5. DB2, CICS, IMS, MQ e USS

Esses subsistemas podem contribuir para spool quando a saída de seus address spaces é direcionada para SYSOUT/JES. Um arquivo de log puramente em DASD ou em z/OS UNIX não deve ser contado como spool JES2.

A melhor prática é identificar primeiro o consumidor pelo JES2 e somente depois abrir a investigação específica do subsistema.

---

# 9. Limpeza segura: ordem recomendada

## Nível 1 - output antigo e desnecessário

Comece por output que claramente não precisa mais existir.

O JES2 permite filtrar output por idade com `AGE>`/`DAYS>` e também por horas. [IBM JES2 `$P O Job`]

Exemplo conservador, após inspeção:

```text
$POJ,AGE>20
```

Esse tipo de comando deve ser usado com critério e somente após verificar que a saída antiga não é necessária para auditoria, troubleshooting ou retenção do laboratório.

A documentação IBM confirma que `$P O Job` purga output e aceita filtros de idade. [IBM JES2 `$P O Job`]

## Nível 2 - held output esquecido

Held output é um candidato clássico para housekeeping. O operador pode liberar ou cancelar output held com `$O` e usar filtros de idade/horas para evitar que saída esquecida ocupe espaço indefinidamente. [IBM JES2]

Antes de automatizar, inspecione:

```text
$D JQ,AGE>7
```

ou use SDSF para revisar o output retido.

## Nível 3 - jobs antigos que ainda precisam ser removidos

Quando o job inteiro não é mais necessário, use `$P JOB`/`$P JQ` com filtros adequados. A ação de purga remove o job e seu output. [IBM JES2 `$P Job`]

Exemplo conceitual:

```text
$P J1234
```

Para limpeza por idade, valide primeiro o conjunto selecionado antes de aplicar a purga em massa.

## Nível 4 - STC específico

Para um STC, primeiro identifique o volume/TGs e o output. Depois trate o output do STC; não purgue o STC em execução apenas para "limpar spool".

Se um STC estiver crescendo continuamente, o objetivo passa a ser corrigir a fonte da saída, não apenas purgá-la repetidamente.

---

# 10. O que NÃO fazer

### Não apagar o HASPACE diretamente

Não use `DELETE`/`SCRATCH` em `VSPROV.VS01.HASPACE` ou `HASPACE2` enquanto o JES2 estiver usando esses datasets.

### Não usar `ICKDSF INIT` em um spool ativo

Isso destruiria a estrutura do volume. A solução encontrada neste laboratório não exigiu reinicialização do DASD.

### Não confundir dataset grande com spool grande

O tamanho de um dataset de LOGREC, DB2, CICS ou USS não responde sozinho à pergunta "quem está ocupando JES2 spool?". O caminho correto é primeiro identificar TG consumers no JES2.

### Não purgar indiscriminadamente STCs

Uma STC pode ser estrutural para CICS, DB2, TCP/IP, MQ, JES2, SDSF, OMVS etc. Primeiro elimine apenas output desnecessário; trate o problema de geração contínua na origem.

### Não usar `$P SPOOL,JSPVS1,CANCEL` como housekeeping normal

`$P SPOOL` é uma operação de drain/delete do volume, não uma limpeza de output. Com `CANCEL`, o impacto pode atingir jobs que tenham espaço alocado em outros volumes. [IBM JES2 `$P SPOOL`]

---

# 11. Housekeeping periódico recomendado para este laboratório

## Diário

```text
$D SPOOL
$D LIMITS(SPOOL),LONG
```

Registrar:

- percentual total;
- percentual de cada volume;
- FREE TGs;
- top consumers;
- taxa de crescimento.

## Semanal

1. Revisar output held/KEEP/LEAVE.
2. Procurar jobs/STCs antigos com grande quantidade de TGs.
3. Purgar output comprovadamente descartável.
4. Revisar se alguma STC está produzindo SYSOUT anormalmente.
5. Comparar `JSPVS1` e `JSPVS2`.

## Quando ultrapassar 80%

Entrar em modo preventivo:

```text
$D SPOOL
$D LIMITS(SPOOL),LONG
```

Identificar o principal consumidor e a taxa de crescimento antes de simplesmente adicionar mais spool.

## Ao atingir o WARN de 90%

Seu ambiente está configurado com:

```text
WARN=90
```

A partir desse ponto, housekeeping deve ser tratado como ação operacional prioritária.

## Em situação crítica

Se houver crescimento rápido:

1. identificar o consumidor;
2. verificar se é JOB, STC ou TSU;
3. determinar se o crescimento é SYSOUT, spool temporário ou execução ativa;
4. parar/purgar somente o que for seguro;
5. adicionar spool somente se a causa não puder ser resolvida rapidamente ou se for necessária capacidade adicional.

A IBM recomenda justamente observar consumidores de spool e remover output desnecessário; também fornece o recurso de limites por job para reduzir o risco de um único workload consumir uma parcela excessiva dos TGs. [IBM JES2 resource limit management]

---

# 12. Monitoramento avançado

O JES2 possui o comando:

```text
$D LIMITS(SPOOL),MASVIEW
```

que apresenta uma visão MAS-wide dos consumidores e taxas de alocação. [IBM JES2 `$D LIMITS`]

Para investigação histórica, registros SMF tipo 26 fornecem informações de utilização de spool, incluindo track groups e buffers usados pelo job. [IBM JES2 held output/spool monitoring]

O Health Check/PFA `PFA_JES_SPOOL_USAGE` também pode identificar comportamento anormal de uso de spool em address spaces, com foco nos maiores crescimentos de TG. [IBM PFA_JES_SPOOL_USAGE]

---

# 13. Checklist operacional de emergência

- [ ] Executar `$D SPOOL`.
- [ ] Executar `$D LIMITS(SPOOL),LONG`.
- [ ] Executar `$D JQ,SPOOL=(V=JSPVS1,PERCENT>1)`.
- [ ] Identificar JOB/STC/TSU responsável.
- [ ] Executar `$D Jxxxx,LONG` no candidato principal.
- [ ] Verificar output held/KEEP/LEAVE.
- [ ] Purgar somente output comprovadamente descartável.
- [ ] Reexecutar `$D SPOOL` e `$D LIMITS(SPOOL),LONG`.
- [ ] Se o consumo continua crescendo, investigar a origem da geração de SYSOUT/spool.
- [ ] Somente depois avaliar expansão do spool.

---

# 14. Procedimento resumido que funcionou no laboratório

```text
1. Detectar shortage de TGS
2. $D SPOOL
3. $D SPOOLDEF
4. Confirmar DASD DE34 / JSPVS2 online
5. Confirmar VTOC do JSPVS2
6. Configurar DSNMASK=VSPROV.VS01.HASPACE*
7. Alterar ACS STORCLAS para isentar HASPACE2
8. Validar ACS
9. Traduzir ACS
10. Ativar SCDS
11. Alocar VSPROV.VS01.HASPACE2 em JSPVS2
12. $S SPL(JSPVS2),DSNAME=VSPROV.VS01.HASPACE2
13. Confirmar $HASP630 ... ACTIVE 0 PERCENT
14. Confirmar $HASP055 ... shortage of TGS relieved
15. $D SPOOL / $D SPOOLDEF
```

---

# 15. Resultado deste laboratório

A expansão foi concluída **sem criar um novo DASD**.

```text
Hercules DASD
     |
     +-- DE2D -> JSPVS1 -> spool original
     |
     +-- DE34 -> JSPVS2 -> VSPROV.VS01.HASPACE2 -> spool adicional
```

Estado final observado:

```text
JSPVS1  ACTIVE  ~90%
JSPVS2  ACTIVE   0%
TOTAL   ~88.3164%
FREE    2007 TGs
```

O objetivo do próximo ciclo operacional não deve ser simplesmente manter o percentual abaixo de 100%. Deve ser responder rapidamente:

> **Quem está usando os TGs, por que está usando, há quanto tempo, a que taxa está crescendo e qual ação é segura para recuperar o espaço?**

---

# Referências

- IBM Documentation - `$S SPOOL - Start a spool volume`  
  https://www.ibm.com/docs/en/zos/3.1.0?topic=section-s-spool-start-spool-volume
- IBM Documentation - `$D SPOOL - Display the status of spool volumes`  
  https://www.ibm.com/docs/en/zos/3.1.0?topic=section-d-spool-display-status-spool-volumes
- IBM Documentation - `$D LIMITS - Display resource limits`  
  https://www.ibm.com/docs/en/zos/3.1.0?topic=section-d-limitsnnnnn-display-resource-limits
- IBM Documentation - `$D Job - Display information about specified jobs`  
  https://www.ibm.com/docs/en/zos/3.1.0?topic=section-d-job-display-information-about-specified-jobs
- IBM Documentation - `$P O Job - Purge a job's output`  
  https://www.ibm.com/docs/en/zos/3.1.0?topic=section-p-o-job-purge-jobs-output
- IBM Documentation - `$P Job - Purge a job`  
  https://www.ibm.com/docs/en/zos/3.1.0?topic=section-p-job-purge-job
- IBM Documentation - `$P SPOOL - Drain a spool volume`  
  https://www.ibm.com/docs/en/zos/3.1.0?topic=section-p-spool-drain-spool-volume
- IBM Documentation - JES2 resource limit management  
  https://www.ibm.com/docs/en/zos/3.1.0?topic=guide-jes2-resource-limit-management
- IBM Documentation - PFA_JES_SPOOL_USAGE  
  https://www.ibm.com/docs/en/zos/3.1.0?topic=checks-pfa-jes-spool-usage

> **Nota:** comandos de purge em massa devem ser testados primeiro em subconjuntos pequenos no laboratório e ajustados à política de retenção. A documentação IBM foi usada para validar sintaxe e comportamento; a política de retenção do laboratório é uma decisão operacional local.
