//* ------------------------------------------------------------
//* JOB: EBJEOD
//* FINALIDADE:
//* Job previsto para o processamento de fechamento diario do
//* laboratorio EMUNAH.
//*
//* STATUS:
//* Estrutura inicial criada. Ajustar programa, DDs e datasets
//* quando a rotina real for implementada.
//* ------------------------------------------------------------
//EBJEOD   JOB ,'EMUNAH EOD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=IEFBR14
//* Step temporario apenas para validar submissao do job.
//* IEFBR14 e um programa simples, usado para testes e rotinas
//* basicas de JCL.
