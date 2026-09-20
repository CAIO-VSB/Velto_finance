<script setup lang="ts">

  definePageMeta({
    title: "Metas de economia",
    layout: "layout-dashboard"
  })

  import CardAddEconomy from '~/components/forms/CardAddEconomy.vue'
  import { useHttpGoals } from "~/composables/useHttp/useHttpGoals"
  import BaseFab from "~/components/ui/BaseFab.vue"
  import type { TGoals } from '~~/types/goals/TGoals'
  import type { TGoalsPayload } from '~~/schemas/goals.schema'
  import CardEditEconomy from '~/components/forms/CardEditEconomy.vue'
  import { useInvalidate } from "~/composables/useInvalidate"
  import CardAddMovementSGoals from '~/components/forms/CardAddMovementSGoals.vue'
  
  const { getAllGoals } = useHttpGoals()
  const { patchGoals, patchArchiveGoals, getBalanceForGoals } = useHttpGoals()
  const { invalidate } = useInvalidate()
  const { notifyError, notifyInfo, notifySuccess } = useNotify()

  const editDraft = ref<TGoals | null>(null)

  const modelAddEconomy = ref(false)
  const modelEditEconomy = ref(false)
  const modelAddMovement = ref(false)

  const { data, isPending: isPendingGoals } = useQuery({
    queryKey: QUERY_KEYS.goals.all,
    queryFn: getAllGoals,
  })

  const { data: balanceForEconomy, isPending: isPendingBalance } = useQuery({
    queryKey: QUERY_KEYS.goals.balance_for_economy,
    queryFn: getBalanceForGoals
  })


  const onlyGoalsActive = computed(() => {
    return data.value?.filter(item => item.active === true)
  })

  function handleOptionAccountsDisable() {
    navigateTo("/economy/economyDisable")
  }

  function getOptionsGoals() {
    const options = [
      { title: 'Editar', value: "edit", icon: "mdi-circle-edit-outline" },
      { title: 'Arquivar', value: "arquivar", icon: "mdi-archive" },
    ]

    return options
  } 

  function getOptions() {
    const options = [
      { title: 'Metas arquivadas', value: "arquivadas", icon: "mdi-archive-clock" },
    ]

    return options
  }


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

  function getSummaryForGoals(goalsId: number) {
    const row = balanceForEconomy.value?.find(item => item.id === goalsId)

    return {
      total: Number(row?.total_lancado ?? 0),
      percentual: Number(row?.percentual ?? 0.00),
      meta: Number(row?.meta ?? 0.00)
    }

  }


  function viewExtract(goals: TGoalsPayload) {
    navigateTo(`/economy/${goals.id}`)
  }

  function getOptionClick(option: string, item: TGoalsPayload) {

    const parseGoalsToEdit = {
      ...item,
      start_date: new Date(item.start_date),
      end_date: new Date(item.end_date)
    }

    if (option === 'edit') {
      editDraft.value = structuredClone(toRaw(parseGoalsToEdit))
      modelEditEconomy.value = true
      return
    }

    if (option === 'arquivar') {
      mutate({id: item.id!, active: false})
      return
    }

  }

</script>


<template>
    <CardAddEconomy v-model="modelAddEconomy"/>
    <CardEditEconomy :draft="editDraft" v-model="modelEditEconomy"/>
    <CardAddMovementSGoals v-model="modelAddMovement" />

    <v-container class="economy-empty-state d-flex align-center justify-center mt-4" v-if="!isPendingGoals && !data?.length">
       <v-overlay
        :model-value="isPendingGoals"
        class="align-center justify-center"
      >
        <v-progress-circular
          color="primary"
          size="64"
          indeterminate
        ></v-progress-circular>
      </v-overlay>
      <v-card
        v-if="!isPending && !data?.length"
        class="overflow-hidden"
        rounded="xl"
        elevation="4"
        max-width="900"
        mx-auto
      >
        <v-empty-state
          icon="mdi-piggy-bank-outline"
          color="success"
          title="Crie sua primeira meta de economia"
          text="Defina um objetivo financeiro para acompanhar seus progressos e manter o foco nos seus planos."
          class="pa-6 pb-2"
        >
          <template #actions>
            <v-btn
              color="primary"
              prepend-icon="mdi-plus"
              rounded="lg"
              class="text-none font-weight-bold mt-3"
              @click="modelAddEconomy = true"
            >
              Criar meta de economia
            </v-btn>
          </template>
        </v-empty-state>

        <v-divider class="mx-6 mt-4" />

        <section class="pa-6 pt-5">
          <div class="text-subtitle-1 font-weight-bold text-blue-grey-darken-4 mb-4">
            É simples começar
          </div>

          <v-stepper
            alt-labels
            color="primary"
            :items="['Defina a meta', 'Faça aportes', 'Acompanhe']"
          >
            <template #item.1>
              <v-card
                flat
                class="text-center pa-5"
              >
                <v-avatar
                  color="primary"
                  variant="tonal"
                  rounded="lg"
                  size="48"
                  class="mb-3"
                >
                  <v-icon icon="mdi-target" />
                </v-avatar>

                <div class="font-weight-bold mb-1">
                  Defina seu objetivo
                </div>

                <div class="text-body-2 text-medium-emphasis">
                  Escolha um nome, o valor desejado e uma data para realizar seu plano.
                </div>
              </v-card>
            </template>

            <template #item.2>
              <v-card
                flat
                class="text-center pa-5"
              >
                <v-avatar
                  color="success"
                  variant="tonal"
                  rounded="lg"
                  size="48"
                  class="mb-3"
                >
                  <v-icon icon="mdi-cash-plus" />
                </v-avatar>

                <div class="font-weight-bold mb-1">
                  Registre seus aportes
                </div>

                <div class="text-body-2 text-medium-emphasis">
                  Adicione os valores que você guardar para deixar o progresso sempre atualizado.
                </div>
              </v-card>
            </template>

            <template #item.3>
              <v-card
                flat
                class="text-center pa-5"
              >
                <v-avatar
                  color="info"
                  variant="tonal"
                  rounded="lg"
                  size="48"
                  class="mb-3"
                >
                  <v-icon icon="mdi-chart-line" />
                </v-avatar>

                <div class="font-weight-bold mb-1">
                  Acompanhe sua evolução
                </div>

                <div class="text-body-2 text-medium-emphasis">
                  Veja quanto falta para alcançar sua meta e mantenha a consistência.
                </div>
              </v-card>
            </template>
          </v-stepper>
        </section>
      </v-card>
    </v-container>

    <v-container
      fluid
      class="pa-4 pa-md-6"
      v-else
    >
        <div class="d-flex justify-end ga-2 mb-6" >
            <v-btn
              color="primary"
              icon="mdi-plus"
              variant="tonal"
              rounded="lg"
              @click="modelAddEconomy = true"
              v-tooltip="'Nova meta'"
            >
            </v-btn>

            <v-menu
                transition="scale-transition"
            >
                <template #activator="{ props }">
                    <v-btn
                      v-bind="props"
                      color="primary"
                      icon="mdi-dots-vertical"
                      variant="tonal"
                      rounded="lg"
                    >
                    </v-btn>
                </template>
                

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
                        @click="handleOptionAccountsDisable"
                    >
                        <v-list-item-title>
                          {{ item.title }}
                        </v-list-item-title>
                    </v-list-item>
                </v-list>
            </v-menu>
        </div>

        <div class="main-cards">
                <v-card
                  v-for="value in onlyGoalsActive"
                  :key="value.id"
                  height="auto"
                  rounded="xl"
                  elevation="2"
                  :loading="isPendingGoals"
                >
                    <v-card-item class="pa-4 pb-0">
                        <v-card-title style="font-size: var(--text-base);" class="font-weight-bold">
                          {{ value.name_identifier }}
                        </v-card-title>

                        <template #append>
                            <v-menu
                              transition="scale-transition"
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
                                        v-for="(action, index) in getOptionsGoals()"
                                        :key="index"
                                        :value="index"
                                        :prepend-icon="action.icon"
                                        rounded="lg"
                                        @click="getOptionClick(action.value, value)"
                                    >
                                        <v-list-item-title>
                                          {{ action.title }}
                                        </v-list-item-title>
                                    </v-list-item>
                                </v-list>
                            </v-menu>
                        </template>
                    </v-card-item>

                    <div class="d-flex align-center justify-center">
                        <v-progress-circular
                          :model-value="getSummaryForGoals(value.id ?? 0).percentual"
                          :size="250"
                          :width="20"
                          bg-color="surface-light"
                          class="ma-3"
                          color="primary"
                          reveal
                          rounded
                        >
                          <div class="d-flex align-baseline">
                            <span style="font-size: var(--text-lg);" class="font-weight-bold">{{ getSummaryForGoals(value.id ?? 0).percentual }}</span>
                            <span style="font-size: var(--text-lg);" class="text-caption text-medium-emphasis">%</span>
                          </div>
                        </v-progress-circular>
                  </div>

                  <div class="pa-2">
                    <v-sheet border rounded="lg" class="pa-4 mb-3">
                      <div class="d-flex jutify-center align-center mb-3 text-body-2 text-medium-emphasis">                
                        Objetivo: 
                        <div class="w-100 d-flex justify-end text-body-2 font-weight-bold text-blue-grey-darken-4">
                          <v-chip color="primary">{{ formatCurrency(value.goal_value ?? 0.00) }}</v-chip>
                        </div>
                      </div>
                      <v-divider></v-divider>
                      <div class="d-flex jutify-center align-center mt-3 mb-3 text-no-wrap text-body-2 text-medium-emphasis">                
                        Data de início: 
                        <div class="w-100 d-flex justify-end text-body-2 font-weight-bold text-blue-grey-darken-4">
                          {{ value.start_date.split("T")[0]?.split("-").reverse().join("/") }}
                        </div>
                      </div>
                      <v-divider></v-divider>
                      <div class="d-flex jutify-center align-center mb-3 mt-3 text-no-wrap text-body-2 text-medium-emphasis">                
                        Data de término: 
                        <div class="w-100 d-flex justify-end text-body-2 font-weight-bold text-blue-grey-darken-4">
                          {{ value.end_date.split("T")[0]?.split("-").reverse().join("/") }}
                        </div>
                      </div>
                      <v-divider></v-divider>
                      <div class="d-flex jutify-center align-center mt-3 mb-3 text-no-wrap text-body-2 text-medium-emphasis">                
                        Aplicação mensal ideal: 
                        <div class="w-100 d-flex justify-end text-body-2 font-weight-bold text-blue-grey-darken-4">
                          <v-chip color="primary">{{ formatCurrency(value.suggested_value ?? 0.00) }}</v-chip>
                        </div>
                      </div>
                      <v-divider></v-divider>
                      <div class="d-flex jutify-center align-center mt-3 mb-3 text-no-wrap text-body-2 text-medium-emphasis">                
                        Meta alcançada: 
                        <div class="w-100 d-flex justify-end text-body-2 font-weight-bold text-blue-grey-darken-4">
                          <v-chip color="green">{{ formatCurrency(getSummaryForGoals(value.id ?? 0).total) }}</v-chip>
                        </div>
                      </div>

                      <div class="mt-7 pa-2 d-flex justify-center">
                        <v-btn
                        class="text-none"
                        color="primary"
                        text="Visualizar extrato"
                        variant="flat"
                        rounded="lg"
                        @click="viewExtract(value)"
                        ></v-btn>
                    </div>
                      
                    </v-sheet>
                  </div>
                  
                </v-card>
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
}

.main-cards {
  display: grid;
  gap: 16px;
  grid-template-columns: repeat(3, 3fr);
}

.text-disabled {
  text-decoration: line-through;
}

@media (max-width: 1400px) {
  .main-cards {
    display: grid;
    gap: 16px;
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 900px) {
  .main-cards {
    display: grid;
    gap: 16px;
    grid-template-columns: repeat(1, 1fr);
  }
}

</style>
