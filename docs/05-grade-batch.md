Objetivo

Este documento tem como objetivo registrar a cadeia batch principal do laboratório, descrevendo a ordem de execução dos jobs, suas dependências, os arquivos de entrada e saída, além dos critérios de continuidade ou bloqueio do processamento.

Visão geral

A cadeia batch do laboratório simula o processamento diário de um ambiente bancário. Esse processamento inclui a recepção do arquivo de entrada, a validação de layout e de regras de negócio, a aplicação dos lançamentos, a consolidação dos saldos, a geração de extratos, a conciliação dos resultados, o fechamento diário e o reprocessamento de rejeitos quando necessário.

Janela batch simulada

O processamento diário do laboratório segue uma janela operacional simulada. Às 06:00 ocorre a pré-checagem do ambiente. Às 06:15 ocorre o backup do estado anterior. Às 06:30 é executado o job EBJLOAD, responsável pela preparação do arquivo do dia. Às 07:00 roda o job EBJVALD, responsável pela validação. Às 07:30 executa-se o job EBJPOST, que aplica os lançamentos. Às 08:00 roda o job EBJSALD, responsável pela consolidação dos saldos. Às 09:00 executa-se o job EBJEXTR, que gera os extratos. Às 09:30 roda o job EBJCONC, que faz a conciliação. Às 10:00 é executado o job EBJEOD, responsável pelo fechamento do dia. O job EBJREPR não faz parte da cadeia normal e deve ser executado sob demanda, apenas quando houver necessidade de reprocessar rejeitos corrigidos.

Descrição dos jobs

O job PRECHECK tem como finalidade verificar se o ambiente está pronto para execução. Ele confere a existência das bibliotecas principais, a existência do arquivo de entrada e a integridade mínima do ambiente. Sua saída é um log de pré-checagem. O processamento só deve continuar se todas as verificações essenciais forem aprovadas.

O job EBBACKUP tem a função de registrar o estado do ambiente antes do processamento do dia. Ele é executado após a pré-checagem e sua finalidade é permitir recuperação ou análise posterior, caso ocorra uma falha durante a execução da cadeia batch. O processamento só deve continuar se o backup terminar com retorno aceitável.

O job EBJLOAD prepara o arquivo de entrada do dia para a etapa seguinte. Sua principal entrada é o dataset Z77948.EMUNAH.ARQ.ENTRADA.SEQ. Como saída, ele disponibiliza o arquivo pronto para validação e gera um log de carga. O processamento só pode seguir se o arquivo existir e estiver acessível.

O job EBJVALD executa o programa EBVALI01. Sua função é validar o layout do arquivo de entrada e também regras de negócio básicas, como conta válida, tipo de lançamento, valor positivo e campos obrigatórios. Sua entrada principal é o dataset Z77948.EMUNAH.ARQ.ENTRADA.SEQ. Como saída, ele produz registros válidos, registros rejeitados no dataset Z77948.EMUNAH.ARQ.REJEITO.SEQ e um relatório de validação. A cadeia só deve continuar se o lote válido for considerado aceitável.

O job EBJPOST executa o programa EBPOST01. Ele aplica os lançamentos válidos, atualiza as contas e grava os movimentos do dia. Suas entradas incluem os registros validados, o arquivo de contas Z77948.EMUNAH.ARQ.CONTA.KSDS e o arquivo de clientes Z77948.EMUNAH.ARQ.CLIENTE.KSDS. Como saída, ele atualiza contas, grava movimentos em Z77948.EMUNAH.ARQ.LANCTO.ESDS e gera log de aplicação. A cadeia só segue se o processamento for concluído sem inconsistências críticas.

O job EBJSALD executa o programa EBSALD01. Sua finalidade é consolidar o saldo diário por conta com base no resultado da aplicação dos lançamentos. Como saída, ele atualiza o dataset Z77948.EMUNAH.ARQ.SALDO.KSDS e produz relatório de saldo. A execução seguinte depende da conclusão correta desta etapa.

O job EBJEXTR executa o programa EBEXTR01. Sua função é gerar o extrato diário com base nos lançamentos e no saldo consolidado. A saída principal desta etapa é uma nova geração de Z77948.EMUNAH.ARQ.EXTRATO.GDG.

O job EBJCONC executa o programa EBCONC01. Ele compara os totais de entrada, os valores aplicados e os saldos finais. Seu objetivo é confirmar que os resultados do dia estão corretos. Ele produz um relatório de conciliação e o fechamento só deve ocorrer se esta etapa indicar consistência.

O job EBJEOD realiza o fechamento diário. Sua função é encerrar o dia operacional, atualizar controles e registrar o fechamento. Ele só deve ser executado se a conciliação estiver aprovada.

O job EBJREPR executa o programa EBREPR01. Sua finalidade é reaplicar registros corrigidos que foram rejeitados em execuções anteriores. Ele não pertence à cadeia principal do dia e deve ser acionado apenas sob demanda.

Dependências

O backup depende do sucesso da pré-checagem. O carregamento do arquivo depende da execução do backup. A validação depende da carga. A aplicação dos lançamentos depende da validação. A consolidação de saldo depende da aplicação. A geração do extrato depende da consolidação. A conciliação depende da geração do extrato. O fechamento do dia depende da conciliação. O reprocessamento é independente da cadeia principal e deve ser executado sob demanda.

Regras de bloqueio

A cadeia deve ser interrompida se o arquivo de entrada estiver ausente, se houver erro crítico de validação, se a aplicação falhar de forma inconsistente ou se a conciliação não fechar corretamente. O job de reprocessamento não substitui a cadeia normal; ele apenas complementa o tratamento de rejeitos.

Datasets principais

Os datasets principais utilizados na cadeia são Z77948.EMUNAH.ARQ.ENTRADA.SEQ, Z77948.EMUNAH.ARQ.REJEITO.SEQ, Z77948.EMUNAH.ARQ.AUDIT.SEQ, Z77948.EMUNAH.ARQ.CLIENTE.KSDS, Z77948.EMUNAH.ARQ.CONTA.KSDS, Z77948.EMUNAH.ARQ.LANCTO.ESDS, Z77948.EMUNAH.ARQ.SALDO.KSDS e Z77948.EMUNAH.ARQ.EXTRATO.GDG.

Critérios de sucesso do dia

O processamento diário é considerado bem-sucedido quando o arquivo de entrada é recebido corretamente, os registros válidos são processados, os rejeitos são gravados de forma consistente, os saldos são consolidados, o extrato é gerado, a conciliação fecha corretamente e o fechamento diário é concluído.