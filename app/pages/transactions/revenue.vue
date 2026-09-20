<script setup lang="ts">

    definePageMeta({
        title: "Transações",
        layout: "layout-dashboard"
    })

    import { useHttpCategories } from '~/composables/useHttp/useHttpCategories'
    import { useHttpAccounts } from "~/composables/useHttp/useHttpAccounts"
    import CardAddMovimentsRevenue from '~/components/forms/CardAddMovimentsRevenue.vue'
    import { useHttpMovements } from '~/composables/useHttp/useHttpMovements'
    import DateInput from "~~/app/components/ui/DateInput.vue"
    import type { TMovements, TMovementsSummary } from '~~/types/movements/TMovements'
    import type { TOptionAction } from '~~/types/option_action/TOptionAction'
    import type { TMovementsOnlyRenevue } from '~~/types/movements/TMovementsOnlyRevenue'
    import type { TMovementsByFilter } from "~~/types/movements/TMovementsByFilter"
    import type { TPeriod } from '~~/types/period/TPeriod'
    import CardSettleTransactionModal from '~/components/forms/CardSettleTransactionModal.vue'
    import CardEditMovementsRevenue from '~/components/forms/CardEditMovementsRevenue.vue'
    import CardDeletTransaction from '~/components/forms/CardDeletTransaction.vue'
    import FilterDrawer from './components/FilterDrawer.vue'
    import type { TMovementsPayload } from '~~/schemas/movements.schema.js'
    import AppCard from '~/components/ui/AppCard.vue'
    import CardEditRecurrenceRevenue from '~/components/forms/CardEditRecurrenceRevenue.vue'
    import useOptions from '~/pages/transactions/composable/useOptions'
    import CardDeleteMovementRecurrence from '~/components/forms/CardDeleteMovementRecurrence.vue'
    import BaseModal from "~/components/ui/BaseModal.vue"
    import BaseUploadFile from '~/components/ui/BaseUploadFile.vue'

    type option = {
        title: string,
        color: string,
        value: string,
        route: string
    }

    const { patchMovementsById,  getMovimentsOnlyRevenuesByFilter } = useHttpMovements()
    const {  notifyInfo, notifySuccess, notifyError } = useNotify()
    const { invalidate } = useInvalidate()
    const { getOnlyRevenues } = useHttpMovements()
    const { getCategoriesOnlyActive } = useHttpCategories()
    const { getAccountsOnlyActive } = useHttpAccounts()

    const editDraft = ref<TMovements | null>(null)
    const confirmDraft = ref<TMovementsPayload | null>(null)

    const route = useRoute()

    const modalAddRevenue = ref(false)

    const modalEditMovementsRevenue = ref(false)

    const modelEditRecurrenceRevenue = ref(false)

    const cardPostValueTransaction = ref(false)

    const cardDeletTransaction = ref(false)

    const cardDeletTransactionRecurrence = ref(false)

    const isFiltered = ref(false)

    const filteredData = ref<TMovementsOnlyRenevue[] | null>(null)

    const lastFilter = ref<TMovementsByFilter | null>(null)

    const movementBeingAttached = ref<TMovementsSummary | null>(null)

    const drawer = ref(false)

    const search = ref('')

    const modelUploadImage = ref(false)

    const urlImage = ref("")

    const showImageRecibo = ref(false)

    const currentReciboUrl = ref<string | null>(null)
        
    const modalHelp = ref(false)

    const labelOptions = ref({
        colorButton: "",
        textButton: "",
        title: "",
        text: ""
    })

    const period = ref({
        month: new Date().getMonth(),
        year: new Date().getFullYear(),
    })
  
    const { data, isPending, refetch } = useQuery({
        queryKey: QUERY_KEYS.movements.only_revenues,
        queryFn: () => getOnlyRevenues(period.value.month, period.value.year),
    })

    const { data:categories } = useQuery({
      queryKey: QUERY_KEYS.categories.active,
      queryFn: getCategoriesOnlyActive,
    })

    const { data:accounts } = useQuery({
      queryKey: QUERY_KEYS.accounts.active,
      queryFn: getAccountsOnlyActive,
    })


    function handleGetPeriod(value: TPeriod) {
        period.value = value
        refetch()
        isFiltered.value = false
    }

    async function handleApplyFilter(filter: TMovementsByFilter) {

       lastFilter.value = filter
       const movements = await getMovimentsOnlyRevenuesByFilter(
        filter.start_day as string,
        filter.end_day as string,
        filter.categorie_id ?? [],
        filter.accounts_id ?? [],
        filter.situation as string,
        filter.for_type ?? []
       )

       filteredData.value = movements
       isFiltered.value = true
    }

    const tableData = computed(() => {
        return isFiltered.value ? filteredData.value : data.value
    })

    const sumary = computed(() => {

        const row = tableData.value?.[0]

        return {
            receitas_pendentes: Number(row?.t_receitas_pendentes ?? 0.00),
            receitas_efetivadas: Number(row?.t_receitas_efetivadas ?? 0.00),
            total_geral: Number(row?.total_geral_receitas ?? 0.00),
        }
    })

    const lastFilterLabels = computed(() => {
        const cats = lastFilter.value?.categorie_id?.map(id => {
            const found = categories.value?.find(c => c.id === id) 
            return found ? {id: found.id, name: found.name_identifier} : null
        })

        const accs = lastFilter.value?.accounts_id?.map(id => {
            const found = accounts.value?.find(a => a.id === id)
            return found ? {id: found.id, name: found.name_identifier} : null
        })

        return { cats, accs}
    })

    const itemsRouter = [
        { title: 'Todas as transações', color: "#673AB7", value: "todas",          route: "/transactions" },
        { title: 'Despesas',            color: "#F44336", value: "despesas",       route: "/transactions/expense" },
        { title: 'Receitas',            color: "#4CAF50", value: "receitas",       route: "/transactions/revenue" },
        { title: 'Transferências',      color: "#2196F3", value: "transferencias", route: "/transactions/transfer" },
    ]
        
    const headers = [
        {
            align: 'center' as const,
            key: 'status_transaction',
            title: 'Situação',
        },
        { key: 'date_transaction', title: 'Data'  },
        { key: 'description_transaction', title: 'Descrição' },
        { key: 'categorie_name', title: 'Categoria' },
        { key: 'account_name', title: 'Conta' },
        { key: 'value_transaction', title: 'Valor' },
        { key: 'actions', title: 'Ações' },
    ]

    const currentItem = computed(() => {
       return itemsRouter.find(item => item.route === route.path)
    })

    const titleButtonOption = computed(() => {
        return currentItem.value?.title 
    })

    const ColorButtonOption = computed(() => {
        return currentItem.value?.color
    })

    function handleMutationSuccess() {
        if (isFiltered.value && lastFilter.value) {
            handleApplyFilter(lastFilter.value)
        }
    }

    function handleClearFilter() {
        filteredData.value = null
        isFiltered.value = false
    }

    function getTitleRouter(item: option) {
        navigateTo(item.route)
    }

    function handleClearFilterAdvanced(value: string, filter?: TMovementsByFilter | null, idCategorie?: number, idAccount?: number) {
        switch (value) {
            case "todos": 
                lastFilter.value!.start_day = null
                lastFilter.value!.end_day = null
                isFiltered.value = false
                break;  
            case "period":
                lastFilter.value!.start_day = null
                lastFilter.value!.end_day = null
                isFiltered.value = false
                break;
            case "categories":
                if (!filter) return
                const categorieId = idCategorie
                const categoriesRemaining = filter.categorie_id?.filter(id => id !== categorieId) ?? null
                const payloadCategorie: TMovementsByFilter = {
                    ...filter,
                    categorie_id: categoriesRemaining?.length ? categoriesRemaining : null
                }
                handleApplyFilter(payloadCategorie)
                break;
            case "accounts":
                if (!filter) return
                const accountId = idAccount
                const accountsRemaining = filter.accounts_id?.filter(id => id !== accountId) ?? null
                const payloadAccounts: TMovementsByFilter = {
                    ...filter,
                    accounts_id: accountsRemaining?.length ? accountsRemaining : null
                }
                handleApplyFilter(payloadAccounts)
                break; 
            case "situation":
                if (!filter) return
                const payloadSituation: TMovementsByFilter = {
                    ...filter,
                    situation: null
                }
                handleApplyFilter(payloadSituation)
                break; 
            case "for_type":
                if (!filter) return
                const payloadFortype: TMovementsByFilter = {
                    ...filter,
                    for_type: null
                }
                handleApplyFilter(payloadFortype)
                break; 
            default:
                break;
        }
    }

    function handleOpenModalUploadImage(movement: TMovementsSummary) {
        modelUploadImage.value = true
        movementBeingAttached.value = movement
    }

    function handleSubmitImageUpload(url: string) {

        if (!movementBeingAttached.value) {
            notifyError("Erro", "Não foi possível identificar a transação.", 7000)
            return
        }
        
        const raw = structuredClone(toRaw(movementBeingAttached.value))

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
            value_transaction: Number(raw.value_transaction ?? 0),
            date_transaction: dateFormated,
            url_recibo: url
        }
        
        mutate(payload)

        movementBeingAttached.value = null
        modelUploadImage.value = false
        currentReciboUrl.value = null
    }

    function closeModalUploadImage() {
        modelUploadImage.value = false
    }

    function openShowRecibo(url: string) {
        currentReciboUrl.value = url
        showImageRecibo.value = true
    }

    function closeModalHelpInvoice() {
      modalHelp.value = false
    }

    function getOptions(moviments: TMovementsSummary): TOptionAction [] {

        const options = [
            moviments.status_transaction === "pendente" ? {
                title: "Efetivar",
                icon: "mdi-check-all",
                value: "efetivar"
            } : null,
            { title: 'Editar', value: "edit", icon: "mdi-circle-edit-outline" },
            { title: 'Anexar arquivo',  value: "arquivo", icon: "mdi-paperclip" },
            { title: 'Deletar', value: "delete", icon: "mdi-delete-forever" },
        ]

        return options.filter(Boolean) as TOptionAction[]

    } 

    const  { mutate } = useMutation({

        mutationFn: (payload: TMovementsPayload) => patchMovementsById(payload.id!, payload),

        onSuccess: () => {
            invalidate(QUERY_KEYS.movements.all)
            invalidate(QUERY_KEYS.movements.only_expenses)
            invalidate(QUERY_KEYS.movements.only_revenues)
            invalidate(QUERY_KEYS.movements.current_balance)
            invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
            notifySuccess("Sucesso", "Transação editada com sucesso", 6000)
        },

        onError: (error) => {
            handleErrorApplication(error.statusCode)
        },

    })

    function handleOpenModalEditMovementsRevenue(movements: TMovementsSummary) {

        //Usamos structuredClone + toRaw para evitar mutar o objeto reativo do Vue
        const rawMovements =  structuredClone(toRaw(movements))

        editDraft.value = parseMovementToEdit(rawMovements)

        modalEditMovementsRevenue.value = true
    }

    function handleOpenModalEditRecurrenceRevenue(movements: TMovementsSummary) {
        //Usamos structuredClone + toRaw para evitar mutar o objeto reativo do Vue
        const rawMovements =  structuredClone(toRaw(movements))
        editDraft.value = parseMovementToEdit(rawMovements)
        modelEditRecurrenceRevenue.value = true
    }

    function handleOptionClick(option: TOptionAction, data: TMovementsSummary) {

        if (option.value === "edit" && data.type_transaction === "receita" && (data.type_recurrence === "fixa" || data.type_recurrence === "parcelada")) {
            handleOpenModalEditRecurrenceRevenue(data)
            return
        }
        

        if (option.value === "edit" && data.type_transaction === "receita") {
            handleOpenModalEditMovementsRevenue(data)
            return 
        }

        if (option.value === "arquivo") {
            handleOpenModalUploadImage(data)
            return
        }

        const raw = structuredClone(toRaw(data))
        
        if (!raw.date_transaction) {
            notifyError(
                "Data inválida",
                "Não foi possível concluir a ação porque a data informada é inválida ou está ausente.",
            )
            return
        }

        const dateFormated = dateToDateOnly(raw.date_transaction)

        const payload: TMovementsPayload = {
            ...raw,
            value_transaction: Number(raw.value_transaction ?? 0),
            date_transaction: dateFormated,
            url_recibo: urlImage.value
        }

        if (option.value === "delete" && (data.type_transaction === "despesa" || data.type_transaction === "receita") && (data.type_recurrence === "fixa" || data.type_recurrence === "parcelada")) {
            confirmDraft.value = payload
            cardDeletTransactionRecurrence.value = true
            return
        }

        if (option.value !== "efetivar" && option.value !== "delete") {
            return
        }
        
        const config = useOptions[option.value]?.[data.type_transaction]
        
        if (config) {
            confirmDraft.value = payload
            labelOptions.value = {
                colorButton: config.colorButton,
                textButton: config.textButton,
                title: config.title,
                text: config.text
            }

            switch (config.modal) {
                case "settle":
                    cardPostValueTransaction.value = true
                    break
                case "deleteMovement":
                    cardDeletTransaction.value = true
                    break
            }

            return
        }


        mutate(payload)
    }


</script>


<template>
    <v-container
        fluid
        class="mt-6 pa-4 pa-md-6"
    >
        <CardAddMovimentsRevenue
            v-model="modalAddRevenue"
            @success="handleMutationSuccess"
        />

        <CardDeletTransaction
            v-model="cardDeletTransaction"
            :draft="confirmDraft"
            :title-botton="labelOptions.textButton"
            :title="labelOptions.title"
            :text="labelOptions.text"
            :color-botton="labelOptions.colorButton"
            @success="handleMutationSuccess"
        />

        <CardEditMovementsRevenue
            v-model="modalEditMovementsRevenue"
            :draft="editDraft"
            @success="handleMutationSuccess"
        />

        <CardSettleTransactionModal
            v-model="cardPostValueTransaction"
            :draft="confirmDraft"
            :title-botton="labelOptions.textButton"
            :title="labelOptions.title"
            :text="labelOptions.text"
            :color-botton="labelOptions.colorButton"
            @success="handleMutationSuccess"
        />

        <CardEditRecurrenceRevenue
            v-model="modelEditRecurrenceRevenue"
            :draft="editDraft"
            @success="handleMutationSuccess"
        />

        <CardDeleteMovementRecurrence
            v-model="cardDeletTransactionRecurrence"
            :draft="confirmDraft"
        />

        <FilterDrawer
            v-model="drawer"
            :items="['Recebidas', 'Pendentes']"
            :field-type-active="true"
            color-button="green"
            @apply-filter="handleApplyFilter"
            @reset-filter="handleClearFilter"
        />

        <BaseUploadFile 
            :model-value="modelUploadImage"
            :loading="false"
            @close-modal="closeModalUploadImage"
            @submit-image="handleSubmitImageUpload"
        />

        <v-row
            align="center"
            class="mb-6"
        >
            <v-col
                cols="12"
                md="auto"
            >
                <v-menu
                    transition="scale-transition"
                    offset="8"
                >
                    <template #activator="{ props }">
                        <v-btn
                            v-bind="props"
                            :color="ColorButtonOption"
                            variant="tonal"
                            append-icon="mdi-chevron-down"
                            rounded="lg"
                            class="text-none font-weight-medium"
                        >
                            {{ titleButtonOption }}
                        </v-btn>
                    </template>

                    <v-card
                        min-width="240"
                        rounded="xl"
                        elevation="4"
                        class="overflow-hidden"
                    >
                        <v-list
                            density="comfortable"
                            class="pa-2"
                        >
                            <v-list-item
                                v-for="(item, index) in itemsRouter"
                                :key="index"
                                :value="index"
                                rounded="lg"
                                @click="getTitleRouter(item)"
                            >
                                <template #prepend>
                                    <v-icon
                                        icon="mdi-circle-medium"
                                        :color="item.color"
                                        class="mr-2"
                                    />
                                </template>

                                <v-list-item-title class="font-weight-medium">
                                    {{ item.title }}
                                </v-list-item-title>
                            </v-list-item>
                        </v-list>
                    </v-card>
                </v-menu>
            </v-col>

            <v-col
                cols="12"
                md
                class="d-flex flex-wrap justify-md-end ga-3"
            >
                <v-btn
                    color="success"
                    prepend-icon="mdi-plus"
                    variant="flat"
                    rounded="lg"
                    class="text-none font-weight-bold"
                    @click="modalAddRevenue = true"
                >
                    Nova receita
                </v-btn>

                <v-btn
                    color="success"
                    prepend-icon="mdi-filter-outline"
                    variant="outlined"
                    rounded="lg"
                    class="text-none font-weight-medium"
                    @click="drawer = true"
                >
                    Filtro
                </v-btn>
            </v-col>
        </v-row>

        <v-row class="mb-6">
            <div class="main-cards">
            <v-col
                cols="12"
                md="4"
            >
                <AppCard
                    subtitle="Receitas pendentes"
                    :loading="isPending"
                    size="40"
                    :value="sumary.receitas_pendentes"
                    color="green"
                    icon="mdi-arrow-down-thin-circle-outline"
                />
            </v-col>

            <v-col
                cols="12"
                md="4"
            >
                <AppCard
                    subtitle="Receitas recebidas"
                    :loading="isPending"
                    size="40"
                    :value="sumary.receitas_efetivadas"
                    color="green"
                    icon="mdi-arrow-up-thin-circle-outline"
                />
            </v-col>

            <v-col
                cols="12"
                md="4"
            >
                <AppCard
                    subtitle="Total"
                    :loading="isPending"
                    size="40"
                    :value="sumary.total_geral"
                    color="primary"
                    icon="mdi-scale-balance"
                />
            </v-col>
            </div>
        </v-row>

        <v-card
            rounded="xl"
            elevation="2"
            class="overflow-hidden"
            :loading="isPending"
        >
            <v-card-text class="pa-5">
                <v-expand-transition>
                    <div
                        v-show="isFiltered"
                        class="d-flex flex-wrap align-center ga-2 mb-4"
                    >
                        <span class="font-weight-bold text-blue-grey-darken-4">
                            Filtros:
                        </span>

                        <v-chip
                            v-if="lastFilter?.start_day && lastFilter.end_day"
                            color="primary"
                            closable
                            @click:close="handleClearFilterAdvanced('period')"
                        >
                            {{ `De ${new Date(lastFilter?.start_day ?? new Date()).toLocaleDateString('pt-br', { timeZone: 'UTC' })} à ${new Date(lastFilter?.end_day ?? new Date()).toLocaleDateString('pt-br', { timeZone: 'UTC' })}` }}
                        </v-chip>

                        <v-chip
                            v-for="categorie in lastFilterLabels.cats"
                            :key="categorie?.name"
                            value="categories"
                            closable
                            @click:close="handleClearFilterAdvanced('categories', lastFilter, categorie?.id)"
                        >
                            {{ categorie?.name }}
                        </v-chip>

                        <v-chip
                            v-for="account in lastFilterLabels.accs"
                            :key="account?.name"
                            closable
                            @click:close="handleClearFilterAdvanced('accounts', lastFilter, account?.id)"
                        >
                            {{ account?.name }}
                        </v-chip>

                        <v-chip
                            v-if="lastFilter?.situation"
                            closable
                            :color="lastFilter?.situation === 'Pagas' || lastFilter?.situation === 'Recebidas' ? 'success' : 'error'"
                            @click:close="handleClearFilterAdvanced('situation', lastFilter)"
                        >
                            {{ lastFilter?.situation }}
                        </v-chip>

                        <v-chip
                            v-for="type in lastFilter?.for_type"
                            :key="type"
                            color="primary"
                            closable
                            @click:close="handleClearFilterAdvanced('for_type', lastFilter)"
                        >
                            {{ type }}
                        </v-chip>
                    </div>
                </v-expand-transition>

                <div
                    v-if="!isFiltered"
                    class="mb-4"
                >
                    <DateInput @apply-filter-month="handleGetPeriod" />
                </div>

                <v-text-field
                    v-model="search"
                    label="Pesquisar"
                    prepend-inner-icon="mdi-magnify"
                    variant="solo-filled"
                    density="comfortable"
                    hide-details
                    single-line
                />
            </v-card-text>

            <v-divider />

            <v-data-table
                :headers="headers"
                :items="tableData!"
                :search="search"
                :loading="isPending"
                mobile-breakpoint="md"
                items-per-page="6"
            >
                <template #item.status_transaction="{ item }">
                    <v-icon
                        :color="item.status_transaction === 'recebido' || item.status_transaction === 'pago' ? 'green' : 'red'"
                        :icon="item.status_transaction === 'recebido' || item.status_transaction === 'pago' ? 'mdi-check-circle' : 'mdi-alert-circle'"
                    />

                    <v-tooltip
                        activator="parent"
                        location="top"
                    >
                        {{ item.status_transaction === 'recebido' || item.status_transaction === 'pago' ? 'Efetivada' : 'Pendente' }}
                    </v-tooltip>
                </template>

                <template #item.value_transaction="{ item }">
                    <v-chip color="green">
                        {{ formatCurrency(item.value_transaction) }}
                    </v-chip>
                </template>

                <template #item.description_transaction="{ item }">
                    <span>
                        {{ item.description_transaction }}

                        <span v-if="item.total_installments">
                            {{ `(${item.installment_current} / ${item.total_installments})` }}
                        </span>
                    </span>
                    <span v-if="item.url_recibo">
                        <v-btn @click="openShowRecibo(item.url_recibo!)" v-tooltip="'Recibo'" variant="text" icon="mdi-receipt-text-check" color="primary"></v-btn>
                            <v-dialog max-width="500" v-model="showImageRecibo">
                                <template v-slot:default="{ isActive }">
                                    <v-card rounded="lg" class="pa-2">
                                        
                                        <div class="d-flex align-center justify-center position-relative pa-4">
                                            <span class="text-h6 font-weight-medium">Visualizar anexo</span>

                                            <v-btn
                                                icon="mdi-close"
                                                variant="text"
                                                density="comfortable"
                                                class="position-absolute"
                                                style="top: 8px; right: 8px;"
                                                @click="isActive.value = false"
                                            />
                                        </div>

                                        <v-card-text>
                                            <v-img
                                                :lazy-src="currentReciboUrl!"
                                                max-height="600"
                                                contain
                                                :src="currentReciboUrl!"
                                                rounded="lg"
                                            >
                                                <template v-slot:placeholder>
                                                    <div class="d-flex align-center justify-center fill-height">
                                                        <v-progress-circular indeterminate />
                                                    </div>
                                                </template>
                                            </v-img>
                                        </v-card-text>

                                    </v-card>
                                </template>
                            </v-dialog>
                    </span>
                </template>

                <template #item.date_transaction="{ item }">
                    {{ formatDate(item.date_transaction) }}
                </template>

                <template #item.actions="{ item }">
                    <v-menu transition="slide-y-transition">
                        <template #activator="{ props }">
                            <v-btn
                                icon="mdi-dots-vertical"
                                variant="text"
                                v-bind="props"
                            />
                        </template>

                        <v-list
                            density="comfortable"
                            class="pa-2"
                        >
                            <v-list-item
                                v-for="action in getOptions(item)"
                                :key="action.title"
                                :value="action.value"
                                :prepend-icon="action.icon"
                                rounded="lg"
                                @click="handleOptionClick(action, item)"
                            >
                                <v-list-item-title>
                                    {{ action.title }}
                                </v-list-item-title>
                            </v-list-item>
                        </v-list>
                    </v-menu>
                </template>
            </v-data-table>
        </v-card>
            <BaseModal
            :persistent-modal="true"
            :model-value="modalHelp"
            title="Recomendações"
            @close-modal="closeModalHelpInvoice"
        >
            <div class="pa-4">
                <p>
                    O pagamento da fatura gera automaticamente um
                    <strong>lançamento em Transações</strong>.
                </p>

                <p>
                    Caso algum lançamento desta fatura esteja incorreto,
                    acesse a tela de <strong>Cartões de crédito</strong>,
                    <strong>reabra a fatura</strong> e realize os ajustes necessários
                    nos lançamentos. Após concluir, <strong>feche a fatura novamente</strong>.
                </p>

                <p>
                    <strong>Importante:</strong> alterações nos lançamentos da fatura devem ser
                    realizadas na tela de <strong>Cartões de crédito</strong>, e não neste
                    lançamento de pagamento.
                </p>

                <p class="mb-0">
                    Esse processo mantém um <strong>padrão de registro e rastreabilidade</strong>,
                    preservando a <strong>integridade do histórico financeiro</strong> e facilitando
                    futuras <strong>auditorias e conferências</strong>.
                </p>
            </div>
        </BaseModal>
    </v-container>
</template>

<style scoped>
.main-cards {
    width: 100%;
    margin: 10px;
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
}

@media (max-width: 1400px) {
    .main-cards {
        display: grid;
        grid-template-columns: 1fr;
        padding: 0 6px 0 6px;
    }

}
</style>