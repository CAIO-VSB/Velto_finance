<script setup lang="ts">

    const props = defineProps<{
        colorBotton: string,
        titleBotton: string,
        title: string,
        text: string,
        draft: TGoalsMovementsPayload | null
    }>()

    const  emit = defineEmits<{
        success: []
    }>()


    import { useInvalidate } from "~/composables/useInvalidate"
    import { useHttpMovements } from '~/composables/useHttp/useHttpMovements'
    import type { TMovementsPayload } from "~~/schemas/movements.schema";
    import type { TGoalsMovementsPayload } from "~~/schemas/goalsMovements.schema";
    import { useHttpGoals } from "~/composables/useHttp/useHttpGoals"

    const { invalidate } = useInvalidate()
    const { deleteMovementsGoals } = useHttpGoals()
    const { notifyError, notifyInfo, notifySuccess } = useNotify()

    const modelValue = defineModel<boolean>()

    const  { mutate } = useMutation({

    mutationFn: (payload: TGoalsMovementsPayload) => deleteMovementsGoals(payload.id!),

    onSuccess: () => {
        invalidate(QUERY_KEYS.goals.all)
        invalidate(QUERY_KEYS.goals.balance_for_economy)
        invalidate(QUERY_KEYS.goals.movements(props.draft?.goals_id ?? 0))
        notifySuccess("Sucesso", "Operação realizada com sucesso", 6000)
        modelValue.value = false
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

        mutate(payload)
    
    }


</script>


<template >

  <div>
      <v-dialog
        transition="dialog-bottom-transition"
        width="650"
        v-model="modelValue"
      >
        <template v-slot:default="{ isActive }">
          <v-card rounded="xl">
            
            <template #title>
              <span class="font-weight-bold text-blue-grey-darken title">{{ props.title }}</span>
            </template>

              <template #subtitle>
                <span class="subtitle">{{ props.text }}</span>
              </template>

              <v-divider></v-divider>

            <v-card-text class="text-display-large pa-5">
              <div class="info">
                  <div>
                      <p class="font-weight-bold text-blue-grey-darken">Descrição</p>
                      <p >{{ props.draft?.description}}</p>
                  </div>

                  <div>
                      <p class="font-weight-bold text-blue-grey-darken">Valor</p>
                      <p style="  text-align: center;">{{ formatCurrency(props.draft?.value_paid ?? 0.00) }}</p>
                  </div>

                  <div>
                      <p class="font-weight-bold text-blue-grey-darken">Data</p>
                      <p style="  text-align: center;">{{ props.draft?.date_movement.split("T")[0]?.split("-").reverse().join("/")}}</p>
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
  min-width: 170px;
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
  font-size: 1.1rem;
}

.subtitle {
  font-size: 0.85rem;
}

}

</style>