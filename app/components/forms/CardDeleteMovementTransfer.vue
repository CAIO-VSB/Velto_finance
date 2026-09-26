<script setup lang="ts">

  const props = defineProps<{
    colorBotton: string,
    titleBotton: string,
    title: string,
    text: string,
    draft: TTransferMovementsPayload | null
  }>()

  type TTransferMovementsPayload = TMovementsPayload & {
    account_origin?: number | null,
    account_destination?: number | null,
    transfer_id?: number | null
  }

  type TDeleteTransferPayload = TTransferMovementsPayload & {
    value_transfer: number
    date_transfer: string
  }

  import { useInvalidate } from "~/composables/useInvalidate"
  import { useHttpTransfer } from '~/composables/useHttp/useHttpTransfer'
  import type { TMovementsPayload } from "~~/schemas/movements.schema";

  const { invalidate } = useInvalidate()
  const { deleteTransferById } = useHttpTransfer()
  const { notifyError, notifyInfo, notifySuccess } = useNotify()

  const modelValue = defineModel<boolean>()

   const  { mutate, isPending } = useMutation({

    mutationFn: (payload: TDeleteTransferPayload) => deleteTransferById(payload.transfer_id!, payload),

    onSuccess: () => {
      invalidate(QUERY_KEYS.movements.all)
      invalidate(QUERY_KEYS.movements.only_expenses)
      invalidate(QUERY_KEYS.movements.only_revenues)
      invalidate(QUERY_KEYS.movements.current_balance)
      invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
      invalidate(QUERY_KEYS.tranfer.all)
      notifySuccess("Sucesso", "Acão realizada com sucesso", 6000)
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

    if (typeof raw.value_transaction !== "number" || !raw.date_transaction) {
      notifyError("Ops!", "A transferência não possui valor ou data válidos.")
      return
    }

    const transferPayload: TDeleteTransferPayload = {
      ...raw,
      value_transfer: raw.value_transaction,
      date_transfer: raw.date_transaction,
      is_deleted: true
    }

    if (props.draft.type_transaction === "transferencia_entrada" || props.draft.type_transaction === "transferencia_saida") {
      mutate(transferPayload)
      return
    }

  }


</script>


<template >

  <div>
      <v-dialog
        transition="dialog-bottom-transition"
        width="450"
        v-model="modelValue"
      >
        <template v-slot:default="{ isActive }">
          <v-card rounded="lg">
            
              <template #title>
              {{ props.title }}
              </template>

              <template #subtitle>
              {{ props.text }}
              </template>

              <v-divider></v-divider>

            <v-card-text class="text-display-large pa-5">
              <div class="info">
                  <div>
                      <p class="font-weight-bold text-blue-grey-darken">Descrição</p>
                      <p >{{ props.draft?.description_transaction }}</p>
                  </div>

                  <div>
                      <p class="font-weight-bold text-blue-grey-darken">Valor</p>
                      <p style="text-align: center;">{{ formatCurrency(props.draft?.value_transaction ?? 0) }}</p>
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
                  :loading="isPending"
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
  min-width: 180px;
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