//* ------------------------------------------------------------
//* JOB: EBJEXTR
//* FINALIDADE:
//* Job previsto para a rotina de extrato do laboratorio
//* EMUNAH.
//*
//* STATUS:
//* Estrutura inicial criada. Ajustar programa, DDs e datasets
//* quando a rotina real for implementada.
//* ------------------------------------------------------------
//EBJEXTR  JOB ,'EMUNAH EXTR',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//STEP1    EXEC PGM=IEFBR14
//* Step temporario apenas para validar submissao do job.
//* IEFBR14 e um programa simples, usado para testes basicos
//* de JCL e validacao de spool.
