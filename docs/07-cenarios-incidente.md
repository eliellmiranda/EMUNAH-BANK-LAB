Título: Cenários de Incidente — Emunah Bank Lab

Objetivo

Este documento descreve cenários controlados de erro e seus resultados esperados, para apoiar testes operacionais, troubleshooting e reprocessamento no laboratório.

Cenário normal-day

Este cenário representa a execução normal do dia, sem falhas. A baseline deve estar restaurada, a massa válida deve estar carregada e o arquivo de entrada precisa estar presente. Os jobs executados são EBJLOAD, EBJVALD, EBJPOST, EBJSALD, EBJEXTR, EBJCONC e EBJEOD. O resultado esperado é retorno aceitável em toda a cadeia, ausência de falhas críticas, conciliação correta e fechamento concluído.

Cenário missing-input

Este cenário representa a ausência do arquivo de entrada no início do processamento. A baseline deve estar restaurada, mas o arquivo de entrada não deve ser enviado. O job principal afetado é EBJLOAD. O resultado esperado é falha no início da cadeia, acionamento do runbook de arquivo ausente e bloqueio do processamento.

Cenário invalid-layout

Este cenário representa um arquivo de entrada com layout incorreto. A baseline deve estar restaurada e um arquivo inválido deve ser enviado. O job principal afetado é EBJVALD. O resultado esperado é geração de rejeitos, retorno elevado ou processamento parcial, além de necessidade de correção e possível reprocessamento.

Cenário duplicate-key

Este cenário representa tentativa de gravação duplicada em arquivo chaveado. A massa deve conter duplicidade controlada. O job afetado será aquele que realizar gravação em KSDS, como a carga inicial ou outro fluxo específico. O resultado esperado é erro de gravação controlado, rejeição do registro e produção de log de inconsistência.

Cenário wrong-disp

Este cenário representa um JCL com parâmetro inadequado de alocação ou uso de dataset. O setup consiste em alterar propositalmente o JCL. O resultado esperado é erro de alocação, interrupção do job e spool com mensagens correspondentes.

Cenário hold-job

Este cenário representa um job submetido, mas não liberado. O setup pode ser simular hold ou bloquear dependência anterior. O resultado esperado é job parado, análise no Zowe Explorer e no SDSF e acionamento do runbook de job em hold.

Cenário saldo-inconsistente

Este cenário representa divergência entre os totais aplicados e o saldo consolidado. O setup pode ser massa preparada com erro ou alteração proposital no cálculo. Os jobs afetados são EBJSALD e EBJCONC. O resultado esperado é falha de conciliação e bloqueio do fechamento.

Cenário late-file

Este cenário representa atraso na chegada do arquivo do dia. O setup deve simular ausência inicial e posterior chegada tardia. O resultado esperado é atraso operacional, decisão de aguardar, cancelar ou seguir com contingência e registro desse comportamento.

Cenário reprocess-required

Este cenário representa a necessidade de reaplicar registros antes rejeitados e depois corrigidos. O setup deve gerar rejeitos controlados e preparar um arquivo corrigido. O job principal afetado é EBJREPR. O resultado esperado é reaplicação correta, ajuste de totais e registro de evidência antes e depois.

Cenário validation-rc08

Este cenário representa uma falha de validação relevante, mas não necessariamente técnica. O setup deve usar massa com erros de negócio significativos. O job principal afetado é EBJVALD. O resultado esperado é retorno elevado, necessidade de decisão operacional e possível bloqueio da cadeia.

Padrão dos cenários

Cada cenário do laboratório deve registrar nome, descrição, setup, jobs afetados, resultado esperado e runbook relacionado.