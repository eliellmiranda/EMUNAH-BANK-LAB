/* REXX ------------------------------------------------------------ */
/* EBHKSPL - EMUNAH BANK LAB - MONITOR DE UTILIZACAO DO SPOOL (JES2) */
/*                                                                    */
/* O que faz:                                                        */
/*   1. Emite $D SPOOL via SDSF (relay de comando de operador)        */
/*   2. Extrai o percentual de utilizacao da mensagem $HASP646        */
/*   3. Classifica severidade: 0=OK 4=ATENCAO 8=ALERTA 12=CRITICO      */
/*   4. Se >=ATENCAO, tambem lista quem esta consumindo mais spool    */
/*      via $D JQ,SPL=(%>1)                                           */
/*                                                                    */
/* Saida: RC do exec = severidade (use em COND= no JCL chamador)      */
/*                                                                    */
/* Requisitos: SDSF instalado e acessivel (padrao em z/OS 3.1).        */
/* ATENCAO: os nomes de stem variable e o formato exato de retorno    */
/* do ISFEXEC '/comando' foram validados contra documentacao publica, */
/* mas NAO foram testados no seu Hercules especificamente. Se algo    */
/* nao bater, entre no SDSF, va no painel e digite COLSHELP para ver  */
/* os nomes reais das variaveis no seu release.                       */
/* ------------------------------------------------------------------ */

LIMITE_ATENCAO = 80
LIMITE_ALERTA  = 90
LIMITE_CRITICO = 95

rc = isfcalls('ON')
if rc <> 0 then do
  say 'EBHKSPL: ISFCALLS(ON) falhou, RC='rc' - SDSF nao disponivel?'
  exit 16
end

/* Da um tempo maior para o console responder antes de ler ISFULOG */
ISFDELAY = 5

/* Emite o comando de operador $D SPOOL atraves do relay "/" do SDSF */
Address SDSF "ISFEXEC '/$D SPOOL'"
sdsfrc = rc

if sdsfrc <> 0 | ISFULOG.0 = 0 then do
  say 'EBHKSPL: ISFEXEC /$D SPOOL falhou ou nao retornou linhas, RC='sdsfrc
  rc = isfcalls('OFF')
  exit 16
end

pctfull = ''
do i = 1 to ISFULOG.0
  linha = ISFULOG.i
  if pos('PERCENT SPOOL UTILIZATION', linha) > 0 then do
    parse var linha 'HASP646' pct 'PERCENT' .
    pctfull = strip(pct)
  end
end

if pctfull = '' then do
  say 'EBHKSPL: nao encontrei $HASP646 na resposta. Linhas recebidas:'
  do i = 1 to ISFULOG.0
    say '  ' ISFULOG.i
  end
  rc = isfcalls('OFF')
  exit 16
end

say 'EBHKSPL: utilizacao atual do spool = 'pctfull'%'

severidade = 0
if pctfull >= LIMITE_ATENCAO then severidade = 4
if pctfull >= LIMITE_ALERTA  then severidade = 8
if pctfull >= LIMITE_CRITICO then severidade = 12

/* A partir de ATENCAO, lista quem esta consumindo mais spool */
if severidade >= 4 then do
  say 'EBHKSPL: acima do limite de atencao - maiores consumidores de spool:'
  Address SDSF "ISFEXEC '/$D JQ,SPL=(%>1)'"
  do i = 1 to ISFULOG.0
    say '  ' ISFULOG.i
  end
end

rc = isfcalls('OFF')

select
  when severidade = 0  then say 'EBHKSPL: OK - spool abaixo de 'LIMITE_ATENCAO'%'
  when severidade = 4  then say 'EBHKSPL: ATENCAO - spool >= 'LIMITE_ATENCAO'%'
  when severidade = 8  then say 'EBHKSPL: ALERTA - spool >= 'LIMITE_ALERTA'%'
  when severidade = 12 then say 'EBHKSPL: CRITICO - spool >= 'LIMITE_CRITICO'% - avalie rodar EBHKPUR'
end

exit severidade
