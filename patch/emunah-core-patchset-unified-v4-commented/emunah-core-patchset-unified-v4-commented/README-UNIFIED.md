# EMUNAH CORE PATCHSET - UNIFIED

Este pacote consolida a Wave 1 e a Wave 2 em um unico patchset.

## Regra de consolidacao
- Quando o mesmo arquivo existia nas duas ondas, foi mantida a versao mais recente da Wave 2.
- Como resultado da comparacao, os arquivos tecnicos duplicados estavam equivalentes entre as duas ondas; a unica diferenca material era o README do patchset.

## Escopo consolidado
### JCL
- jcl/batch/EBJPRECK.jcl
- jcl/batch/EBJSOD.jcl
- jcl/batch/EBJCUTF.jcl
- jcl/batch/EBJCUTE.jcl
- jcl/batch/EBJSNAP.jcl
- jcl/batch/EBJCONC.jcl
- jcl/batch/EBJEOD.jcl
- jcl/batch/EBJVALD.jcl
- jcl/batch/EBJPOST.jcl
- jcl/batch/EBJEXTR.jcl
- jcl/deploy/EBDEPLOY.jcl

### COBOL
- cobol/batch/EBPCHK01.cbl
- cobol/batch/EBCTL01.cbl
- cobol/batch/EBCONC01.cbl
- cobol/batch/EBJEOD01.cbl
- cobol/batch/EBSNAP01.cbl
- cobol/batch/EBVALI01.cbl
- cobol/batch/EBPOST01.cbl
- cobol/batch/EBEXTR01.cbl

### COPYBOOKS
- copybooks/layouts/CPSTS001.cpy
- copybooks/layouts/CPSNP001.cpy
- copybooks/layouts/CPCONC001.cpy
- copybooks/layouts/CPAUD001.cpy
- copybooks/layouts/CPLCT001.cpy
- copybooks/layouts/CPREJ001.cpy
- copybooks/layouts/CPEXT001.cpy
- copybooks/layouts/CPSLD001.cpy

## Aplicacao sugerida
1. Publicar os copybooks
2. Publicar os COBOLs
3. Publicar os JCLs
4. Rodar EBDEPLOY
5. Validar a cadeia: EBJPRECK -> EBJSOD -> EBJVALD -> EBJPOST -> EBJSNAP -> EBJCONC -> EBJEXTR -> EBJEOD

## Observacoes
- Este patchset unifica as duas ondas entregues na conversa.
- O pacote e voltado para publicacao local -> remoto via Zowe.
- O conteudo foi consolidado como artefato pronto para upload; a validacao final ainda deve ser feita no z/OS via compile/job/spool.


## Revisão v2

Este patch unificado v2 corrige uma divergência do pacote anterior e inclui também `EBACCR01.cbl` e `EBCLLOAD.cbl`, totalizando 10 COBOLs no diretório `cobol/batch/`.


## v3 note
This v3 package adds the untouched baseline JCL members EBJBCKPD, EBJWAIT, EBJLOAD, EBJACCR, and EBJCLLD so the upload list matches a 15-member end-to-end chain. These five were not rewritten in the patch; they are included for packaging completeness.
