<script lang="ts" setup>
    import CurrencyInput from "~/components/ui/CurrencyInput.vue"
    import { useHttpCategories } from '~/composables/useHttp/useHttpCategories'
    import { useHttpCreditsCards } from "~/composables/useHttp/useHttpCreditCard"
    import { useHttpMovementCreditCard } from "~/composables/useHttp/useHttpMovementCreditCard.js"
    import { useHttpInvoices } from "~/composables/useHttp/useHttpInvoices.js"
    import { useValidateSchemas } from "~/composables/useValidateSchema"
    import { useValidateFields } from "~/composables/useValidateFields"
    import { useInvalidate } from "~/composables/useInvalidate"
    import CardAddCategorie from '~/components/forms/CardAddCategorie.vue'
    import type { TMovementCreditCard } from "~~/types/credit_card/TMovementCreditCard"
    import type { TRecurrence } from "~~/types/recurrence/TRecurrence"
    import { useRecurrenceStore } from "~~/store/modules/recurrence-store"
    import CardAddCreditCard from "./CardAddCreditCard.vue"
    import type { TCreditCard } from "~~/types/credit_card/TCredit-card.js"
    import BaseModal from "../ui/BaseModal.vue"
    

    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    const { getCategoriesOnlyActive } = useHttpCategories()
    const { getCreditCardOnlyActive } = useHttpCreditsCards()
    const { validateSchemaMovementsCreditCard } = useValidateSchemas()
    const { postMovementCreditCard } = useHttpMovementCreditCard()
    const { getNextOpenPeriod } = useHttpInvoices()
    const { invalidate } = useInvalidate()
    const { nameRules, selectRules, dateRules, currencyRules } = useValidateFields()

    const recurrenceStore = useRecurrenceStore()

    const { data:categories } = useQuery({
      queryKey: QUERY_KEYS.categories.active,
      queryFn: getCategoriesOnlyActive,
    })

    const { data:creditCardOnlyActive, isPending } = useQuery({
      queryKey: QUERY_KEYS.creditCards.all,
      queryFn: getCreditCardOnlyActive,
    })

    const emit = defineEmits<{
      success: []
    }>()

    const form = ref()
    const modelValue = defineModel<boolean>()
    const modelInvoice = ref<number | null>(null)
    const menuCreditCard = ref(false)
    const modelCreditCard = ref<number | null>(null)
    const menuCategorias = ref(false)
    const modelCategorias = ref<number | null>(null)
    const searchCategorias = ref("")
    const modalAddCategorie = ref(false)
    const modalAddCreditCard = ref(false)
    const modalHelpInvoice = ref(false)
    const showInputParcelado = ref("")
    const showInputFixa = ref("")
    const showSwitch = ref(false)
    const creditCardData = ref<TCreditCard | null>(null)
    const date = ref('')
    const menu = ref(false)
    const updateInvoiceAutomatically = ref(false)

    const movementCreditCardForm = ref<TMovementCreditCard>({
      credit_card_id: null,
      invoice_id: null,
      accounts_id: null,
      categorie_id: null,
      description_credit: "",
      value_transaction: 0.00,
      purchase_date: new Date(),
      observation: "",
      status_movement: "ativa",
      invoice_month: null,
      invoice_year: null,
      refund_of_movement_id: null,
      description_reversal: null,
      status_invoice: null,
      type_recurrence: null
    })

    const recorrenceForm = ref<TRecurrence>({
      value_recurrence: 0.00,
      description_recurrence: "",
      accounts_id: null,
      categorie_id: null,
      type_recurrence: "",
      frequency_recurrence: "Meses",
      total_installments: 2,
      day_maturity: null,
      is_active: true
    })

    watch(() => [
      movementCreditCardForm.value.value_transaction,
      movementCreditCardForm.value.description_credit,
      movementCreditCardForm.value.categorie_id,
      movementCreditCardForm.value.purchase_date,
      modelCreditCard
      ] as const, ([value, description, categorie, purchase_date]) => {
      recorrenceForm.value.value_recurrence = value 
      recorrenceForm.value.description_recurrence = description
      recorrenceForm.value.categorie_id = categorie
      recorrenceForm.value.day_maturity = purchase_date
    }, {immediate: true}) 

    watch(showInputFixa, (newVal) => {
      if (newVal === 'fixa') {
        showInputParcelado.value = ""
        showSwitch.value = true
        recorrenceForm.value.type_recurrence = newVal
      } else if (newVal === 'avista') {
        showSwitch.value = false
      }
    })

    watch(showInputParcelado, (newVal) => {
      if (newVal === 'parcelada') {
        showInputFixa.value = ""
        showSwitch.value = true
        recorrenceForm.value.type_recurrence = newVal
      } else if (newVal === 'unica') {
        showInputParcelado.value = ""
        showSwitch.value = false
      }
    })

    watch(menuCategorias, (val) => {
      if (!val) searchCategorias.value = ""
    })

    watch(modelCategorias, (val) => {
      if (!val) searchCategorias.value = ""
      movementCreditCardForm.value.categorie_id = val
    })

    watch(creditCardData, (val) => {
      movementCreditCardForm.value.accounts_id = val?.accounts_id ?? null
    })

    watch(modelCreditCard, async (val) => {
      movementCreditCardForm.value.credit_card_id = val

      const selectCard = creditCardOnlyActive.value?.find(
        card => card.id === val
      )

      if (selectCard) {
        creditCardData.value = selectCard
        await updateSuggestedInvoice()
      }

    })

    const filterCategorias = computed(() => {
      return categories.value?.filter(item => item.name_identifier.toLowerCase().includes(searchCategorias.value.toLowerCase()))
    })
    
    function closeModalHelpInvoice() {
      modalHelpInvoice.value = false
    }

    function resetForm() {
      showInputFixa.value = ""
      showInputParcelado.value = ""
      recorrenceForm.value.frequency_recurrence = ""
      recorrenceForm.value.total_installments = 2
      recorrenceForm.value.frequency_recurrence = "Meses"
      modelCategorias.value = null
      modelInvoice.value = null
      modelCreditCard.value = null
      movementCreditCardForm.value.categorie_id = null
      movementCreditCardForm.value.description_credit = ""
      movementCreditCardForm.value.observation = ""
      movementCreditCardForm.value.value_transaction = 0.00
      movementCreditCardForm.value.purchase_date = new Date()
      date.value = `${String(new Date().getFullYear())}-${String(new Date().getMonth() + 1)}`
      showSwitch.value = false
    }

    function resetFormAndCloseModal() {
      showInputFixa.value = ""
      showInputParcelado.value = ""
      recorrenceForm.value.frequency_recurrence = ""
      recorrenceForm.value.total_installments = 2
      recorrenceForm.value.frequency_recurrence = "Meses"
      modelCategorias.value = null
      modelInvoice.value = null
      modelCreditCard.value = null
      movementCreditCardForm.value.categorie_id = null
      movementCreditCardForm.value.description_credit = ""
      movementCreditCardForm.value.observation = ""
      movementCreditCardForm.value.value_transaction = 0.00
      movementCreditCardForm.value.purchase_date = new Date()
      date.value = `${String(new Date().getFullYear())}-${String(new Date().getMonth() + 1)}`
      showSwitch.value = false
      modelValue.value = false
    }

    function handleOpenModalAddCategorie() {
      modalAddCategorie.value = true
    }

    function handleOpenModalAddCreditCard() {
      modalAddCreditCard.value = true
    }

    function salveCreditCardDate(data: TCreditCard) {
      creditCardData.value = data
    }

    async function updateSuggestedInvoice() {
      const purchaseDate = movementCreditCardForm.value.purchase_date
      const closingDay = creditCardData.value?.closing_day
      const cardId = creditCardData.value?.id

      if (!purchaseDate || !closingDay || !cardId){
        return
      }

      const result = calculateInvoiceMonth(
        new Date(purchaseDate),
        closingDay ?? 0
      )

      let finalMonth = result.month
      let finalYear = result.year

      try {
        const nextOpenPeriod = await getNextOpenPeriod(cardId ?? 0)

        //Aqui seria uma conversão para meu front-end
        //Pois no front os meses se iniciam em 0-11, e o back trabalha com 1-12
        //Caso não existisse conversão, a conversão iria ficar sempre um mês a frente
        const suggestedMonthZeroBased = finalMonth 

        const suggestedIsBeforeOpen = 
          finalYear < nextOpenPeriod.year ||
          (finalYear === nextOpenPeriod.year && suggestedMonthZeroBased < nextOpenPeriod.month)

          if (suggestedIsBeforeOpen) {
            finalMonth = nextOpenPeriod.month 
            finalYear = nextOpenPeriod.year
          }

      } catch {

      }

      updateInvoiceAutomatically.value = true

      date.value = `${finalYear}-${String(finalMonth).padStart(2, "0")}`

      nextTick(() => {
        updateInvoiceAutomatically.value = false
      })
    }

    
    watch(() => movementCreditCardForm.value.purchase_date, () => {
      updateSuggestedInvoice()
    })

    function handleInvoiceManualChange() {
      if (updateInvoiceAutomatically.value) {
        return
      }

      menu.value = false
    }

    const { mutate:mutateMovements, isPending:isPendingMovements  } = useMutation({

      mutationFn: postMovementCreditCard,

      onSuccess: () => {
        invalidate(QUERY_KEYS.movementsCreditCard.byCreditCard)
        invalidate(QUERY_KEYS.movementsCreditCard.totalInvoice)
        invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
        invalidate(QUERY_KEYS.dashboard.expenseByCategorie)
        invalidate(QUERY_KEYS.dashboard.renevueByCategorie)
        invalidate(QUERY_KEYS.dashboard.sumary)
        invalidate(QUERY_KEYS.dashboard.balanceEvolution)
        invalidate(QUERY_KEYS.dashboard.lastMovements)
        invalidate(QUERY_KEYS.dashboard.cards)
        notifySuccess("Sucesso", "Operação realizada com sucesso", 6000)
        resetForm()
        emit("success")
      },

      onError: (error) => {
        handleErrorApplication(error.statusCode)
      },

    })

  async function submitMovement(options: {closeAfterSave: boolean}) {

    if (!movementCreditCardForm.value.purchase_date) {
      notifyError(
        "Data inválida",
        "Não foi possível concluir a ação porque a data informada é inválida ou está ausente.",
      )
      return
    }

    if (!movementCreditCardForm.value.credit_card_id ) {
      notifyInfo(
        "Cartão de crédito inválido",
        "Não foi possível concluir a ação porque o cartão de crédito informado é inválido ou está ausente.",
        6000
      )
      return
    }

    if (!recorrenceForm.value.total_installments) {
      notifyError(
        "Total de parcelas inválido",
        "Não foi possível concluir a ação porque o total de parcela é inválido ou está ausente.",
      )
      return
    }

    if (recorrenceForm.value.total_installments >= 100) {
      notifyError("Atenção", "A quantidade de parcelas não pode exceder 100.", 7000)
      return
    }

    const dateFormated = dateToDateOnly(movementCreditCardForm.value.purchase_date)

    const [year, month] = date.value.split("-").map(Number)

    try {
      const { valid } = await form.value.validate()

      if (valid) {

        const movementsCrediCardPayload = {
          ...movementCreditCardForm.value,
          purchase_date: dateFormated,
          credit_cards_id: modelCreditCard.value,
          closingDay: creditCardData.value?.closing_day,
          dueDay: creditCardData.value?.due_day,
          invoice_month: month,
          invoice_year: year,
        }

        const recurrencePayload = {
          ...recorrenceForm.value,
          day_maturity: movementCreditCardForm.value.purchase_date
        }

        const movementCreditCardFormated = {
          ...movementCreditCardForm.value,
          invoice_month: month ?? null,
          invoice_year: year ?? null,
          dueDay: creditCardData.value?.due_day
        }

        const resultSchema = validateSchemaMovementsCreditCard(movementsCrediCardPayload)
        if (!resultSchema.success) return

        if (showInputFixa.value || showInputParcelado.value) {
          await recurrenceStore.movementsCreditCardFormated(movementCreditCardFormated, recurrencePayload)
          invalidate(QUERY_KEYS.movementsCreditCard.byCreditCard)
          invalidate(QUERY_KEYS.movementsCreditCard.totalInvoice)
          invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
          invalidate(QUERY_KEYS.dashboard.expenseByCategorie)
          invalidate(QUERY_KEYS.dashboard.renevueByCategorie)
          invalidate(QUERY_KEYS.dashboard.sumary)
          invalidate(QUERY_KEYS.dashboard.balanceEvolution)
          invalidate(QUERY_KEYS.dashboard.lastMovements)
          invalidate(QUERY_KEYS.dashboard.cards)
          notifySuccess("Sucesso", "Operação realizada com sucesso", 6000)
          emit("success")
        } else {
          mutateMovements(resultSchema.data)
        } 

        resetForm()
          if (options.closeAfterSave) {
            modelValue.value = false
          }
        }

    } catch (err) {
      notifyError("Erro", "Ocorreu um erro ao validar o formulário. Por favor, tente novamente.", 6000)
    } 

  }


</script>

<template>


  <div class="text-center">
    <v-form
    @submit.prevent
    ref="form"
    validate-on="lazy blur"
    >
      <v-dialog v-model="modelValue" max-width="750">
        <v-card rounded="lg" elevation="8">
          <v-card-item class="pa-4 pb-2">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken-4">
              Nova despesa
            </v-card-title>

            <v-card-subtitle class="mt-1">
              Registre uma nova saída para acompanhar sua vida financeira.
            </v-card-subtitle>

            <template #prepend>
              <v-avatar color="red" variant="tonal" rounded="lg">
                <v-icon icon="mdi-bank-plus" color="red"/>
              </v-avatar>
            </template>
          </v-card-item>
          <v-divider></v-divider>
          <v-card-text>
            <v-row density="comfortable">
              <v-col
               cols="12" md="6" sm="12"
              >
              <CurrencyInput variant="solo-filled" prepend-inner-icon="mdi-cash" :rules="currencyRules" autocomplete="off" label="Valor*" v-model="movementCreditCardForm.value_transaction" />
              </v-col>

              <v-col
              cols="12" md="6" sm="12"
              >
              <v-date-input prepend-inner-icon="mdi-calendar" prepend-icon="" :rules="dateRules" autocomplete="off" name="date" label="Data*" variant="solo-filled"" v-model="movementCreditCardForm.purchase_date"></v-date-input>
              </v-col>
              
              <v-col
              cols="12" md="12" sm="12"
              >
              <v-text-field prepend-inner-icon="mdi-pencil"  prepend-icon="" :rules="nameRules" :counter="45" maxlength="45"  autocomplete="name" name="name" label="Descrição*" variant="solo-filled"" v-model="movementCreditCardForm.description_credit"></v-text-field>
              </v-col>

              <v-col
              cols="12" md="12" sm="12"
              >
              <v-select
                autocomplete="off"
                :loading="isPendingMovements"
                v-model="modelCategorias"
                v-model:menu="menuCategorias"
                :items="filterCategorias"
                item-title="name_identifier"
                item-value="id"
                variant="solo-filled"
                label="Categoria*"
                persistent-hint
                :rules="selectRules"
                prepend-inner-icon="mdi-shape"
                clearable
                >
                  <template #append-inner>
                    <v-tooltip
                    activator="parent"
                    location="top"
                    >Nova categoria</v-tooltip>
                    <v-icon @click.stop="handleOpenModalAddCategorie" class="button-hover" icon="mdi-plus-box"></v-icon>
                  </template>
                  
                  <template v-slot:selection="{item}">
                    <v-avatar style="width: 30px; height: 30px; margin-right: 12px;"> 
                      <v-avatar :icon="item.url_icon"></v-avatar>
                    </v-avatar>
                    <span>{{ item.name_identifier }}</span>
                  </template>

                  <template v-slot:item="{props, item}">
                    <v-list-item v-bind="props">
                      <template v-slot:prepend>
                        <v-avatar :icon="item.url_icon"></v-avatar>
                      </template>
                    </v-list-item>
                  </template>

                  <template v-slot:prepend-item>
                    <div class="pa-2 border-b">
                      <v-text-field
                        v-model="searchCategorias"
                        :error="!!searchCategorias && !filterCategorias?.length"
                        density="compact"
                        placeholder="Buscar..."
                        prepend-inner-icon="mdi-magnify"
                        variant="outlined"
                        @click.stop
                        @keydown.stop
                        @mousedown.stop
                        hide-details="auto"
                      >                 
                    </v-text-field>
                    </div>
                  </template>
                </v-select>
              </v-col>

              <v-col
              cols="12" md="12" sm="12"
              >
              <v-select
                autocomplete="off"
                :loading="isPendingMovements"
                v-model="modelCreditCard"
                v-model:menu="menuCreditCard"
                :items="creditCardOnlyActive"
                item-title="name_identifier"
                item-value="id"
                variant="solo-filled"
                label="Cartão de crédito*"
                persistent-hint
                :rules="selectRules"
                prepend-inner-icon="mdi-credit-card"
                clearable
                >
                  <template #append-inner>
                    <v-tooltip
                    activator="parent"
                    location="top"
                    >Novo cartão de crédito</v-tooltip>
                    <v-icon @click.stop="handleOpenModalAddCreditCard" class="button-hover" icon="mdi-plus-box"></v-icon>
                  </template>
                  
                  <template v-slot:selection="{item}">
                    <v-avatar style="width: 30px; height: 30px; margin-right: 12px;"> 
                      <v-avatar :image="item.url_logo" ></v-avatar>
                    </v-avatar>
                    <span>{{ item.name_identifier }}</span>
                  </template>

                  <template v-slot:item="{props, item}">
                    <v-list-item @click="salveCreditCardDate(item)" v-bind="props">
                      <template v-slot:prepend>
                        <v-avatar :image="item.url_logo" ></v-avatar>
                      </template>
                    </v-list-item>
                  </template>
                </v-select>
              </v-col>

                <v-col
                cols="12" md="12" sm="12"
                >
                  <v-text-field prepend-inner-icon="mdi-note-text" v-model="movementCreditCardForm.observation" :counter="100" maxlength="100" autocomplete="off" label="Observação" variant="solo-filled"></v-text-field >
                </v-col>

                
              <v-col cols="12" md="12" sm="12">
                  <v-menu
                      v-model="menu"
                      :close-on-content-click="false"
                      min-width="auto"
                      transition="scale-transition"
                      >
                      <template v-slot:activator="{ props: activatorProps }">
                          <v-text-field
                          v-model="date"
                          label="Fatura (Selecione um cartão)"
                          prepend-inner-icon="mdi-calendar"
                          hide-details
                          readonly
                          v-bind="activatorProps"
                          variant="solo-filled"
                          >
                          <template #append-inner>
                            <v-icon @click.stop="modalHelpInvoice = true" v-tooltip="'Sugestão de fatura'" style="cursor: pointer;" icon="mdi-help-circle"></v-icon>
                          </template>
                          </v-text-field>
                      </template>
                      <v-month-picker
                        v-model="date"
                        @update:model-value="handleInvoiceManualChange"
                      >
                    </v-month-picker>
                  </v-menu>
                </v-col>
                
            <small class="text-caption text-medium-emphasis"
              >* Indica campos obrigatórios</small
            >

                <v-col cols="12">

                  <v-sheet border rounded="lg" class="pa-4 mb-3">
                  <div class="text-body-2 font-weight-bold text-blue-grey-darken-3 mb-3">
                    Opções da despesa
                  </div>

                  <v-row>
                    <v-col cols="12" sm="6" md="4">
                      <v-switch
                        v-model="showInputFixa"
                        color="error"
                        label="Despesa fixa"
                        hide-details
                        false-value="avista"
                        true-value="fixa"
                        true-icon="mdi-pin"
                        false-icon="mdi-close"
                      ></v-switch> 
                    </v-col>

                    <v-col cols="12" sm="6" md="4">
                      <v-switch
                        v-model="showInputParcelado"
                        color="error"
                        label="Despesa parcelada"
                        hide-details
                        false-value="unica"
                        true-value="parcelada"
                        true-icon="mdi-repeat"
                        false-icon="mdi-close"
                      ></v-switch> 
                    </v-col>

                    <div class="d-flex align-center">
                      <v-tooltip location="top" open-on-click>
                        <template v-slot:activator="{ props }">
                            <v-icon v-bind="props" icon="mdi-help-circle" size="25" class="ml-1" style="cursor: pointer;"></v-icon>
                        </template>
                        Ao marcar como fixa, serão geradas as próximas 12 ocorrências, para melhor previsibilidade e controle. Após esse período, você poderá renovar a recorrência.
                      </v-tooltip>
                    </div>

                    </v-row>
                  </v-sheet>

                </v-col>

                <v-col
                  cols="12" md="6" sm="6" 
                  >
                  <v-number-input
                  v-if="showInputParcelado"
                  v-model="recorrenceForm.total_installments"
                  variant="solo-filled"
                  controlVariant="default"
                  :min="2"
                  :max="100"
                  label="Número de parcelas*"
                  :hideInput="false"
                  inset
                ></v-number-input>
                </v-col>

                <v-col
                  cols="12" md="6" sm="6" 
                  >
                  <v-select
                  v-if="showInputParcelado"
                  v-model="recorrenceForm.frequency_recurrence"
                  label="Periodicidade*"
                  :items="['Meses']"
                  variant="solo-filled"
                  readonly
                ></v-select>
                </v-col>

            </v-row>

          </v-card-text>

          <v-divider></v-divider>

          <v-card-actions class="pa-4 d-flex flex-wrap ga-2">
            <v-btn
              class="text-none"
              text="Fechar"
              variant="text"
              rounded="lg"
              @click="resetFormAndCloseModal"
            ></v-btn>
            <v-spacer></v-spacer>
            <v-btn
              class="text-none"
              value="btn-criar"
              color="primary"
              text="Salvar e criar nova"
              variant="outlined"
              rounded="lg"
              :loading="isPendingMovements"
              @click="submitMovement({closeAfterSave: false})"
            ></v-btn>
            <v-btn
              class="text-none"
              value="btn-salvar"
              color="primary"
              text="Salvar"
              rounded="lg"
              variant="flat"
              :loading="isPendingMovements"
              @click="submitMovement({closeAfterSave: true})"
            ></v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-form>

    <div style="position: absolute;">
      <CardAddCategorie v-model="modalAddCategorie"/>
      <CardAddCreditCard v-model="modalAddCreditCard" />
    </div>
    <div>
      <BaseModal @close-modal="closeModalHelpInvoice" title="Sobre a sugestão de fatura" :model-value="modalHelpInvoice">
        <div class="pa-4">
          <v-alert
              type="info"
              variant="tonal"
              rounded="lg"
              border="start"
              density="comfortable"
          >
              A fatura é sugerida automaticamente com base na data da compra
              e no fechamento do cartão. Se a fatura sugerida já estiver
              fechada, o sistema aponta a próxima fatura em aberto.
          </v-alert>
        </div>
      </BaseModal>
    </div>

  </div>
</template>

<style  scoped>

.icon-add-logo:hover {
  background-color: rgba(128, 128, 128, 0.562);
  border-radius: 60%;
}

.button-hover:hover {
  background-color: rgba(255, 255, 255, 0.418);
  transform: scale(1.1); /* Efeito de zoom */
  transition: 0.3s; /* Transição suave */
}

@media (max-width: 680px) {
  .options-footer {
    flex-direction: column;
  }
}

</style>
