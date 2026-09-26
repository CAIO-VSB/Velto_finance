<script lang="ts" setup>

    import CurrencyInput from "~/components/ui/CurrencyInput.vue"

    import { useHttpCategories } from '~/composables/useHttp/useHttpCategories'
    import { useHttpRecurrence } from "~/composables/useHttp/useHttpRecurrence"

    import { useValidateSchemas } from "~/composables/useValidateSchema"
    import { useValidateFields } from "~/composables/useValidateFields"
    import { useInvalidate } from "~/composables/useInvalidate"

    import { useHttpCreditsCards } from "~/composables/useHttp/useHttpCreditCard"

    import type { TMovementCreditCard } from "~~/types/credit_card/TMovementCreditCard"
    import type { TCreditCard } from "~~/types/credit_card/TCredit-card"
    import type { TMovementCreditCardPayload } from "~~/schemas/movementCreditCard.schema"

    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    const { getCategoriesOnlyActive } = useHttpCategories()
    const { getCreditCardOnlyActive } = useHttpCreditsCards()
    const { validateSchemaMovementsCreditCard } = useValidateSchemas()
    const { patchMovementsCreditCardRecurrenceById } = useHttpRecurrence()
    const { invalidate } = useInvalidate()
    const { nameRules, selectRules, dateRules, currencyRules } = useValidateFields()

    const { data:categories } = useQuery({
      queryKey: QUERY_KEYS.categories.active,
      queryFn: getCategoriesOnlyActive,
    })

    const props = defineProps<{
      draft: TMovementCreditCard | null
    }>()

    const { data:creditCardOnlyActive, isPending: isPendingCreditCard } = useQuery({
      queryKey: QUERY_KEYS.creditCards.all,
      queryFn: getCreditCardOnlyActive,
    })

    const  emit = defineEmits<{
      success: []
    }>()

    const form = ref()
    const modelValue = defineModel<boolean>()
    const menuCategorias = ref(false)
    const modelCategorias = ref<number | null>(null)
    const menuCreditCard = ref(false)
    const date = ref('')
    const menu = ref(false)
    const searchCategorias = ref("")
    const switchValue = ref()
    const editScope = ref("somente_esta")
    const alertPrimary = ref("*Não é possível alterar a Data")
    const alertSecundary = ref("*Não é possível alterar o Valor, Data, Cartão e fatura")
    const showAlertPrimary = ref(false)
    const showAlertSecundary = ref(false)
    const showFields = ref({
      valor: false,
      data_compra: false,
      cartao: false,
      fatura: false,
    })

    watch(editScope, (newVal) => {
      if (newVal === "somente_esta") {
        showAlertPrimary.value = false
        showAlertSecundary.value = false
        showFields.value.cartao = false
        showFields.value.data_compra = false
        showFields.value.fatura = false
        showFields.value.valor = false
      }

      if (newVal === "esta_futuras") {
        showAlertPrimary.value = true
        showAlertSecundary.value = false
        showFields.value.data_compra = true
        showFields.value.cartao = false
        showFields.value.fatura = false
        showFields.value.valor = false
      }

      if (newVal === "todas") {
        showAlertSecundary.value = true
        showAlertPrimary.value = false
        showFields.value.cartao = true
        showFields.value.data_compra = true
        showFields.value.fatura = true
        showFields.value.valor = true
      }
      
    })

    watch(() => props.draft, (newDraft) => {
      if (!newDraft) return
      const formattedMonth = String(props.draft?.invoice_month).padStart(2, '0');
      const formattedYear = String(props.draft?.invoice_year);
      date.value = `${formattedYear}-${formattedMonth}`
    }, {immediate: true})

    watch(menuCategorias, (val) => {
      if (!val) searchCategorias.value = ""
    })

    //Watch reponsável por mostrar a categoria e conta atual
    watch(() => props.draft, (newDraft) => {
      if (newDraft) {
        modelCategorias.value = newDraft.categorie_id ?? null
      }
    }, {immediate: true})

    //Watch responsável por atualizar a categoria escolhida pelo usário no ato da edição
    watch(modelCategorias, (val) => {
      if (props.draft) props.draft.categorie_id = val ?? -1
    })

    watch(() => props.draft, (val) => {
      if (props.draft) switchValue.value = val?.status_movement
    })

    const creditCardData = computed<TCreditCard | null>(() =>
        creditCardOnlyActive.value?.find(card => card.id === props.draft?.credit_card_id) ?? null
    )

    const filterCategorias = computed(() => {
      return categories.value?.filter(item => item.name_identifier.toLowerCase().includes(searchCategorias.value.toLowerCase()))
    })

    function resetStates() {
      editScope.value = "somente_esta"
      modelValue.value = false
    }

    const  { mutate, isPending  } = useMutation({

    mutationFn: (payload: TMovementCreditCardPayload) => patchMovementsCreditCardRecurrenceById(payload.id!, payload, editScope.value, payload.recurrence_id!),
    
      onSuccess: () => {
        invalidate(QUERY_KEYS.movementsCreditCard.byCreditCard)
        invalidate(QUERY_KEYS.movementsCreditCard.totalInvoice)
        invalidate(QUERY_KEYS.movements.only_expenses)
        invalidate(QUERY_KEYS.movements.all)
        notifySuccess("Sucesso", "Operação realizada com sucesso", 6000)
        emit("success")
        modelValue.value = false
        resetStates()
      },

      onError: (error) => {
        handleErrorApplication(error.statusCode)
      },

    })

    async function submitEditMovement() {
      try {

        if(!props.draft) {
          notifyError("Ops!", "Algo não parece certo. Confira os dados e tente novamente.")
          return
        } 

        const { valid } = await form.value.validate()

        const raw = structuredClone(toRaw(props.draft))

        if (!raw.purchase_date)  {
          notifyError(
            "Data inválida",
            "Não foi possível concluir a ação porque a data informada é inválida ou está ausente.",
          )
          return
        }

        const dateFormated = dateToDateOnly(raw.purchase_date)
        const [year, month] = date.value.split("-").map(Number)

        const movementsCrediCardPayload = {
          ...props.draft,
          purchase_date: dateFormated,
          closingDay: creditCardData.value?.closing_day,
          dueDay: creditCardData.value?.due_day,
          invoice_month: month,
          invoice_year: year
        }
        
        const resultSchema = validateSchemaMovementsCreditCard(movementsCrediCardPayload)
        
        if (valid) {
          if (resultSchema.success) {
            mutate(resultSchema.data)
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
    v-if="props.draft"
    >
      <v-dialog v-model="modelValue" max-width="600">
        <v-card rounded="lg" elevation="5">
          <v-card-item class="pa-4 pb-2">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
              <span>{{ `Editar despesa ${props.draft.type_recurrence}` }}</span>
            </v-card-title>

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
            <CurrencyInput  variant="solo-filled" :disabled="showFields.valor" prepend-inner-icon="mdi-cash"  input-color="#C62828" base-color="#C62828" color="#C62828" :rules="currencyRules"  autocomplete="off" label="Valor*" v-model="props.draft.value_transaction" />
            </v-col>

            <v-col
              cols="12" md="6" sm="12"
            >
            <v-date-input :disabled="showFields.data_compra" prepend-inner-icon="mdi-calendar" prepend-icon="" :rules="dateRules" autocomplete="off" name="date" label="Data*" variant="solo-filled" v-model="props.draft.purchase_date"></v-date-input>
            </v-col>

            <v-col
             cols="12" md="12" sm="12"
            >
            <v-text-field prepend-inner-icon="mdi-pencil" :rules="nameRules" :counter="45" maxlength="45"  autocomplete="name" name="name" label="Descrição*" variant="solo-filled" v-model="props.draft.description_credit"></v-text-field>
            </v-col>

            <v-col
              cols="12" md="12" sm="12"
              >
              <v-select
                autocomplete="off"
                :loading="isPendingCreditCard"
                v-model="props.draft.credit_card_id"
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
                :disabled="showFields.cartao"
                >

                  <template v-slot:selection="{item}">
                    <v-avatar style="width: 25px; height: 24px; margin-right: 12px;"> 
                      <v-avatar :image="item.url_logo" ></v-avatar>
                    </v-avatar>
                    <span>{{ item.name_identifier }}</span>
                  </template>

                  <template v-slot:item="{props, item}">
                    <v-list-item  v-bind="props">
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
                      prepend-icon="mdi-bank"
                    >                 
                  </v-text-field>
                  </div>
                </template>
              </v-select>
            </v-col>

            <v-col
             cols="12" md="12" sm="12"
            >
              <v-text-field prepend-inner-icon="mdi-note-text" v-model="props.draft.observation" :counter="100" maxlength="100" autocomplete="off" label="Observação" variant="solo-filled""></v-text-field >
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
                          label="Fatura"
                          prepend-inner-icon="mdi-calendar"
                          hide-details
                          readonly
                          v-bind="activatorProps"
                          variant="solo-filled"
                          :disabled="showFields.fatura"
                          >
                          </v-text-field>
                      </template>

                      <v-month-picker
                          v-model="date"
                          @update:model-value="menu = false"
                      ></v-month-picker>
                  </v-menu>
                </v-col>

            <small class="text-caption text-medium-emphasis"
              >* Indica campos obrigatórios</small
            >

              <v-col
                dens cols="12" md="12" sm="12"
              >
                <v-sheet border rounded="lg" class="pa-4">
                <div class="text-body-2 font-weight-bold text-blue-grey-darken mb-3">
                  {{ `Atenção! Esta é uma despesa ${(props.draft.type_recurrence === 'fixa') ? 'fixa' : 'parcelada'}. Você deseja:` }}
                </div>

                <div class="mt-2">
                  <v-radio-group v-model="editScope" hide-details>
                    <v-radio color="red" label="Editar somente esta" value="somente_esta"></v-radio>
                    <v-radio color="red" label="Editar esta, e as futuras" value="esta_futuras"></v-radio>
                    <v-radio  color="red" label="Editar todas (incluindo estornadas)" value="todas"></v-radio>
                  </v-radio-group>
                  </div>

                  <div class="mt-2">
                    <span v-if="showAlertPrimary" class="mt-2 font-weight-bold">{{ alertPrimary }}</span>
                    <span v-if="showAlertSecundary" class="mt-2 font-weight-bold">{{ alertSecundary }}</span>
                  </div>

                </v-sheet>
              </v-col>

            </v-row>
          </v-card-text>

          <v-divider></v-divider>

          <v-card-actions class="pa-4 d-flex flex-wrap ga-2">
            <v-btn
              class="text-none"
              text="Fechar"
              variant="text"
              @click="resetStates"
            ></v-btn>
            <v-spacer></v-spacer>
            <v-btn
              class="text-none"
              color="primary"
              text="Salvar"
              variant="flat"
              rounded="lg"
              :loading="isPending"
              @click="submitEditMovement"
            ></v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-form>

    <div style="position: absolute;">

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

.button-hover:hover {
  background-color: rgba(255, 255, 255, 0.418);
  transform: scale(1.1); 
  transition: 0.3s; 
}


</style>
