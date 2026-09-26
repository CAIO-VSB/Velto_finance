<script setup lang="ts">

    import { useHttpCategories } from '~/composables/useHttp/useHttpCategories'
    import { useHttpAccounts } from "~/composables/useHttp/useHttpAccounts"
    import { differenceInDays } from 'date-fns'
    import type { TMovementsByFilter } from '~~/types/movements/TMovementsByFilter'
    
    const emit = defineEmits<{
        applyFilter: [filter: TMovementsByFilter],
        resetFilter: [reset: string]
    }>()

    const props = defineProps<{
        colorButton: string,
        textColor?: string,
        fieldTypeActive: boolean,
        items: string[],
        loadingButton?: boolean
    }>()

    const { getCategoriesOnlyActive } = useHttpCategories()
    const { getAccountsOnlyActive } = useHttpAccounts()
    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    const { nameRules, selectRules, dateRules, currencyRules } = useValidateFields()

    const { data:categories, isPending:categorieIsPending } = useQuery({
      queryKey: QUERY_KEYS.categories.active,
      queryFn: getCategoriesOnlyActive,
    })

    const { data:accounts, isPending:accountsIsPending } = useQuery({
      queryKey: QUERY_KEYS.accounts.active,
      queryFn: getAccountsOnlyActive,
    })

    const modelValue = defineModel<boolean>()
    const menuCategorias = ref(false)
    const modelCategorias = ref<number[]>([])
    const searchCategorias = ref("")
    const searchAccounts = ref("")
    const modelAccounts = ref<number[]>([])
    const menuAccounts = ref(false)
    const startDate = ref<Date | null>(null)
    const endDate = ref<Date | null>(null)

    const filterFrom = ref<TMovementsByFilter>({
        start_day: null,
        end_day: null,
        categorie_id: [],
        accounts_id: [],
        situation: null,
        for_type: []
    })

    watch(modelCategorias, (val) => {
        filterFrom.value.categorie_id = val
    })

    watch(modelAccounts, (val) => {
        filterFrom.value.accounts_id = val
    })

    const filterCategorias = computed(() => {
      return categories.value?.filter(item => item.name_identifier.toLowerCase().includes(searchCategorias.value.toLowerCase()))
    })

    const filterAccounts = computed(() => {
      return accounts.value?.filter(item => item.name_identifier.toLowerCase().includes(searchAccounts.value?.toLowerCase() ?? ''))
    })

    function resetForm() {
        filterFrom.value.for_type = []
        filterFrom.value.situation = null
        filterFrom.value.end_day = null,
        filterFrom.value.start_day = null,
        modelAccounts.value = [],
        modelCategorias.value = [],
        startDate.value = null
        endDate.value = null
        modelValue.value = false
        emit("resetFilter", "todos")
    }

    function submitForm() {

        if (!startDate.value || !endDate.value) {
            notifyInfo("Atenção", "Informe o período para consulta", 7000)
            return
        }

        const diff = differenceInDays(endDate.value, startDate.value)

        if (diff > 90) {
            notifyInfo("Atenção", "O período máximo de consulta é 90 dias", 7000)
            return
        }

        if (startDate?.value && endDate?.value) {
            filterFrom.value.start_day = new Date(startDate.value).toISOString().split('T')[0] as string
            filterFrom.value.end_day = new Date(endDate.value).toISOString().split('T')[0] as string
        }

        emit("applyFilter", filterFrom.value)

        modelValue.value = false
    }


</script>

<template>
    <v-navigation-drawer
        v-model="modelValue"
        location="right"
        temporary
        width="470"
    >
        <v-list class="pa-2">
            <v-list-item class="px-3 py-2">
                <v-list-item-title class="text-h6 font-weight-bold">
                    Filtro de transações
                </v-list-item-title>

                <v-list-item-subtitle class="mt-1">
                    Refine os lançamentos exibidos na tabela.
                </v-list-item-subtitle>
            </v-list-item>
        </v-list>

        <v-divider />

        <div class="pa-5">

            <v-row class="mb-7">
                <v-col
                    cols="12"
                    sm="6"
                >
                    <v-date-input
                        v-model="startDate"
                        label="De"
                        autocomplete="off"
                        prepend-icon=""
                        variant="solo-filled"
                        rounded="lg"
                        clearable
                        hide-details="auto"
                    />
                </v-col>

                <v-col
                    cols="12"
                    sm="6"
                >
                    <v-date-input
                        v-model="endDate"
                        label="Até"
                        autocomplete="off"
                        prepend-icon=""
                        variant="solo-filled"
                        rounded="lg"
                        clearable
                        hide-details="auto"
                    />
                </v-col>
            </v-row>

            <v-select
                v-model="modelCategorias"
                v-model:menu="menuCategorias"
                :items="filterCategorias"
                :loading="categorieIsPending"
                :rules="selectRules"
                item-title="name_identifier"
                item-value="id"
                label="Categorias"
                variant="solo-filled"
                autocomplete="off"
                clearable
                multiple
                class="mb-4"
            >
                <template #selection="{ item }">
                    <div class="d-flex align-center ga-2">
                        <v-avatar
                            :icon="item.url_icon"
                            size="30"
                        />

                        <span>{{ item.name_identifier }}</span>
                    </div>
                </template>

                <template #item="{ props: itemProps, item }">
                    <v-list-item v-bind="itemProps">
                        <template #prepend>
                            <v-avatar :icon="item.url_icon" />
                        </template>
                    </v-list-item>
                </template>

                <template #prepend-item>
                    <div class="pa-2">
                        <v-text-field
                            v-model="searchCategorias"
                            :error="!!searchCategorias && !filterCategorias?.length"
                            density="compact"
                            placeholder="Buscar..."
                            prepend-inner-icon="mdi-magnify"
                            variant="outlined"
                            hide-details="auto"
                            @click.stop
                            @keydown.stop
                            @mousedown.stop
                        />
                    </div>

                    <v-divider />
                </template>
            </v-select>

            <v-select
                v-model="modelAccounts"
                v-model:menu="menuAccounts"
                :items="filterAccounts"
                :rules="selectRules"
                :loading="accountsIsPending"
                item-title="name_identifier"
                item-value="id"
                label="Contas"
                variant="solo-filled"
                autocomplete="off"
                clearable
                multiple
                class="mb-4"
            >
                <template #selection="{ item }">
                    <div class="d-flex align-center ga-2">
                        <v-avatar size="30">
                            <v-img
                                :src="item.url_image"
                                :alt="item.name_identifier"
                            />
                        </v-avatar>

                        <span>{{ item.name_identifier }}</span>
                    </div>
                </template>

                <template #item="{ props: itemProps, item }">
                    <v-list-item v-bind="itemProps">
                        <template #prepend>
                            <v-avatar>
                                <v-img
                                    :src="item.url_image"
                                    :alt="item.name_identifier"
                                />
                            </v-avatar>
                        </template>
                    </v-list-item>
                </template>

                <template #prepend-item>
                    <div class="pa-2">
                        <v-text-field
                            v-model="searchAccounts"
                            :error="!!searchAccounts && !filterAccounts?.length"
                            density="compact"
                            placeholder="Buscar..."
                            prepend-inner-icon="mdi-magnify"
                            variant="outlined"
                            hide-details="auto"
                            @click.stop
                            @keydown.stop
                            @mousedown.stop
                        />
                    </div>

                    <v-divider />
                </template>
            </v-select>

            <v-select
                v-model="filterFrom.situation"
                :items="props.items"
                label="Situações"
                variant="solo-filled"
                clearable
                class="mb-4"
            />

            <v-select
                v-model="filterFrom.for_type"
                :disabled="props.fieldTypeActive"
                :items="['Despesas', 'Receitas', 'Tranferências de entrada', 'Transferências de saída', 'Cartão de crédito']"
                label="Tipos"
                variant="solo-filled"
                clearable
                multiple
            />
        </div>

        <v-divider />

        <v-card-actions class="pa-5 justify-space-between">
            <v-btn
                variant="plain"
                class="text-none font-weight-medium"
                @click="resetForm"
            >
                Cancelar

                <v-tooltip
                    activator="parent"
                    text="Remove todos os filtros e restaura a pesquisa"
                />
            </v-btn>

            <v-btn
                :color="props.colorButton"
                variant="flat"
                rounded="lg"
                class="text-none font-weight-bold"
                @click="submitForm"
            >
                Aplicar filtros
            </v-btn>
        </v-card-actions>
    </v-navigation-drawer>
</template>

<style scoped>
</style>