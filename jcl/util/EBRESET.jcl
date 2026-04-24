Enriquece EBRESET com documentacao dos 5 steps de reset do ambiente.
DELSAIDA (IDCAMS DELETE de 7 datasets de saida com SET MAXCC=0 em
cada - idempotente), DELREPR (DELETE de REPR.LANCTO e REPR.REJPERM),
DELBKP (DELETE de 3 backups simples), RECRIA (IDCAMS DEFINE CLUSTER
recria LANCTO.ESDS vazio) e RECRIASEQ (IEFBR14 recria REJEITOS.SEQ
e AUDIT.SEQ vazios). Documenta o escopo: preserva masters (KSDS de
clientes/contas), DEV e seed.