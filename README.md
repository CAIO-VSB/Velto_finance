# Velto Finance 

Sistema completo de controle financeiro pessoal, criado para simplificar a gestão do dia a dia financeiro em um único lugar. Com o Velto Finance você acompanha receitas, despesas, cartões de crédito, metas de economia e transferências entre contas, tendo uma visão clara e centralizada da sua saúde financeira.


## ✨ Funcionalidades

- Dashboard inteligente — resumo mensal de receitas, despesas e saldo, com gráficos de evolução patrimonial e despesas por categoria
- Gestão de cartões de crédito — controle de faturas, parcelamentos, estornos e status de fechamento/vencimento automático
- Metas financeiras — defina objetivos de economia e acompanhe o progresso em tempo real
- Transferências entre contas — organize movimentações entre diferentes bancos e carteiras
- Filtros avançados — busque movimentações por período, categoria, conta ou tipo de transação
- Autenticação segura — login com e-mail/senha ou via Google e Discord, com opção de "lembrar-me" por até 30 dias
- Notificações automáticas — alertas de fatura próxima do vencimento direto no seu e-mail


## 🛠️ Tecnologias

**Client:** Vue 3 + Vuetify 4 + Nuxt 4 

**Server:** Nitro (motor do servidor utilizado pelo nuxt) + PostgresSQL

**Autenticação**: Better-auth (https://better-auth.com/)

**Infraestrutura**: Docker + Docker Compose, com pipeline de build muilt-estágio (app + migrations)


