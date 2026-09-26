<script setup lang="ts">
  import { useHttpCreditsCards } from "~/composables/useHttp/useHttpCreditCard"
  import type { TCreditCard } from "~~/types/credit_card/TCredit-card";
  import { addMonths } from "date-fns"
  import CardPaymentTotalInvoice from "~/components/forms/CardPaymentTotalInvoice.vue";
  import NoticePaymentTotalInvoice from "~/components/ui/NoticePaymentTotalInvoice.vue"
  import NoticePaymentPartialInvoice from "~/components/ui/NoticePaymentPartialInvoice.vue";
  import NoticePaymentAdvanceInvoice from "~/components/ui/NoticePaymentAdvanceInvoice.vue";
  import CardPaymentPartial from "~/components/forms/CardPaymentPartialInvoice.vue";
  import CardPaymentAdvance from "~/components/forms/CardPaymentAdvanceInvoice.vue";
  import type { TOptionAction } from "~~/types/option_action/TOptionAction";
import CardReopenInvoice from "~/components/forms/CardReopenInvoice.vue";

  const { notifyError } = useNotify()

  const { getCreditCardOnlyActive } = useHttpCreditsCards()

  const { data:allCreditCard, isPending } = useQuery({
    queryKey: QUERY_KEYS.creditCards.all,
    queryFn: getCreditCardOnlyActive,
  })

  const modelNoticePaymentTotalInvoice = ref(false)
  const modelNoticePaymentPartial = ref(false)
  const modelNoticePaymentAdvance = ref(false)
  const modelCardPaymentTotal = ref(false)
  const modelCardPaymentPartial = ref(false)
  const modelCardPaymentAdvance = ref(false)
  const modelReopenInvoice = ref(false)

  type TPeriod = {
    year: number,
    month: number
  }

  const props = defineProps<{
    creditCard: TCreditCard | null,
    totalInvoice: number | null,
    loading: boolean | null,
    period: TPeriod,
    invoiceId : number | null,
    statusInvoices: string | null
  }>()

  function getOptions(): TOptionAction [] {

    const options = [
      props.statusInvoices !== 'paga' ? { title: 'Pagamento total', icon: 'mdi-check-circle-outline', value: 'pag_total' } : null,
      props.statusInvoices !== 'paga' ? { title: 'Pagamento parcial', icon: 'mdi-circle-half-full', value: 'pag_parcial' } : null,
      props.statusInvoices !== 'paga' ? { title: 'Pagamento adiantado', icon: 'mdi-clock-fast', value: 'pag_adiantado' } : null,
      props.statusInvoices === 'paga' ? { title: 'Reabrir fatura', icon: 'mdi-lock-open-variant', value: 'reabrir_fatu' } : null,
    ]

    return options.filter(Boolean) as TOptionAction[]

  } 

  const sumary = computed(() => {
    const row = props.creditCard

    if (!row) {
      return {
        limiteTotal: 0,
        ultimosDigitos: "",
        fechamento: "",
        vencimento: ""
      }
    }
   
    const closingDay = row.closing_day ?? 0
    const dueDay = row.due_day ?? 0

    if (props.period?.month === null && props.period?.year === null ) {
      notifyError(
        "Período inválido",
        "Não foi possível identificar o mês e o ano da fatura."
      )
      return
    }

    const closingDate = new Date(
      props.period.year,
      props.period.month,
      closingDay
    )

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
      limiteTotal: row.limit_card,
      ultimosDigitos: row.four_digits,
      fechamento: closingDate.toLocaleDateString("pt-BR"),
      vencimento: dueDate.toLocaleDateString("pt-BR")
    }

  })

  function showModalPaymentTotal() {
    modelCardPaymentTotal.value = true
  }

  function showModalPaymentPartial() {
    modelCardPaymentPartial.value = true
  }

  function showModalPaymentAdvance() {
    modelCardPaymentAdvance.value = true
  }

  function handleOptionClick(option: string | null) {

    if (option === 'pag_adiantado') {
      modelNoticePaymentAdvance.value = true
      return
    }

    if (option === 'pag_total') {
      modelNoticePaymentTotalInvoice.value = true
      return
    }

    if (option === 'pag_parcial') {
      modelNoticePaymentPartial.value = true
      return
    }

    if (option === 'reabrir_fatu') {
      modelReopenInvoice.value = true
      return
    }
  }

</script>

<template>
    <v-card
        rounded="xl"
        elevation="2"
        :loading="props.loading ?? false"
    >
        <v-card-item class="pa-5 pb-0">
            <v-card-title class="text-h6 font-weight-bold">
                Detalhamento
            </v-card-title>

            <v-card-subtitle class="mt-1">
                Informações e ações da fatura selecionada.
            </v-card-subtitle>
        </v-card-item>

        <v-card-text class="pa-5">
            <div class="d-flex flex-column ga-4">
                <div class="d-flex align-center justify-space-between ga-3">
                    <span class="text-body-2 text-medium-emphasis">
                        Valor a pagar
                    </span>

                    <v-chip
                        color="primary"
                        variant="tonal"
                    >
                        {{ formatCurrency(totalInvoice) }}
                    </v-chip>
                </div>

                <div class="d-flex align-center justify-space-between ga-3">
                    <span class="text-body-2 text-medium-emphasis">
                        Status da fatura
                    </span>

                    <v-chip
                        color="primary"
                        variant="tonal"
                    >
                        <span v-if="props.totalInvoice === 0">{{ "Fatura zerada" }}</span>
                        <span v-else>{{ `Fatura ${statusInvoices ?? 'parcial'}` }}</span>
                    </v-chip>
                </div>

                <v-menu
                    transition="scale-transition"
                    offset="8"
                >
                    <template #activator="{ props: menuProps }">
                        <v-btn
                            v-bind="menuProps"
                            color="primary"
                            prepend-icon="mdi-dots-horizontal"
                            variant="flat"
                            rounded="lg"
                            block
                            class="text-none font-weight-bold"
                        >
                            Ações da fatura
                        </v-btn>
                    </template>

                    <v-card
                        min-width="260"
                        rounded="xl"
                        elevation="4"
                        class="overflow-hidden"
                    >
                        <v-list
                            density="comfortable"
                            class="pa-2"
                        >
                            <v-list-item
                                v-for="(item, index) in getOptions()"
                                :key="index"
                                :value="index"
                                :prepend-icon="item.icon"
                                rounded="lg"
                                @click="handleOptionClick(item.value || null)"
                            >
                                <v-list-item-title>
                                    {{ item.title }}
                                </v-list-item-title>
                            </v-list-item>
                        </v-list>
                    </v-card>
                </v-menu>
            </div>
        </v-card-text>

        <v-divider />

        <v-card-text class="pa-5">
            <div class="d-flex flex-column ga-4">
                <div class="d-flex align-center justify-space-between ga-3">
                    <span class="text-body-2 text-medium-emphasis">
                        Fechamento
                    </span>

                    <span class="text-body-2 font-weight-bold text-blue-grey-darken">
                        {{ sumary?.fechamento }}
                    </span>
                </div>

                <div class="d-flex align-center justify-space-between ga-3">
                    <span class="text-body-2 text-medium-emphasis">
                        Vencimento
                    </span>

                    <span class="text-body-2 font-weight-bold text-blue-grey-darken">
                        {{ sumary?.vencimento }}
                    </span>
                </div>

                <div class="d-flex align-center justify-space-between ga-3">
                    <span class="text-body-2 text-medium-emphasis">
                        Limite total
                    </span>

                    <span class="text-body-2 font-weight-bold text-blue-grey-darken">
                        {{ formatCurrency(sumary?.limiteTotal ?? 0.00) }}
                    </span>
                </div>

                <div class="d-flex align-center justify-space-between ga-3">
                    <span class="text-body-2 text-medium-emphasis">
                        4 últimos dígitos
                    </span>

                    <span class="text-body-2 font-weight-bold text-blue-grey-darken">
                        {{ sumary?.ultimosDigitos }}
                    </span>
                </div>
            </div>
        </v-card-text>
    </v-card>

    <CardPaymentTotalInvoice
        v-model="modelCardPaymentTotal"
        :period="props.period"
        :invoice-id="props.invoiceId"
        :total-invoice="props.totalInvoice"
        :draft="props.creditCard"
    />

    <CardPaymentPartial
        v-model="modelCardPaymentPartial"
        :period="props.period"
        :invoice-id="props.invoiceId"
        :total-invoice="props.totalInvoice"
        :draft="props.creditCard"
    />

    <CardPaymentAdvance
        v-model="modelCardPaymentAdvance"
        :period="props.period"
        :invoice-id="props.invoiceId"
        :total-invoice="props.totalInvoice"
        :draft="props.creditCard"
    />

    <NoticePaymentTotalInvoice
        v-model="modelNoticePaymentTotalInvoice"
        :invoice-value="props.totalInvoice ?? 0.00"
        @show-modal-payment="showModalPaymentTotal"
    />

    <NoticePaymentPartialInvoice
        v-model="modelNoticePaymentPartial"
        :invoice-value="props.totalInvoice ?? 0.00"
        @show-modal-payment="showModalPaymentPartial"
    />

    <NoticePaymentAdvanceInvoice
        v-model="modelNoticePaymentAdvance"
        :invoice-value="props.totalInvoice ?? 0.00"
        @show-modal-payment="showModalPaymentAdvance"
    />

    <CardReopenInvoice
        v-model="modelReopenInvoice"
        :invoice-id="props.invoiceId"
    />
    
</template>

<style scoped>
</style>