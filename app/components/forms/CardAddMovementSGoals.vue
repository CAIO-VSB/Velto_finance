<script lang="ts" setup>

  import metaLogo from "~/assets/Target With Dollar Sign.webp"
  import { useHttpAccounts } from "~/composables/useHttp/useHttpAccounts"
  import { useHttpGoals } from "~/composables/useHttp/useHttpGoals"
  import { useValidateFields } from "~/composables/useValidateFields"
  import { useValidateSchemas } from "~/composables/useValidateSchema"
  import { useInvalidate } from "~/composables/useInvalidate"
  import CurrencyInput from "~/components/ui/CurrencyInput.vue"
  import type { TGoalsMovements } from "~~/types/goals/TMovementsGoals"

  const modelValue = defineModel<boolean>()
  
  const props = defineProps<{
    goalsId?: number | null
  }>()

  const { getAccountsOnlyActive } = useHttpAccounts()
  const { getAllGoals, postMovementGoals } = useHttpGoals()
  const { selectRules, dateRules, currencyRules, nameRules } = useValidateFields()
  const { validateSchemaGoalsMovements } = useValidateSchemas()
  const { invalidate } = useInvalidate()
  const { notifyError, notifyInfo, notifySuccess } = useNotify()
  
  const menuAccounts = ref(false)
  const modelAccounts = ref<number | null>(null)
  const menuGoals = ref(false)
  const modelGoals = ref<number | null>(null)
  const changeIgnoredTransaction = ref(false)
  const formRef = ref()

  const movementGoalsForm = ref<TGoalsMovements>({
    goals_id: null,
    description: "",
    value_paid: 0.00,
    date_movement: new Date(),
    accounts_id: null,
    active: false,
    is_ignored: changeIgnoredTransaction.value
  })

  const { data:accounts, isPending: isPendingAccounts } = useQuery({
    queryKey: QUERY_KEYS.accounts.active,
    queryFn: getAccountsOnlyActive,
  })

  const { data, isPending: isPendingGoals } = useQuery({
    queryKey: QUERY_KEYS.goals.all,
    queryFn: getAllGoals,
  })

  const onlyGoalsActive = computed(() => {
    return data.value?.filter(item => item.active === true)
  })


  const { mutate, isPending  } = useMutation({

    mutationFn: postMovementGoals,

    onSuccess: () => {
      invalidate(QUERY_KEYS.goals.all)
      invalidate(QUERY_KEYS.goals.balance_for_economy)
      invalidate(QUERY_KEYS.goals.movements(props.goalsId ?? 0))
      notifySuccess("Sucesso", "Operação realizada com sucesso", 6000)
      resetForm()
    },

    onError: (error) => {
      handleErrorApplication(error.statusCode)
    },

  })

  function resetForm() {
    movementGoalsForm.value.value_paid = 0.00
    movementGoalsForm.value.goals_id = null
    movementGoalsForm.value.description = ""
    movementGoalsForm.value.date_movement = new Date()
    movementGoalsForm.value.accounts_id = null
    modelGoals.value = null
    modelAccounts.value = null
    modelValue.value = false
  }

  async function submitForm() {

    const { valid } = await formRef.value.validate()

    const dateMovementFormated = dateToDateOnly(movementGoalsForm.value.date_movement)

      try {

        const payload = {
          ...movementGoalsForm.value,
          accounts_id: modelAccounts.value,
          goals_id: modelGoals.value,
          date_movement: dateMovementFormated,
          is_ignored: changeIgnoredTransaction.value
        }

        const resultSchema =  validateSchemaGoalsMovements(payload)

        console.log("Valor sendo enviado " + JSON.stringify(payload))

        if (!resultSchema.success) {
          notifyInfo(
            "Dados inválidos",
            "Verifique as informações preenchidas e tente novamente.",
            7000
          )
          return
        }

        if (valid && resultSchema.success) {
          mutate(payload)
        }

    } catch (error) {
      notifyError("Erro", "Ocorreu um erro ao validar o formulário. Por favor, tente novamente.", 6000)
    }

  }


</script>
 

<template>


  <div class="text-center">
    <v-form
    @submit.prevent
    ref="formRef"
    validate-on="lazy blur"
    >
      <v-dialog v-model="modelValue" max-width="600">
        <v-card rounded="lg" elevation="6">
          <v-card-item class="pa-4 pb-2">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken-4">
              Nova aplicação
            </v-card-title>

            <v-card-subtitle class="mt-1">
              Preencha os dados abaixo para lançar uma nova aplicação.
            </v-card-subtitle>

            <template #prepend>
              <v-avatar color="primary" variant="tonal" rounded="lg">
                <v-icon icon="mdi-plus" color="primary" />
              </v-avatar>
            </template>
          </v-card-item>
          <v-divider></v-divider>
          <v-card-text >
            
            <v-row density="comfortable">

            <v-col
              cols="12" md="12" sm="12"
              >
              <v-text-field prepend-inner-icon="mdi-pencil"  prepend-icon="" :rules="nameRules" :counter="45" maxlength="45"  autocomplete="name" name="name" label="Descrição" variant="solo-filled" v-model="movementGoalsForm.description"></v-text-field>
            </v-col>

              <v-col
              cols="12" md="12" sm="12"
              >
                <CurrencyInput variant="solo-filled" prepend-inner-icon="mdi-cash" :rules="currencyRules" text-color="primary" autocomplete="off" label="Valor a ser aplicado" hint="Valor que você deseja aplicar" v-model="movementGoalsForm.value_paid"/>
              </v-col>

              <v-col
              cols="12" md="12" sm="12"
              >
                <v-date-input prepend-inner-icon="mdi-calendar" prepend-icon="" :rules="dateRules" autocomplete="off" label="Data do lançamento" variant="solo-filled" v-model="movementGoalsForm.date_movement"></v-date-input>
              </v-col>

            <v-col
            cols="12" md="12" sm="12"
            >
              <v-select
                v-model="modelAccounts"
                v-model:menu="menuAccounts"
                :items="accounts"
                :rules="selectRules"
                item-title="name_identifier"
                item-value="id"
                variant="solo-filled"
                label="Conta"
                hint="O valor será debitado desta conta"
                persistent-hint
                autocomplete="off"
                prepend-inner-icon="mdi-bank"
                >

                  <template v-slot:selection="{item}">
                    <v-avatar style="width: 25px; height: 24px; margin-right: 12px;"> 
                      <v-img  :src="item.url_image" :alt="item.name_identifier"></v-img>
                    </v-avatar>
                    <span >{{ item.name_identifier }}</span>
                  </template>

                  <template v-slot:item="{props, item}">
                    <v-list-item  v-bind="props">
                      <template v-slot:prepend>
                        <v-avatar>
                          <v-img :src="item.url_image" :alt="item.name_identifier"></v-img>
                        </v-avatar>
                      </template>
                    </v-list-item>
                  </template>

                </v-select>
                </v-col>

            <v-col
            cols="12" md="12" sm="12"
            >
              <v-select
                v-model="modelGoals"
                v-model:menu="menuGoals"
                :items="onlyGoalsActive"
                :rules="selectRules"
                item-title="name_identifier"
                item-value="id"
                variant="solo-filled"
                label="Meta"
                hint="O valor será creditado nesta meta"
                persistent-hint
                autocomplete="off"
                prepend-inner-icon="mdi-bank"
                >

                  <template v-slot:selection="{item}">
                    <v-avatar style="width: 24px; height: 24px; margin-right: 12px;"> 
                      <v-img  :src="metaLogo" ></v-img>
                    </v-avatar>
                    <span >{{ item.name_identifier }}</span>
                  </template>

                  <template v-slot:item="{props, item}">
                    <v-list-item  v-bind="props">
                      <template v-slot:prepend>
                        <v-avatar>
                          <v-img :src="metaLogo" ></v-img>
                        </v-avatar>
                      </template>
                    </v-list-item>
                  </template>

                </v-select>
                </v-col>
            </v-row>
          </v-card-text>

          <div class="pl-7 d-flex ga-5">
            <v-switch size="small"color="primary" :true-value="true" :false-value="false" v-model="changeIgnoredTransaction" label="Ignorar transação" inset="material"></v-switch>
            <div class="mt-1"> 
              <v-tooltip text="Ao marcar esta opção, nenhum débito será gerado em conta bancária. O lançamento servirá apenas para controle do seu progresso na meta." class="pt-3">
                <template v-slot:activator="{ props }">
                  <v-btn v-bind="props" variant="plain" icon="mdi-help-circle"></v-btn>
                </template>
              </v-tooltip>
            </div>
          </div>

          <v-divider></v-divider>

          <v-card-actions  class="pa-4 d-flex flex-wrap ga-2">
            <v-btn
              class="text-none"
              text="Cancelar"
              variant="text"
              @click="modelValue = false"
            ></v-btn>
            <v-spacer></v-spacer>
            <v-btn
              class="text-none"
              value="btn-salvar"
              color="primary"
              text="Salvar"
              variant="flat"
              rounded="lg"
              @click="submitForm"
              :loading="isPending"
            ></v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-form>

  </div>
</template>

<style  scoped>

.icon-add-logo:hover {
  background-color: rgba(128, 128, 128, 0.562);
  border-radius: 60%;
}

.button-hover:hover {
  background-color: rgba(255, 255, 255, 0.418);
  transform: scale(1.1); /* Efeito de zoom */
  transition: 0.3s; /* Transição suave */
}

@media (max-width: 680px) {
  .options-footer {
    flex-direction: column;
  }
}

</style>
