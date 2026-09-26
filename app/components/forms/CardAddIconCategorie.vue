<script lang="ts" setup>

  import { useSelectedIcon, type TSelectIcon } from "~/composables/useCategorie/useSelectedIcon"

  // Lista contendo todos os bancos, value e tipo 
  const icons = [
  // ========== RECEITAS ==========
  { name: '13º Salário', icon: 'mdi-cash-multiple', type: 'Receita' },
  { name: 'FGTS', icon: 'mdi-bank', type: 'Receita' },
  { name: 'Mesada', icon: 'mdi-account-cash', type: 'Receita' },
  { name: 'Cashback', icon: 'mdi-cash-refund', type: 'Receita' },
  { name: 'Pensão', icon: 'mdi-hand-coin', type: 'Receita' },
  { name: 'Herança', icon: 'mdi-treasure-chest', type: 'Receita' },
  { name: 'Restituição IR', icon: 'mdi-file-document-refresh', type: 'Receita' },
  { name: 'Prêmio Loteria', icon: 'mdi-trophy-variant', type: 'Receita' },
  { name: 'Empréstimo Recebido', icon: 'mdi-arrow-down-bold-circle', type: 'Receita' },
  { name: 'Auxílio', icon: 'mdi-hand-heart-outline', type: 'Receita' },
  { name: 'Hora Extra', icon: 'mdi-clock-plus', type: 'Receita' },
  { name: 'PLR', icon: 'mdi-currency-usd', type: 'Receita' },
  { name: 'Royalties', icon: 'mdi-crown', type: 'Receita' },
  { name: 'Consultoria', icon: 'mdi-account-tie', type: 'Receita' },
  { name: 'Doação Recebida', icon: 'mdi-charity', type: 'Receita' },
  { name: 'Reembolso Médico', icon: 'mdi-medical-bag', type: 'Receita' },
  { name: 'Gorjeta', icon: 'mdi-hand-coin-outline', type: 'Receita' },
  { name: 'Vale Alimentação', icon: 'mdi-food-apple', type: 'Receita' },
  { name: 'Pensão por Morte', icon: 'mdi-account-heart', type: 'Receita' },
  { name: 'Patrocínio', icon: 'mdi-handshake', type: 'Receita' },

  // ========== DESPESAS ==========
  { name: 'Pets', icon: 'mdi-paw', type: 'Despesa' },
  { name: 'Beleza', icon: 'mdi-lipstick', type: 'Despesa' },
  { name: 'Presentes', icon: 'mdi-gift', type: 'Despesa' },
  { name: 'Streaming', icon: 'mdi-netflix', type: 'Despesa' },
  { name: 'Academia', icon: 'mdi-dumbbell', type: 'Despesa' },
  { name: 'Viagem', icon: 'mdi-airplane', type: 'Despesa' },
  { name: 'Telefone/Internet', icon: 'mdi-wifi', type: 'Despesa' },
  { name: 'Vestuário', icon: 'mdi-tshirt-crew', type: 'Despesa' },
  { name: 'Restaurante', icon: 'mdi-silverware-fork-knife', type: 'Despesa' },
  { name: 'Manutenção Casa', icon: 'mdi-hammer-wrench', type: 'Despesa' },
  { name: 'Delivery', icon: 'mdi-moped', type: 'Despesa' },
  { name: 'Gás/Água/Luz', icon: 'mdi-water-pump', type: 'Despesa' },
  { name: 'Condomínio', icon: 'mdi-office-building', type: 'Despesa' },
  { name: 'Empréstimo', icon: 'mdi-bank-transfer', type: 'Despesa' },
  { name: 'Cartão de Crédito', icon: 'mdi-credit-card', type: 'Despesa' },
  { name: 'Farmácia', icon: 'mdi-pill', type: 'Despesa' },
  { name: 'Combustível', icon: 'mdi-gas-station', type: 'Despesa' },
  { name: 'Uber/Transporte', icon: 'mdi-taxi', type: 'Despesa' },
  { name: 'Cabeleireiro', icon: 'mdi-content-cut', type: 'Despesa' },
  { name: 'Eletrônicos', icon: 'mdi-cellphone', type: 'Despesa' },
  { name: 'Eletrônicos', icon: 'mdi-dots-horizontal', type: 'Despesa' },
]
  const { selectIcon } = useSelectedIcon()

  const dialogFilter = ref(false)
  const radios = ref("")
  const currentRadio = ref("")
  const loading = ref(false)

  function selectdItem(data: TSelectIcon) {
    selectIcon(data)
  }

  watch(radios, (newValue: string) => {
    currentRadio.value = newValue
    dialogFilter.value = false
  })

  const modelValue = defineModel<boolean>()

</script>

<template>
    <v-dialog
        v-model="modelValue"
        max-width="520"
    >
        <v-card
            rounded="xl"
            elevation="4"
        >
            <v-card-item class="pa-5 pb-2">
                <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
                    Selecione um ícone
                </v-card-title>

                <v-card-subtitle class="mt-1">
                    Escolha o ícone que melhor representa sua categoria.
                </v-card-subtitle>

                <template #append>
                    <v-btn
                        icon="mdi-filter-variant"
                        variant="text"
                        @click="dialogFilter = true"
                    >
                        <v-tooltip
                            activator="parent"
                            text="Filtrar ícones"
                        />
                    </v-btn>
                </template>
            </v-card-item>

            <v-divider />

            <v-card-text class="pa-5">
                <div class="icon-grid">
                    <v-avatar
                        v-for="item in icons"
                        :key="item.name"
                        size="52"
                        color="grey-lighten-3"
                        class="icon-cell"
                        @click="selectdItem(item)"
                    >
                        <v-icon
                            :icon="item.icon"
                            size="26"
                            color="blue-grey-darken-2"
                        />

                        <v-tooltip
                            activator="parent"
                            location="top"
                            :text="item.name"
                        />
                    </v-avatar>
                </div>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog
        v-model="dialogFilter"
        max-width="320"
    >
        <v-card
            rounded="xl"
            elevation="4"
        >
            <v-card-item class="pa-5 pb-2">
                <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken-4">
                    Filtro
                </v-card-title>

                <v-card-subtitle class="mt-1">
                    Filtre os ícones exibidos na lista.
                </v-card-subtitle>
            </v-card-item>

            <v-card-text class="px-5 pb-5">
                <v-radio-group
                    v-model="radios"
                    hide-details
                >
                    <v-radio
                        label="Receitas"
                        value="Despesa"
                    />

                    <v-radio
                        label="Despesas"
                        value="Receita"
                    />
                </v-radio-group>
            </v-card-text>
        </v-card>
    </v-dialog>
</template>

<style scoped>

.icon-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(52px, 1fr));
  gap: 12px;
}

.icon-cell {
  cursor: pointer;
  transition: transform 0.15s ease, background-color 0.15s ease;
}

.icon-cell:hover {
  transform: scale(1.08);
  background-color: rgb(var(--v-theme-primary)) !important;
}

.icon-cell:hover .v-icon {
  color: white !important;
}
</style>