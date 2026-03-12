Título: Runbooks Operacionais — Emunah Bank Lab

Objetivo

Este documento tem como finalidade registrar os procedimentos de diagnóstico, correção e reprocessamento para os principais incidentes do laboratório. Ele serve como manual operacional para consulta rápida sempre que ocorrer um erro.

Estrutura de uso

Cada incidente deve ser analisado de acordo com os seguintes pontos: sintoma apresentado, causa provável, forma de diagnóstico, ação corretiva, necessidade ou não de reprocessamento e evidências que devem ser guardadas.

Incidente: arquivo de entrada ausente

O sintoma típico é a falha do job EBJLOAD, com a cadeia principal impedida de prosseguir. A causa provável pode ser ausência do dataset de entrada, nome incorreto, problema de upload ou erro de catálogo. O diagnóstico deve começar pela verificação da existência do dataset Z77948.EMUNAH.ARQ.ENTRADA.SEQ, seguida da conferência do nome e do conteúdo do arquivo. A ação corretiva consiste em reenviar o arquivo de entrada, corrigir o nome ou o destino do dataset e repetir a checagem de existência. Depois da correção, o job EBJLOAD deve ser reexecutado. Como evidência, devem ser guardados o spool do job, a evidência da lista de datasets e o horário do reenvio do arquivo.

Incidente: layout inválido no arquivo de entrada

O sintoma típico é a geração de muitos rejeitos pelo job EBJVALD ou um retorno elevado na validação. As causas prováveis incluem tamanho incorreto do registro, tipo inválido, valor incorreto, data fora do padrão ou conta inexistente. O diagnóstico deve ser feito por meio do relatório de validação, da análise do dataset Z77948.EMUNAH.ARQ.REJEITO.SEQ e da comparação entre o layout do arquivo e o copybook esperado. A ação corretiva consiste em corrigir o arquivo de entrada, revisar a geração da massa ou ajustar o layout se o erro estiver na definição. Após a correção, o job EBJVALD deve ser reexecutado. Como evidência, devem ser guardados os registros rejeitados, o motivo de rejeição e a versão do layout utilizado.

Incidente: conta inexistente ou inválida

O sintoma mais comum é a rejeição de lançamentos na validação ou na aplicação. A causa provável é ausência da conta em Z77948.EMUNAH.ARQ.CONTA.KSDS, carga inicial incompleta ou chave de conta incorreta. O diagnóstico exige consulta ao arquivo de contas, verificação da carga inicial e conferência da chave de agência e conta. A ação corretiva pode ser corrigir a massa de entrada, recarregar o cadastro da conta ou ajustar o conteúdo da chave. O reprocessamento deve ser feito por meio do job adequado, geralmente EBJREPR, ou pela repetição da etapa correspondente da cadeia. Como evidência, devem ser guardados o spool da validação ou da aplicação, a prova da ausência da conta e a massa corrigida.

Incidente: falha na aplicação de lançamentos

O sintoma típico é a falha do job EBJPOST. As causas prováveis são erro de lógica do programa, conta bloqueada, saldo insuficiente ou falha na gravação de arquivo. O diagnóstico deve incluir análise do spool do job, verificação do arquivo de contas, análise dos lançamentos válidos recebidos e conferência do comportamento do programa. A ação corretiva consiste em corrigir o programa ou a massa de dados, recompilar o programa e reenviar a versão corrigida para o ambiente remoto. O reprocessamento deve ocorrer apenas após a confirmação de que o estado do ambiente está consistente; em alguns casos pode ser necessário restaurar a baseline antes de reaplicar. Como evidência, devem ser guardados o spool, o RC, os registros afetados e a indicação se a falha provocou impacto parcial ou total.

Incidente: falha de conciliação

O sintoma típico é a falha do job EBJCONC, impedindo o fechamento do dia. A causa provável pode estar em divergência entre os totais de entrada e saída, erro no saldo consolidado, falha de reprocessamento ou geração incorreta do extrato. O diagnóstico deve comparar totais de entrada e saída, quantidade de registros válidos e rejeitados, cálculo do saldo e conteúdo do extrato. A ação corretiva consiste em localizar a divergência, corrigir a causa de origem e reexecutar a etapa necessária. O fechamento nunca deve ser executado enquanto a conciliação estiver inconsistente. As evidências devem incluir relatório de conciliação, totais esperados e obtidos e logs dos jobs envolvidos.

Incidente: job em hold ou não executado

O sintoma é o job permanecer parado ou não iniciar. As causas prováveis são status HOLD, dependência anterior não atendida ou falha em job predecessor. O diagnóstico deve ser feito no Zowe Explorer e no SDSF, além da conferência da ordem de execução definida na grade batch. A ação corretiva pode envolver liberar o job, reenviá-lo ou corrigir a dependência anterior. O reprocessamento deve começar no job afetado, desde que o estado anterior do ambiente esteja consistente. As evidências necessárias são status do job, tela do SDSF e horários de parada e liberação.

Incidente: reprocessamento de rejeitos

O sintoma é a existência de registros corrigidos que ainda não foram reaplicados. A causa típica é um erro anterior já identificado e corrigido. O diagnóstico deve verificar a consistência do arquivo corrigido, a causa original do rejeito e a segurança da reaplicação. A ação corretiva consiste em preparar o arquivo corrigido, executar o job EBJREPR e validar o impacto em saldo e extrato. Como evidência, devem ser guardados os rejeitos originais, a versão corrigida e o spool do job de reprocessamento.

Regra geral de evidências

Sempre que ocorrer uma falha, devem ser guardados o nome do job, horário, RC, spool principal, datasets afetados, ação executada e a decisão sobre reprocessamento.