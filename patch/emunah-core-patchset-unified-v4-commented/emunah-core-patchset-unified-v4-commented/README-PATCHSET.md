# Emunah Bank Lab — Core Patchset (Wave 2)

Este pacote expande o patchset anterior com a segunda leva de padronização.

## Escopo adicional desta leva

Foram adicionados ou reescritos os seguintes artefatos:

- `EBJVALD.jcl`
- `EBJPOST.jcl`
- `EBJEXTR.jcl`
- `EBVALI01.cbl`
- `EBPOST01.cbl`
- `EBEXTR01.cbl`
- `EBSNAP01.cbl`
- `CPAUD001.cpy`
- `CPLCT001.cpy`
- `CPREJ001.cpy`
- `CPEXT001.cpy`
- `CPSLD001.cpy`

## Objetivo da Wave 2

- Padronizar layouts de movimento, rejeito, auditoria, extrato e saldo.
- Fechar lacunas entre JCL e contrato real dos programas.
- Deixar `EBJVALD`, `EBJPOST`, `EBJEXTR` e `EBSNAP01` alinhados ao modelo novo da cadeia.

## Ordem de publicação sugerida

1. Publicar os copybooks desta pasta
2. Publicar os COBOLs desta pasta
3. Publicar os JCLs desta pasta
4. Rodar `EBDEPLOY`
5. Testar a cadeia principal completa

## Observações importantes

- O HLQ foi mantido como `Z77948` para bater com o estado atual do lab.
- `EBJVALD` agora passa `CONTA` para permitir validação de existência/status da conta.
- `EBJPOST` agora passa `REJEITOS` para registrar rejeições de postagem.
- `EBJEXTR` agora passa `CONTA` e `AUDIT`, permitindo gerar extrato com saldo de posição.
- `CPEXT001` foi alinhado para 132 bytes, compatível com `ARQ.EXTRATO.GDG`.
- `CPAUD001` foi alinhado para 120 bytes, compatível com `ARQ.AUDIT.SEQ` do lab.
- `CPSLD001` foi compatibilizado com a abordagem atual de snapshot/saldo sequencial do lab.

## Honestidade técnica

Este pacote foi escrito para ficar coerente com a arquitetura e os layouts do projeto.
Ele não foi compilado/executado no z/OS dentro desta conversa, então ainda vale rodar a sequência normal de publicação, build e testes de spool.
