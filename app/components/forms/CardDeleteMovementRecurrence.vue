<script setup lang="ts">

    const props = defineProps<{
        draft: TMovementsPayload | null
    }>()

    const  emit = defineEmits<{
        success: []
    }>()

    import { useInvalidate } from "~/composables/useInvalidate"
    import { useHttpRecurrence } from '~/composables/useHttp/useHttpRecurrence'
    import type { TMovementsPayload } from "~~/schemas/movements.schema";

    const { invalidate } = useInvalidate()
    const { deleteMovementsRecurrenceById } = useHttpRecurrence()
    const { notifyError, notifyInfo, notifySuccess } = useNotify()

    const modelValue = defineModel<boolean>()
    const editScope = ref("somente_esta")

    const  { mutate } = useMutation({

    mutationFn: (payload: TMovementsPayload) => deleteMovementsRecurrenceById(payload.id!, payload, editScope.value, payload.recurrence_id!),

    onSuccess: () => {
        invalidate(QUERY_KEYS.movements.all)
        invalidate(QUERY_KEYS.movements.only_expenses)
        invalidate(QUERY_KEYS.movements.only_revenues)
        invalidate(QUERY_KEYS.movements.current_balance)
        invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
        notifySuccess(
        "Sucesso",
        "Operação realizada com sucesso.",
        5000
        )
        resetStates()
        emit("success")
    },

    onError: (error) => {
        handleErrorApplication(error.statusCode)
    },

    })

    function resetStates() {
      editScope.value = "somente_esta"
      modelValue.value = false
    }

    async function submitForm() {

        if(!props.draft) {
            notifyError("Ops!", "Algo não parece certo. Confira os dados e tente novamente.")
            return
        } 

        const raw = structuredClone(toRaw(props.draft))

        const payload = {
            ...raw
        }

        mutate(payload)
    
    }

</script>


<template >

  <div>
      <v-dialog
        transition="dialog-bottom-transition"
        width="520"
        v-model="modelValue"
      >
        <template v-slot:default="{ isActive }">
          <v-card rounded="xl">
            
              <template #title>
              <span class="font-weight-bold text-blue-grey-darken title">Deseja deletar esta {{ props.draft?.type_transaction === 'despesa' ? 'despesa' : 'receita' }}?</span>
              </template>

              <template #subtitle>
              <span class="subtitle">Atenção! Essa ação não poderá ser desfeita</span>
              </template>

              <v-divider></v-divider>

            <v-card-text class="text-display-large pa-5">
              <div class="info">
                  <div>
                      <p class="font-weight-bold text-blue-grey-darken">Descrição</p>
                      <p>{{ props.draft?.description_transaction }}</p>
                  </div>

                  <div>
                      <p class="font-weight-bold text-blue-grey-darken">Valor</p>
                      <p style=" text-align: center;">{{ formatCurrency(props.draft?.value_transaction ?? 0.00) }}</p>
                  </div>

                  <div>
                      <p class="font-weight-bold text-blue-grey-darken">Valor</p>
                      <p style=" text-align: center;">{{ props.draft?.date_transaction?.split("-").reverse().join("/") }}</p>
                  </div>
              </div> 

              <div class="info-alert">
                <div>
                    <p style="margin-top: 30px;" class="font-weight-bold">Atenção! Esta é uma {{  props.draft?.type_transaction === 'despesa' ? 'despesa' : 'receita'  }} {{ props.draft?.type_recurrence === 'fixa' ? 'fixa' : 'parcelada'  }}. O que você deseja excluir?</p>
                </div>
                <v-radio-group v-model="editScope" hide-details class="mt-2">
                    <v-radio :color="props.draft?.type_transaction === 'despesa' ? 'red' : 'green'" label="Somente esta" value="somente_esta"></v-radio>
                    <v-radio :color="props.draft?.type_transaction === 'despesa' ? 'red' : 'green'" label="Todas as pendentes" value="pendentes"></v-radio>
                    <v-radio :color="props.draft?.type_transaction === 'despesa' ? 'red' : 'green'" label="Todas (incluindo efetivadas)" value="todas"></v-radio>
                </v-radio-group>
              </div> 
            </v-card-text>

              <v-divider></v-divider>

              <v-card-actions class="pa-4 d-flex flex-wrap ga-2">
              <v-btn
                  text="Cancelar"
                  variant="text"
                  :color="props.draft?.type_transaction === 'despesa' ? 'red' : 'green'"
                  class="text-none "
                  @click="resetStates"
                  rounded="lg"
              ></v-btn>

              <v-spacer></v-spacer>

              <v-btn
                  text="Deletar"
                  variant="elevated"
                  :color="props.draft?.type_transaction === 'despesa' ? 'red' : 'green'"
                  class="text-none"
                  @click="submitForm"
                  rounded="lg"
              ></v-btn>
              </v-card-actions>
            
          </v-card>
        </template>
      </v-dialog>
  </div>


</template>

<style scoped>

.info {
    display: flex;
    gap: 2rem;
    flex-wrap: wrap;
}

.info > div {
    display: flex;
    flex-direction: column;
    align-items: center;
    min-width: 120px;
    font-size: 1rem;
}

.info-alert {
    font-size: 1rem;
}


@media (max-width: 600px) {

.info > div {
    display: flex;
    flex-direction: row;
    text-align: center;
    min-width: 170px;
    font-size: 1rem;
    gap: 20px;
}

.title {
    font-size: 1.2rem;
}

.subtitle {
    font-size: 0.85rem;
}

}

</style>