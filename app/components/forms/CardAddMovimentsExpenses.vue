<script lang="ts" setup>

  import CurrencyInput from "~/components/ui/CurrencyInput.vue"
  import { useHttpCategories } from '~/composables/useHttp/useHttpCategories'
  import { useHttpAccounts } from "~/composables/useHttp/useHttpAccounts"
  import { useHttpMovements } from "~/composables/useHttp/useHttpMovements"
  import { useValidateSchemas } from "~/composables/useValidateSchema"
  import { useValidateFields } from "~/composables/useValidateFields"
  import { useInvalidate } from "~/composables/useInvalidate"
  import CardAddCategorie from '~/components/forms/CardAddCategorie.vue'
  import CardAddAccount from "~/components/forms/CardAddAccount.vue"
  import type { TMovements } from "~~/types/movements/TMovements"
  import type { TRecurrence } from "~~/types/recurrence/TRecurrence"
  import { useRecurrenceStore } from "~~/store/modules/recurrence-store"

  const { notifyError, notifyInfo, notifySuccess } = useNotify()
  const { getCategoriesOnlyActive } = useHttpCategories()
  const { getAccountsOnlyActive } = useHttpAccounts()
  const { validateSchemaMovements } = useValidateSchemas()
  const { postMovements } = useHttpMovements()
  const { invalidate } = useInvalidate()
  const { nameRules, selectRules, dateRules, currencyRules } = useValidateFields()
  const recurrenceStore = useRecurrenceStore()

  const { data:categories } = useQuery({
    queryKey: QUERY_KEYS.categories.active,
    queryFn: getCategoriesOnlyActive,
  })

  const { data:accounts } = useQuery({
    queryKey: QUERY_KEYS.accounts.active,
    queryFn: getAccountsOnlyActive,
  })

  const props = defineProps<{
    draft?: Partial<TMovements> | null
  }>()

  const emit = defineEmits<{
    success: []
  }>()

  const form = ref()
  const modelValue = defineModel<boolean>()
  const menuCategorias = ref(false)
  const modelCategorias = ref<number | null>(null)
  const searchCategorias = ref("")
  const searchAccounts = ref("")
  const modelAccounts = ref<number | null>(null)
  const menuAccounts = ref(false)
  const modalAddCategorie = ref(false)
  const modalAddAccount = ref(false)
  const labelSwitch = ref("Despesa paga")
  const showInputParcelado = ref("")
  const showInputFixa = ref("")
  const showSwitch = ref(false)

  const movementsForm = ref<TMovements>({
    type_transaction: "despesa",
    value_transaction: 0.00,
    date_transaction: new Date(),
    description_transaction: "",
    categorie_id: null,
    accounts_id: null,
    status_transaction: "pago"
  })

  const recorrenceForm = ref<TRecurrence>({
    value_recurrence: 0.00,
    description_recurrence: "",
    accounts_id: null,
    categorie_id: null,
    type_recurrence: null,
    frequency_recurrence: "Dias",
    total_installments: 2,
    day_maturity: null,
    is_active: true
  })

    watch(() => [
    movementsForm.value.value_transaction,
    movementsForm.value.description_transaction,
    movementsForm.value.accounts_id,
    movementsForm.value.categorie_id,
    movementsForm.value.date_transaction
  ] as const, ([value, description, account, categorie, matury]) => {
    recorrenceForm.value.value_recurrence = value 
    recorrenceForm.value.description_recurrence = description
    recorrenceForm.value.accounts_id = account
    recorrenceForm.value.categorie_id = categorie
    recorrenceForm.value.day_maturity = matury 
  }, {immediate: true}) 

  watch(showInputFixa, (newVal) => {
    if (newVal === 'fixa') {
      showInputParcelado.value = ""
      labelSwitch.value = "Despesa pendente"
      movementsForm.value.status_transaction = "pendente"
      showSwitch.value = true
      recorrenceForm.value.type_recurrence = newVal
    } else if (newVal === 'avista') {
      labelSwitch.value = "Despesa recebida"
      movementsForm.value.status_transaction = "pago"
      showSwitch.value = false
    }
  })

  watch(showInputParcelado, (newVal) => {
    if (newVal === 'parcelada') {
      showInputFixa.value = ""
      labelSwitch.value = "Receita pendente"
      movementsForm.value.status_transaction = "pendente"
      showSwitch.value = true
      recorrenceForm.value.type_recurrence = newVal
    } else if (newVal === 'unica') {
      showInputParcelado.value = ""
      labelSwitch.value = "Receita recebida"
      movementsForm.value.status_transaction = "recebido"
      showSwitch.value = false
    }
  })

  watch(() => props.draft, (val) => {
    if (val?.accounts_id) {
      modelAccounts.value = val.accounts_id
    }
  }, {immediate: true})

  watch(menuCategorias, (val) => {
    if (!val) searchCategorias.value = ""
  })

  watch(modelAccounts, (val) => {
    if (!val) searchAccounts.value = ""
    movementsForm.value.accounts_id = val
  })

  watch(modelCategorias, (val) => {
    if (!val) searchAccounts.value = ""
    movementsForm.value.categorie_id = val
  })

  watch(menuAccounts, (val) => {
    if (!val) searchAccounts.value = ""
  })

  watch(movementsForm.value, (val) => {

    if (val.status_transaction === 'pago') {
      labelSwitch.value = "Despesa paga"
    } else if (val.status_transaction === "pendente") {
      labelSwitch.value = "Despesa pendente"
    }

  })

  const filterCategorias = computed(() => {
    return categories.value?.filter(item => item.name_identifier.toLowerCase().includes(searchCategorias.value.toLowerCase()))
  })

  const filterAccounts = computed(() => {
    return accounts.value?.filter(item => item.name_identifier.toLowerCase().includes(searchAccounts.value?.toLowerCase() ?? ''))
  })

  function resetForm() {
    showInputFixa.value = ""
    showInputParcelado.value = ""
    recorrenceForm.value.frequency_recurrence = ""
    recorrenceForm.value.total_installments = 2
    modelAccounts.value = null
    modelCategorias.value = null
    movementsForm.value.accounts_id = null
    movementsForm.value.categorie_id = null
    movementsForm.value.description_transaction = ""
    movementsForm.value.observation = ""
    movementsForm.value.value_transaction = 0.00
    movementsForm.value.url_recibo = ""
    movementsForm.value.status_transaction = "pago"
    movementsForm.value.date_transaction = new Date()
    showSwitch.value = false
  }

  function resetFormAndCloseModal() {
    showInputFixa.value = ""
    showInputParcelado.value = ""
    recorrenceForm.value.frequency_recurrence = ""
    recorrenceForm.value.total_installments = 2
    modelAccounts.value = null
    modelCategorias.value = null
    movementsForm.value.accounts_id = null
    movementsForm.value.categorie_id = null
    movementsForm.value.description_transaction = ""
    movementsForm.value.observation = ""
    movementsForm.value.value_transaction = 0.00
    movementsForm.value.url_recibo = ""
    movementsForm.value.status_transaction = "pago"
    movementsForm.value.date_transaction = new Date()
    showSwitch.value = false
    modelValue.value = false
  }

  function handleOpenModalAddCategorie() {
    modalAddCategorie.value = true
  }

  function handleOpenModalAddAccount() {
    modalAddAccount.value = true
  }

  const  { mutate, isPending  } = useMutation({
    
    mutationFn: postMovements,

    onSuccess: () => {
      invalidate(QUERY_KEYS.accounts.all)
      invalidate(QUERY_KEYS.movements.all)
      invalidate(QUERY_KEYS.movements.only_expenses)
      invalidate(QUERY_KEYS.movements.current_balance)
      invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
      invalidate(QUERY_KEYS.dashboard.expenseByCategorie)
      invalidate(QUERY_KEYS.dashboard.renevueByCategorie)
      invalidate(QUERY_KEYS.dashboard.sumary)
      invalidate(QUERY_KEYS.dashboard.balanceEvolution)
      invalidate(QUERY_KEYS.dashboard.expenseByThreeMonths)
      invalidate(QUERY_KEYS.dashboard.lastMovements)
      invalidate(QUERY_KEYS.dashboard.cards)
      notifySuccess("Sucesso", "Despesa lançada com sucesso", 6000)
      resetForm()
      emit("success")
    },

    onError: (error) => {
     handleErrorApplication(error.statusCode)
    },

  })

  async function submitMovement(options: {closeAfterSave: boolean}) {
  
    if (!movementsForm.value.date_transaction) {
      notifyError(
        "Data inválida",
        "Não foi possível concluir a ação porque a data informada é inválida ou está ausente.",
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
    
    const dateFormated = dateToDateOnly(movementsForm.value.date_transaction)

    try {

      const { valid } = await form.value.validate()

      if (valid) {

        const movementsPayload = {
          ...movementsForm.value,
          date_transaction: dateFormated
        }

        const recurrencePayload = {
          ...recorrenceForm.value,
          day_maturity: movementsForm.value.date_transaction
        }

        const resultSchema = validateSchemaMovements(movementsPayload)
        
        if (!resultSchema.success) return

        if (showInputFixa.value || showInputParcelado.value) {
          await recurrenceStore.movementsFormated(movementsForm.value, recurrencePayload)
          invalidate(QUERY_KEYS.movements.all)
          invalidate(QUERY_KEYS.movements.only_expenses)
          invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
          invalidate(QUERY_KEYS.dashboard.expenseByCategorie)
          invalidate(QUERY_KEYS.dashboard.renevueByCategorie)
          invalidate(QUERY_KEYS.dashboard.sumary)
          invalidate(QUERY_KEYS.dashboard.balanceEvolution)
          invalidate(QUERY_KEYS.dashboard.lastMovements)
          invalidate(QUERY_KEYS.dashboard.cards)
          invalidate(QUERY_KEYS.dashboard.expenseByThreeMonths)
          notifySuccess("Sucesso", "Despesa lançada com sucesso", 6000)
          emit("success")
        } else {
          mutate(resultSchema.data)
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
      <v-dialog v-model="modelValue" max-width="700">
        <v-card  rounded="lg" elevation="8">
            <v-card-item class="pa-4 pb-2">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
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
            <v-row >

              <v-col
               cols="12" md="6" sm="12"
              >
              <CurrencyInput variant="solo-filled" prepend-inner-icon="mdi-cash" input-color="#C62828" base-color="#C62828" color="#C62828" :rules="currencyRules"  autocomplete="off" label="Valor*" v-model="movementsForm.value_transaction" />
              </v-col>
            
              <v-col
              dens cols="12" md="6" sm="12"
              >
              <v-date-input prepend-inner-icon="mdi-calendar" prepend-icon="" :rules="dateRules" autocomplete="off" name="date" label="Data*" variant="solo-filled" v-model="movementsForm.date_transaction"></v-date-input>
              </v-col>

              <v-col
              dens cols="12" md="6" sm="12"
              >
              <v-text-field prepend-inner-icon="mdi-pencil" :rules="nameRules" :counter="45" maxlength="45"  autocomplete="name" name="name" label="Descrição*" variant="solo-filled" v-model="movementsForm.description_transaction"></v-text-field>
              </v-col>

              <v-col
              dens cols="12" md="6" sm="12"
              >
              <v-select
                v-model="modelAccounts"
                v-model:menu="menuAccounts"
                :items="filterAccounts"
                :rules="selectRules"
                item-title="name_identifier"
                item-value="id"
                variant="solo-filled"
                label="Conta*"
                hint="O valor será debitado desta conta"
                persistent-hint
                autocomplete="off"
                prepend-inner-icon="mdi-bank"
                  >
                  <template #append-inner>
                    <v-tooltip
                    activator="parent"
                    location="top"
                    >Nova conta</v-tooltip>
                    <v-icon @click.stop="handleOpenModalAddAccount"  class="button-hover" icon="mdi-plus-box"></v-icon>
                  </template>

                  <template v-slot:selection="{item}">
                    <v-avatar style="width: 25px; height: 24px; margin-right: 12px;"> 
                      <v-img  :src="item.url_image" :alt="item.name_identifier"></v-img>
                    </v-avatar>
                    <span >{{ item.name_identifier }}</span>
                  </template>

                  <template v-slot:item="{props, item}">
                    <v-list-item  v-bind="props">
                      <template v-slot:prepend>
                        <v-avatar>
                          <v-img :src="item.url_image" :alt="item.name_identifier"></v-img>
                        </v-avatar>
                      </template>
                    </v-list-item>
                  </template>

                  <template v-slot:prepend-item>
                    <div class="pa-2 border-b">
                      <v-text-field
                        v-model="searchAccounts"
                        :error="!!searchAccounts && !filterAccounts?.length"
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
                dens cols="12" md="12" sm="12"
                >
                <v-select
                autocomplete="off"
                :loading="isPending"
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
                dens cols="12" md="12" sm="12"
                >
                <v-text-field prepend-inner-icon="mdi-note-text" v-model="movementsForm.observation" :counter="100" maxlength="100" autocomplete="off" label="Observação" variant="solo-filled"></v-text-field>
                </v-col>

                <v-col cols="12">
                <v-sheet border rounded="lg" class="pa-4 mb-3">
                  <div class="text-body-2 font-weight-bold text-blue-grey-darken-3 mb-3">
                    Opções da receita
                  </div>

                  <v-row>
                    <v-col cols="12" sm="6" md="4">
                      <v-switch
                        :disabled="showSwitch"
                        v-model="movementsForm.status_transaction"
                        color="error"
                        :label="labelSwitch"
                        hide-details
                        false-value="pendente"
                        true-value="pago"
                        true-icon="mdi-check"
                        false-icon="mdi-close"
                    ></v-switch> 
                    </v-col>

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

                    <v-col cols="12" sm="6" md="4" class="d-flex align-center">
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

                    <v-tooltip location="top">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-help-circle-outline"
                          variant="text"
                          size="small"
                        />
                      </template>
                      Ao marcar como fixa, serão geradas as próximas 12
                      ocorrências. Você poderá renovar a recorrência após esse
                      período.
                    </v-tooltip>

                    </v-col>

                    </v-row>
                    
                  </v-sheet>
                  </v-col>

                  <v-col
                    cols="12" md="6"
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
                    cols="12" sm="6"
                    >
                    <v-select
                    v-if="showInputParcelado"
                    v-model="recorrenceForm.frequency_recurrence"
                    label="Selecione a periodicidade*"
                    :items="['Dias', 'Semanas', 'Meses', 'Anos']"
                    variant="solo-filled"
                    ></v-select>
                  </v-col>

              </v-row>
            <small class="text-caption text-medium-emphasis">* Indica campos obrigatórios</small>
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
             <v-spacer />
            <v-btn
              class="text-none"
              color="red"
              text="Salvar e criar nova"
              variant="outlined"
              :loading="isPending"
              rounded="lg"
              @click="submitMovement({closeAfterSave: false})"
            ></v-btn>

            <v-btn
              class="text-none"
              color="red"
              text="Salvar"
              variant="flat"
              rounded="lg"
              :loading="isPending"
              @click="submitMovement({closeAfterSave: true})"
            ></v-btn>

          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-form>

    <div style="position: absolute;">
      <CardAddCategorie v-model="modalAddCategorie"/>
      <CardAddAccount v-model="modalAddAccount"/>
    </div>

  </div>
</template>

<style lang="scss" scoped>

.icon-add-logo:hover {
  background-color: rgba(128, 128, 128, 0.562);
  border-radius: 60%;
}

::v-deep(.v-field__field) {
  align-items: center;
}

::v-deep(.v-card-title) {
  align-items: center;
}

@media (max-width: 680px) {
  .options-footer {
    flex-direction: column;
  }
}

.button-hover:hover {
  background-color: rgba(255, 255, 255, 0.418);
  transform: scale(1.1); 
  transition: 0.3s; 
}


</style>
