<script lang="ts" setup>
    import CurrencyInput from "~/components/ui/CurrencyInput.vue"
    import { useHttpCategories } from '~/composables/useHttp/useHttpCategories'
    import { useHttpCreditsCards } from "~/composables/useHttp/useHttpCreditCard"
    import { useHttpMovementCreditCard } from "~/composables/useHttp/useHttpMovementCreditCard.js"
    import { useValidateSchemas } from "~/composables/useValidateSchema"
    import { useValidateFields } from "~/composables/useValidateFields"
    import { useInvalidate } from "~/composables/useInvalidate"
    import CardAddCategorie from '~/components/forms/CardAddCategorie.vue'
    import type { TMovementCreditCard } from "~~/types/credit_card/TMovementCreditCard"
    import CardAddCreditCard from "./CardAddCreditCard.vue"
    import type { TCreditCard } from "~~/types/credit_card/TCredit-card.js"
    import BaseModal from "../ui/BaseModal.vue"
    import type { TMovementCreditCardPayload } from "~~/schemas/movementCreditCard.schema.js"

    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    const { getCategoriesOnlyActive } = useHttpCategories()
    const { getCreditCardOnlyActive } = useHttpCreditsCards()
    const { validateSchemaMovementsCreditCard } = useValidateSchemas()
    const { patchMovementCardById } = useHttpMovementCreditCard()
    const { invalidate } = useInvalidate()
    const { nameRules, selectRules, dateRules, currencyRules } = useValidateFields()

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

    const props = defineProps<{
      draft: TMovementCreditCard | null 
    }>()

    const form = ref()
    const modelValue = defineModel<boolean>()
    const menuCreditCard = ref(false)
    const modelCreditCard = ref<number | null>(null)
    const menuCategorias = ref(false)
    const modelCategorias = ref<number>()
    const searchCategorias = ref("")
    const modalAddCategorie = ref(false)
    const modalAddCreditCard = ref(false)
    const modalHelpInvoice = ref(false)
    const date = ref('')
    const menu = ref(false)
    const updateInvoiceAutomatically = ref(false)

    watch(() => props.draft, (newDraft) => {
      if (!newDraft) return
      const formattedMonth = String(props.draft?.invoice_month).padStart(2, '0');
      const formattedYear = String(props.draft?.invoice_year);
      date.value = `${formattedYear}-${formattedMonth}`
    }, {immediate: true})

    watch(menuCategorias, (val) => {
      if (!val) searchCategorias.value = ""
    })

    watch(modelCategorias, (newVal) => {
      if (props.draft === null) return
      //Salvar no banco -1 indica erro
      props.draft.categorie_id = newVal ?? -1
    })

    watch(modelCreditCard, (newVal) => {
      if (props.draft === null) return
      props.draft.credit_card_id = newVal ?? -1
    })

    const filterCategorias = computed(() => {
      return categories.value?.filter(item => item.name_identifier.toLowerCase().includes(searchCategorias.value.toLowerCase()))
    })

    const creditCardData = computed(() => {
      return creditCardOnlyActive.value?.find(card => card.id === props.draft?.credit_card_id) ?? null
    })

    function handleOpenModalAddCategorie() {
      modalAddCategorie.value = true
    }

    function handleOpenModalAddCreditCard() {
      modalAddCreditCard.value = true
    }

    function closeModalHelpInvoice() {
      modalHelpInvoice.value = false
    }

    function updateSuggestedInvoice() {
      const purchaseDate = props.draft?.purchase_date
      const closingDay = creditCardData.value?.closing_day

      if (!purchaseDate || !closingDay){
        return
      }

      const result = calculateInvoiceMonth(
        new Date(purchaseDate),
        closingDay ?? 0
      )

      updateInvoiceAutomatically.value = true

      date.value = `${result.year}-${String(result.month).padStart(2, "0")}`

      nextTick(() => {
        updateInvoiceAutomatically.value = false
      })
    }

    function handleInvoiceManualChange() {
      if (updateInvoiceAutomatically.value) {
        return
      }

      menu.value = false
    }

    const { mutate, isPending:isPendingMovements  } = useMutation({

      mutationFn: (payload: TMovementCreditCardPayload) => patchMovementCardById(payload.id!, payload, null),

      onSuccess: () => {
        invalidate(QUERY_KEYS.movementsCreditCard.byCreditCard)
        invalidate(QUERY_KEYS.movementsCreditCard.totalInvoice)
        invalidate(QUERY_KEYS.movements.only_expenses)
        invalidate(QUERY_KEYS.movements.all)
        notifySuccess("Sucesso", "Operação realizada com sucesso", 6000)
        emit("success")
        modelValue.value = false
      },

      onError: (error) => {
        handleErrorApplication(error.statusCode)
      },

    })

  async function submitMovement() {

    if (!props.draft?.purchase_date) {
      notifyError(
        "Data inválida",
        "Não foi possível concluir a ação porque a data informada é inválida ou está ausente.",
      )
      return
    }

    const dateFormated = dateToDateOnly(props.draft.purchase_date)
    const [year, month] = date.value.split("-").map(Number)

    try {
      const { valid } = await form.value.validate()

      if (valid) {

        const movementsCrediCardPayload = {
          ...props.draft,
          purchase_date: dateFormated,
          closingDay: creditCardData.value?.closing_day,
          dueDay: creditCardData.value?.due_day,
          invoice_month: month,
          invoice_year: year
        }

        const resultSchema = validateSchemaMovementsCreditCard(movementsCrediCardPayload)

        if (!resultSchema.success) return

        mutate(resultSchema.data)

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
        <v-card rounded="lg" elevation="6">
          <v-card-item class="pa-4 pb-2">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
              Editar despesa do cartão de crédito
            </v-card-title>
            <template #prepend>
              <v-avatar color="red" variant="tonal" rounded="lg">
                <v-icon icon="mdi-pencil" color="red"/>
              </v-avatar>
            </template>
          </v-card-item>
          <v-divider></v-divider>
          <v-card-text v-if="props.draft">
            <v-row density="comfortable">
              <v-col
               cols="12" md="6" sm="12"
              >
              <CurrencyInput variant="solo-filled" prepend-inner-icon="mdi-cash" :rules="currencyRules" text-color="primary" autocomplete="off" label="Valor*" v-model="props.draft.value_transaction" />
              </v-col>

              <v-col
              cols="12" md="6" sm="12"
              >
              <v-date-input prepend-inner-icon="mdi-calendar" @update:model-value="updateSuggestedInvoice" prepend-icon="" :rules="dateRules" autocomplete="off" name="date" label="Data*" variant="solo-filled" v-model="props.draft.purchase_date"></v-date-input>
              </v-col>
              
              <v-col
              cols="12" md="12" sm="12"
              >
              <v-text-field prepend-inner-icon="mdi-pencil"  prepend-icon="" :rules="nameRules" :counter="45" maxlength="45"  autocomplete="name" name="name" label="Descrição*" variant="solo-filled"" v-model="props.draft.description_credit"></v-text-field>
              </v-col>

              <v-col
              cols="12" md="12" sm="12"
              >
              <v-select
                autocomplete="off"
                :loading="isPendingMovements"
                v-model="props.draft.categorie_id"
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
                            >
                            <template #append-inner>
                                <v-icon @click.stop="modalHelpInvoice = true" v-tooltip="'Recomendações'" style="cursor: pointer;" icon="mdi-help-circle"></v-icon>
                            </template>
                            </v-text-field>
                        </template>
                        <v-month-picker
                            v-model="date"
                            @update:model-value="handleInvoiceManualChange"
                        ></v-month-picker>
                    </v-menu>
                </v-col>

            </v-row>

            <div class="mt-4">
                <small class="text-caption text-medium-emphasis"
                >* Indica campos obrigatórios</small
                >
            </div>

          </v-card-text>

          <v-divider></v-divider>

          <v-card-actions class="pa-4 d-flex flex-wrap ga-2">
            <v-btn
              class="text-none"
              text="Fechar"
              variant="text"
              rounded="lg"
              @click="modelValue = false"
            ></v-btn>
            <v-spacer></v-spacer>
            <v-btn
              class="text-none"
              value="btn-salvar"
              color="primary"
              text="Editar"
              variant="flat"
              rounded="lg"
              :loading="isPendingMovements"
              @click="submitMovement"
            ></v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-form>

    <div style="position: absolute;">
    <CardAddCategorie v-model="modalAddCategorie"/>
    <CardAddCreditCard v-model="modalAddCreditCard" />
    <BaseModal @close-modal="closeModalHelpInvoice" title="Recomendações" :model-value="modalHelpInvoice">
        <div class="pa-3">
            <p>
                Recomenda-se evitar alterações em <strong>faturas já fechadas</strong>,
                pois isso pode afetar os <strong>valores e o histórico financeiro</strong>.
                </p>

                <p>
                Caso seja necessário realizar alguma alteração, recomenda-se
                <strong>reabrir a fatura</strong>, realizar os ajustes e
                <strong>fechá-la novamente</strong> após a conclusão.
            </p>
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
