<script lang="ts" setup>
  import { format } from "date-fns";
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
  const showInputParcelado = ref("")
  const showInputFixa = ref("")
  const labelSwitch = ref("Receita recebida")
  const showSwitch = ref(false)

  const movementsForm = ref<TMovements>({
    type_transaction: "receita",
    value_transaction: null,
    date_transaction: new Date(),
    description_transaction: "",
    categorie_id: null,
    accounts_id: null,
    status_transaction: "recebido"
  })

  const recorrenceForm = ref<TRecurrence>({
    value_recurrence: 0.00,
    description_recurrence: "",
    accounts_id: null,
    categorie_id: null,
    type_recurrence: "",
    frequency_recurrence: null,
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
      labelSwitch.value = "Receita pendente"
      movementsForm.value.status_transaction = "pendente"
      showSwitch.value = true
      recorrenceForm.value.type_recurrence = newVal
    } else if (newVal === 'avista') {
      labelSwitch.value = "Receita recebida"
      movementsForm.value.status_transaction = "recebido"
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

    if (val.status_transaction === 'recebido') {
      labelSwitch.value = "Receita recebida"
    } else if (val.status_transaction === "pendente") {
      labelSwitch.value = "Receita pendente"
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
    movementsForm.value.status_transaction = "recebido"
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
    movementsForm.value.status_transaction = "recebido"
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

  const  { mutate:mutateMovements, isPending:isPendingMovements  } = useMutation({
    
    mutationFn: postMovements,

    onSuccess: () => {
      invalidate(QUERY_KEYS.accounts.all)
      invalidate(QUERY_KEYS.movements.all)
      invalidate(QUERY_KEYS.movements.only_revenues)
      invalidate(QUERY_KEYS.movements.current_balance)
      invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
      invalidate(QUERY_KEYS.dashboard.expenseByCategorie)
      invalidate(QUERY_KEYS.dashboard.renevueByCategorie)
      invalidate(QUERY_KEYS.dashboard.sumary)
      invalidate(QUERY_KEYS.dashboard.balanceEvolution)
      invalidate(QUERY_KEYS.dashboard.lastMovements)
      invalidate(QUERY_KEYS.dashboard.cards)
      notifySuccess("Sucesso", "Receita lançada com sucesso", 6000)
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
          date_transaction: dateFormated,
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
          invalidate(QUERY_KEYS.movements.only_revenues)
          invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
          invalidate(QUERY_KEYS.dashboard.expenseByCategorie)
          invalidate(QUERY_KEYS.dashboard.renevueByCategorie)
          invalidate(QUERY_KEYS.dashboard.sumary)
          invalidate(QUERY_KEYS.dashboard.balanceEvolution)
          invalidate(QUERY_KEYS.dashboard.lastMovements)
          invalidate(QUERY_KEYS.dashboard.cards)
          notifySuccess("Sucesso", "Receita lançada com sucesso", 6000)
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
  <v-form
    ref="form"
    validate-on="lazy blur"
    @submit.prevent
  >
    <v-dialog v-model="modelValue" max-width="760">
      <v-card rounded="lg" elevation="8">
        <v-card-item class="pa-4 pb-2">
          <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
            Nova receita
          </v-card-title>

          <v-card-subtitle class="mt-1">
            Registre uma nova entrada para acompanhar sua vida financeira.
          </v-card-subtitle>

          <template #prepend>
            <v-avatar color="green" variant="tonal" rounded="lg">
              <v-icon icon="mdi-bank-plus" color="green" />
            </v-avatar>
          </template>
        </v-card-item>

        <v-divider />

        <v-card-text class="pa-4 pa-sm-6">
          <v-row>
            <v-col cols="12" md="6">
              <CurrencyInput
                v-model="movementsForm.value_transaction"
                :rules="currencyRules"
                prepend-inner-icon="mdi-cash"
                input-color="green"
                base-color="green"
                color="green"
                text-color="green"
                variant="solo-filled"
                autocomplete="off"
                label="Valor *"
                density="comfortable"
              />
            </v-col>

            <v-col cols="12" md="6">
              <v-date-input
                v-model="movementsForm.date_transaction"
                :rules="dateRules"
                prepend-inner-icon="mdi-calendar-outline"
                prepend-icon=""
                autocomplete="off"
                name="date"
                label="Data *"
                variant="solo-filled"
                density="comfortable"
                color="primary"
              />
            </v-col>

            <v-col cols="12" md="6">
              <v-text-field
                v-model="movementsForm.description_transaction"
                :rules="nameRules"
                :counter="45"
                maxlength="45"
                prepend-inner-icon="mdi-pencil-outline"
                autocomplete="name"
                name="name"
                label="Descrição *"
                variant="solo-filled"
                density="comfortable"
                color="primary"
              />
            </v-col>

            <v-col cols="12" md="6">
              <v-select
                v-model="modelAccounts"
                v-model:menu="menuAccounts"
                :items="filterAccounts"
                :rules="selectRules"
                item-title="name_identifier"
                item-value="id"
                label="Conta *"
                hint="O valor será creditado nesta conta."
                persistent-hint
                autocomplete="off"
                prepend-inner-icon="mdi-bank-outline"
                variant="solo-filled"
                density="comfortable"
                color="primary"
                clearable
              >
                <template #append-inner>
                  <v-tooltip text="Nova conta" location="top">
                    <template #activator="{ props }">
                      <v-btn
                        v-bind="props"
                        icon="mdi-plus"
                        color="primary"
                        variant="text"
                        size="small"
                        density="compact"
                        @click.stop="handleOpenModalAddAccount"
                      />
                    </template>
                  </v-tooltip>
                </template>

                <template #selection="{ item }">
                  <v-avatar size="25" class="mr-3">
                    <v-img
                      :src="item.url_image"
                      :alt="item.name_identifier"
                    />
                  </v-avatar>
                  <span>{{ item.name_identifier }}</span>
                </template>

                <template #item="{ props, item }">
                  <v-list-item v-bind="props">
                    <template #prepend>
                      <v-avatar>
                        <v-img
                          :src="item.url_image"
                          :alt="item.name_identifier"
                        />
                      </v-avatar>
                    </template>
                  </v-list-item>
                </template>

                <template #prepend-item>
                  <div class="pa-2">
                    <v-text-field
                      v-model="searchAccounts"
                      :error="!!searchAccounts && !filterAccounts?.length"
                      density="compact"
                      placeholder="Buscar conta..."
                      prepend-inner-icon="mdi-magnify"
                      variant="outlined"
                      color="primary"
                      hide-details="auto"
                      @click.stop
                      @keydown.stop
                      @mousedown.stop
                    />
                  </div>

                  <v-divider />
                </template>
              </v-select>
            </v-col>

            <v-col cols="12" >
              <v-select
                v-model="modelCategorias"
                v-model:menu="menuCategorias"
                :items="filterCategorias"
                :rules="selectRules"
                item-title="name_identifier"
                item-value="id"
                autocomplete="off"
                prepend-inner-icon="mdi-shape-outline"
                label="Categoria *"
                variant="solo-filled"
                density="comfortable"
                color="primary"
                clearable
              >
                <template #append-inner>
                  <v-tooltip text="Nova categoria" location="top">
                    <template #activator="{ props }">
                      <v-btn
                        v-bind="props"
                        icon="mdi-plus"
                        color="primary"
                        variant="text"
                        size="small"
                        density="compact"
                        @click.stop="handleOpenModalAddCategorie"
                      />
                    </template>
                  </v-tooltip>
                </template>

                <template #selection="{ item }">
                  <v-avatar
                    :icon="item.url_icon"
                    size="30"
                    class="mr-3"
                  />
                  <span>{{ item.name_identifier }}</span>
                </template>

                <template #item="{ props, item }">
                  <v-list-item v-bind="props">
                    <template #prepend>
                      <v-avatar :icon="item.url_icon" />
                    </template>
                  </v-list-item>
                </template>

                <template #prepend-item>
                  <div class="pa-2">
                    <v-text-field
                      v-model="searchCategorias"
                      :error="!!searchCategorias && !filterCategorias?.length"
                      density="compact"
                      placeholder="Buscar categoria..."
                      prepend-inner-icon="mdi-magnify"
                      variant="outlined"
                      color="primary"
                      hide-details="auto"
                      @click.stop
                      @keydown.stop
                      @mousedown.stop
                    />
                  </div>

                  <v-divider />
                </template>
              </v-select>
            </v-col>

            <v-col cols="12">
              <v-text-field
                v-model="movementsForm.observation"
                :counter="100"
                maxlength="100"
                prepend-inner-icon="mdi-note-text-outline"
                autocomplete="off"
                label="Observação"
                variant="solo-filled"
                density="comfortable"
                color="primary"
              />
            </v-col>

            <v-col cols="12">
              <v-sheet border rounded="lg" class="pa-4">
                <div class="text-body-2 font-weight-bold text-blue-grey-darken-3 mb-3">
                  Opções da receita
                </div>

                <v-row>
                  <v-col cols="12" sm="6" md="4">
                    <v-switch
                      v-model="movementsForm.status_transaction"
                      :disabled="showSwitch"
                      color="primary"
                      :label="labelSwitch"
                      hide-details
                      false-value="pendente"
                      true-value="recebido"
                      true-icon="mdi-check"
                      false-icon="mdi-close"
                    />
                  </v-col>

                  <v-col cols="12" sm="6" md="4">
                    <v-switch
                      v-model="showInputFixa"
                      color="primary"
                      label="Receita fixa"
                      hide-details
                      false-value="avista"
                      true-value="fixa"
                      true-icon="mdi-pin"
                      false-icon="mdi-close"
                    />
                  </v-col>

                  <v-col cols="12" sm="6" md="4" class="d-flex align-center">
                    <v-switch
                      v-model="showInputParcelado"
                      color="primary"
                      label="Receita parcelada"
                      hide-details
                      false-value="unica"
                      true-value="parcelada"
                      true-icon="mdi-repeat"
                      false-icon="mdi-close"
                    />

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

            <v-col v-if="showInputParcelado" cols="12" md="6">
              <v-number-input
                v-model="recorrenceForm.total_installments"
                :min="2"
                :max="100"
                density="comfortable"
                variant="solo-filled"
                control-variant="default"
                label="Número de parcelas *"
                color="primary"
                inset
              />
            </v-col>

            <v-col v-if="showInputParcelado" cols="12" md="6">
              <v-select
                v-model="recorrenceForm.frequency_recurrence"
                :items="['Dias', 'Semanas', 'Meses', 'Anos']"
                label="Periodicidade *"
                density="comfortable"
                variant="solo-filled"
                color="primary"
                hide-details="auto"
              />
            </v-col>
          </v-row>

          <div class="text-caption text-medium-emphasis mt-2">
            * Indica campos obrigatórios.
          </div>
        </v-card-text>

        <v-divider />

        <v-card-actions class="pa-4 d-flex flex-wrap ga-2">
          <v-btn
            class="text-none"
            variant="text"
            @click="resetFormAndCloseModal"
          >
            Fechar
          </v-btn>

          <v-spacer />

          <v-btn
            :loading="isPendingMovements"
            color="green"
            variant="outlined"
            rounded="lg"
            class="text-none"
            @click="submitMovement({ closeAfterSave: false })"
          >
            Salvar e criar nova
          </v-btn>

          <v-btn
            :loading="isPendingMovements"
            color="green"
            variant="flat"
            rounded="lg"
            class="text-none"
            @click="submitMovement({ closeAfterSave: true })"
          >
            Salvar
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-form>

  <CardAddCategorie v-model="modalAddCategorie" />
  <CardAddAccount v-model="modalAddAccount" />
</template>

<style scoped>
</style>