//* ============================================================
//* ARQUIVO      : EBJPOST.jcl
//* CAMINHO LOCAL: jcl/batch/EBJPOST.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJPOST)
//*
//* FINALIDADE:
//* Aplicar nas contas os lancamentos ja validados pelo EBJVALD.
//*
//* POSICAO NA CADEIA DIARIA:
//* EBJVALD (validacao) --> EBJPOST --> EBJCUTF (EOTI)
//*
//* O QUE ESTE JOB FAZ:
//* 0. Valida se o CTL.STATUS = OPEN (janela de entrada aberta)
//* 1. Le lancamentos validos do ESDS (MOVTIN)
//* 2. Localiza a conta no KSDS (CONTA) por READ chave
//* 3. Verifica saldo disponivel para debitos:
//* Disponivel = CNT-SALDO + CNT-LIMITE
//* 4. Atualiza CNT-SALDO com REWRITE no KSDS
//* 5. Registra cada postagem na auditoria
//*
//* CODIGOS DE RETORNO:
//* RC 0  = todos os lancamentos postados com sucesso
//* RC 4  = algum lancamento rejeitado por saldo insuficiente
//* RC 8  = dia nao esta OPEN (EBCTL01) ou erro de I/O no KSDS
//* RC 12 = erro critico de abertura de arquivo
//* ============================================================
//EBJPOST  JOB ,'EMUNAH POST',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP CHKSTAT: GARANTIR QUE O DIA ESTA ABERTO ===========
//* Usa o EBCTL01 em modo leitura (CHK) para validar se o
//* status e OPEN. Impede a postagem se ja passou do horario
//* de corte (EOTI/EOFI) ou se o dia esta fechado.
//*
//CHKSTAT  EXEC PGM=EBCTL01,PARM='CHK,OPEN'
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CTLSTAT  DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=SHR
//*
//* === STEP POSTA: POSTAGEM DE LANCAMENTOS (EBPOST01) =========
//* Executa somente se a checagem de status retornou RC=0.
//*
//POSTA    EXEC PGM=EBPOST01,COND=(0,NE)
//STEPLIB  DD DSN=Z77948.EMUNAH.DEV.LOADLIB,DISP=SHR
//* Biblioteca contendo o modulo executavel EBPOST01.
//MOVTIN   DD DSN=Z77948.EMUNAH.ARQ.LANCTO.ESDS,DISP=SHR
//* VSAM ESDS de lancamentos validados (saida do EBJVALD).
//* Leitura sequencial do inicio ao fim.
//CLIENTE  DD DSN=Z77948.EMUNAH.ARQ.CLIENTE.KSDS,DISP=SHR
//* VSAM KSDS de clientes. Consultado para validar
//* se o cliente da conta esta ativo.
//CONTA    DD DSN=Z77948.EMUNAH.ARQ.CONTA.KSDS,DISP=SHR
//* VSAM KSDS de contas. Aberto em I-O pelo programa
//* para READ + REWRITE do saldo apos cada lancamento.
//AUDIT    DD DSN=Z77948.EMUNAH.ARQ.AUDIT.SEQ,DISP=MOD
//* Auditoria da postagem. DISP=MOD = append.
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*