# Changelog

Todas as mudanças notáveis deste projeto serão documentadas aqui.


## [1.0.6] - 2026-09-21
### Adicionado
- Layout principal no notebook padronizado com apenas uma coluna no dashboard

## [1.0.5] - 2026-09-21
### Corrigido
- Cards de despesas e receitas com responsividade incorretas
- Títulos das rotas com font-size padrão - responsividade incorretas

## [1.0.4] - 2026-09-21
### Adicionado
- Aplicação contém uma estrutura para ser um PWA - podendo ser instalável 

## [1.0.4] - 2026-09-20
### Corrigido
- E-mails travando o login social (Google) por `await` bloqueante no envio via Resend
- URL de reset de senha com `/dashboard` indevido no `callbackURL`

## [1.0.3] - 2026-09-20
### Corrigido
- Variável `CLOUDINARY_CLOUD_NAME` não chegando em produção (build-time vs runtime)
- Encoding UTF-16 corrompendo caracteres acentuados no restore do banco

## [1.0.2] - 2026-09-15
### Adicionado
- Upload de recibo/anexo em transações via Cloudinary
- Opção "não debitar de conta bancária" em aplicações de metas