<script setup lang="ts">

  definePageMeta({
    title: "Contas bancárias",
    layout: "layout-dashboard"
  })

  import { useHttpAccounts } from "~/composables/useHttp/useHttpAccounts"
  import type { TAccount } from "~~/types/account/TAccount.types"
  import { useInvalidate } from "~/composables/useInvalidate"
  
  const { getAllAccounts, getBalanceForAccount, patchAccountById } = useHttpAccounts()
  const { notifyError, notifyInfo, notifySuccess } = useNotify()
  const { invalidate } = useInvalidate()

  const loadingButton = ref(false)
  const headers = [
    { key: 'name_identifier', title: 'Descrição' },
    { key: 'type_account', title: 'Tipo de conta' },
    { key: 'saldo_atual', title: 'Saldo atual' },
    { key: 'actions', title: 'Ações' },
  ]

  const { isPending, data, error } = useQuery({
    queryKey: QUERY_KEYS.accounts.all,
    queryFn: getAllAccounts,
  })

  const { data:balanceForId } = useQuery({
    queryKey: QUERY_KEYS.accounts.getBalanceForAccount,
    queryFn: getBalanceForAccount,
  })

  const  { mutate } = useMutation({

    mutationFn: (payload: TAccount) => patchAccountById(payload.id!, payload),

    onSuccess: () => {
      invalidate(QUERY_KEYS.accounts.all)
      invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
      notifySuccess("Sucesso", "Operação realizada com sucesso", 6000)
    },

    onError: (error) => {
      const errorFatal = handleErrorApplication(error.statusCode)
      console.dir("O erro tá vindo aqui pelo menos " + errorFatal)
    },

  })

  const onlyAccountsDisable = computed(() => {
    return data.value?.filter(item => item.active === false)
  })

  const totalArchived = computed(() => {

    const total = balanceForId.value?.filter(item => item.active === false).reduce((acc, item) => {
      return Number(acc) + Number(item.saldo_atual)
    }, 0)

   return total
    
  })

  function backScreenAccounts() {
    navigateTo("/accounts")
  }

  function restoreAccount(account: TAccount) {
    
    loadingButton.value = true

    try {

      if (!account) {
        notifyError("Error", "Conta não encontrada. Tente novamente")
        return
      }      

      const payload = {
        ...account,
        active: true,
        initial_balance: account.initial_balance ? Number(account.initial_balance) : null
      }

      mutate(payload)

    } catch (e) {
      console.log("Erro ao restautar conta", e)
    } finally {
      loadingButton.value = false
    }

  }

</script>

<template>
    <v-container
        fluid
        class="mt-6 pa-4 pa-md-6"
    >
        <div class="d-flex align-center ga-2 mb-6">
            <v-btn
              icon="mdi-arrow-left"
              variant="text"
              @click="backScreenAccounts"
            >
            </v-btn>

            <div>
                <div class="text-h6 font-weight-bold text-blue-grey-darken">
                    Contas arquivadas
                </div>

                <div class="text-body-2 text-medium-emphasis">
                    Consulte e restaure contas que foram arquivadas.
                </div>
            </div>
        </div>

        <v-row>
            <v-col
                cols="12"
                xl="9"
            >
                <v-card
                    rounded="xl"
                    elevation="2"
                    border
                    class="overflow-hidden"
                >
                    <v-card-item class="pa-4 pb-2">
                        <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
                            Contas
                        </v-card-title>
                    </v-card-item>

                    <v-divider />

                    <v-data-table
                        :headers="headers"
                        :items="onlyAccountsDisable"
                        :loading="isPending"
                        mobile-breakpoint="md"
                        hide-default-footer
                    >
                        <template #item.saldo_atual="{ item }">
                            <v-chip
                                :color="item.saldo_atual! >= 0 ? 'success' : 'error'"
                                size="small"
                            >
                                {{ formatCurrency(item.saldo_atual ?? 0.00) }}
                            </v-chip>
                        </template>

                        <template #item.actions="{ item }">
                            <v-tooltip text="Restaurar">
                                <template #activator="{ props }">
                                    <v-btn
                                        v-bind="props"
                                        icon="mdi-restore"
                                        variant="text"
                                        :loading="loadingButton"
                                        @click="restoreAccount(item)"
                                    />
                                </template>
                            </v-tooltip>
                        </template>
                    </v-data-table>
                </v-card>
            </v-col>

            <v-col
                cols="12"
                xl="3"
            >
                <v-card
                    rounded="xl"
                    elevation="2"
                    border
                    height="100%"
                >
                    <v-card-text class="pa-4">
                        <div class="d-flex align-center justify-space-between">
                            <span class="text-body-2 text-medium-emphasis">
                                Saldo total arquivado
                            </span>

                            <v-avatar
                                color="primary"
                                variant="tonal"
                                icon="mdi-scale-unbalanced"
                                rounded="lg"
                                size="44"
                            />
                        </div>

                        <div style="font-size: var(--text-md);" class="font-weight-bold text-blue-grey-darken mt-5">
                            {{ formatCurrency(totalArchived ?? 0.00) }}
                        </div>

                        <v-chip
                            color="primary"
                            size="small"
                            variant="tonal"
                            class="mt-4"
                        >
                            Arquivado
                        </v-chip>
                    </v-card-text>
                </v-card>
            </v-col>
        </v-row>
    </v-container>
</template>

<style scoped>
</style>