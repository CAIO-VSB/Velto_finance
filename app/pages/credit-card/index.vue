<script setup lang="ts">
    definePageMeta({
        title: "Cartões de Crédito",
        layout: "layout-dashboard"
    })

    import alertImg from "~/assets/img-credit-card-alert.png"
    import CardAddCartao from "~/components/forms/CardAddCreditCard.vue"
    import { useHttpCreditsCards } from "~/composables/useHttp/useHttpCreditCard"
    import { useHttpMovementCreditCard } from "~/composables/useHttp/useHttpMovementCreditCard"
    import BaseFab from "~/components/ui/BaseFab.vue";
    import type { TCreditCard } from "~~/types/credit_card/TCredit-card"
    import CardEditCard from "~/components/forms/CardEditCreditCard.vue";
    import { useInvalidate } from "~/composables/useInvalidate"
    import CardInfoCreditCard from "~/pages/credit-card/components/CardInfoCreditCard.vue";
    import CardMovementsCreditCard from "~/pages/credit-card/components/CardMovementsCreditCard.vue";
    import DateInput from '~/components/ui/DateInput.vue'
    import CardAddMovimentsCreditCard from "~/components/forms/CardAddMovimentsCreditCard.vue";
    import type { TPeriod } from "~~/types/period/TPeriod"
    import DialogHelpInvoice from "./components/DialogHelpInvoice.vue"
    import type { TMovementCreditCard } from "~~/types/credit_card/TMovementCreditCard.js"
    import { useHttpInvoices } from "~/composables/useHttp/useHttpInvoices.js"

    const { getCreditCardOnlyActive, patchCreditCardById, getCreditCardOnlyDisable } = useHttpCreditsCards()
    const { getByCreditCard, getTotalInvoice } = useHttpMovementCreditCard()
    const { getNextOpenPeriod, getRefreshStatusInvoice } = useHttpInvoices()
    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    const { invalidate } = useInvalidate()

    const { data:allCreditCard, isPending } = useQuery({
        queryKey: QUERY_KEYS.creditCards.all,
        queryFn: getCreditCardOnlyActive,
    })

    const { data:allDeactivatedCrediCard, isPending: isPendingDisable } = useQuery({
        queryKey: QUERY_KEYS.creditCards.disable,
        queryFn: getCreditCardOnlyDisable,
    })

    export type TOptionActionGetOptions = {
        title: string,
        icon: string,
        value: string | boolean
    }

    const showDialogHelpInvoice = ref(false)
    const menu = ref(false)
    const modalAddCard = ref(false)
    const modalEditCard = ref(false)
    const modalAddMovementCreditCard = ref(false)
    const editDraft = ref<TCreditCard | null>(null)
    const selectedCardData = ref<TCreditCard | null>(null)
    const selectedCard = ref("")
    const selectdLogo = ref("")
    const disabeldButtonAddExpense = ref(false)
    const invoiceId = ref<number | null>(null)
    const statusInvoice = ref<string | null>(null)

    const period = ref({
        month: new Date().getMonth(),
        year: new Date().getFullYear(),
    })

    onMounted(() => {
        getRefreshStatusInvoice()
    })
    
    const { data:dataByCreditCard, isPending: isPendingByCreditCard, refetch  } = useQuery({
    queryKey: computed(() => [
        ...QUERY_KEYS.movementsCreditCard.byCreditCard,
        selectedCardData.value?.id,
        period.value.month,
        period.value.year
    ]),
    queryFn: () => getByCreditCard(period.value.month, period.value.year, selectedCardData.value?.id ?? 0),
    enabled: computed(() => !!selectedCardData.value?.id)
    })

    const { data:totalInvoice, isPending: isPendingTotalInvoice, refetch: refetchTotalInvoice } = useQuery({
    queryKey: computed(() => [
        ...QUERY_KEYS.movementsCreditCard.totalInvoice,
        selectedCardData.value?.id,
        period.value.month,
        period.value.year
    ]),
    queryFn: () => getTotalInvoice(period.value.month, period.value.year, selectedCardData.value?.id ?? 0),
    enabled: computed(() => !!selectedCardData.value?.id)
    })

    const { data: nextOpenPeriod } = useQuery({
        queryKey: computed(() => [...QUERY_KEYS.creditCards.nextOpenPeriod, selectedCardData.value?.id]),
        queryFn: () => getNextOpenPeriod(selectedCardData.value?.id ?? 0),
        enabled: computed(() => !!selectedCardData.value?.id)
    })


    const  { mutate } = useMutation({

    mutationFn: (payload: TCreditCard) => patchCreditCardById(payload.id!, payload),

    onSuccess: () => {
        invalidate(QUERY_KEYS.creditCards.all)
        invalidate(QUERY_KEYS.creditCards.disable)
    },

    onError: (error) => {
        handleErrorApplication(error.data)
    },

    })

    watch(dataByCreditCard, (newVal: TMovementCreditCard[] | undefined) => {
        
        if (!newVal || newVal?.length === 0) {
        disabeldButtonAddExpense.value = false
        invoiceId.value = null
        statusInvoice.value = null
        return
        }

        const status = newVal[0]?.status_invoice ?? null

        disabeldButtonAddExpense.value = status !== 'aberta'
        invoiceId.value = newVal[0]?.invoice_id ?? null
        statusInvoice.value = status

    }, {immediate: true})

    /**
     * Watch responsável por escutar as mudanças nos dados vindo do banco de dados
     * Sempre que mudar algum dado e existir valor, buscamos pelo id e setamos o novos valores
     */
    watch(allCreditCard, (val) => {
        if (val?.length) {
        //Sempre atualizar o selectedCardData com os dados mais recentes
        const current = val.find(item => item.id === selectedCardData.value?.id) ?? val[0]
        selectedCard.value = current?.name_identifier ?? ""
        selectdLogo.value = current?.url_logo ?? ""
        selectedCardData.value = current ?? null
        editDraft.value = current ?? null
        }
    }, {immediate: true})


    const totalForInvoice = computed(() => totalInvoice.value?.total ?? 0)

    const valueLimitedUsed = computed(() => {
        return calcutePercentage(totalForInvoice.value, selectedCardData.value?.limit_card ?? 0)
    })

    const showAlertLimitedUsed = computed(() => valueLimitedUsed.value >= 85)

    function getOptions(creditCard: TCreditCard): TOptionActionGetOptions [] {
        return [
        {title: "Editar", icon: "mdi-lead-pencil", value: "edit"},
        {
            title: creditCard.active ? "Inativar" : "Ativar",
            icon: creditCard.active ? "mdi-minus-circle-off" : "mdi-check-circle",
            value: creditCard.active ? false : true
        },
        { title: 'Adicionar novo cartão', icon: 'mdi-plus-circle', value: "new" }
        ]
    }

    function handleGetPeriod(value: TPeriod) {
        period.value = value
        refetch()
        refetchTotalInvoice()
    }

    function handleSelectedCard(card: TCreditCard) {
        selectedCard.value = card.name_identifier ?? ""
        selectdLogo.value = card.url_logo ?? ""
        selectedCardData.value = card 
        menu.value = false
        editDraft.value = structuredClone(toRaw(card))
        handleGetPeriod(period.value)
    }

    function handleOpenModalEditCardCredit(creditCard: TCreditCard) {
        modalEditCard.value = true
        editDraft.value = structuredClone(toRaw(creditCard))
    }

    function handleAddCarton() {
        modalAddCard.value = true
    }

    function closeModalHelpInvoice() {
        showDialogHelpInvoice.value = false
    }

    function handleOptionClick(option:TOptionActionGetOptions, data: TCreditCard) {

        if (option.value === "edit") {
            handleOpenModalEditCardCredit(data)
            return
        }

        if (option.value === "new") {
            handleAddCarton()
            return
        }

        const payload = structuredClone(toRaw(data))

        if (typeof option.value === "boolean") {
            payload.active = option.value
            notifySuccess("Sucesso", "Operação realizada com sucesso", 6000)
        }

        mutate(payload)
    
    }

</script>

<template>

    <CardAddCartao v-model="modalAddCard" />

    <CardEditCard
        v-model="modalEditCard"
        :draft="editDraft"
    />

    <CardAddMovimentsCreditCard v-model="modalAddMovementCreditCard" />

    <DialogHelpInvoice
        :model-value="showDialogHelpInvoice"
        @close-modal="closeModalHelpInvoice"
    />

    <v-container
    v-if="!isPending && !allCreditCard?.length"
    class="credit-cards-empty-state d-flex align-center justify-center mt-4"
    >
    <v-card
        class="overflow-hidden"
        rounded="xl"
        elevation="4"
        max-width="900"
        mx-auto
        v-if="!isPending && !allCreditCard?.length"
    >
        <v-empty-state
        icon="mdi-credit-card-outline"
        color="primary"
        title="Adicione seu primeiro cartão"
        text="Cadastre seus cartões de crédito para acompanhar limites, faturas e manter seus gastos organizados."
        class="pa-6 pb-2"
        >
        <template #actions>
            <v-btn
            color="primary"
            prepend-icon="mdi-plus"
            rounded="lg"
            class="text-none font-weight-bold mt-3"
            @click="modalAddCard = true"
            >
            Adicionar cartão
            </v-btn>
        </template>
        </v-empty-state>

        <v-divider class="mx-6 mt-4" />

        <section class="pa-6 pt-5">
        <div class="text-subtitle-1 font-weight-bold text-blue-grey-darken-4 mb-4">
            É simples começar
        </div>

        <v-stepper
            mobile-breakpoint="sm"
            alt-labels
            color="primary"
            :items="['Cadastre o cartão', 'Registre suas compras', 'Acompanhe sua fatura']"
        >
            <template #item.1>
            <v-card flat class="text-center pa-5">
                <v-avatar
                color="primary"
                variant="tonal"
                rounded="lg"
                size="48"
                class="mb-3"
                >
                <v-icon icon="mdi-credit-card-plus-outline" />
                </v-avatar>

                <div class="font-weight-bold mb-1">
                Cadastre seu cartão
                </div>

                <div class="text-body-2 text-medium-emphasis">
                Informe o nome, limite disponível e as datas de fechamento e vencimento.
                </div>
            </v-card>
            </template>

            <template #item.2>
            <v-card flat class="text-center pa-5">
                <v-avatar
                color="success"
                variant="tonal"
                rounded="lg"
                size="48"
                class="mb-3"
                >
                <v-icon icon="mdi-cart-plus" />
                </v-avatar>

                <div class="font-weight-bold mb-1">
                Registre suas compras
                </div>

                <div class="text-body-2 text-medium-emphasis">
                Adicione suas despesas para manter a fatura sempre atualizada.
                </div>
            </v-card>
            </template>

            <template #item.3>
            <v-card flat class="text-center pa-5">
                <v-avatar
                color="info"
                variant="tonal"
                rounded="lg"
                size="48"
                class="mb-3"
                >
                <v-icon icon="mdi-file-document-outline" />
                </v-avatar>

                <div class="font-weight-bold mb-1">
                Acompanhe sua fatura
                </div>

                <div class="text-body-2 text-medium-emphasis">
                Veja o total gasto, o limite restante e se organize antes do vencimento.
                </div>
            </v-card>
            </template>
        </v-stepper>
        </section>
    </v-card>
    </v-container>

    <v-container
        v-else
        fluid
        class="mt-6 pa-4 pa-md-6"
    >
        <v-row>
            <v-col
                cols="12"
                xl="4"
            >
                <v-card
                    rounded="xl"
                    elevation="2"
                    :loading="isPending"
                >
                    <v-card-text class="pa-5">
                        <div class="d-flex align-center ga-2">
                            <v-menu
                                v-model="menu"
                                :close-on-content-click="false"
                                location="bottom start"
                                offset="8"
                            >
                                <template #activator="{ props }">
                                    <v-btn
                                        v-bind="props"
                                        variant="text"
                                        rounded="lg"
                                        class="flex-grow-1 justify-start text-none px-2"
                                    >
                                        <template #prepend>
                                            <v-avatar size="34">
                                                <v-img :src="selectdLogo" />
                                            </v-avatar>
                                        </template>

                                        <span class="font-weight-bold text-truncate">
                                            {{ selectedCard }}
                                        </span>

                                        <template #append>
                                            <v-icon icon="mdi-chevron-down" />
                                        </template>
                                    </v-btn>
                                </template>

                                <v-card
                                    min-width="320"
                                    rounded="xl"
                                    elevation="2"
                                    class="overflow-hidden"
                                >
                                    <div class="pa-4">
                                        <div class="text-subtitle-1 font-weight-bold">
                                            Cartões de crédito
                                        </div>

                                        <div class="text-caption text-medium-emphasis mt-1">
                                            Selecione o cartão que deseja consultar.
                                        </div>
                                    </div>

                                    <v-divider />

                                    <v-list
                                        density="comfortable"
                                        class="pa-2"
                                    >
                                        <v-list-item
                                            v-for="card in allCreditCard"
                                            :key="card.id"
                                            :value="card"
                                            :prepend-avatar="card.url_logo"
                                            rounded="lg"
                                            @click="handleSelectedCard(card)"
                                        >
                                            <v-list-item-title class="font-weight-medium">
                                                {{ card.name_identifier }}
                                            </v-list-item-title>
                                        </v-list-item>

                                        <v-list-item
                                            prepend-icon="mdi-plus"
                                            title="Adicionar novo cartão"
                                            value="new"
                                            rounded="lg"
                                            @click="handleAddCarton"
                                        />
                                    </v-list>

                                    <template v-if="allDeactivatedCrediCard?.length">
                                        <v-divider />

                                        <div class="px-4 pt-4 text-caption text-medium-emphasis">
                                            CARTÕES DESATIVADOS
                                        </div>

                                        <v-list
                                            density="comfortable"
                                            class="pa-2"
                                        >
                                            <v-list-item
                                                v-for="card in allDeactivatedCrediCard"
                                                :key="card.id"
                                                :value="card"
                                                :prepend-avatar="card.url_logo"
                                                rounded="lg"
                                                @click="handleSelectedCard(card)"
                                            >
                                                <v-list-item-title class="text-disabled">
                                                    {{ card.name_identifier }}
                                                </v-list-item-title>
                                            </v-list-item>
                                        </v-list>
                                    </template>
                                </v-card>
                            </v-menu>

                            <v-menu v-if="selectedCardData">
                                <template #activator="{ props }">
                                    <v-btn
                                        v-bind="props"
                                        icon="mdi-dots-vertical"
                                        variant="text"
                                    >
                                    </v-btn>
                                </template>

                                <v-list
                                    density="comfortable"
                                    class="pa-2"
                                >
                                    <v-list-item
                                        v-for="item in getOptions(selectedCardData)"
                                        :key="item.title"
                                        :value="item.title"
                                        :prepend-icon="item.icon"
                                        rounded="lg"
                                        @click="handleOptionClick(item, selectedCardData)"
                                    >
                                        <v-list-item-title>
                                            {{ item.title }}
                                        </v-list-item-title>
                                    </v-list-item>
                                </v-list>
                            </v-menu>
                        </div>

                        <div class="mt-6">
                            <template v-if="selectedCardData?.limit_card && selectedCardData.limit_card > 0">
                                <div class="d-flex align-center justify-space-between mb-2">
                                    <span class="text-body-2 text-medium-emphasis">
                                        Limite utilizado
                                    </span>

                                    <span class="text-body-2 font-weight-bold text-medium-emphasis">
                                        {{ valueLimitedUsed.toFixed() ?? 0.00 }}%
                                    </span>
                                </div>

                                <v-progress-linear
                                    :model-value="valueLimitedUsed"
                                    :color="valueLimitedUsed < 85 ? 'primary' : 'error'"
                                    height="12"
                                    rounded
                                />

                                <div class="d-flex justify-space-between mt-3 text-body-2 text-medium-emphasis">
                                    <span>{{ formatCurrency(totalForInvoice ?? 0.00) }}</span>
                                    <span>de</span>
                                    <span>{{ formatCurrency(selectedCardData?.limit_card ?? 0.00) }}</span>
                                </div>
                            </template>

                            <v-alert
                            v-else
                            type="info"
                            variant="tonal"
                            rounded="lg"
                            density="compact"
                            class="mx-5 mt-5"
                            border="start"
                            text="Cadastre um limite para acompanhar melhor seus gastos e manter suas finanças sob controle."
                            />
                        </div>

                        <v-divider class="my-5" />

                        <DateInput :initial-period="nextOpenPeriod" @apply-filter-month="handleGetPeriod" />
                    </v-card-text>

                    <v-expand-transition>
                        <div
                            v-if="showAlertLimitedUsed"
                            class="px-1 pb-4 w-100"
                        >
                            <v-alert
                            v-if="showAlertLimitedUsed"
                            type="warning"
                            variant="tonal"
                            rounded="lg"
                            density="compact"
                            class="mx-5 mt-5"
                            border="start"
                            title="Limite do cartão"
                            text="Seus gastos já ultrapassaram 85% do limite disponível. Considere acompanhar as próximas compras para evitar atingir o limite."
                            />
                        </div>
                    </v-expand-transition>
                </v-card>

                <div class="mt-5">
                    <CardInfoCreditCard
                        :status-invoices="statusInvoice"
                        :invoice-id="invoiceId"
                        :loading="isPendingByCreditCard"
                        :credit-card="editDraft"
                        :total-invoice="totalForInvoice"
                        :period="period"
                    />
                </div>
            </v-col>

            <v-col
                cols="12"
                xl="8"
            >
                <CardMovementsCreditCard
                    :credit-card="selectedCardData"
                    :movements-credit-card="dataByCreditCard ?? null"
                />
            </v-col>
        </v-row>

        <div class="fab-wrapper">
            <v-tooltip
                text="Ajuda sobre a fatura"
                location="left"
            >
                <template #activator="{ props }">
                    <BaseFab
                        v-bind="props"
                        color="primary"
                        icon="mdi-help"
                        size="50"
                        @click="showDialogHelpInvoice = true"
                    />
                </template>
            </v-tooltip>

            <v-tooltip
                text="Nova despesa"
                location="left"
            >
                <template #activator="{ props }">
                    <BaseFab
                        v-bind="props"
                        :disabled="disabeldButtonAddExpense"
                        color="primary"
                        icon="mdi-plus"
                        size="50"
                        @click="modalAddMovementCreditCard = true"
                    />
                </template>
            </v-tooltip>
        </div>
    </v-container>
</template>

<style scoped>
.fab-wrapper {
  position: fixed;
  right: 24px;
  bottom: 24px;
  z-index: 10;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.text-disabled {
    text-decoration: line-through;
}
</style>