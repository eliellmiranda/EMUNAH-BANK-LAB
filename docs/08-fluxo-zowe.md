Título: Fluxo Zowe — Emunah Bank Lab

Objetivo

Este documento tem como objetivo explicar como o laboratório usa Zowe CLI e Zowe Explorer para integrar o projeto local ao ambiente mainframe remoto.

Princípio geral

O laboratório é organizado em três camadas. A camada local contém os arquivos-fonte, a documentação, os scripts e as automações. A camada remota contém os datasets, membros, jobs, spool e arquivos de negócio. A camada 3270 representa a operação e investigação clássica. O Zowe é a ponte entre o ambiente local e o ambiente mainframe remoto.

Papel de cada camada

O ambiente local é usado para editar COBOL, JCL e copybooks, manter documentação, controlar versão com Git e preparar automações e cenários. O ambiente remoto é usado para armazenar membros e datasets reais, compilar, executar jobs, gerar spool e manter os arquivos do laboratório. O TN3270 é usado para ISPF, SDSF, TSO, troubleshooting e operação tradicional. O Zowe é usado para publicar arquivos locais no mainframe, abrir datasets e membros remotos no VS Code, submeter jobs, consultar jobs e outputs e automatizar tarefas por CLI.

Fluxo de trabalho padrão

O fluxo de trabalho do laboratório segue a seguinte lógica: primeiro os arquivos são editados localmente no VS Code. Depois são salvos na estrutura local do projeto. Em seguida são publicados no ambiente remoto por meio do Zowe CLI ou do Zowe Explorer. Após a publicação, os membros e datasets são conferidos no ambiente remoto. O próximo passo é submeter o JCL correspondente. Em seguida, acompanha-se o status do job e consultam-se os outputs e spools. Se necessário, a investigação é aprofundada no 3270. Havendo necessidade de correção, a alteração deve preferencialmente ser feita no ambiente local, e então o ciclo é repetido.

Fluxo de publicação

Os copybooks da pasta local copybooks/layouts são publicados no dataset remoto Z77948.EMUNAH.DEV.COPY. Os programas COBOL batch da pasta cobol/batch são publicados em Z77948.EMUNAH.DEV.COBOL. Os JCLs das pastas jcl/compile e jcl/batch são publicados em Z77948.EMUNAH.DEV.JCL. Os arquivos de entrada da pasta data/entrada são publicados em Z77948.EMUNAH.ARQ.ENTRADA.SEQ.

Fluxo de execução

O build do sistema envolve o envio de programas e copybooks e a submissão de EBCOMP, EBLINK e EBBUILD. A execução batch envolve o envio do arquivo de entrada, a submissão da cadeia batch e o acompanhamento de RC e spool. A operação diária pode ser feita pela visão rápida do Zowe Explorer, mas a investigação clássica deve ser realizada pelo TN3270 e pelo SDSF quando necessário.

Regras do laboratório

O projeto local é a fonte principal do código e da documentação. O ambiente remoto é a área de build e execução. O 3270 é a ferramenta principal de operação e diagnóstico. Alterações permanentes devem ser feitas preferencialmente no local e publicadas no remoto. A edição remota deve ser usada quando fizer sentido operacional, e não como padrão principal de desenvolvimento.

Critério de uso correto do Zowe

O fluxo com Zowe está correto quando os arquivos locais são publicados no remoto de forma controlada, os membros aparecem no Explorer, os jobs podem ser submetidos sem depender de edição manual no 3270 e os resultados podem ser consultados tanto no Explorer quanto no SDSF.

Exemplo de ciclo completo

O desenvolvedor edita o arquivo EBPOST01.cbl localmente, publica esse arquivo para Z77948.EMUNAH.DEV.COBOL(EBPOST01), publica também o copybook relacionado, submete o job de build, depois submete o job batch, verifica RC e output, investiga eventuais erros e, se necessário, corrige novamente no ambiente local antes de republicar e reexecutar.