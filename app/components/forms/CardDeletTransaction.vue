<script setup lang="ts">

  const props = defineProps<{
    colorBotton: string,
    titleBotton: string,
    title: string,
    text: string,
    draft: TMovementsPayload | null
  }>()

  const  emit = defineEmits<{
    success: []
  }>()

  import type { TMovements } from "~~/types/movements/TMovements"
  import { useInvalidate } from "~/composables/useInvalidate"
  import { useHttpMovements } from '~/composables/useHttp/useHttpMovements'
  import type { TMovementsPayload } from "~~/schemas/movements.schema";


  const { invalidate } = useInvalidate()
  const { patchMovementsById } = useHttpMovements()
  const { notifyError, notifyInfo, notifySuccess } = useNotify()


  const modelValue = defineModel<boolean>()

  const  { mutate } = useMutation({

  mutationFn: (payload: TMovementsPayload) => patchMovementsById(payload.id!, payload),

  onSuccess: () => {
    invalidate(QUERY_KEYS.movements.all)
    invalidate(QUERY_KEYS.movements.only_expenses)
    invalidate(QUERY_KEYS.movements.only_revenues)
    invalidate(QUERY_KEYS.movements.current_balance)
    invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
    invalidate(QUERY_KEYS.tranfer.all)
    emit("success")
  },

  onError: (error) => {
    handleErrorApplication(error.statusCode)
  },

})

async function submitForm() {

  if(!props.draft) {
    notifyError("Ops!", "Algo não parece certo. Confira os dados e tente novamente.")
    return
  } 

  const raw = structuredClone(toRaw(props.draft))

  const payload = {
    ...raw
  }

  if (props.draft.type_transaction === "receita") {
    payload.is_deleted = true
    modelValue.value = false
    notifySuccess("Sucesso", "Receita deletada com sucesso", 6000)
  }
  
  if (props.draft.type_transaction === "despesa") {
    payload.is_deleted = true
    modelValue.value = false
    notifySuccess("Sucesso", "Despesa deletada com sucesso", 6000)
  }

  mutate(payload)
  
}


</script>


<template >

  <div>
      <v-dialog
        transition="dialog-bottom-transition"
        width="500"
        v-model="modelValue"
      >
        <template v-slot:default="{ isActive }">
          <v-card rounded="xl">
            
            <template #title>
              <span class="font-weight-bold text-blue-grey-darken-4 title">{{ props.title }}</span>
            </template>

              <template #subtitle>
                <span class="subtitle">{{ props.text }}</span>
              </template>

              <v-divider></v-divider>

            <v-card-text class="text-display-large pa-5">
              <div class="info">
                  <div>
                      <p class="font-weight-bold text-blue-grey-darken-4">Descrição</p>
                      <p style="color: rgba(0, 0, 0, 0.5);">{{ props.draft?.description_transaction }}</p>
                  </div>

                  <div>
                      <p class="font-weight-bold text-blue-grey-darken-4">Valor</p>
                      <p style="color: rgba(0, 0, 0, 0.5);  text-align: center;">{{ formatCurrency(props.draft?.value_transaction ?? 0.00) }}</p>
                  </div>

                  <div>
                      <p class="font-weight-bold text-blue-grey-darken-4">Data</p>
                      <p style="color: rgba(0, 0, 0, 0.5);  text-align: center;">{{ props.draft?.date_transaction?.split("-").reverse().join("/")}}</p>
                  </div>
              </div> 
            </v-card-text>

              <v-divider></v-divider>

              <v-card-actions class="pa-4 d-flex flex-wrap ga-2">
              <v-btn
                  text="Cancelar"
                  variant="text"
                  :color="props.colorBotton"
                  class="text-none"
                  rounded="lg"
                  @click="isActive.value = false"
              ></v-btn>
              <v-spacer></v-spacer>
              <v-btn
                  :text="props.titleBotton"
                  variant="elevated"
                  :color="props.colorBotton"
                  class="text-none"
                  rounded="lg"
                  @click="submitForm"
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