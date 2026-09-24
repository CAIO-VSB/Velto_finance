<script setup lang="ts">

    import type { TOptionAction } from '~~/types/option_action/TOptionAction';
    import type { TGoalsMovements, TgoalsMovementsSumary } from '~~/types/goals/TMovementsGoals';
    import type { TGoals } from '~~/types/goals/TGoals';
    import type { TGoalsMovementsPayload } from '~~/schemas/goalsMovements.schema';
    import type { TGoalsPayload } from '~~/schemas/goals.schema';
    import CardEditMovementsGoals from '~/components/forms/CardEditMovementsGoals.vue';
    import CardDeleteMovementsGoals from '~/components/forms/CardDeleteMovementsGoals.vue';

    const props = defineProps<{
        movementsGoals: TgoalsMovementsSumary[] | null,
        goals: TGoalsPayload | null
        selectGoals: number | null
    }>()

    const { notifyError, notifyInfo, notifySuccess } = useNotify()

    const editDraft = ref<TGoalsMovements | null>(null)
    const deleteDraft = ref<TGoalsMovementsPayload| null>(null)
    const search = ref('')
    const modalDeleteMovement = ref(false)
    const modalEditMovement = ref(false)

  const headers = [
    { key: 'description', title: 'Descrição' },
    { key: 'value_paid', title: 'Valor aplicado' },
    { key: 'date_movement', title: 'Data da aplicação' },
    { key: 'accounts_id', title: 'Conta bancária' },
    { key: 'actions', title: 'Ações' },
  ]

    const totalForGoals = computed(() => {
        return props.movementsGoals
            ?.filter(item => item.goals_id === props.selectGoals)
            .reduce((acc, item) => acc + Number(item.value_paid), 0) ?? 0.00
    })

    function getOptions(itemGoals: TgoalsMovementsSumary): TOptionAction [] {

    const options = [
        { title: 'Editar', value: "edit", icon: "mdi-circle-edit-outline" },
        { title: 'Excluir', value: "delete", icon: "mdi-delete-forever" },
    ]

        return options.filter(Boolean) as TOptionAction[]
    }


    function handleOptionClick(option: TOptionAction, data: TgoalsMovementsSumary) {

        const editDraftFormated = {
            ...data,
            start_date: new Date(data.start_date ?? new Date()),
            end_data: new Date(data.end_date ?? new Date()),
            date_movement: parseDateOnlyToLocalDate(data.date_movement)
        }

        if (option.value === 'edit') {
            modalEditMovement.value = true
            editDraft.value = editDraftFormated
            return
        }
        
        if (option.value === 'delete') {
            modalDeleteMovement.value = true
            deleteDraft.value = data
        }
    }


</script>

<template>

    <div>
        <CardEditMovementsGoals :draft="editDraft" v-model="modalEditMovement"/>
        <CardDeleteMovementsGoals :draft="deleteDraft" title="Deletar aplicação" text="Atenção! Esta ação é irreversível e os dados serão excluídos permanentemente." title-botton="Deletar" color-botton="primary"  v-model="modalDeleteMovement"/>
    </div>

    <v-card
        rounded="xl"
        elevation="2"
        class="overflow-hidden"
    >
        <v-card-item class="pa-5 pb-0">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken-4">
                Lançamentos
            </v-card-title>

            <v-card-subtitle class="mt-1">
                Acompanhe suas aplicações realizadas nesta meta.
            </v-card-subtitle>
        </v-card-item>

        <v-card-text class="pa-5">
            <v-text-field
                v-model="search"
                label="Pesquisar lançamento"
                prepend-inner-icon="mdi-magnify"
                variant="solo-filled"
                density="comfortable"
                hide-details
                single-line
                clearable
            >
            </v-text-field>
        </v-card-text>

        <v-divider />

        <v-data-table
            :headers="headers"
            :items="props.movementsGoals || []"
            :search="search"
            mobile-breakpoint="md"
            items-per-page="10"
        >
            <template #item.description="{ item }">
                <div class="d-flex align-center ga-2">
                    <span>{{ item.description }}</span>
                    <span v-if="item.is_ignored"><v-chip color="orange">Ignorada</v-chip></span>
                </div>
            </template>

            <template #item.value_paid="{ item }">
                <div >
                    <span><v-chip color="primary">{{ formatCurrency(item.value_paid) }}</v-chip></span>
                </div>
            </template>
            
            <template #item.date_movement="{ item }">
                <div >
                    <span>{{ item.date_movement.split("T")[0]?.split("-").reverse().join("/") }}</span>
                </div>
            </template>

            <template #item.accounts_id="{ item }">
                <div>
                    <span>{{ item.name_account }}</span>
                </div>
            </template>

            <template #item.actions="{ item }">
                <v-menu
                    transition="slide-y-transition"
                >
                    <template #activator="{ props }">
                        <v-btn
                            v-bind="props"
                            icon="mdi-dots-vertical"
                            variant="text"
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

</template>

<style scoped>
:deep(.v-data-table-header__content) {
  font-weight: bold;
}

</style>