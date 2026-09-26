<script setup lang="ts">

    const props = defineProps<{
    colorBotton: string,
    titleBotton: string,
    title: string,
    text: string,
    draft: TMovementCreditCardPayload | null
    }>()

    const  emit = defineEmits<{
        success: []
    }>()

    import { useInvalidate } from "~/composables/useInvalidate"
    import { useHttpMovementCreditCard } from '~/composables/useHttp/useHttpMovementCreditCard'
    import type { TMovementCreditCardPayload } from "~~/schemas/movementCreditCard.schema"; 

    const { invalidate } = useInvalidate()
    const { patchMovementCardById } = useHttpMovementCreditCard()
    const { notifyError, notifyInfo, notifySuccess } = useNotify()

    const modelValue = defineModel<boolean>()
    const dateFormated = ref("")

    watch(() => props.draft, (val) => {
        dateFormated.value = val?.purchase_date.split("-").reverse().join("/") ?? "Data inválida"
    })

    const { mutate, isPending:isPendingMovements  } = useMutation({

      mutationFn: (payload: TMovementCreditCardPayload) => patchMovementCardById(payload.id!, payload, 'deletada'),

      onSuccess: () => {
        invalidate(QUERY_KEYS.movementsCreditCard.byCreditCard)
        invalidate(QUERY_KEYS.movementsCreditCard.totalInvoice)
        invalidate(QUERY_KEYS.movements.only_expenses)
        invalidate(QUERY_KEYS.movements.all)
        notifySuccess("Sucesso", "Operação realizada com sucesso", 6000)
        //emit("success")
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
            ...raw,
            status_movement: "deletada"
        }

        mutate(payload)
        
    }


</script>


<template >

  <div>
      <v-dialog
        transition="dialog-bottom-transition"
        width="650"
        class="mx-auto"
        v-model="modelValue"
        v-if="props.draft"
      >
        <template v-slot:default="{ isActive }">
          <v-card rounded="lg">
            
              <template  #title>
                <span class="title">{{ props.title }}</span>
              </template>

              <template #subtitle>
                <span class="subtitle">{{ props.text }}</span>
              </template>

              <v-divider></v-divider>

            <v-card-text class="text-display-large pa-5">
              <div class="info">
                  <div>
                      <p class="font-weight-bold text-blue-grey-darken">Descrição</p>
                      <p>{{ props.draft?.description_credit }}</p>
                  </div>

                  <div>
                      <p class="font-weight-bold text-blue-grey-darken">Valor</p>
                      <p style=" text-align: center;">{{ formatCurrency(props.draft?.value_transaction ?? 0.00) }}</p>
                  </div>
                  <div>
                      <p class="font-weight-bold text-blue-grey-darken">Data da compra</p>
                      <p style="text-align: center;">{{ dateFormated }}</p>
                  </div>
              </div> 
            </v-card-text>

              <v-divider></v-divider>

              <v-card-actions class="pa-4 d-flex flex-wrap ga-2">
              <v-btn
                  text="Cancelar"
                  variant="text"
                  :color="props.colorBotton"
                  class="text-none "
                  @click="isActive.value = false"
              ></v-btn>
              <v-spacer></v-spacer>
              <v-btn
                  :text="props.titleBotton"
                  variant="flat"
                  :color="props.colorBotton"
                  class="text-none"
                  @click="submitForm"
                  rounded="lg"
                  :loading="isPendingMovements"
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


@media (max-width: 600px) {

.info > div {
    display: flex;
    flex-direction: row;
    text-align: center;
    min-width: 140px;
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