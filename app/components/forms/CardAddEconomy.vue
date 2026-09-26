<script lang="ts" setup>

    import { useHttpAccounts } from "~/composables/useHttp/useHttpAccounts"
    import { useHttpGoals } from "~/composables/useHttp/useHttpGoals"
    import { useValidateFields } from "~/composables/useValidateFields"
    import { useValidateSchemas } from "~/composables/useValidateSchema"
    import { useInvalidate } from "~/composables/useInvalidate"
    import CurrencyInput from "~/components/ui/CurrencyInput.vue"
    import type { TGoals } from "~~/types/goals/TGoals"
  
    const modelValue = defineModel<boolean>()

    const { getAccountsOnlyActive } = useHttpAccounts()
    const { postGoals } = useHttpGoals()
    const { selectRules, dateRules, currencyRules, nameRules } = useValidateFields()
    const { validateSchemaGoals } = useValidateSchemas()
    const { invalidate } = useInvalidate()
    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    
    const goalsForm = ref<TGoals>({
      name_identifier: "",
      suggested_value: 0.00,
      goal_value: 0.00,
      start_date: new Date(),
      end_date: new Date(),
      active: true,
      value_initial: null
    })

    const menuAccounts = ref(false)
    const modelAccounts = ref<number | null>(null)
    const formRef = ref()

    const { data:accounts, isPending: isPendingAccounts } = useQuery({
      queryKey: QUERY_KEYS.accounts.active,
      queryFn: getAccountsOnlyActive,
    })

    const { mutate, isPending  } = useMutation({

      mutationFn: postGoals,

      onSuccess: () => {
        invalidate(QUERY_KEYS.goals.all)
        invalidate(QUERY_KEYS.goals.balance_for_economy)
        notifySuccess("Sucesso", "Operação realizada com sucesso", 6000)
        resetForm()
      },

      onError: (error) => {
        handleErrorApplication(error.statusCode)
      },

    })

    function resetForm() {
      goalsForm.value.value_initial = null
      goalsForm.value.active = true
      goalsForm.value.end_date = new Date()
      goalsForm.value.goal_value = 0.00
      goalsForm.value.name_identifier = ""
      goalsForm.value.start_date = new Date()
      goalsForm.value.suggested_value = 0.00
      modelAccounts.value = null
      modelValue.value = false
    }

    async function submitForm() {

      const { valid } = await formRef.value.validate()

      const startDateFormated = dateToDateOnly(goalsForm.value.start_date)
      const endDateFormated = dateToDateOnly(goalsForm.value.end_date)

      try {

        const payload = {
          ...goalsForm.value,
          accounts_id: modelAccounts.value,
          start_date: startDateFormated,
          end_date: endDateFormated
        }

        const resultSchema = validateSchemaGoals(payload)

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
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
              Meta de economia
            </v-card-title>

            <v-card-subtitle class="mt-1">
              Preencha os dados abaixo para cadastrar sua meta financeira.
            </v-card-subtitle>

            <template #prepend>
              <v-avatar color="primary" variant="tonal" rounded="lg">
                <v-icon icon="mdi-piggy-bank-outline" color="primary" />
              </v-avatar>
            </template>
          </v-card-item>
          <v-divider></v-divider>
          <v-card-text >
            
            <v-row density="comfortable">

            <v-col
              cols="12" md="12" sm="12"
              >
              <v-text-field prepend-inner-icon="mdi-pencil"  prepend-icon="" :rules="nameRules" :counter="45" maxlength="45"  autocomplete="name" name="name" label="Nome da meta" variant="solo-filled" v-model="goalsForm.name_identifier"></v-text-field>
            </v-col>

              <v-col
              cols="12" md="12" sm="12"
              >
                <CurrencyInput variant="solo-filled" prepend-inner-icon="mdi-cash" text-color="primary" autocomplete="off" label="Valor inicial" hint="Quanto você já tem guardado para esta meta" v-model="goalsForm.value_initial"/>
              </v-col>

              <v-col
              cols="12" md="12" sm="12"
              >
                <CurrencyInput variant="solo-filled" prepend-inner-icon="mdi-cash" :rules="currencyRules" text-color="primary" autocomplete="off" label="Valor total da meta" hint="Valor que você deseja alcançar" v-model="goalsForm.goal_value"/>
              </v-col>

              <v-col
              cols="12" md="12" sm="12"
              >
                <CurrencyInput variant="solo-filled" prepend-inner-icon="mdi-cash" text-color="primary" autocomplete="off" label="Valor sugerido" hint="Valor sugerido para os lançamentos desta meta. Este campo é opcional." v-model="goalsForm.suggested_value"/>
              </v-col>

              <v-col
              cols="12" md="12" sm="12"
              >
                <v-date-input prepend-inner-icon="mdi-calendar" prepend-icon="" :rules="dateRules" autocomplete="off" label="Data de início" variant="solo-filled" v-model="goalsForm.start_date"></v-date-input>
              </v-col>

              <v-col
              cols="12" md="12" sm="12"
              >
                <v-date-input prepend-inner-icon="mdi-calendar" prepend-icon="" :rules="dateRules" autocomplete="off" label="Data de término" variant="solo-filled" v-model="goalsForm.end_date"></v-date-input>
              </v-col>
            </v-row>

          </v-card-text>

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
