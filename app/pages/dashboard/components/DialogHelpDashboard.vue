<script setup lang="ts">

  const modelValue = defineModel<boolean>()

  const emits = defineEmits<{
    closeModal: []
  }>()

  const guideSections = [
    {
      icon: 'mdi-bank-outline',
      title: 'Cartões de resumo',
      description: 'No topo, "Saldo atual" considera o saldo inicial das suas contas ativas mais tudo que já foi efetivado, sem depender do período selecionado. Já "Receitas" e "Despesas" mostram tudo lançado no mês — recebido/pago ou ainda pendente. "Cartões de crédito" soma as faturas do mês, pagas ou a vencer.',
    },
    {
      icon: 'mdi-calendar-check-outline',
      title: 'Resumo de pendências',
      description: 'Mostra o total de receitas e despesas do mês que ainda estão marcadas como pendentes — ou seja, lançadas mas ainda sem confirmação de recebimento/pagamento. Quando tudo está em dia, o card fica vazio.',
    },
    {
      icon: 'mdi-history',
      title: 'Últimos lançamentos',
      description: 'As movimentações mais recentes do mês selecionado, com data, descrição, valor e a conta bancária usada — um jeito rápido de conferir o que entrou ou saiu sem precisar abrir a tela de transações.',
    },
    {
      icon: 'mdi-chart-donut',
      title: 'Receitas e Despesas por categoria',
      description: 'Os dois gráficos de rosca mostram como seu dinheiro se distribui entre categorias no mês — de onde vêm as receitas, e para onde vão as despesas. O total geral de cada um aparece abaixo do gráfico.',
    },
    {
      icon: 'mdi-chart-timeline-variant',
      title: 'Frequência de gastos',
      description: 'Compara o total de despesas mês a mês, pra você perceber se algum período teve gasto fora do padrão em relação aos outros.',
    },
    {
      icon: 'mdi-chart-line',
      title: 'Evolução do saldo',
      description: 'Mostra como o seu saldo foi mudando ao longo dos últimos meses, já descontando o dinheiro guardado em metas — é o saldo "livre" de verdade, não só a soma de receitas menos despesas.',
    },
    {
      icon: 'mdi-scale-balance',
      title: 'Balanço mensal',
      description: 'Compara receitas e despesas do mês lado a lado, mostrando o resultado final (balanço) — se ficou positivo ou negativo naquele período.',
    },
    {
      icon: 'mdi-bank',
      title: 'Minhas contas',
      description: 'Lista suas contas bancárias ativas com o saldo atual de cada uma, pra você ver rapidamente onde o dinheiro está guardado.',
    },
  ]

  function closeModal() {
    modelValue.value = false
    emits("closeModal")
  }

</script>

<template>
  <v-dialog
    v-model="modelValue"
    transition="dialog-bottom-transition"
    fullscreen
  >
    <v-card class="help-card">
      <v-toolbar color="primary">
        <v-btn
          icon="mdi-close"
          @click="closeModal"
        ></v-btn>

        <v-toolbar-title>Como funciona o dashboard</v-toolbar-title>
      </v-toolbar>

      <v-card-text class="help-content">
        <div class="intro">
          <v-icon icon="mdi-view-dashboard-outline" size="40" color="primary" class="mb-2"></v-icon>
          <p class="intro-text">
            Um resumo rápido de cada parte da sua tela inicial, pra você achar tudo com facilidade.
          </p>
        </div>

        <div class="guide-list">
          <template v-for="(section, i) in guideSections" :key="section.title">
            <div class="guide-item">
              <v-avatar color="primary" variant="tonal" size="40">
                <v-icon :icon="section.icon"></v-icon>
              </v-avatar>

              <div class="guide-text">
                <span class="guide-title">{{ section.title }}</span>
                <span class="guide-description">{{ section.description }}</span>
              </div>
            </div>
            <v-divider v-if="i < guideSections.length - 1" class="guide-divider"></v-divider>
          </template>
        </div>
      </v-card-text>

      <v-card-actions class="pa-4">
        <v-spacer></v-spacer>
        <v-btn
          color="primary"
          variant="flat"
          text="Entendi"
          @click="closeModal"
        ></v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<style scoped>

.help-content {
  max-width: 640px;
  margin: 0 auto;
}

.intro {
  text-align: center;
  padding: 24px 8px 8px;
}

.intro-text {
  font-size: 0.95rem;
  max-width: 420px;
  margin: 0 auto;
}

.guide-list {
  margin-top: 16px;
}

.guide-item {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 14px 4px;
}

.guide-text {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.guide-title {
  font-weight: 700;
  font-size: 1rem;
}

.guide-description {
  font-size: 0.9rem;
  line-height: 1.4;
}

.guide-divider {
  margin-left: 56px;
}
</style>