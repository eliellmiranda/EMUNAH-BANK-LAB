/* REXX ----------------------------------------------------------- */
/* PROGRAMA : EBSUBJCL                                              */
/* FUNCAO   : SUBMETER JCL COM ESPECIFICACAO DE BIBLIOTECA          */
/* LOCAL    : RECURSO DE OPERADOR                                   */
/*----------------------------------------------------------------- */
PARSE UPPER ARG MEMBRO JCLLIB
ADDRESS TSO

/* Validacao de parametros obrigatorios */
IF MEMBRO = '' THEN DO
  SAY 'ERRO: Nome do membro nao informado.'
  SAY 'USO : EBSUBJCL <MEMBRO> [BIBLIOTECA]'
  SAY 'EX  : EBSUBJCL EBJCHAIN ELIEL.EMUNAH.PRD.JCL'
  EXIT 8
END

/* Define biblioteca padrao de HML se nao informada */
IF JCLLIB = '' THEN
  JCLLIB = 'ELIEL.EMUNAH.HML.JCL'

ALVO = JCLLIB'('MEMBRO')'

/* Auditoria tecnica: verifica se o arquivo/membro existe */
X = LISTDSI("'"ALVO"'")
IF X <> 0 THEN DO
  SAY 'ERRO: O MEMBRO' MEMBRO 'NAO EXISTE EM' JCLLIB
  EXIT 8
END

SAY 'SUBMETENDO JOB:' ALVO
"SUBMIT '"ALVO"'"

IF RC = 0 THEN DO
  SAY 'SUCESSO: JOB' MEMBRO 'ENVIADO COM SUCESSO.'
  EXIT 0
END
ELSE DO
  SAY 'FALHA NO SUBMIT. RETURN CODE:' RC
  EXIT 12
END
