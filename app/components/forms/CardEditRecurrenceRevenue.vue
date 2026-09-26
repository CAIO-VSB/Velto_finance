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

    import type { TMovements, TMovementsSummary } from "~~/types/movements/TMovements"
    import type { TMovementsPayload } from "~~/schemas/movements.schema"
  import { useHttpRecurrence } from "~/composables/useHttp/useHttpRecurrence"

    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    const { getCategoriesOnlyActive } = useHttpCategories()
    const { getAccountsOnlyActive } = useHttpAccounts()
    const { validateSchemaMovements } = useValidateSchemas()
    const { patchMovementsRecurrenceById } = useHttpRecurrence()
    const { invalidate } = useInvalidate()
    const { nameRules, selectRules, dateRules, currencyRules } = useValidateFields()

    const { data:categories } = useQuery({
        queryKey: QUERY_KEYS.categories.active,
        queryFn: getCategoriesOnlyActive,
    })

    const { data:accounts } = useQuery({
        queryKey: QUERY_KEYS.accounts.active,
        queryFn: getAccountsOnlyActive,
    })

    const props = defineProps<{
        draft: TMovementsSummary | null
    }>()

    const  emit = defineEmits<{
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
    const switchValue = ref()
    const labelSwitch = ref("Receita recebida")
    const editScope = ref("somente_esta")
    const alertPrimary = ref("*Não é possível alterar a Data ou Efetivar a receita.")
    const alertSecundary = ref("*Não é possível alterar o Valor, Data, Conta ou Efetivar a receita.")
    const showAlertPrimary = ref(false)
    const showAlertSecundary = ref(false)
    const showFields = ref({
        valor: false,
        vencimento: false,
        conta: false,
        efetivar: false,
    })

    watch(editScope, (newVal) => {

      if (newVal === "somente_esta") {
        showAlertPrimary.value = false
        showAlertSecundary.value = false
        showFields.value.conta = false
        showFields.value.efetivar = false
        showFields.value.valor = false
        showFields.value.vencimento = false
      }

      if (newVal === "pendentes") {
        showAlertPrimary.value = true
        showAlertSecundary.value = false
        showFields.value.vencimento = true
        showFields.value.efetivar = true
      }

      if (newVal === "todas") {
        showAlertSecundary.value = true
        showAlertPrimary.value = false
        showFields.value.conta = true
        showFields.value.efetivar = true
        showFields.value.valor = true
        showFields.value.vencimento = true
      }
      
    })

    watch(menuCategorias, (val) => {
    if (!val) searchCategorias.value = ""
    })

    //Watch reponsável por mostrar a categoria e conta atual
    watch(() => props.draft, (newDraft) => {
        if (newDraft) {
        modelCategorias.value = newDraft.categorie_id ?? null
        modelAccounts.value = newDraft.accounts_id ?? null
        }
    }, {immediate: true})

    //Watch responsável por atualizar a categoria escolhida pelo usário no ato da edição
    watch(modelCategorias, (val) => {
        if (props.draft) props.draft.categorie_id = val
    })

    //Watch responsável por atualizar a conta escolhida pelo usário no ato da edição
    watch(modelAccounts, (val) => {
        if (props.draft) props.draft.accounts_id = val
    })

    watch(menuAccounts, (val) => {
        if (!val) searchAccounts.value = ""
    })

    watch(() => props.draft, (val) => {
        if (props.draft) switchValue.value = val?.status_transaction
    })

    watch(switchValue, (val) => {
        if (val === 'recebido') {
        labelSwitch.value = "Receita recebida"
        if (props.draft) props.draft.status_transaction = switchValue.value
        } else if (val === "pendente") {
        labelSwitch.value = "Receita pendente"
        if (props.draft) props.draft.status_transaction = switchValue.value
        }
    })

    const filterCategorias = computed(() => {
        return categories.value?.filter(item => item.name_identifier.toLowerCase().includes(searchCategorias.value.toLowerCase()))
    })

    const filterAccounts = computed(() => {
        return accounts.value?.filter(item => item.name_identifier.toLowerCase().includes(searchAccounts.value?.toLowerCase() ?? ''))
    })

    function resetForm() {
        modelAccounts.value = null
        modelCategorias.value = null    
        modelValue.value = false
    }

    const  { mutate, isPending  } = useMutation({
        
        mutationFn: (payload: TMovementsPayload) => patchMovementsRecurrenceById(payload.id!, payload, editScope.value, payload.recurrence_id!),

        onSuccess: () => {
        invalidate(QUERY_KEYS.accounts.all)
        invalidate(QUERY_KEYS.movements.all)
        invalidate(QUERY_KEYS.movements.only_revenues)
        invalidate(QUERY_KEYS.movements.current_balance)
        notifySuccess("Sucesso", "Receita editada com sucesso", 6000)
        resetForm()
        emit("success")
        modelValue.value = false
        },

        onError: (error) => {
        handleErrorApplication(error.statusCode)
        },

    })

    async function handleEditMovementRevenue() {
  
        try {

            if(!props.draft) {
                notifyError("Ops!", "Algo não parece certo. Confira os dados e tente novamente.")
                return
            } 

            const { valid } = await form.value.validate()

            const raw = structuredClone(toRaw(props.draft))

            if (!raw.date_transaction) {
                notifyError(
                    "Data inválida",
                    "Não foi possível concluir a ação porque a data informada é inválida ou está ausente.",
                )
                return
            }

            const dateFormated = dateToDateOnly(raw.date_transaction)

            const payload = {
            ...raw,
            date_transaction: dateFormated
            }

            const resultSchema = validateSchemaMovements(payload)

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
      <v-dialog v-model="modelValue" max-width="750">
        <v-card rounded="lg" elevation="5">

          <v-card-item class="pa-4 pb-2">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
              Editar receita
            </v-card-title>

            <v-card-subtitle class="mt-1">
              Preencha os dados para editar seu lançamento.
            </v-card-subtitle>

            <template #prepend>
              <v-avatar color="green" variant="tonal" rounded="lg">
                <v-icon icon="mdi-pencil" color="green" />
              </v-avatar>
            </template>
          </v-card-item>

          <v-divider></v-divider>
          <v-card-text>
            <v-row>

            <v-col
             cols="12" md="6" sm="12"
            >
            <CurrencyInput :disabled="showFields.valor"  prepend-inner-icon="mdi-cash" input-color="#2E7D32" base-color="#2E7D32" color="#2E7D32" :rules="currencyRules"  text-color="green" autocomplete="off" label="Valor*" v-model="props.draft.value_transaction"  variant="solo-filled"/>
            </v-col>

            <v-col
             cols="12" md="6" sm="12"
            >
            <v-date-input :disabled="showFields.vencimento" prepend-inner-icon="mdi-calendar" prepend-icon="" :rules="dateRules" autocomplete="off" name="date" label="Data*" variant="solo-filled" v-model="props.draft.date_transaction"></v-date-input>
            </v-col>

            <v-col
             cols="12" md="6" sm="12"
            >
            <v-text-field prepend-inner-icon="mdi-pencil" :rules="nameRules" :counter="30" maxlength="30"  autocomplete="name" name="name" label="Descrição*" variant="solo-filled"" v-model="props.draft.description_transaction"></v-text-field>
            </v-col>

            <v-col
             cols="12" md="6" sm="12"
            >
                <v-select
                v-model="modelAccounts"
                v-model:menu="menuAccounts"
                :items="filterAccounts"
                :rules="selectRules"
                item-title="name_identifier"
                item-value="id"
                variant="solo-filled""
                label="Conta*"
                hint="O valor será creditado nesta conta"
                persistent-hint
                autocomplete="off"
                prepend-inner-icon="mdi-bank"
                :disabled="showFields.conta"
                >

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
              variant="solo-filled""
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

            <v-col
            cols="12" md="12" sm="12"
            >
              <v-sheet border rounded="lg" class="pa-4">
                <div class="text-body-2 font-weight-bold text-blue-grey-darken mb-3">
                  Opções da receita
                </div>

                <v-switch
                v-model="switchValue"
                color="success"
                :label="labelSwitch"
                hide-details
                false-value="pendente"
                true-value="recebido"
                true-icon="mdi-check"
                false-icon="mdi-close"
                :disabled="showFields.efetivar"
                ></v-switch> 

              </v-sheet>
              </v-col>

              <v-col
                dens cols="12" md="12" sm="12"
              >
              <v-sheet border rounded="lg" class="pa-4">
                <div class="text-body-2 font-weight-bold text-blue-grey-darken mb-3">
                  {{ `Atenção! Esta é uma despesa ${(props.draft.type_recurrence === 'fixa') ? 'fixa' : 'parcelada'}. Você deseja:` }}
                </div>

                <div class="mt-2">
                  <v-radio-group v-model="editScope" hide-details>
                    <v-radio color="green" label="Editar somente esta" value="somente_esta"></v-radio>
                    <v-radio color="green" label="Editar todas as pendentes" value="pendentes"></v-radio>
                    <v-radio color="green" label="Editar todas (incluindo efetivadas)" value="todas"></v-radio>
                  </v-radio-group>
                </div>
                <div class="mt-2">
                  <span v-if="showAlertPrimary" class="mt-2 font-weight-bold">{{ alertPrimary }}</span>
                  <span v-if="showAlertSecundary" class="mt-2 font-weight-bold">{{ alertSecundary }}</span>
                </div>
              </v-sheet>
              </v-col>
            </v-row>

            <small class="text-caption text-medium-emphasis">* Indica campos obrigatórios</small>
          </v-card-text>

          <v-divider></v-divider>

          <v-card-actions class="pa-4 d-flex flex-wrap ga-2"a>
            <v-btn
              class="text-none"
              text="Fechar"
              variant="text"
              @click="resetForm"
              rounded="lg"
            ></v-btn>

            <v-spacer></v-spacer>

            <v-btn
              class="text-none"
              color="primary"
              text="Salvar"
              variant="flat"
              rounded="lg"
              :loading="isPending"
              @click="handleEditMovementRevenue"
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

.button-hover:hover {
  background-color: rgba(255, 255, 255, 0.418);
  transform: scale(1.1); /* Efeito de zoom */
  transition: 0.3s; /* Transição suave */
}


</style>
