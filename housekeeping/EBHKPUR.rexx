/* REXX ------------------------------------------------------------ */
/* EBHKPUR - EMUNAH BANK LAB - PURGA SELETIVA DE SPOOL (JES2 / SDSF) */
/*                                                                    */
/* Uso:                                                               */
/*   %EBHKPUR REPORT   -> so lista quem SERIA purgado (nao faz nada) */
/*   %EBHKPUR PURGE    -> purga de fato os jobs candidatos            */
/*   (sem argumento = REPORT, por seguranca)                          */
/*                                                                    */
/* Politica de seguranca: WHITELIST POR INCLUSAO. So mexe em jobs     */
/* cujo nome COMECA com um dos prefixos liberados abaixo, E que       */
/* estejam em status OUTPUT ou PURGE (nunca em job ativo). Qualquer   */
/* STC/job fora dessa lista (JES2, TCPIP, DBB, DBBS, IMS*, CICS*,     */
/* RACF, VTAM, IBMUSER/TSO de operador etc.) e' IGNORADO por padrao.  */
/*                                                                    */
/* Ajuste a lista PREFIXOS_LIBERADOS para a sua convencao de nomes.   */
/* ------------------------------------------------------------------ */

arg modo .
if modo = '' then modo = 'REPORT'
modo = translate(modo)

if modo <> 'REPORT' & modo <> 'PURGE' then do
  say 'EBHKPUR: modo invalido ('modo'). Use REPORT ou PURGE.'
  exit 16
end

/* Prefixos de jobname liberados para purge automatico.               */
/* Tudo que NAO comecar com um destes prefixos e' preservado.         */
PREFIXOS_LIBERADOS = 'TSU TEST TMP USR EBJ EBHK'

/* Status do SDSF (painel ST) que sao candidatos a purge.              */
/* Jobs executando, em input, em conversao etc. NUNCA entram aqui.     */
STATUS_CANDIDATOS = 'OUTPUT PURGE'

rc = isfcalls('ON')
if rc <> 0 then do
  say 'EBHKPUR: ISFCALLS(ON) falhou, RC='rc' - SDSF nao disponivel?'
  exit 16
end

isfprefix = '*'
isfowner  = '*'

Address SDSF "ISFEXEC ST"
strc = rc

if strc <> 0 then do
  say 'EBHKPUR: ISFEXEC ST falhou, RC='strc
  rc = isfcalls('OFF')
  exit 16
end

totaljobs = JNAME.0
say 'EBHKPUR: modo='modo' - jobs retornados pelo painel ST='totaljobs
say 'EBHKPUR: prefixos liberados = 'PREFIXOS_LIBERADOS

qtdcandidatos = 0
qtdpurgados   = 0
qtdfalhas     = 0

do i = 1 to totaljobs
  nome   = strip(JNAME.i)
  status = strip(translate(STATUS.i))
  token  = TOKEN.i

  /* So considera jobs em status de saida/purge */
  if wordpos(status, STATUS_CANDIDATOS) = 0 then iterate

  /* Confere se o prefixo do nome do job esta liberado */
  liberado = 0
  do j = 1 to words(PREFIXOS_LIBERADOS)
    prefixo = word(PREFIXOS_LIBERADOS, j)
    if pos(prefixo, nome) = 1 then liberado = 1
  end

  if liberado = 0 then iterate  /* fora da whitelist: preserva */

  qtdcandidatos = qtdcandidatos + 1
  say 'EBHKPUR: candidato ->' nome '(status='status')'

  if modo = 'PURGE' then do
    Address SDSF "ISFACT ST TOKEN('"token"') PARM(NP P)"
    actrc = rc
    if actrc = 0 then do
      qtdpurgados = qtdpurgados + 1
      say '   -> purgado com sucesso'
    end
    else do
      qtdfalhas = qtdfalhas + 1
      say '   -> FALHA ao purgar, RC='actrc
    end
  end
end

rc = isfcalls('OFF')

say '----------------------------------------------------'
say 'EBHKPUR: candidatos encontrados = 'qtdcandidatos
if modo = 'PURGE' then do
  say 'EBHKPUR: purgados com sucesso   = 'qtdpurgados
  say 'EBHKPUR: falhas ao purgar       = 'qtdfalhas
end
else
  say 'EBHKPUR: modo REPORT - nada foi alterado. Rode "%EBHKPUR PURGE" para agir.'
say '----------------------------------------------------'

/* NOTA: este exec nao filtra por idade (dias) porque o nome exato   */
/* da stem-variable de data/idade no painel ST pode variar por       */
/* release. Antes de adicionar esse filtro, entre no SDSF, va no     */
/* painel ST e digite COLSHELP para descobrir a variavel certa no    */
/* seu z/OS 3.1, depois compare com a data atual.                    */

exit qtdcandidatos
