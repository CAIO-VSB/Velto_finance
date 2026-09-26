<script setup lang="ts">

    definePageMeta({
        title: "Transações",
        layout: "layout-dashboard"
    })

    import { useHttpTransfer } from '~/composables/useHttp/useHttpTransfer'
    import { useHttpMovements } from '~/composables/useHttp/useHttpMovements'
    import DateInput from '~/components/ui/DateInput.vue'
    import type { TTransfer } from '~~/types/transfer/TTransfer'
    import type { TOptionAction } from '~~/types/option_action/TOptionAction'
    import type { TPeriod } from '~~/types/period/TPeriod'
    import CardAddTransfer from '~/components/forms/CardAddTransfer.vue'
    import CardEditTransfer from '~/components/forms/CardEditTransfer.vue'
    import CardDeleteTransfer from '~/components/forms/CardDeleteTransfer.vue'
    import type { TTransferPayload } from '~~/schemas/transfer.schema'
    import AppCard from '~/components/ui/AppCard.vue'

    type option = {
        title: string,
        color: string,
        value: string,
        route: string
    }

    const { getTransfer } = useHttpTransfer()
    const { getMoviments, getCurrentBalance } = useHttpMovements()
    const {  notifyInfo, notifySuccess, notifyError } = useNotify()

    const editDraft = ref<TTransfer | null>(null)
    const confirmDraft = ref<TTransferPayload | null>(null)
   
    const route = useRoute()
    const search = ref('')
    const modalAddTransfer = ref(false)
    const modalEditTransfer = ref(false)
    const cardDeleteTransfer = ref(false)
    const teste = ref(true)
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


    const { data:movements, isPending:isPendingMovements, refetch:RefetchMovements } = useQuery({
        queryKey: QUERY_KEYS.movements.all,
        queryFn: () => getMoviments(period.value.month, period.value.year)
    })

    const { data:currentBalance, isPending:isPendingCurrentBalance } = useQuery({
        queryKey: QUERY_KEYS.movements.current_balance,
        queryFn: getCurrentBalance
    })
  
    const { data, isPending, refetch } = useQuery({
        queryKey: QUERY_KEYS.tranfer.all,
        queryFn: () => getTransfer(period.value.month, period.value.year),
    })

    function handleGetPeriod(value: TPeriod) {
        period.value = value
        refetch()
        RefetchMovements()
    }

    
    const sumary = computed(() => {

        const row = movements.value?.[0]

        return {
            receitas: Number(row?.t_receitas ?? 0.00),
            despesas: Number(row?.t_despesas ?? 0.00),
            balanco_mensal: Number(row?.balanco_mensal ?? 0.00),
            saldo_atual: Number(row?.saldo_atual ?? 0.00)
        }
    })

    const balanceCurrent = computed(() => {
        
        const row = currentBalance.value?.[0]

        return {
            saldo_atual: Number(row?.saldo_atual ?? 0.00)
        }

    })

    const itemsRouter = [
        { title: 'Todas as transações', color: "#673AB7", value: "todas",          route: "/transactions" },
        { title: 'Despesas',            color: "#F44336", value: "despesas",       route: "/transactions/expense" },
        { title: 'Receitas',            color: "#4CAF50", value: "receitas",       route: "/transactions/revenue" },
        { title: 'Transferências',      color: "#2196F3", value: "transferencias", route: "/transactions/transfer" },
    ]
        
    const headers = [
        { key: 'date_transfer', title: 'Data'  },
        { key: 'observation', title: 'Observação' },
        { key: 'account_origin_name', title: 'De' },
        { key: 'account_destination_name', title: 'Para' },
        { key: 'value_transfer', title: 'Valor' },
        { key: 'actions', title: 'Ações' },
    ]

    const currentItem = computed(() => {
       return itemsRouter.find(item => item.route === route.path)
    })

    const titleButtonOption = computed(() => {
        return currentItem.value?.title ?? "Todas"
    })

    const ColorButtonOption = computed(() => {
        return currentItem.value?.color
    })

    function getTitleRouter(item: option) {
        navigateTo(item.route)
    }

    function getOptions(): TOptionAction [] {
        return [
        { title: 'Editar',  value: "edit", icon: "mdi-pencil" },
        { title: 'Deletar', value: "delete", icon: "mdi-delete-forever" }
        ]
    } 

    function handleOpenModalEditTransfer(transfer: TTransfer) {

        console.log("Está passando o id?", transfer.id)
    
        //Usamos structuredClone + toRaw para evitar mutar o objeto reativo do Vue
        const rawTransfer =  structuredClone(toRaw(transfer))

        editDraft.value = parseTransferToEdit(rawTransfer)

        modalEditTransfer.value = true
    }

    function handleOptionClick(option: TOptionAction, data: TTransfer) {

        if (option.value === "edit") {
            handleOpenModalEditTransfer(data)
            return 
        }

        if (option.value === "arquivo") {
            notifyInfo("Em desenvolvimento", "Estamos trabalhando nesta funcionalidade para disponibilizá-la em breve.", 6000, true)
            return
        }

        const raw = structuredClone(toRaw(data))

        if (!raw.date_transfer) {
            notifyError(
                "Data inválida",
                "Não foi possível concluir a ação porque a data informada é inválida ou está ausente.",
            )
            return
        }

        const dateFormated = dateToDateOnly(raw.date_transfer)

        const payload = {
            ...raw,
            value_transfer: Number(raw.value_transfer ?? 0),
            date_transfer: dateFormated,
        }

        if (option.value === "delete") {
            confirmDraft.value = payload
            payload.is_deleted = true
            labelOptions.value.colorButton = "blue"
            labelOptions.value.textButton = "Deletar"
            labelOptions.value.title = "Deletar transferência"
            labelOptions.value.text = "Essa ação não poderá ser desfeita."
            cardDeleteTransfer.value = true
            return
        }
    }
 
</script>

<template>
    <v-container
        fluid
        class="mt-6 pa-4 pa-md-6"
    >
        <CardAddTransfer v-model="modalAddTransfer" />

        <CardEditTransfer
            v-model="modalEditTransfer"
            :draft="editDraft"
        />

        <CardDeleteTransfer
            v-model="cardDeleteTransfer"
            :draft="confirmDraft"
            :title-botton="labelOptions.textButton"
            :title="labelOptions.title"
            :text="labelOptions.text"
            :color-botton="labelOptions.colorButton"
        />

        <v-row
            align="center"
            class="mb-6"
        >
            <v-col
                class="main-btn-option"
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
                        elevation="2"
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
            class="d-flex justify-md-end ga-3"
            >
                <v-btn
                    :color="ColorButtonOption"
                    prepend-icon="mdi-plus"
                    variant="flat"
                    rounded="lg"
                    class="text-none font-weight-bold btn-add-transfer"
                    @click="modalAddTransfer = true"
                >
                    Nova transferência
                </v-btn>
            </v-col>
        </v-row>

        <v-row class="mb-6">  
            <div class="main-cards">
            <v-col
                cols="12"
                sm="6"
                lg="3"
                md="6"
            >
                <AppCard
                    subtitle="Saldo atual"
                    :loading="isPendingCurrentBalance"
                    size="40"
                    :value="balanceCurrent.saldo_atual"
                    color="primary"
                    icon="mdi-bank"
                    text-tool-tip="O cálculo do saldo atual é independente do período selecionado, considerando o saldo inicial das contas ativas juntamente com todas as movimentações efetivadas de entrada e saída"
                    icon-tool-tip="mdi-information-outline"
                    size-icon-tool-tip="20px"
                />
            </v-col>

            <v-col
                cols="12"
                sm="6"
                lg="3"
            >
                <AppCard
                    subtitle="Receitas"
                    :loading="isPending"
                    size="40"
                    :value="sumary.receitas"
                    color="success"
                    icon="mdi-arrow-down-thin-circle-outline"
                    text-tool-tip="O valor apresentado corresponde à soma de todas as receitas efetivadas registradas nas contas ativas"
                    icon-tool-tip="mdi-information-outline"
                    size-icon-tool-tip="20px"
                />
            </v-col>

            <v-col
                cols="12"
                sm="6"
                lg="3"
            >
                <AppCard
                    subtitle="Despesas"
                    :loading="isPending"
                    size="40"
                    :value="sumary.despesas"
                    color="error"
                    icon="mdi-arrow-up-thin-circle-outline"
                    text-tool-tip="O valor apresentado corresponde à soma de todas as despesas efetivadas registradas nas contas ativas"
                    icon-tool-tip="mdi-information-outline"
                    size-icon-tool-tip="20px"
                />
            </v-col>

            <v-col
                cols="12"
                sm="6"
                lg="3"
            >
                <AppCard
                    subtitle="Balanço mensal"
                    :loading="isPending"
                    size="40"
                    :value="sumary.balanco_mensal"
                    color="primary"
                    icon="mdi-scale-balance"
                    text-tool-tip="O balanço mensal é calculado com base na soma de todas as receitas efetivadas menos todas as despesas efetivadas do período selecionado"
                    icon-tool-tip="mdi-information-outline"
                    size-icon-tool-tip="20px"
                />
            </v-col>
            </div>
        </v-row>

        <v-card
            v-if="!isPending"
            rounded="xl"
            elevation="2"
            class="overflow-hidden"
        >
            <v-card-text class="pa-5">
                <div class="mb-4">
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
                :items="data"
                :search="search"
                mobile-breakpoint="md"
                :loading="isPending"
            >
                <template #item.account_origin_name="{ item }">
                    <div class="d-flex align-center ga-2">
                        <v-avatar size="30">
                            <v-img :src="item.logo_origem" />
                        </v-avatar>

                        <span>{{ item.account_origin_name }}</span>
                    </div>
                </template>

                <template #item.account_destination_name="{ item }">
                    <div class="d-flex align-center ga-2">
                        <v-avatar size="30">
                            <v-img :src="item.logo_destino" />
                        </v-avatar>

                        <span>{{ item.account_destination_name }}</span>
                    </div>
                </template>

                <template #item.value_transfer="{ item }">
                    <v-chip color="primary">
                        {{ formatCurrency(item.value_transfer ?? 0.00) }}
                    </v-chip>
                </template>

                <template #item.date_transfer="{ item }">
                    {{ formatDate(item.date_transfer) }}
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
                                v-for="action in getOptions()"
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
    </v-container>
</template>

<style scoped>

.main-cards {
    width: 100%;
    margin: 10px;
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 16px;
}

:deep(.v-data-table-header__content) {
  font-weight: bold;
}

@media (max-width: 1400px) {
    .main-cards {
        display: grid;
        grid-template-columns: 1fr;
        padding: 0 6px 0 6px;
    }

}

@media (max-width: 690px) {

    .main-btn-option {
        display: flex;
        width: 100%;
        flex-direction: column;
    }


    .btn-add-transfer {
        width: 100%;
    }

}
</style>
