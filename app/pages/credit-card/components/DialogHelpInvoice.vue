<script setup lang="ts">

  const modelValue = defineModel<boolean>()

  const emits = defineEmits<{
    closeModal: []
  }>()


  const statusLegend = [
    {
      icon: 'mdi-sticker-check',
      color: 'green',
      title: 'Ativa',
      description: 'Compra em vigor. O valor entra na soma da fatura normalmente.',
    },
    {
      icon: 'mdi-credit-card-refund',
      color: 'orange',
      title: 'Estornada',
      description: 'Compra revertida. O valor dela é abatido do total a pagar da fatura.',
    },
    {
      icon: 'mdi-archive-cancel',
      color: 'red',
      title: 'Deletada',
      description: 'Removida da fatura. Não entra na soma e fica sem ações disponíveis.',
    },
  ]

  const guideSections = [
    {
      icon: 'mdi-file-document-outline',
      title: 'Resumo da fatura',
      description: 'No topo você vê o valor a pagar, o saldo anterior, a data de fechamento, o vencimento, o limite total e os últimos 4 dígitos do cartão — um retrato rápido da fatura atual.',
    },
    {
      icon: 'mdi-dots-vertical',
      title: 'Ações da fatura',
      description: 'O menu "Ações da fatura" reúne as opções de pagamento: total, parcial ou adiantado, além da opção de reabrir uma fatura já fechada quando necessário. Ao registrar um pagamento total ou parcial, a fatura atual é fechada; no pagamento parcial, o valor restante entra como um lançamento de ajuste na próxima fatura.',
    },
    {
      icon: 'mdi-plus-circle-outline',
      title: 'Nova despesa',
      description: 'O botão de nova despesa só fica disponível enquanto a fatura atual está aberta. Depois que ela fecha, o lançamento sempre cai na próxima fatura — nunca é possível lançar retroativamente numa fatura já fechada, mesmo que a compra tenha sido feita antes do fechamento.',
    },
    {
      icon: 'mdi-gesture-tap-button',
      title: 'Ações por lançamento',
      description: 'Toque nos três pontos de cada linha para editar, excluir ou estornar aquela compra específica. Lançamentos já deletados não têm mais ações disponíveis.',
    },
    {
      icon: 'mdi-swap-horizontal',
      title: 'Deletar x Estornar',
      description: 'Deletar remove a compra como se ela nunca tivesse existido. Estornar mantém o registro na fatura, mas desconta o valor do total a pagar — útil quando você quer manter o histórico.',
    },
    {
      icon: 'mdi-eye-outline',
      title: 'Mostrar compras canceladas',
      description: 'Por padrão, lançamentos deletados não aparecem na lista. No menu de três pontos ao lado da busca, você pode exibi-los de volta — eles continuam disponíveis, só ficam ocultos para deixar a tela mais limpa no dia a dia. Útil para um controle mais rigoroso do histórico da fatura.',
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

        <v-toolbar-title>Como funciona a fatura</v-toolbar-title>
      </v-toolbar>

      <v-card-text class="help-content">
        <div class="intro">
          <v-icon icon="mdi-credit-card-outline" size="40" color="primary" class="mb-2"></v-icon>
          <p class="intro-text">
            Um resumo rápido de cada parte da tela da fatura, pra você achar tudo com facilidade.
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

        <div class="legend-section">
          <span class="legend-title">Situação dos lançamentos</span>

          <v-card
            v-for="status in statusLegend"
            :key="status.title"
            variant="tonal"
            :color="status.color"
            class="legend-card"
          >
            <v-card-text class="legend-card-text">
              <v-icon :icon="status.icon" :color="status.color" size="28"></v-icon>
              <div class="legend-text">
                <span class="legend-label" :class="`text-${status.color}`">{{ status.title }}</span>
                <span class="legend-description">{{ status.description }}</span>
              </div>
            </v-card-text>
          </v-card>
        </div>

        <v-alert
          type="warning"
          variant="tonal"
          icon="mdi-alert-outline"
          class="warning-alert"
        >
          <div class="warning-title">Fique atento com faturas passadas</div>
          <ul class="warning-list">
            <li>Não é possível lançar novas despesas em uma fatura já fechada — o lançamento sempre vai para a fatura em aberto.</li>
            <li>Evite reabrir uma fatura já fechada sem necessidade — isso pode afetar o cálculo das faturas seguintes.</li>
            <li>Não edite valores de faturas antigas só para "ajustar" um número. Prefira estornar ou lançar uma nova compra na fatura atual.</li>
            <li>Mudanças retroativas em faturas já fechadas podem bagunçar o saldo anterior e o valor a pagar das faturas seguintes.</li>
          </ul>
        </v-alert>

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

.legend-section {
  margin-top: 32px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.legend-title {
  font-weight: 900;
  font-size: 0.95rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  margin-bottom: 4px;
}

.legend-card {
  border-radius: 12px;
}

.legend-card-text {
  display: flex;
  align-items: flex-start;
  gap: 14px;
}

.legend-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.legend-label {
  font-weight: 700;
  font-size: 0.95rem;
}

.legend-description {
  font-size: 0.85rem;
}

.warning-alert {
  margin-top: 28px;
  border-radius: 12px;
}

.warning-title {
  font-weight: 700;
  margin-bottom: 6px;
}

.warning-list {
  margin: 0;
  padding-left: 18px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  font-size: 0.88rem;
}
</style>