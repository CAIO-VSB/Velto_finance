# Changelog

Todas as mudanças notáveis deste projeto serão documentadas aqui.

### MAJOR.MINOR.PATCH — formato da versão.

## 2.0.0 — mudança grande e incompatível, que pode quebrar algo para quem já usa o sistema.
## 1.1.0 — funcionalidade nova, sem quebrar o que já existia.
## 1.1.1 — correções, ajustes visuais e pequenas melhorias.

## [1.6.2] - 2026-09-26

### Adicionado

- Adiciona uma nova configuração no docker-compose para a criação de container de migração


## [1.6.1] - 2026-09-26

### Corrigido

- Corrigi problemas visuais na telas de auth quando se utiliza o modo escuro


## [1.6.0] - 2026-09-26

### Adicionado

- Adicionado a opção de tema escuro no app

## [1.5.0] - 2026-09-26

### Adicionado

- Adicionado e-mail de alerta para tentativas de cadastro usando um endereço de e-mail já cadastrado.

## [1.4.0] - 2026-09-26

### Adicionado

- Adicionado estado vazio na tela de contas bancárias para orientar a criação da primeira conta.

## [1.3.2] - 2026-09-26

### Corrigido

- Corrigida a exibição do botão de adicionar meta de economia durante o estado vazio de primeiro acesso.

## [1.3.1] - 2026-09-21

### Corrigido

- Ajustada a responsividade da tipografia nos cards do dashboard em dispositivos menores.

## [1.3.0] - 2026-09-21

### Adicionado

- Adicionado novo layout aos templates de e-mail.

## [1.2.6] - 2026-09-21

### Corrigido

- Corrigida a responsividade dos cards de exclusão de movimentações.

## [1.2.5] - 2026-09-21

### Corrigido

- Corrigida falha de autenticação via Google OAuth 2.0.

## [1.2.4] - 2026-09-21

### Corrigido

- Padronizado o layout principal em notebooks para uma única coluna no dashboard.

## [1.2.3] - 2026-09-21

### Corrigido

- Corrigida a responsividade dos cards de despesas e receitas.
- Corrigida a responsividade dos títulos das rotas.

## [1.2.2] - 2026-09-20

### Corrigido

- Corrigido bloqueio no login social via Google causado pelo envio bloqueante de e-mails pelo Resend.
- Corrigida URL de redefinição de senha que incluía `/dashboard` indevidamente no `callbackURL`.

## [1.2.1] - 2026-09-20

### Corrigido

- Corrigida indisponibilidade da variável `CLOUDINARY_CLOUD_NAME` em produção.
- Corrigido problema de codificação UTF-16 que corrompia caracteres acentuados na restauração do banco de dados.

## [1.2.0] - 2026-09-15

### Adicionado

- Adicionado upload de recibos e anexos em transações via Cloudinary.
- Adicionada opção de não debitar uma conta bancária em aplicações de metas.

## [1.1.0] - 2026-09-01

### Adicionado

- Adicionadas melhorias visuais às telas de categorias.

## [1.0.0]

### Adicionado

- Lançamento inicial do Velto Finance.