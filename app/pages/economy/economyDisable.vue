<script setup lang="ts">

    definePageMeta({
        title: "Metas arquivadas",
        layout: "layout-dashboard",
    })

    import { useHttpGoals } from "~/composables/useHttp/useHttpGoals"
    import { useInvalidate } from "~/composables/useInvalidate"
    import type { TGoalsPayload } from "~~/schemas/goals.schema"
    import type { TGoals } from "~~/types/goals/TGoals"
  
    const { getAllGoals } = useHttpGoals()
    const { patchGoals, patchArchiveGoals } = useHttpGoals()
    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    const { invalidate } = useInvalidate()

    const loadingButton = ref(false)

    const headers = [
    { key: 'name_identifier', title: 'Descrição' },
    { key: 'goal_value', title: 'Meta total' },
    { key: 'start_date', title: 'Data de início' },
    { key: 'end_date', title: ' Data de término' },
    { key: 'actions', title: 'Ações' },
    ]

    const { data, isPending: isPendingGoals } = useQuery({
        queryKey: QUERY_KEYS.goals.all,
        queryFn: getAllGoals,
    })

    const { mutate, isPending  } = useMutation({

    mutationFn: ({id, active}: {id: number; active: boolean}) => patchArchiveGoals(id, active),

    onSuccess: () => {
        invalidate(QUERY_KEYS.goals.all)
        notifySuccess("Sucesso", "Operação realizada com sucesso", 6000)
    },

    onError: (error) => {
        handleErrorApplication(error.statusCode)
    },

    })

    const onlyGoalsDisable = computed(() => {
        return data.value?.filter(item => item.active === false)
    })

    watch(onlyGoalsDisable, (val) => {
        console.log("Valorea qui aaaaaaaa " + JSON.stringify(data.value))
    })

    const totalArchived = computed(() => {

        const total = data.value?.filter(item => item.active === false).reduce((acc, item) => {
            return Number(acc) + Number(item.goal_value)
        }, 0)

        return total

    })

    function backScreenAccounts() {
        navigateTo("/economy")
    }

    function restoreAccount(item: TGoalsPayload) {

        loadingButton.value = true

        try {

            if (!item) {
                notifyError("Error", "Economia não encontrada. Tente novamente")
                return
            }      

            mutate({id: item.id!, active: true})

        } catch (e) {
            console.log("Erro ao restautar conta", e)
        } finally {
            loadingButton.value = false
        }

    }

</script>

<template>
    <v-container
        fluid
        class="mt-6 pa-4 pa-md-6"
    >
        <div class="d-flex align-center ga-2 mb-6">
            <v-btn
              icon="mdi-arrow-left"
              variant="text"
              @click="backScreenAccounts"
            >
            </v-btn>

            <div>
                <div class="text-h6 font-weight-bold text-blue-grey-darken">
                    Metas arquivadas
                </div>

                <div class="text-body-2 text-medium-emphasis">
                    Consulte e restaure metas de economias que foram arquivadas.
                </div>
            </div>
        </div>

        <v-row>
            <v-col
                cols="12"
                xl="9"
            >
                <v-card
                    rounded="xl"
                    elevation="2"
                    border
                    class="overflow-hidden"
                >
                    <v-card-item class="pa-4 pb-2">
                        <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
                            Metas de economia
                        </v-card-title>
                    </v-card-item>

                    <v-divider />

                    <v-data-table
                        :headers="headers"
                        :items="onlyGoalsDisable"
                        :loading="isPending"
                        mobile-breakpoint="md"
                        hide-default-footer
                    >
                        <template #item.goal_value="{ item }">
                            <v-chip
                                :color="item.goal_value! >= 0 ? 'success' : 'error'"
                                size="small"
                            >
                                {{ formatCurrency(item.goal_value ?? 0.00) }}
                            </v-chip>
                        </template>

                        <template #item.start_date="{ item }">
                            {{ item.start_date.split("T")[0]?.split("-").reverse().join("/") }}
                        </template>

                        <template #item.end_date="{ item }">
                            {{ item.end_date.split("T")[0]?.split("-").reverse().join("/") }}
                        </template>

                        <template #item.actions="{ item }">
                            <v-tooltip text="Restaurar">
                                <template #activator="{ props }">
                                    <v-btn
                                        v-bind="props"
                                        icon="mdi-restore"
                                        variant="text"
                                        :loading="loadingButton"
                                        @click="restoreAccount(item)"
                                    />
                                </template>
                            </v-tooltip>
                        </template>
                    </v-data-table>
                </v-card>
            </v-col>

            <v-col
                cols="12"
                xl="3"
            >
                <v-card
                    rounded="xl"
                    elevation="2"
                    border
                    height="100%"
                >
                    <v-card-text class="pa-4">
                        <div class="d-flex align-center justify-space-between">
                            <span class="text-body-2 text-medium-emphasis">
                                Saldo total arquivado
                            </span>

                            <v-avatar
                                color="primary"
                                variant="tonal"
                                icon="mdi-scale-unbalanced"
                                rounded="lg"
                                size="44"
                            />
                        </div>

                        <div style="font-size: var(--text-md);" class="font-weight-bold text-blue-grey-darken mt-5">
                            {{ formatCurrency(totalArchived ?? 0.00) }}
                        </div>

                        <v-chip
                            color="primary"
                            size="small"
                            variant="tonal"
                            class="mt-4"
                        >
                            Arquivado
                        </v-chip>
                    </v-card-text>
                </v-card>
            </v-col>
        </v-row>
    </v-container>
</template>

<style scoped>
:deep(.v-data-table-header__content) {
  font-weight: bold;
}

</style>