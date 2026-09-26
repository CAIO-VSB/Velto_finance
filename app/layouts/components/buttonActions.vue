<script setup lang="ts">


  import { mergeProps } from 'vue'
  import CardAddMovimentsRevenue  from '~/components/forms/CardAddMovimentsRevenue.vue'
  import CardAddMovimentsExpenses from '~/components/forms/CardAddMovimentsExpenses.vue'
  import CardAddTransfer from '~/components/forms/CardAddTransfer.vue';
  import CardAddMovimentsCreditCard from '~/components/forms/CardAddMovimentsCreditCard.vue';

  const props = defineProps<{
    rail: boolean
  }>()

  const modalAddRevenue = ref(false)
  const modalExpenses = ref(false)
  const modalTranfer = ref(false)
  const modalAddMovementCreditCard = ref(false)

  const items = [
    { title: 'Receita', icon: "mdi-arrow-up-circle-outline", value: "receita", color: "green" },
    { title: 'Despesa', icon: "mdi-arrow-down-circle-outline", value: "despesa", color: "red" },
    { title: 'Despesa Cartão', icon: "mdi-credit-card-outline", value: "despesaCartao", color: "blue" },
    { title: 'Transferência', icon: "mdi-swap-horizontal", value: "transfer", color: "blue" }
  ]

  function getOption(data: string)  {
    
    if (data === "receita") {
      modalAddRevenue.value = true
      return
    }

    if (data === "despesa") {
      modalExpenses.value = true
      return
    }

    if (data === "transfer") {
      modalTranfer.value = true
      return
    }

    if (data === "despesaCartao") {
      modalAddMovementCreditCard.value = true
      return
    }

  }


</script>


<template>
  <div>
    <v-menu
      location="end"
      origin="top left"
      transition="scale-transition"
      offset="8"
    >
      <template #activator="{ props: menu }">
        <v-tooltip
          location="top"
          :disabled="!rail"
        >
          <template #activator="{ props: tooltip }">
            <v-scale-transition mode="out-in">
              <div
                v-if="!rail"
                class="px-3"
              >
                <v-btn
                  v-bind="mergeProps(menu, tooltip)"
                  block
                  color="primary"
                  variant="elevated"
                  rounded="lg"
                  size="large"
                  height="48"
                  class="text-none font-weight-bold"
                >
                  <v-icon
                    icon="mdi-plus"
                    size="21"
                    class="mr-2"
                  />

                  Novo lançamento

                  <v-icon
                    icon="mdi-chevron-down"
                    size="18"
                    class="ml-auto"
                  />
                </v-btn>
              </div>

              <v-btn
                v-else
                v-bind="mergeProps(menu, tooltip)"
                color="primary"
                icon="mdi-plus"
                size="44"
                rounded="lg"
                variant="elevated"
              />
            </v-scale-transition>
          </template>

          <span>Novo lançamento</span>
        </v-tooltip>
      </template>

      <v-card
        min-width="260"
        rounded="xl"
        elevation="4"
        class="overflow-hidden"
      >
        <div class="pa-4">
          <div class="text-subtitle-1 font-weight-bold text-blue-grey-darken">
            Novo lançamento
          </div>

          <div class="text-caption text-medium-emphasis mt-1">
            Escolha o tipo de movimentação
          </div>
        </div>

        <v-divider />

        <v-list
          density="comfortable"
          class="pa-2"
        >
          <v-list-item
            v-for="(item, index) in items"
            :key="index"
            :value="index"
            rounded="lg"
            class="launch-item"
            @click="getOption(item.value)"
          >
            <template #prepend>
              <v-avatar
                size="38"
                rounded="lg"
                :color="`${item.color}-lighten-5`"
                class="mr-3"
              >
                <v-icon
                  :icon="item.icon"
                  :color="item.color"
                  size="21"
                />
              </v-avatar>
            </template>

            <v-list-item-title class="font-weight-medium text-blue-grey-darken">
              {{ item.title }}
            </v-list-item-title>

            <template #append>
              <v-icon
                icon="mdi-chevron-right"
                size="18"
                class="text-medium-emphasis"
              />
            </template>
          </v-list-item>
        </v-list>
      </v-card>
    </v-menu>

    <CardAddMovimentsRevenue v-model="modalAddRevenue" />

    <CardAddMovimentsExpenses v-model="modalExpenses" />

    <CardAddTransfer v-model="modalTranfer" />

    <CardAddMovimentsCreditCard v-model="modalAddMovementCreditCard" />

  </div>
</template>

<style scoped>
.launch-item {
  transition: background-color 0.15s ease;
}
</style>