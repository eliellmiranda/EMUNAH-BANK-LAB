//* ------------------------------------------------------------
//* JOB: EBBUILD
//* FINALIDADE:
//* Executar o build do programa COBOL EBCLLOAD.
//*
//* BUILD, neste contexto, significa:
//* 1. Compilar o fonte COBOL.
//* 2. Gerar o modulo objeto.
//* 3. Executar a link-edicao.
//* 4. Gravar o modulo executavel na LOADLIB.
//*
//* OBSERVACAO:
//* Este job usa a procedure padrao IGYWCL, que normalmente
//* ja executa as etapas de compilacao e link-edicao.
//* ------------------------------------------------------------
//EBBUILD  JOB ,'EMUNAH BUILD',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//* Define o job que sera submetido ao JES.
//* EBBUILD:
//*   Nome do job.
//* 'EMUNAH BUILD':
//*   Descricao do job para identificacao no spool.
//* CLASS=A:
//*   Classe de execucao do job.
//* MSGCLASS=X:
//*   Classe para onde ira a saida do spool.
//* MSGLEVEL=(1,1):
//*   Solicita exibicao das instrucoes JCL e das mensagens do
//*   processamento no spool.

//CL       EXEC IGYWCL
//* Executa a procedure/cataloged procedure IGYWCL.
//* Essa procedure e uma rotina padrao de compilacao COBOL,
//* geralmente responsavel por:
//* - chamar o compilador COBOL
//* - gerar o objeto
//* - chamar o binder/link-editor
//* - produzir o modulo de carga final
//*
//* CL:
//*   Nome do step.
//* IGYWCL:
//*   Procedure padrao usada para compilar e linkar programas
//*   COBOL no ambiente mainframe.

//COBOL.SYSIN   DD DSN=Z77948.EMUNAH.DEV.COBOL(EBCLLOAD),DISP=SHR
//* Informa o fonte COBOL que sera compilado.
//* COBOL.SYSIN:
//*   DD sobrescrevendo a entrada esperada pela etapa COBOL da
//*   procedure IGYWCL.
//* DSN=Z77948.EMUNAH.DEV.COBOL(EBCLLOAD):
//*   Membro EBCLLOAD dentro da biblioteca de fontes COBOL.
//* DISP=SHR:
//*   Abre o dataset em modo compartilhado para leitura.

//COBOL.SYSLIB  DD DSN=Z77948.EMUNAH.DEV.COPY,DISP=SHR
//* Informa a biblioteca de copybooks usada na compilacao.
//* COBOL.SYSLIB:
//*   DD sobrescrevendo a biblioteca pesquisada pelo compilador
//*   para resolver instrucoes COPY.
//* DSN=Z77948.EMUNAH.DEV.COPY:
//*   Biblioteca que contem os copybooks do laboratorio.
//* DISP=SHR:
//*   Abre a biblioteca em modo compartilhado para leitura.

//LKED.SYSLMOD  DD DSN=Z77948.EMUNAH.DEV.LOADLIB(EBCLLOAD),DISP=SHR
//* Define onde o modulo executavel sera gravado apos a
//* link-edicao.
//* LKED.SYSLMOD:
//*   DD sobrescrevendo a saida esperada pela etapa de binder
//*   ou link-editor da procedure.
//* DSN=Z77948.EMUNAH.DEV.LOADLIB(EBCLLOAD):
//*   O modulo final sera gravado como membro EBCLLOAD dentro
//*   da LOADLIB do laboratorio.
//* DISP=SHR:
//*   Indica acesso compartilhado ao dataset.
//*   Na pratica, este membro sera criado ou substituido pelo
//*   processo de link-edicao, conforme o ambiente permita.

//LKED.SYSPRINT DD SYSOUT=*
//* Direciona para o spool a saida detalhada da etapa de
//* link-edicao.
//* Aqui costumam aparecer mensagens do binder, mapa do modulo,
//* simbolos resolvidos e eventuais erros de link.

//*
//* Fim do job.
//* Esta linha comentada final pode ser mantida apenas como
//* separador visual.