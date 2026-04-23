//* ------------------------------------------------------------
//* ARQUIVO      : EBJCLLD.jcl
//* CAMINHO LOCAL: jcl/batch/EBJCLLD.jcl
//*
//* CONTEXTO DIDATICO:
//* Executar a carga inicial de clientes e contas do laboratório.
//*
//* PAPEL NO LAB:
//* Popular os masters antes da cadeia do dia.
//*
//* FLUXO RESUMIDO:
//* 1. Lê SEED.CLIENTES.SEQ.
//* 2. Lê SEED.CONTAS.SEQ.
//* 3. Grava CLIENTE.KSDS, CONTA.KSDS e AUDIT.SEQ.
//*
//* OBSERVACOES:
//* - Mantido no pacote para suportar bootstrap funcional do
//* ambiente.
//* ------------------------------------------------------------
//EBJCLLD  JOB ,'EMUNAH CARGA',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//* Define o JOB que sera submetido ao JES.
//* EBJCLLD:
//*   Nome do job.
//* 'EMUNAH CARGA':
//*   Descricao do job para identificacao no spool.
//* CLASS=A:
//*   Classe de execucao do job, conforme regras do ambiente.
//* MSGCLASS=X:
//*   Classe onde a saida do job sera direcionada.
//* MSGLEVEL=(1,1):
//*   Pede exibicao das instrucoes JCL e das mensagens geradas
//*   durante a execucao do job e do step.
//STEP1    EXEC PGM=EBCLLOAD
//* Executa o programa chamado EBCLLOAD.
//* Este e o step principal do job.
//* Todo o processamento desta carga ocorre neste step.
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Informa a biblioteca de carga onde o sistema deve procurar
//* o modulo executavel EBCLLOAD.
//* DSN:
//*   Nome da LOADLIB do laboratorio.
//* DISP=SHR:
//*   Abre o dataset em modo compartilhado.
//CLIENTIN DD DSN=Z77948.EMUNAH.SEED.CLIENTES.SEQ,DISP=SHR
//* Arquivo de entrada sequencial contendo os registros de
//* clientes que serao carregados no ambiente.
//* CLIENTIN:
//*   DDNAME logico esperado pelo programa.
//* DISP=SHR:
//*   Abertura compartilhada, normalmente para leitura.
//CONTAIN  DD DSN=Z77948.EMUNAH.SEED.CONTAS.SEQ,DISP=SHR
//* Arquivo de entrada sequencial contendo os registros de
//* contas que serao carregados no ambiente.
//* CONTAIN:
//*   DDNAME logico esperado pelo programa.
//* DISP=SHR:
//*   Abertura compartilhada, normalmente para leitura.
//CLIENTE  DD DSN=Z77948.EMUNAH.ARQ.CLIENTE.KSDS,DISP=SHR
//* Arquivo VSAM KSDS de clientes.
//* O programa deve gravar aqui os registros lidos do arquivo
//* CLIENTIN.
//* KSDS:
//*   Key Sequenced Data Set, isto e, arquivo indexado por
//*   chave.
//* DISP=SHR:
//*   Acesso compartilhado ao dataset.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* Arquivo VSAM KSDS de contas.
//* O programa deve gravar aqui os registros lidos do arquivo
//* CONTAIN.
//* DISP=SHR:
//*   Acesso compartilhado ao dataset.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Arquivo sequencial de auditoria do processamento.
//* Pode receber mensagens de controle, quantidades lidas,
//* quantidades gravadas e possiveis ocorrencias.
//* DISP=MOD:
//*   Se o dataset existir, grava no final sem apagar o que
//*   ja estava registrado anteriormente.
//SYSOUT   DD SYSOUT=*
//* Direciona a saida geral do step para o spool.
//* Usado para mensagens operacionais e saidas de sistema.
//SYSPRINT DD SYSOUT=*
//* Direciona para o spool a saida detalhada de impressao do
//* programa.
//* Normalmente contem relatorios, estatisticas e mensagens de
//* diagnostico do processamento.
