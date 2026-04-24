//* ============================================================
//* ARQUIVO      : EBJCUTE.jcl
//* CAMINHO LOCAL: jcl/batch/EBJCUTE.jcl
//* HOST / PDS   : Z77948.EMUNAH.DEV.JCL(EBJCUTE)
//*
//* FINALIDADE:
//*   Cutoff Contabil - marca CTL.STATUS = EOFI
//*   (End Of Financial Input): fecha a janela contabil do dia,
//*   sinalizando que nenhum novo lancamento contabil pode entrar.
//*
//* POSICAO NA CADEIA DIARIA:
//*   EBJACCR (accruals) --> EBJCUTE (EOFI) --> EBJSNAP (snapshot)
//*
//* MAQUINA DE ESTADOS CTL.STATUS:
//*   vazio/CLOSED -> OPEN (EBJSOD)
//*             -> EOTI (EBJCUTF)   <- janela financeira fechada
//*             -> EOFI (EBJCUTE)   <- janela contabil fechada
//*             -> CLOSED (EBJEOD)
//*
//* OBS: Esta versao usa IEBGENER para gravacao direta.
//*      Sera substituida pelo programa EBCTL01 (COBOL) que
//*      implementa a maquina de estados com validacao de
//*      transicao e REWRITE do registro de controle.
//*
//* CODIGOS DE RETORNO:
//*   RC 0  = EOFI gravado com sucesso
//*   RC 12 = falha no IEBGENER - STATUS nao atualizado
//* ============================================================
//EBJCUTE  JOB ,'EMUNAH CUTE',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* === STEP WRTSTAT: GRAVAR STATUS = EOFI =======================
//*   IEBGENER usa SYSUT1 inline (DD *) contendo o literal "EOFI"
//*   e SYSUT2 aponta para ARQ.CTL.STATUS com DISP=OLD.
//*   DISP=OLD obtem controle exclusivo e sobrescreve o conteudo
//*   anterior (era EOTI gravado pelo EBJCUTF).
//*
//WRTSTAT  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD *
EOFI
/*
//*           Registro inline de 4 bytes gravado no arquivo de status.
//SYSUT2   DD DSN=Z77948.EMUNAH.ARQ.CTL.STATUS,DISP=OLD
//*           Arquivo de controle de status do ciclo diario.
//*           DISP=OLD = acesso exclusivo, sobrescreve conteudo.
//SYSIN    DD DUMMY
//*           IEBGENER nao requer parametros para copia simples.
//*
//* === STEP VERIFY: CONFIRMAR STATUS GRAVADO ===================
//*   COND=(0,NE): executa somente se WRTSTAT terminou com RC=0.
//*   IDCAMS LISTCAT gera evidencia no SYSPRINT do conteudo
//*   catalogado do ARQ.CTL.STATUS apos a atualizacao.
//*
//VERIFY   EXEC PGM=IDCAMS,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  LISTCAT ENT('Z77948.EMUNAH.ARQ.CTL.STATUS') ALL
/*