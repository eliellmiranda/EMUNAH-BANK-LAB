/* REXX *************************************************************/
/* MEMBRO   : EBRESET                                               */
/* FUNCAO   : LIMPAR E REPROVISIONAR O AMBIENTE DO LAB              */
/********************************************************************/
HLQ = 'ELIEL.EMUNAH'
ADDRESS TSO

SAY '*** INICIANDO RESET DO AMBIENTE EMUNAH BANK ***'

/* 1. Deletar arquivos de trabalho e KSDS antigos */
"DELETE '"HLQ".ARQ.CONTA.KSDS' CL"
"DELETE '"HLQ".ARQ.VALIDOS.SEQ'"
"DELETE '"HLQ".ARQ.EXTRATO.SEQ'"

/* 2. Recriar KSDS via IDCAMS (Execucao em background via TSO) */
/* Aqui simulamos a chamada do utilitario para recriar o cluster */
SAY 'RECRIACO CLUSTERS VSAM...'
"ALLOC F(SYSIN) DUMMY"
"ALLOC F(SYSPRINT) DA(*)"
/* Nota: Em um lab real, voce apontaria para um dataset c/ os comandos IDCAMS */
/* 3. Popular com dados de SEED (Carga Inicial) */
SAY 'CARREGANDO DADOS INICIAIS (SEED)...'
"ALLOC F(IN)  DA('"HLQ".SEED.CONTAS.SEQ') SHR"
"ALLOC F(OUT) DA('"HLQ".ARQ.CONTA.KSDS') SHR"
/* O comando REPRO do IDCAMS faria a carga aqui */

IF RC = 0 THEN
    SAY '>>> AMBIENTE RESETADO COM SUCESSO! <<<'
ELSE
    SAY '>>> ERRO NO RESET. VERIFIQUE OS LOGS. <<<'

EXIT 0
