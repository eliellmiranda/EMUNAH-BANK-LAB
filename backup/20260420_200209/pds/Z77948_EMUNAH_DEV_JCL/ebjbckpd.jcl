Migra as 3 saidas do EBJBACKP de datasets sequenciais fixos
para Generation Data Groups, aproveitando as bases definidas
pelo EBDEFGDG (commit eb7a874).

Saidas migradas:
- BKP.CLIENTE.SEQ -> BKP.CLIENTE.GDG(+1)  LIMIT(7)
- BKP.CONTA.SEQ   -> BKP.CONTA.GDG(+1)    LIMIT(7)
- BKP.AUDIT.SEQ   -> BKP.AUDIT.GDG(+1)    LIMIT(14)

Cada execucao do job passa a gerar uma nova geracao
catalogada. As geracoes mais antigas que excederem o LIMIT
da base GDG sao descatalogadas e fisicamente apagadas
(NOEMPTY + SCRATCH definidos em EBDEFGDG).

Beneficios:
- Historico automatico de N dias de backup.
- Restauracao por geracao relativa: BKP.CLIENTE.GDG(-1),
  (-2), etc. ate o LIMIT da base.
- Elimina necessidade de DELETE manual antes de cada job
  (que antes existia implicitamente em DISP=NEW,CATLG).

Detalhes tecnicos:
- DCB ganha MODEL.DSCB para que SMS herde os atributos da
  base GDG na criacao da geracao.
- LRECL, SPACE, UNIT e RECFM mantidos por step (cada VSAM
  tem RECORDSIZE proprio).
- COND=(4,LT) mantido entre steps: falha em STEP1 aborta
  STEP2/STEP3, preservando atomicidade de backup.

Nao inclui backup de REJEITOS (BKP.REJEITOS.GDG): rejeitos
sao output transacional do dia, nao estado pre-batch.
Esse backup sera responsabilidade do EBJHKREJ (housekeeping)
ou de um job dedicado de fim de dia.

Pre-requisito:
- EBDEFGDG ja executado em ambiente alvo (bases GDG criadas).
