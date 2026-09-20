<script setup lang="ts">

    definePageMeta({
        title: "Metas de economia / Extrato",
        layout: "layout-dashboard",
    })

    import metaLogo from "~/assets/Target With Dollar Sign.webp"
    import BaseFab from "~/components/ui/BaseFab.vue";
    import { useInvalidate } from "~/composables/useInvalidate"
    import CardMovementsGoals from "~/pages/economy/components/CardMovementsGoals.vue";
    import DateInput from '~/components/ui/DateInput.vue'
    import type { TPeriod } from "~~/types/period/TPeriod"
    import type { TGoals } from "~~/types/goals/TGoals";
    import { useHttpGoals } from "~/composables/useHttp/useHttpGoals"
    import type { TGoalsPayload } from "~~/schemas/goals.schema";
    import CardAddMovementSGoals from "~/components/forms/CardAddMovementSGoals.vue";

    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    const { invalidate } = useInvalidate()
    const { getAllGoals, getMovementGoals, getBalanceForGoals } = useHttpGoals()

    export type TOptionActionGetOptions = {
        title: string,
        icon: string,
        value: string | boolean
    }

    const route = useRoute()
    const menu = ref(false)
    const modelAddMovement = ref(false)
    const editDraft = ref<TGoals | null>(null)
    const selectedGoals = ref<TGoalsPayload | null>(null)
    const selectedNameGoals = ref("")

    const period = ref({
        month: new Date().getMonth(),
        year: new Date().getFullYear(),
    })

    const { data, isPending: isPendingGoals } = useQuery({
        queryKey: QUERY_KEYS.goals.all,
        queryFn: getAllGoals,
    })

    const id = computed(() => Number(route.params.id))

    const currentGoalsId = computed(() => selectedGoals.value?.id ?? id.value)

    const { data: movementsGoals, isPending, refetch } = useQuery({
        queryKey: QUERY_KEYS.goals.movements(currentGoalsId.value),
        queryFn: () => getMovementGoals(currentGoalsId.value, period.value.month, period.value.year)
    })

    const { data: balanceForEconomy, isPending: isPendingBalance } = useQuery({
        queryKey: QUERY_KEYS.goals.balance_for_economy,
        queryFn: getBalanceForGoals
    })

    const onlyGoalsActive = computed(() => {
        return data.value?.filter(item => item.active === true)
    })

    function backScreenEconomy() {
        navigateTo("/economy")
    }

    /**
     * Watch responsável por escutar as mudanças nos dados vindo do banco de dados
     * Sempre que mudar algum dado e existir valor, buscamos pelo id e setamos o novos valores
     */
    watch(onlyGoalsActive, (val) => {
    if (val?.length) {
        //Sempre atualizar o selectedCardData com os dados mais recentes
        const current = val.find(item => item.id === id.value) ?? val[0]
        selectedNameGoals.value = current?.name_identifier ?? ""
        selectedGoals.value = current ?? null
    }
    }, {immediate: true})


    const totalForGoals = computed(() => {

        const row = balanceForEconomy.value?.find(item => item.id === currentGoalsId.value)

        return {
            total: Number(row?.total_lancado ?? 0),
            percentual: Number(row?.percentual ?? 0.00),
            meta: Number(row?.meta ?? 0.00)
        }

    })


    function handleGetPeriod(value: TPeriod) {
        period.value = value
        refetch()
    }

    function handleSelectedGoals(goals: TGoalsPayload) {
        selectedNameGoals.value = goals.name_identifier ?? ""
        selectedGoals.value = goals 
        menu.value = false
        //editDraft.value = structuredClone(toRaw(card))
        handleGetPeriod(period.value)
    }


</script>

<template>

    <div class="mt-4">
        <v-btn
        icon="mdi-arrow-left"
        variant="text"
        @click="backScreenEconomy"
        >
        </v-btn>
    </div>

    <v-container
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
                                                <v-img :src="metaLogo" />
                                            </v-avatar>
                                        </template>

                                        <span class="font-weight-bold text-blue-grey-darken-4 text-truncate">
                                            {{ selectedNameGoals }}
                                        </span>

                                        <template #append>
                                            <v-icon icon="mdi-chevron-down" />
                                        </template>
                                    </v-btn>
                                </template>

                                <v-card
                                    min-width="320"
                                    rounded="xl"
                                    elevation="4"
                                    class="overflow-hidden"
                                >
                                    <div class="pa-4">
                                        <div class="text-subtitle-1 font-weight-bold text-blue-grey-darken-4">
                                            Metas de economia
                                        </div>

                                        <div class="text-caption text-medium-emphasis mt-1">
                                            Selecione a meta que deseja consultar.
                                        </div>
                                    </div>

                                    <v-divider />

                                    <v-list
                                        density="comfortable"
                                        class="pa-2"
                                    >
                                        <v-list-item
                                            v-for="goals in onlyGoalsActive"
                                            :key="goals.id"
                                            :value="goals"
                                            :prepend-avatar="metaLogo"
                                            rounded="lg"
                                            @click="handleSelectedGoals(goals)"
                                        >
                                            <v-list-item-title class="font-weight-medium">
                                                {{ goals.name_identifier   }}
                                            </v-list-item-title>
                                        </v-list-item>
                                    </v-list>
                                </v-card>
                            </v-menu>

                        </div>

                        <div class="mt-6">
                            <template v-if="currentGoalsId">
                                <div class="d-flex align-center justify-space-between mb-2">
                                    <span class="text-body-2 text-medium-emphasis">
                                        Meta alcançada
                                    </span>

                                    <span class="text-body-2 font-weight-bold text-blue-grey-darken-4">
                                        {{ totalForGoals.percentual.toFixed() ?? 0.00 }}%
                                    </span>
                                </div>

                                <v-progress-linear
                                    :model-value="totalForGoals.percentual"
                                    :color="totalForGoals.percentual < 85 ? 'primary' : 'success'"
                                    height="12"
                                    rounded
                                />

                                <div class="d-flex justify-space-between mt-3 text-body-2 text-medium-emphasis">
                                    <span>{{ formatCurrency(totalForGoals.total ?? 0.00) }}</span>
                                    <span>de</span>
                                    <span>{{ formatCurrency(totalForGoals.meta ?? 0.00) }}</span>
                                </div>
                            </template>
                        </div>

                        <v-divider class="my-5" />

                        <DateInput  @apply-filter-month="handleGetPeriod" />
                    </v-card-text>

                </v-card>

            </v-col>

            <v-col
                cols="12"
                xl="8"
            >
              <CardMovementsGoals
              :select-goals="selectedGoals?.id || null"
              :goals="selectedGoals" 
              :movements-goals="movementsGoals || []"
              />
            </v-col>
        </v-row>

        <div>
            <CardAddMovementSGoals :goals-id="currentGoalsId" v-model="modelAddMovement"/>
        </div>

        <div class="fab-wrapper">
          <v-tooltip
            text="Novo lançamento"
            location="left"
          >
              <template #activator="{ props }">
                <BaseFab
                  v-bind="props"
                  color="primary"
                  icon="mdi-plus"
                  size="60"
                  v-tooltip="'Novo lançamento'"
                  @click="modelAddMovement = true"
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