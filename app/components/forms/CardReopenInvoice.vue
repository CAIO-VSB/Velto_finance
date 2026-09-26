<script setup lang="ts">

    import { useInvalidate } from "~/composables/useInvalidate"
    import { useHttpInvoices } from "~/composables/useHttp/useHttpInvoices"

    const { invalidate } = useInvalidate()
    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    const { patchReopenInvoice } = useHttpInvoices()

    const modelValue = defineModel<boolean>()

    const props = defineProps<{
        invoiceId: number | null
    }>()


    const  { mutate, isPending } = useMutation({

        mutationFn: (payload: number) => patchReopenInvoice(payload),

        onSuccess: () => {
            notifySuccess("Sucesso", "Operação realizada com sucesso", 6000)
            invalidate(QUERY_KEYS.accounts.all)
            invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
            invalidate(QUERY_KEYS.movementsCreditCard.byCreditCard)
            invalidate(QUERY_KEYS.movementsCreditCard.totalInvoice)
            modelValue.value = false
        },

        onError: (error) => {
            handleErrorApplication(error.statusCode)
        },
    })

    function handleReopenInvoice() {

        if (!props.invoiceId) {
            notifyError(
                "Erro ao processar",
                "Não foi possível localizar a fatura. Tente novamente."
            )
            return
        }

        mutate(props.invoiceId)

    }


</script>

<template>
  <v-container>
    <v-row class="justify-space-around">
      <v-col cols="12" md="6">
        <v-dialog
          transition="dialog-bottom-transition"
          width="auto"
          v-model="modelValue"
        >

          <template v-slot:default="{ isActive }">
            <v-card class="pa-5 position-relative" rounded="xl">

                <div class="position-absolute top-0 right-0 pa-3 ">
                    <v-icon class="rounded-lg btn-close-modal pa-4" @click="isActive.value = false"  style="cursor: pointer;" icon="mdi-close"></v-icon>
                </div>

                <template #title>
                    <div class="text-center mb-5" >
                        <span style="font-size: var(--text-md);" class="text-center mb-5 font-weight-bold text-blue-grey-darken">Reabrir fatura</span>
                    </div>
                </template>

                <template #subtitle>
                    <span  class="text-center mb-5">Você tem certeza que deseja reabrir esta fatura?</span>
                </template>
              <v-card-actions class="justify-center">
                <v-btn
                color="primary"
                text="Reabrir"
                variant="flat"
                class="w-100"
                rounded="lg"
                @click="handleReopenInvoice"
                :loading="isPending"
                ></v-btn>
              </v-card-actions>
            </v-card>
          </template>
        </v-dialog>
      </v-col>
    </v-row>
  </v-container>
</template>

<style scoped>

.btn-close-modal:hover {
    background-color: rgba(128, 128, 128, 0.144);
}

</style>