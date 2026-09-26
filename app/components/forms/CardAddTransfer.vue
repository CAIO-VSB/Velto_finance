<script lang="ts" setup>

  import { useValidateFields } from "~/composables/useValidateFields"
  import { useInvalidate } from "~/composables/useInvalidate"
  import CurrencyInput from "~/components/ui/CurrencyInput.vue"
  import { useHttpAccounts } from "~/composables/useHttp/useHttpAccounts"
  import { useHttpTransfer } from "~/composables/useHttp/useHttpTransfer"
  import { useValidateSchemas } from "~/composables/useValidateSchema" 
  import type { TTransfer } from "~~/types/transfer/TTransfer"
  import type { TTransferPayload } from '~~/schemas/transfer.schema'

  const { notifyError, notifyInfo, notifySuccess } = useNotify()
  const {  selectRules, currencyRules, dateRules } = useValidateFields() 
  const { invalidate } = useInvalidate()
  const { getAccountsOnlyActive } = useHttpAccounts()
  const { postTransfer } = useHttpTransfer()
  const { validateSchemaTransfer } = useValidateSchemas()

  const form = ref()
  const modelValue = defineModel<boolean>()
  const modelAccountOrigin = ref<number | null>(null)
  const modelAccountDestination = ref<number | null>(null)
  const transferForm = ref<TTransfer>({
    value_transfer: 0.00,
    date_transfer: new Date(),
    account_destination: null,
    account_origin: null,
    observation: "",
    is_deleted: false
  })

  const { data:accounts } = useQuery({
    queryKey: QUERY_KEYS.accounts.active,
    queryFn: getAccountsOnlyActive,
  })

  watch(modelAccountOrigin, (newVal) => {
    transferForm.value.account_origin = newVal
  })

  watch(modelAccountDestination, (newVal) => {
    transferForm.value.account_destination = newVal
  })

  const accountsFilteredOrigin = computed(() => {
    return accounts.value?.filter(item => item.id !== modelAccountDestination.value)
  })

  const accountsFilteredDestination = computed(() => {
    return accounts.value?.filter(item => item.id !== modelAccountOrigin.value)
  })

  function resetForm() {
    transferForm.value.value_transfer = 0.00
    transferForm.value.observation = ""
    modelValue.value = false
    modelAccountDestination.value = null
    modelAccountOrigin.value = null
  }

  const  { mutate, isPending  } = useMutation({

  mutationFn: (payload: TTransferPayload) => postTransfer(payload),

  onSuccess: () => {
    invalidate(QUERY_KEYS.tranfer.all)
    invalidate(QUERY_KEYS.movements.all)
    invalidate(QUERY_KEYS.movements.only_expenses)
    invalidate(QUERY_KEYS.movements.only_revenues)
    invalidate(QUERY_KEYS.movements.current_balance)
    invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
    invalidate(QUERY_KEYS.dashboard.expenseByCategorie)
    invalidate(QUERY_KEYS.dashboard.renevueByCategorie)
    invalidate(QUERY_KEYS.dashboard.sumary)
    invalidate(QUERY_KEYS.dashboard.balanceEvolution)
    invalidate(QUERY_KEYS.dashboard.lastMovements)
    invalidate(QUERY_KEYS.dashboard.cards)
    notifySuccess("Sucesso", "Tranferência lançada com sucesso", 6000)
    modelValue.value = false
    resetForm()
  },

  onError: (error) => {
    handleErrorApplication(error.statusCode)
    console.dir(error)
  },

  })

  async function handleAddAccount() {
    if (!transferForm.value.date_transfer) {
      notifyError(
        "Data inválida",
        "Não foi possível concluir a ação porque a data informada é inválida ou está ausente.",
      )
      return
    }

    try {
      
      const { valid } = await form.value.validate()

      const dateFormated = dateToDateOnly(transferForm.value.date_transfer)
      
      if (valid) {
        
        const transferPayload = {
          ...transferForm.value,
          date_transfer: dateFormated
        }

        const resultSchema = validateSchemaTransfer(transferPayload)

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
    >
      <v-dialog persistent v-model="modelValue" max-width="750">
        <v-card rounded="lg">
          <v-card-item class="pa-4 pb-2">
              <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
              Nova Transferência
              </v-card-title>

              <v-card-subtitle class="mt-1">
              Registre uma nova transferência para acompanhar sua vida financeira.
              </v-card-subtitle>

              <template #prepend>
              <v-avatar color="primary" variant="tonal" rounded="lg">
                  <v-icon icon="mdi-swap-horizontal" color="primary"/>
              </v-avatar>
              </template>
          </v-card-item>
          <v-divider></v-divider>
          <v-card-text>
            <form>

              <CurrencyInput variant="solo-filled""  :rules="currencyRules" prepend-inner-icon="mdi-cash" input-color="#2196F3" base-color="#2196F3" color="#2196F3" text-color="#2196F3" autocomplete="off" label="Valor*" v-model="transferForm.value_transfer"/>
              
              <v-date-input :rules="dateRules" v-model="transferForm.date_transfer" prepend-inner-icon="mdi-calendar" prepend-icon=""  autocomplete="off" name="date" label="Data*" variant="solo-filled"" ></v-date-input>

              <v-select v-model="modelAccountOrigin" clearable prepend-inner-icon="mdi-bank-transfer-out" :rules="selectRules" item-value="id" item-title="name_identifier" color="primary" label="Conta origem*" :items="accountsFilteredOrigin" variant="solo-filled"">      
                 <template v-slot:selection="{item}">
                    <v-avatar style="width: 30px; height: 30px; margin-right: 12px;"> 
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
              </v-select>

              <v-select v-model="modelAccountDestination" clearable prepend-inner-icon="mdi-bank-transfer-in" :rules="selectRules" item-value="id" item-title="name_identifier"  color="primary" label="Conta destino*" :items="accountsFilteredDestination" variant="solo-filled"">
                 <template v-slot:selection="{item}">
                    <v-avatar style="width: 30px; height: 30px; margin-right: 12px;"> 
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
              </v-select>

              <v-text-field v-model="transferForm.observation" prepend-inner-icon="mdi-note-text" :counter="100" maxlength="100" autocomplete="off" label="Observação" variant="solo-filled""></v-text-field >

            </form>

            <small class="text-caption text-medium-emphasis"
              >* Indica campos obrigatórios</small
            >
          </v-card-text>

          <v-divider></v-divider>

          <v-card-actions class="pa-4 d-flex flex-wrap ga-2">
            <v-btn
              class="text-none"
              text="Cancelar"
              variant="plain"
              @click="resetForm"
            ></v-btn>
            <v-spacer></v-spacer>
            <v-btn
              class="text-none"
              color="primary"
              text="Salvar"
              variant="flat"
              rounded="lg"
              :loading="isPending"
              @click="handleAddAccount"
            ></v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-form>
  </div>
</template>


<style scoped>

.icon-add-logo:hover {
  background-color: rgba(128, 128, 128, 0.267);
  border-radius: 60%;
}

::v-deep(.v-field__field) {
  align-items: center;
}

::v-deep(.v-card-title) {
  align-items: center;
}


</style>
