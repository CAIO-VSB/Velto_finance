<script lang="ts" setup>

  import { addMonths } from "date-fns"
  import { useHttpAccounts } from "~/composables/useHttp/useHttpAccounts"
  import { useHttpInvoices } from "~/composables/useHttp/useHttpInvoices"
  import { useValidateFields } from "~/composables/useValidateFields"
  import { useInvalidate } from "~/composables/useInvalidate"
  import type { TCreditCard } from "~~/types/credit_card/TCredit-card.js"
  import CurrencyInput from "~/components/ui/CurrencyInput.vue"
  
  const { notifyError, notifyInfo, notifySuccess } = useNotify()
  const { getAccountsOnlyActive } = useHttpAccounts()
  const { patchPaymentPartial, getRefreshStatusInvoice } = useHttpInvoices()

  const { invalidate } = useInvalidate()
  const { selectRules, dateRules, currencyRules } = useValidateFields()

  const { data:accounts, isPending: isPendingAccounts } = useQuery({
    queryKey: QUERY_KEYS.accounts.active,
    queryFn: getAccountsOnlyActive,
  })

  const emit = defineEmits<{
    success: []
  }>()

  const props = defineProps<{
    draft: TCreditCard | null,
    totalInvoice: number | null,
    invoiceId: number | null,
    period: { month: number, year: number }
  }>()

  type formPaymentPartial = {
    datePayment: Date,
    accontsId: number | null,
    invoiceId: number | null,
    totalPaid: number | null
  }

  type formPaymentPartialPayload =  {
    datePayment: string,
    accontsId: number,
    invoiceId: number | null,
    totalInvoice: number | null,
    totalPaid: number | null
  }

  const modelValue = defineModel<boolean>()
  const menuAccounts = ref(false)
  const modelAccounts = ref<number | null>(null)
  const valuePaid = ref(0.00)

  const form = ref<formPaymentPartial>({
    datePayment: new Date(),
    accontsId: modelAccounts.value,
    invoiceId: null,
    totalPaid: valuePaid.value
  })
  
  //Watch reponsável por mostrar a categoria e conta atual
  watch(() => props.draft, (newDraft) => {
    if (newDraft) {
      modelAccounts.value = newDraft.accounts_id ?? null
    }
  }, {immediate: true})

  //Watch responsável por atualizar a conta escolhida pelo usário no ato da edição
  watch(modelAccounts, (val) => {
    if (!props.draft?.accounts_id) return

    if (props.draft) props.draft.accounts_id = val ?? null
  })

  const sumary = computed(() => {
    const row = props.draft

    if (!row) {
      return {
        vencimento: ""
      }
    }

    const closingDay = row.closing_day ?? 0
    const dueDay = row.due_day ?? 0

    if (props.period === null && props.period === null ) {
      notifyError(
        "Período inválido",
        "Não foi possível identificar o mês e o ano da fatura."
      )
      return
    }

    let dueDate = new Date(
    props.period.year,
    props.period.month,
    dueDay
    )

    if (dueDay !== null && closingDay !== null) {
      if (dueDay <= closingDay) {
        dueDate = addMonths(dueDate, 1)
      }
    }

    return {
      vencimento: dueDate.toLocaleDateString("pt-BR")
    }

  })

  function resetForm() {
    form.value.totalPaid = 0.00
    modelValue.value = false
  }

  const  { mutate, isPending } = useMutation({

    mutationFn: (payload: formPaymentPartialPayload) => patchPaymentPartial(payload.datePayment, payload.accontsId, payload.invoiceId!, payload.totalInvoice!, payload.totalPaid!),

    onSuccess: () => {
      notifySuccess("Sucesso", "Operação realizada com sucesso", 6000)
      invalidate(QUERY_KEYS.accounts.all)
      invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
      invalidate(QUERY_KEYS.movementsCreditCard.byCreditCard)
      invalidate(QUERY_KEYS.movementsCreditCard.totalInvoice)
      invalidate(QUERY_KEYS.creditCards.nextOpenPeriod)
      modelValue.value = false
      getRefreshStatusInvoice()
      emit("success")
    },

    onError: (error) => {
      handleErrorApplication(error.statusCode)
    },
  })

  async function submitForm() {
    const dateFormated = dateToDateOnly(form.value.datePayment)
    const accountsId = modelAccounts.value

    if (props.totalInvoice === 0) {
      notifyInfo(
        'Fatura sem saldo',
        'Esta fatura não possui nenhum valor pendente para pagamento.',
        7000,
        true
      )
      return
    }

    if (form.value.totalPaid === 0) {
      notifyInfo(
        'Valor não informado',
        'Informe um valor maior que R$ 0,00 para realizar o pagamento.',
        7000,
        true
      )
      return
    }

    if (!dateFormated || !accountsId) {
      notifyError("Erro inesperado", "Data do pagamento ou conta do pagamento inválidos. Tente novamente mais tarde", 7500)
      return
    }     
    
    if (!form.value.totalPaid) {
      notifyError("Erro inesperado", "Data do pagamento ou conta do pagamento inválidos. Tente novamente mais tarde", 7500)
      return
    }
    
    if (form.value.totalPaid <= 0 || form.value.totalPaid === null) {
      notifyInfo(
        'Valor inválido',
        'Informe um valor maior que R$ 0,00 para realizar o pagamento parcial.',
        7000,
        true
      )
      return
    }
    
    const payload = {
      ...form.value,
      datePayment: dateFormated,
      accontsId: accountsId,
      invoiceId: props.invoiceId,
      totalInvoice: props.totalInvoice,
      totalPaid: form.value.totalPaid
    }

    mutate(payload)

  }


</script>
 

<template>


  <div class="text-center">
    <v-form
    @submit.prevent
    ref="formRef"
    validate-on="lazy blur"
    >
      <v-dialog v-model="modelValue" max-width="600">
        <v-card rounded="lg">
          <v-card-item class="pa-4 pb-2">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
              Pagamento parcial
            </v-card-title>

            <v-card-subtitle class="mt-1">
              Preencha os dados para relizar o pagamento parcial da fatura.
            </v-card-subtitle>

            <template #prepend>
              <v-avatar color="red" variant="tonal" rounded="lg">
                <v-icon icon="mdi-credit-card-outline" color="red" />
              </v-avatar>
            </template>
          </v-card-item>
          <v-divider></v-divider>
          <v-card-text v-if="props.draft">
            <v-row density="comfortable">

            <div class="info w-100">
                <div class="d-flex ga-2 justify-space-between">
                    <p >Cartão:</p>
                     <v-chip><p class="font-weight-semibold">{{ props.draft.name_identifier }}</p></v-chip>
                </div>

                <div class="d-flex ga-2 justify-space-between">
                    <p >Fatura:</p>
                    <v-chip><p class="font-weight-semibold">{{sumary?.vencimento}}</p></v-chip>
                </div>

                <div class="d-flex ga-6 justify-space-between">
                    <p >Valor total:</p>
                    <v-chip color="red"><p class="font-weight-semibold">{{ formatCurrency(props.totalInvoice)}}</p></v-chip>
                </div>
              </div> 

              <v-col
              cols="12" md="12" sm="12"
              >
              <CurrencyInput variant="solo-filled" prepend-inner-icon="mdi-cash" :rules="currencyRules" text-color="primary" autocomplete="off" label="Valor pago" v-model="form.totalPaid"/>
              </v-col>

              <v-col
              cols="12" md="12" sm="12"
              >
              <v-date-input prepend-inner-icon="mdi-calendar" prepend-icon="" :rules="dateRules" autocomplete="off" name="date" label="Data do pagamento" variant="solo-filled" v-model="form.datePayment"></v-date-input>
              </v-col>
              
            <v-col
             cols="12" md="12" sm="12"
            >
              <v-select
                v-model="modelAccounts"
                v-model:menu="menuAccounts"
                :items="accounts"
                :rules="selectRules"
                item-title="name_identifier"
                item-value="id"
                variant="solo-filled"
                label="Conta"
                hint="O valor será debitado desta conta"
                persistent-hint
                autocomplete="off"
                prepend-inner-icon="mdi-bank"
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

                </v-select>
                </v-col>
            </v-row>

          </v-card-text>

          <v-divider></v-divider>

          <v-card-actions class="pa-4 d-flex flex-wrap ga-2">
            <v-btn
              class="text-none"
              text="Cancelar"
              variant="text"
              rounded="lg"
              @click="resetForm"
            ></v-btn>
            <v-spacer></v-spacer>
            <v-btn
              class="text-none"
              value="btn-salvar"
              color="primary"
              text="Pagar parcial"
              variant="flat"
              rounded="lg"
              @click="submitForm"
              :loading="isPending"
            ></v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-form>

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
