<script setup lang="ts">
  import type { TMovementCreditCard } from '~~/types/credit_card/TMovementCreditCard';
  import type { TOptionAction } from '~~/types/option_action/TOptionAction';
  import CardEditMovementCreditCard from "~/components/forms/CardEditMovementCreditCard.vue"
  import CardAddReversal from '~/components/forms/CardAddReversal.vue';
  import CardDeleteMovementCreditCard from '~/components/forms/CardDeleteMovementCreditCard.vue';
  import type { TMovementCreditCardPayload } from '~~/schemas/movementCreditCard.schema';
  import CardEditRecurrenceCreditCard from '~/components/forms/CardEditRecurrenceCreditCard.vue';
  import CardDeleteRecurrenceCreditCard from '~/components/forms/CardDeleteRecurrenceCreditCard.vue';
import type { TCreditCard } from '~~/types/credit_card/TCredit-card';

  const props = defineProps<{
    movementsCreditCard: TMovementCreditCard[] | null,
    creditCard: TCreditCard | null
  }>()

  const { notifyError, notifyInfo, notifySuccess } = useNotify()

  const search = ref('')
  const modalEditMovement = ref(false)
  const modalAddReversal = ref(false)
  const modalDeleteMovement = ref(false)
  const modalEditRecurrence = ref(false)
  const modalDeleteRecurrence = ref(false)
  const editDraft = ref<TMovementCreditCard | null>(null)
  const deleteDraft = ref<TMovementCreditCardPayload | null>(null)
  const shoppingActive  = ref<boolean | null>(true)

  const statusMovementConfig: Record<string, {color: string, icon: string, text?: string}> = {
    ativa: { color: 'success', icon: 'mdi-sticker-check', text: 'Compra ativa' },
    deletada: { color: 'red', icon: 'mdi-archive-cancel', text: 'Compra deletada' },
    estornada: { color: 'orange', icon: 'mdi-credit-card-refund', text: 'Compra estornada' },
    estorno: { color: 'orange', icon: 'mdi-credit-card-refund', text: 'Compra estornada' },
    adiantado: { color: 'blue', icon: 'mdi-calendar-arrow-left', text: 'Pagamento adiantado' },
    parcial: { color: 'blue', icon: 'mdi-cash-minus', text: 'Pagamento parcial' },
  }

  const headers = [
    {
      align: 'center' as const,
      key: 'status_movement',
      title: 'Situação',
    },
    { key: 'purchase_date', title: 'Data da compra' },
    { key: 'categorie_name', title: 'Categoria' },
    { key: 'description_credit', title: 'Descrição' },
    { key: 'value_transaction', title: 'Valor' },
    { key: 'actions', title: 'Ações' },
  ]

  const items = computed(() => [
    shoppingActive.value ? { title: 'Mostrar compras deletadas', icon: 'mdi-delete-empty', value: 'mostrar'} : { title: 'Mostrar somente ativas', icon: 'mdi-credit-card-check', value: 'nao-mostrar'},
  ])

  function getOptions(creditCardMovements: TMovementCreditCard): TOptionAction [] {

    const options = [
      { title: 'Editar', value: "edit", icon: "mdi-circle-edit-outline" },
      { title: 'Excluir', value: "delete", icon: "mdi-delete-forever" },
      (creditCardMovements.status_movement === 'ativa' || creditCardMovements.status_movement === 'estornada') ? { title: 'Estornar', value: "estornar", icon: "mdi-arrow-u-left-bottom-bold" } : null,
    ]

    return options.filter(Boolean) as TOptionAction[]
  }

  function getStatusConfig(status: string | null | undefined) {
    return statusMovementConfig[status ?? ''] ?? { color: 'grey', icon: 'mdi-help-circle' }
  }

  const movementCreditCardData = computed(() => {
    if (!props.movementsCreditCard) return []

    return shoppingActive.value
    ? props.movementsCreditCard.filter(item => (item.status_movement !== 'deletada'))
    : props.movementsCreditCard
  })

  function handleShowShoopingActive(option: string) {
    shoppingActive.value = option === 'mostrar' ? false : true
  }

  function handleOptionClick(option: TOptionAction, data: TMovementCreditCard) {

    const raw = structuredClone(toRaw(data))

    if (raw.purchase_date === null) {
      notifyError("Error", "Data da compra ausente ou incorreta")
      return
    }

    const dateFormated = dateToDateOnly(raw.purchase_date)

    const payloadDeleteDraft = {
      ...raw,
      purchase_date: dateFormated,
      value_transaction: Number(raw.value_transaction ?? 0),
      categorie_id: Number(raw.categorie_id),
      dueDay: props.creditCard?.due_day
    }

    if (option.value === 'delete' && (data.type_recurrence === 'fixa' || data.type_recurrence === 'parcelada')) {
      console.log("Caiu aqui ?")
      modalDeleteRecurrence.value = true
      deleteDraft.value = payloadDeleteDraft
      return
    }

    if (option.value === 'edit' && (data.type_recurrence === 'fixa' || data.type_recurrence === 'parcelada')) {
      modalEditRecurrence.value = true
      const rawMovement = structuredClone(toRaw(data))
      editDraft.value = parseMovementCreditCardToEdit(rawMovement)
      return
    }

    if (option.value === 'delete') {
      modalDeleteMovement.value = true
      deleteDraft.value = payloadDeleteDraft
      return
    }

    if (option.value === 'estornar') {
      modalAddReversal.value = true
      const rawMovement = structuredClone(toRaw(data))
      editDraft.value = parseMovementCreditCardToEdit(rawMovement)
      return
    }

    if (option.value === 'edit') {
      modalEditMovement.value = true
      const rawMovement = structuredClone(toRaw(data))
      editDraft.value = parseMovementCreditCardToEdit(rawMovement)
      return
    }

  }

</script>

<template>
    <v-card
        rounded="xl"
        elevation="2"
        class="overflow-hidden"
    >
        <v-card-item class="pa-5 pb-0">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken-4">
                Lançamentos
            </v-card-title>

            <v-card-subtitle class="mt-1">
                Acompanhe as compras realizadas neste cartão.
            </v-card-subtitle>
        </v-card-item>

        <v-card-text class="pa-5">
            <v-text-field
                v-model="search"
                label="Pesquisar lançamento"
                prepend-inner-icon="mdi-magnify"
                variant="solo-filled"
                density="comfortable"
                hide-details
                single-line
                clearable
            >
                <template #append-inner>
                    <v-menu
                        transition="slide-y-transition"
                        offset="8"
                    >
                        <template #activator="{ props }">
                            <v-btn
                                v-bind="props"
                                color="primary"
                                icon="mdi-dots-vertical"
                                variant="text"
                            />
                        </template>

                        <v-list
                            density="comfortable"
                            class="pa-2"
                        >
                            <v-list-item
                                v-for="(item, index) in items"
                                :key="index"
                                :value="index"
                                :prepend-icon="item.icon"
                                rounded="lg"
                                @click="handleShowShoopingActive(item.value)"
                            >
                                <v-list-item-title>
                                    {{ item.title }}
                                </v-list-item-title>
                            </v-list-item>
                        </v-list>
                    </v-menu>
                </template>
            </v-text-field>
        </v-card-text>

        <v-divider />

        <v-data-table
            :headers="headers"
            :items="movementCreditCardData || []"
            :search="search"
            mobile-breakpoint="md"
            items-per-page="10"
        >
            <template #item.purchase_date="{ item }">
                {{ formatDate(item.purchase_date) }}
            </template>

            <template #item.value_transaction="{ item }">
                <v-chip :color="getStatusConfig(item.status_movement).color">
                    {{ formatCurrency(item.value_transaction) }}
                </v-chip>
            </template>

            <template #item.status_movement="{ item }">
                <v-icon
                    :color="getStatusConfig(item.status_movement).color"
                    :icon="getStatusConfig(item.status_movement).icon"
                />

                <v-tooltip
                    activator="parent"
                    location="top"
                >
                    {{ getStatusConfig(item.status_movement).text }}
                </v-tooltip>
            </template>

            <template #item.description_credit="{ item }">
                <div class="d-flex flex-column">
                    <span>
                        {{ item.description_credit }}

                        <span v-if="item.total_installments">
                            ({{ item.installment_number }} / {{ item.total_installments }})
                        </span>
                    </span>

                    <span
                        v-if="item.description_reversal"
                        class="text-error text-caption mt-1"
                    >
                        ↳ {{ item.description_reversal }}
                    </span>
                </div>
            </template>

            <template #item.actions="{ item }">
                <div
                    v-if="item.status_invoice === 'paga'"
                    class="d-flex align-center"
                >
                    <v-btn
                        icon="mdi-block-helper"
                        variant="text"
                        disabled
                    />

                    <v-tooltip text="Ação indisponível em faturas pagas">
                        <template #activator="{ props }">
                            <v-btn
                                v-bind="props"
                                icon="mdi-alert-circle"
                                variant="text"
                            />
                        </template>
                    </v-tooltip>
                </div>

                <v-menu
                    v-else
                    transition="slide-y-transition"
                    :disabled="item.status_movement === 'deletada'"
                >
                    <template #activator="{ props }">
                        <v-btn
                            v-bind="props"
                            icon="mdi-dots-vertical"
                            variant="text"
                        />
                    </template>

                    <v-list
                        density="comfortable"
                        class="pa-2"
                    >
                        <v-list-item
                            v-for="action in getOptions(item)"
                            :key="action.title"
                            :value="action.value"
                            :prepend-icon="action.icon"
                            rounded="lg"
                            @click="handleOptionClick(action, item)"
                        >
                            <v-list-item-title>
                                {{ action.title }}
                            </v-list-item-title>
                        </v-list-item>
                    </v-list>
                </v-menu>
            </template>
        </v-data-table>
    </v-card>

    <CardEditMovementCreditCard
        v-model="modalEditMovement"
        :draft="editDraft"
    />

    <CardAddReversal
        v-model="modalAddReversal"
        :draft="editDraft"
    />

    <CardDeleteMovementCreditCard
        v-model="modalDeleteMovement"
        :draft="deleteDraft"
        title="Deletar despesa de cartão?"
        text="Atenção: esta ação não pode ser desfeita."
        title-botton="Deletar"
        color-botton="primary"
    />

    <CardEditRecurrenceCreditCard
        v-model="modalEditRecurrence"
        :draft="editDraft"
    />

    <CardDeleteRecurrenceCreditCard
        v-model="modalDeleteRecurrence"
        :draft="deleteDraft"
    />
</template>

<style scoped>
:deep(.v-data-table-header__content) {
  font-weight: bold;
}
</style>