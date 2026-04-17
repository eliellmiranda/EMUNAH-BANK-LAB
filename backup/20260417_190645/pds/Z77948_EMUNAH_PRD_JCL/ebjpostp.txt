//EBJPOSTP JOB ,'EMUNAH PRD POST',CLASS=A,MSGCLASS=X,
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*-----------------------------------------------------------------*
//* JOB      : EBJPOSTP                                             *
//* BIBLIOTECA: Z77948.EMUNAH.PRD.JCL                               *
//* FUNCAO   : EXECUTAR A POSTAGEM DE MOVIMENTOS EM PRODUCAO        *
//*                                                                 *
//* O QUE ESTE JOB FAZ:                                             *
//* - Executa o programa EBPOST01                                   *
//* - Le movimentos validados                                       *
//* - Atualiza o cadastro de contas                                 *
//* - Gera trilha de auditoria                                      *
//*                                                                 *
//* OBSERVACOES IMPORTANTES:                                        *
//* - CONTA usa DISP=OLD porque o KSDS sera atualizado              *
//* - AUDIT usa DISP=MOD para preservar o historico existente       *
//* - STEPLIB aponta para a LOADLIB oficial de producao             *
//*-----------------------------------------------------------------*
//STEP1    EXEC PGM=EBPOST01
//*
//* LOADLIB OFICIAL DE PRODUCAO
//STEPLIB  DD DSN=Z77948.EMUNAH.PRD.LOADLIB,DISP=SHR
//*
//* ENTRADA COM MOVIMENTOS VALIDOS
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.VALID.SEQ,DISP=SHR
//*
//* CADASTRO MASTER DE CONTAS - UPDATE
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=OLD
//*
//* TRILHA DE AUDITORIA - ACRESCENTA NOVOS REGISTROS
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
