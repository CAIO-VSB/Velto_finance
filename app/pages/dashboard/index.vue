<script setup lang="ts">

    definePageMeta({
        title: "Dashboard",
        layout: "layout-dashboard",
    })

    import BaseFab from "~/components/ui/BaseFab.vue";
    import AppCard from '~/components/ui/AppCard.vue'
    import BaseCard from '~/components/ui/BaseCard.vue';
    import DateInput from '~/components/ui/DateInput.vue'
    import { useHttpDashboard } from "~/composables/useHttp/useHttpDashboard"
    import { useHttpMovements } from '~/composables/useHttp/useHttpMovements'
    import { useHttpAccounts } from "~/composables/useHttp/useHttpAccounts"
    
    import { useDonutChart } from "~/composables/useVueCharts/useDonuChart"
    import { useLineChart } from "~/composables/useVueCharts/useLineChart"
    import { useBarChart, type BarDatum } from "~/composables/useVueCharts/useBarChart"
    import type { TPeriod } from '~~/types/period/TPeriod';
import DialogHelpDashboard from "./components/DialogHelpDashboard.vue";

    const { getExpenseByCategorie, getRenevueByCategorie, getAllSumary, getTotalByCards, getLastMovements, getExpensesByThreeMonths, getBalanceEvolution } = useHttpDashboard()
    const { getCurrentBalance, getMoviments } = useHttpMovements()
    const { getAllAccounts } = useHttpAccounts()

    const period = ref({
        month: new Date().getMonth(),
        year: new Date().getFullYear(),
    })

    const showDialogHelpDashboard = ref(false)

    const { data:expenseByCategorie, isPending:isPendingExpenseByCategorie, refetch:refetchByCategorieExpense } = useQuery({
        queryKey: QUERY_KEYS.dashboard.expenseByCategorie,
        queryFn: () => getExpenseByCategorie(period.value.month, period.value.year)
    })

    const { data:renevueByCategorie, isPending:isPendingByCategorieRenevue, refetch:refecthByCategorieRenevue } = useQuery({
        queryKey: QUERY_KEYS.dashboard.renevueByCategorie,
        queryFn: () => getRenevueByCategorie(period.value.month, period.value.year)
    })

    const { data:dataSumary, isPending:isPendingSumary, refetch:refecthSumary } = useQuery({
        queryKey: QUERY_KEYS.dashboard.sumary,
        queryFn: () => getAllSumary(period.value.month, period.value.year)
    })

    const { data:currentBalance, isPending:isPendingCurrentBalance } = useQuery({
        queryKey: QUERY_KEYS.movements.current_balance,
        queryFn: getCurrentBalance
    })

    const { data:byCards, isPending:isPendingByCards, refetch:refecthByCards } = useQuery({
        queryKey: QUERY_KEYS.dashboard.cards,
        queryFn: () => getTotalByCards(period.value.month, period.value.year)
    })

    const { data:allAccounts, isPending: isPendingAccounts } = useQuery({
        queryKey: QUERY_KEYS.accounts.all,
        queryFn: getAllAccounts,
    })

    const { data: allMovements, isPending: isPendingMovements, refetch: refetchMovements } = useQuery({
        queryKey: QUERY_KEYS.movements.all,
        queryFn: () => getMoviments(period.value.month, period.value.year)
    })

    const { data: allLastMovements, isPending: isPendingLastMovements, refetch: refetchLastMovements } = useQuery({
        queryKey: QUERY_KEYS.dashboard.lastMovements,
        queryFn: () => getLastMovements(period.value.month, period.value.year)
    })

    const { data: allExpenseThreeMonths, isPending: isPendingExpenseThreeMonths, refetch: refetchExpenseThreeMonths } = useQuery({
        queryKey: QUERY_KEYS.dashboard.expenseByThreeMonths,
        queryFn: () => getExpensesByThreeMonths(period.value.month, period.value.year)
    })

    const { data: allBalanceEvolution, isPending: isPendingBalanceEvolution, refetch: refetchBalanceEvolution } = useQuery({
        queryKey: QUERY_KEYS.dashboard.balanceEvolution,
        queryFn: () => getBalanceEvolution(period.value.month, period.value.year)
    })


    const onlyAccountsActive = computed(() => {
        return allAccounts.value?.filter(item => item.active === true) 
    })

    const onlyExpenseActive = computed(() => {
        return allMovements.value?.filter(item => item.type_transaction === 'despesa') 
    })

    const balanceCurrent = computed(() => {        
        const row = currentBalance.value?.[0]

        return {
            saldo_atual: Number(row?.saldo_atual ?? 0.00)
        }
        
    })
    
    const balanceByCards = computed(() => {        
        const row = byCards.value?.[0]

        return {
            total_cartoes: Number(row?.t_cartoes ?? 0.00)
        }
        
    })

    const summary = computed(() => {

        const row = dataSumary.value?.[0]

        return {
            receitas: Number(row?.t_receitas ?? 0),
            despesas: Number(row?.t_despesas ?? 0),
            balancoMensal: Number(row?.balanco_mensal ?? 0)
        }
    })



    const totalExpensesPending = computed(() => {
        const result = allMovements.value
        ?.filter(item => (item.status_transaction === 'pendente' && item.type_transaction === 'despesa'))
        .reduce((acc, item) => acc + Number(item.value_transaction), 0) ?? 0.00

        return result
    })

    const totalRenevuePending = computed(() => {
        const result = allMovements.value
        ?.filter(item => (item.status_transaction === 'pendente' && item.type_transaction === 'receita'))
        .reduce((acc, item) => acc + Number(item.value_transaction), 0) ?? 0.00

        return result
    })


    const totalByRenevue = computed(() => {
        const result = renevueByCategorie.value?.reduce((acc, item) => {
            return acc + item.value 
        }, 0)

        return result
    })

    const totalByExpense = computed(() => {
        const result = expenseByCategorie.value?.reduce((acc, item) => {
            return acc + item.value 
        }, 0)

        return result
    })

    function navigateToTransaction() {
        navigateTo("/transactions")
    }

    function closeModalHelpDashboard() {
        showDialogHelpDashboard.value = false
    }


    function handleGetPeriod(value: TPeriod) {
        period.value = value
        refecthByCategorieRenevue()
        refetchByCategorieExpense()
        refecthByCards()
        refecthSumary()
        refetchLastMovements()
        refetchMovements()
        refetchExpenseThreeMonths()
        refetchBalanceEvolution()
    }

    const barData = computed<BarDatum[]>(() => [
        { name: 'Receitas', value: summary.value.receitas, color: '#2BB673' },
        { name: 'Despesas', value: summary.value.despesas, color: '#FF6B6B' },
    ])

    const { option: expenseOption } = useDonutChart(computed(() => expenseByCategorie.value ?? []), ['62%', '50%'] )
    const { option: renevueOption } = useDonutChart(computed(() => renevueByCategorie.value ?? []), ['55%', '50%'])
    const { option: balancoOption } = useBarChart(barData)
    const { option: balanceExpenseThreeMonths } = useBarChart(computed(() => allExpenseThreeMonths.value ?? []))
    const { option: balanceEvolution } = useLineChart(computed(() => allBalanceEvolution.value ?? []))



</script>

<template>

    <DialogHelpDashboard 
    v-model="showDialogHelpDashboard"
    @close-modal="closeModalHelpDashboard"
    />
    
    <div class="dashboard-wrapper">
        <div class="date-filter">
            <DateInput  @apply-filter-month="handleGetPeriod"/>
        </div>

        <div class="main-cards">
            <div class="card-full">
                <AppCard
                    subtitle="Saldo atual"
                    size="40"
                    :value="balanceCurrent.saldo_atual"
                    color="primary"
                    icon="mdi-bank"
                    :loading="isPendingSumary"
                    v-tooltip="'Total de dinheiro que entrou no período selecionado.'"
                />
            </div>

            <div class="card-item">
                <AppCard
                    subtitle="Receitas"
                    size="40"
                    :value="summary.receitas"
                    color="success"
                    icon="mdi-arrow-down-thin-circle-outline"
                    v-tooltip="'Total de dinheiro que entrou no período selecionado.'"
                    :loading="isPendingSumary"
                />
            </div>

            <div class="card-item">
                <AppCard
                    subtitle="Despesas"
                    size="40"
                    :value="summary.despesas"
                    color="error"
                    icon="mdi-arrow-up-thin-circle-outline"
                    v-tooltip="'Total de dinheiro que saiu no período selecionado.'"
                    :loading="isPendingSumary"
                />
            </div>

            <div class="card-item">
                <AppCard
                    subtitle="Cartões de crédito"
                    size="40"
                    :value="balanceByCards.total_cartoes"
                    color="primary"
                    icon="mdi-credit-card"
                    v-tooltip="'Total das faturas dos seus cartões de crédito no mês atual, incluindo as já pagas e as que ainda estão em aberto.'"
                    :loading="isPendingByCards"
                />
            </div>
        </div>

        <div class="charts-row">
            <BaseCard  title="Resumo de pendências" subtitle="Veja o que precisa da sua atenção" :loading="isPendingMovements">
                <div v-if="!totalExpensesPending && !totalRenevuePending">
                    <v-empty-state
                        icon="mdi-calendar-check-outline"
                        color="primary"
                        title="Opa! Você não possui pendências no momento."
                    >
                        <template #text>
                            <span>
                                Suas contas e movimentações estão em dia.
                            </span>
                        </template>
                    </v-empty-state>
                </div>
                <div class="pa-5" v-else>
                    <div class="d-flex align-center ga-4">
                        <span class="text-no-wrap font-weight-bold">Total de despesas pendentes</span>
                        <div class="d-flex justify-end w-100">
                            <v-chip class="font-weight-bold" variant="text" color="red"><span class="d-flex justify-end mr-5">{{ formatCurrency(totalExpensesPending) }}</span></v-chip>
                        </div>
                    </div>
                    <v-divider style="margin-top: 10px; margin-bottom: 10px;"></v-divider>
                    <div class="d-flex align-center ga-4">
                        <span class="text-no-wrap font-weight-bold">Total de receitas pendentes</span>
                        <div class="d-flex justify-end w-100">
                            <v-chip class="font-weight-bold" variant="text" color="green"><span class="d-flex justify-end mr-5">{{ formatCurrency(totalRenevuePending) }}</span></v-chip>
                        </div>
                    </div>
                    <v-divider style="margin-top: 80px; margin-bottom: 10px; color: black;"></v-divider>
                    <div class="d-flex align-center justify-center" style="margin-bottom: -10px;">
                        <v-btn v-tooltip="'Ir para a tela de transações'" @click="navigateToTransaction" color="primary" variant="text">
                        VER MAIS    
                        </v-btn>
                    </div>
                </div>
            </BaseCard>
            
            <BaseCard :loading="isPendingMovements" title="Últimos lançamentos" subtitle="Confira suas movimentações recentes" >
                <v-empty-state
                    v-if="!allLastMovements?.length"
                    icon="mdi-history"
                    color="primary"
                    title="Opa! Você ainda não possui lançamentos este mês."
                >
                    <template #text>
                        <span>
                            Adicione uma receita ou despesa para visualizar seus últimos lançamentos.
                        </span>
                    </template>
                </v-empty-state>
                <div class="pa-5" v-else>
                    <v-table height="200px">
                        <thead>
                            <tr>
                                <th class="text-left font-weight-bold">
                                Tipo
                                </th>
                                <th class="text-left font-weight-bold">
                                Data
                                </th>
                                <th class="text-left font-weight-bold">
                                Descrição
                                </th>
                                <th class="text-left font-weight-bold">
                                valor
                                </th>
                                <th class="text-left font-weight-bold">
                                Conta bancária
                                </th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr
                                v-for="item in allLastMovements"
                                :key="item.id"
                            >
                                <td class="text-capitalize">{{item.type_recurrence|| "avulsa" }}</td>

                                <td>{{ formatDate(item.date_transaction) }}</td>

                                <td>
                                    <span>{{ item.description_transaction }}

                                    <span v-if="item.total_installments">
                                        {{ `(${item.installment_current} / ${item.total_installments})` }}
                                    </span>

                                </span>
                                </td>
                                <td><v-chip :color="(item.type_transaction === 'receita') ? 'success' : 'red'">{{ formatCurrency(item.value_transaction)}}</v-chip></td>
                                <td>{{ item.name_accounts }}</td>
                            </tr>
                        </tbody>
                    </v-table>
                </div>
                
            </BaseCard>

            <BaseCard :loading="isPendingByCategorieRenevue" title="Frequência de gastos" subtitle="Identifique os períodos com mais gastos" >
                <div class="d-flex align-center justify-center"  v-if="!onlyExpenseActive?.length" style="height: 510px;">
                    <v-empty-state
                        icon="mdi-chart-timeline-variant"
                        color="green"
                        title="Ainda não há dados de gastos"
                        >
                        <template #text>
                            <span>Registre suas despesas para identificar seus hábitos de consumo.</span>
                        </template>
                    </v-empty-state>
                </div>
                <div class="pa-5" v-else>
                    <VChart class="mt-4" :option="balanceExpenseThreeMonths" autoresize style="height: 430px"/>
                </div>
            </BaseCard>
            <BaseCard :loading="isPendingByCategorieRenevue" title="Evolução do saldo" subtitle="Veja como seu saldo evolui ao longo do tempo">
                <div class="d-flex align-center justify-center"  v-if="!allMovements?.length" style="height: 510px;">
                    <v-empty-state
                        icon="mdi-chart-line"
                        color="green"
                        title="Sua evolução começa aqui"
                        >
                        <template #text>
                            <span>Adicione movimentações para acompanhar a evolução do seu saldo ao longo do tempo.</span>
                        </template>
                    </v-empty-state>
                </div>
                <div class="pa-5" v-else>
                    <VChart class="mt-5" :option="balanceEvolution" autoresize style="height: 430px"/>
                </div>
            </BaseCard>

            <BaseCard :loading="isPendingExpenseByCategorie" title="Despesas por categoria" subtitle="Visualize onde seus gastos estão concentrados">
                <div class="d-flex align-center justify-center"  v-if="!allMovements?.length" style="height: 510px;">
                    <v-empty-state
                        icon="mdi-chart-donut"
                        color="error"
                        title="Nenhuma despesa registrada"
                        >
                        <template #text>
                            <span>Registre suas despesas para visualizar onde seu dinheiro está sendo gasto.</span>
                        </template>
                    </v-empty-state>
                </div>
                <div class="pa-4" v-else>
                    <VChart class="mt-5" :option="expenseOption" autoresize style="height: 430px"/>
                    <div class="d-flex justify-end pa-1">
                        <v-sheet :width="220" :height="25" class="rounded-lg px-3" border>
                            <span class="text-medium-emphasis">
                                Total geral: 
                            </span>
                            <span class="font-weight-bold">
                                {{ formatCurrency(totalByExpense ?? 0.00) }}
                            </span>
                        </v-sheet>
                    </div>
                </div>
            </BaseCard>

                        <BaseCard :loading="isPendingByCategorieRenevue" title="Receitas por categoria" subtitle="Visualize a origem das suas receitas">
                <div class="d-flex align-center justify-center"  v-if="!allMovements?.length" style="height: 510px;">
                    <v-empty-state
                        icon="mdi-chart-pie-outline"
                        color="green"
                        title="Nenhuma receita registrada"
                        >
                        <template #text>
                            <span>Registre suas receitas para acompanhar a origem dos seus ganhos.</span>
                        </template>
                    </v-empty-state>
                </div>
                <div class="pa-5" v-else>
                    <VChart class="mt-5" :option="renevueOption" autoresize style="height: 430px"/>
                    <div class="d-flex justify-end pa-1">
                        <v-sheet :width="220" :height="25" class="rounded-lg px-3" border>
                            <span class="text-medium-emphasis">
                                Total geral: 
                            </span>
                            <span class="font-weight-bold">
                                {{ formatCurrency(totalByRenevue ?? 0.00) }}
                            </span>
                        </v-sheet>
                    </div>
                </div>
            </BaseCard>
        </div>

        <div class="charts-row charts-row-single">
            <BaseCard :loading="isPendingCurrentBalance" title="Balanço mensal" subtitle="Compare suas receitas e despesas mensais">
                <div class="d-flex align-center justify-center"  v-if="!allMovements?.length" style="height: 510px;">
                    <v-empty-state
                        icon="mdi-scale-balance"
                        color="primary"
                        title="Sem dados para o balanço"
                        >
                        <template #text>
                            <span>Adicione receitas e despesas para acompanhar seu balanço mensal.</span>
                        </template>
                    </v-empty-state>
                </div>
                <div class="pa-5 d-flex justify-center charts-balanco" v-else>
                    <VChart class="mt-4" :option="balancoOption" autoresize style="height: 430px"/>
                    <div class="w-100 mt-8 d-flex flex-column ga-4">
                        <div class="d-flex align-center">
                            <span class="font-weight-bold">Receitas</span>
                            <div class="d-flex justify-end w-100">
                                <v-chip class="font-weight-bold" variant="text" color="success">{{ formatCurrency(summary.receitas) }}</v-chip>
                            </div>
                        </div>

                        <div class="d-flex align-center">
                            <span class="font-weight-bold">Despesas</span>
                            <div class="d-flex justify-end w-100">
                                <v-chip class="font-weight-bold" variant="text" color="red">{{ formatCurrency(summary.despesas) }}</v-chip>
                            </div>
                        </div>
                       
                        <v-divider></v-divider>
                        
                        <div class="d-flex align-center">
                            <span class="font-weight-bold">Balanço</span>
                            <div class="d-flex justify-end w-100">
                                <v-chip class="font-weight-bold" variant="text" :color="(summary.balancoMensal <= 0) ? 'red' : 'success' ">{{ formatCurrency(summary.balancoMensal) }}</v-chip>
                            </div>
                        </div>
                    </div>
                </div>
            </BaseCard>

            <BaseCard :loading="isPendingAccounts" title="Minhas contas" subtitle="Visualize o saldo das suas contas ativas">
                <div
                    class="d-flex align-center justify-center"
                    v-if="!onlyAccountsActive?.length"
                    style="height: 510px;"
                >
                    <v-empty-state
                        icon="mdi-bank-outline"
                        color="primary"
                        title="Você ainda não possui contas."
                    >
                        <template #text>
                            <span>
                                Adicione uma conta bancária para começar a controlar seu saldo e suas movimentações.
                            </span>
                        </template>
                    </v-empty-state>
                </div>
                <div class="pa-5" v-for="value in onlyAccountsActive" :key="value.id" v-else>
                    <div class="d-flex align-center ga-4">
                        <div>
                            <v-img
                            :width="40"
                            rounded="lg"
                            :src="value.url_image"
                            ></v-img>
                        </div>
                        <span class="font-weight-bold">{{ value.name_identifier }}</span>
                        
                    </div>
                    <div class="mt-3">
                        <div class="d-flex justify-end align-center ">
                            <div class="d-flex justify-start w-100">
                                <span class="text-medium-emphasis text-no-wrap mr-3">Saldo atual</span>
                            </div>
                             <v-chip class="font-weight-bold" variant="text" :color="(value.saldo_atual! <= 0) ? 'red' : 'green'"><span class="font-weight-bold mr-4">{{ formatCurrency(value.saldo_atual ?? 0.00) }}</span></v-chip>
                        </div>
                        <v-divider></v-divider>
                    </div>
                </div>
            </BaseCard>
        </div>
    </div>

    <div class="fab-wrapper">
        <v-tooltip
            text="Entenda o dashboard"
            location="left"
        >
            <template #activator="{ props }">
                <BaseFab
                    v-bind="props"
                    color="primary"
                    icon="mdi-help"
                    size="50"
                    @click="showDialogHelpDashboard = true"
                />
            </template>
        </v-tooltip>
    </div>

</template>

<style scoped>

.dashboard-wrapper {
    width: 100%;
    padding: 24px;
}

.date-filter {
    margin-bottom: 32px;
}

.main-cards {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 15px;
    width: 100%;
}

.charts-row {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 20px;
    width: 100%;
    margin-top: 40px;
}

.charts-row-single {
    grid-template-columns: repeat(2, 1fr);
}

.fab-wrapper {
  position: fixed;
  right: 24px;
  bottom: 24px;
  z-index: 10;
  display: flex;
  flex-direction: column;
  gap: 10px;
}



@media (max-width: 1450px) {
    .main-cards {
        grid-template-columns: repeat(2, 1fr);
    }

    .charts-row {
        grid-template-columns: 1fr;
    }
}

@media (max-width: 960px) {
    .main-cards {
        grid-template-columns: repeat(2, 1fr);
    }

    .charts-row {
        grid-template-columns: 1fr;
    }

    .charts-balanco {
        display: flex;
        flex-direction: column;
    }
}


@media (max-width: 600px) {
    .dashboard-wrapper {
        padding: 16px;
    }

    .main-cards {
        grid-template-columns: 1fr;
    }

    .charts-balanco {
        display: flex;
        flex-direction: column;
    }
}

</style>