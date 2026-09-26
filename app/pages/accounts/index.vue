<script setup lang="ts">

  definePageMeta({
    title: "Contas bancárias",
    layout: "layout-dashboard"
  })

  import CardAddAccount from "~/components/forms/CardAddAccount.vue"
  import CardEditAccount from "~/components/forms/CardEditAccount.vue"
  import type { TAccount } from "~~/types/account/TAccount.types"
  import type { TOptionAction } from "~~/types/option_action/TOptionAction"
  import { useHttpAccounts } from "~/composables/useHttp/useHttpAccounts"
  import { useSelectedColor } from "~/composables/useAccount/useSelectedColor"
  import { useSelectedBank } from "~/composables/useAccount/useSelectedBank"
  import { useInvalidate } from "~/composables/useInvalidate"
  import CardAddMovimentsExpenses from "~/components/forms/CardAddMovimentsExpenses.vue"
  import type { TMovements } from "~~/types/movements/TMovements"

  const { getAllAccounts, getBalanceForAccount, patchAccountById } = useHttpAccounts()
  const { resetColor } = useSelectedColor()
  const { resetBank } = useSelectedBank()
  const { invalidate } = useInvalidate()
  const { notifyError, notifyInfo, notifySuccess } = useNotify()
  

  const modalAddAccount = ref(false)
  const modalEditAccount = ref(false)
  const modalAddExpense = ref(false)
  const editDraft = ref<TAccount | null>(null)
  const draftAccount = ref<Partial<TMovements> | null>(null)

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
     handleErrorApplication(error.statusCode)
    },

  })

  function handleOpenModalAddAccount() {
    modalAddAccount.value = true
    resetColor()
    resetBank()
  }


  const totalForAccountsActive = computed(() => {

    const total = data.value?.filter(item => item.active === true).reduce((acc, item) => {
      return Number(acc) + Number(item.saldo_atual)
    }, 0) ?? 0.00

   return total
    
  })

  const filteredAccounts = computed(() => {
    return data.value?.filter(item => item.active !== false)
  })


  function getOptionsAccounts(account: TAccount) {
    const options = [
      { title: 'Editar', value: "edit", icon: "mdi-circle-edit-outline" },
      { title: 'Arquivar', value: "arquivar", icon: "mdi-archive" },
    ]

    return options
  } 

  function getOptions() {
    const options = [
      { title: 'Contas arquivadas', value: "arquivadas", icon: "mdi-archive-clock" },
    ]

    return options
  } 

  function handleCloseEditAccount() {
    modalEditAccount.value = false
    editDraft.value = null
  }

  function handleOpenAddExpense(account: TAccount) {
    draftAccount.value = {accounts_id: account.id}
    modalAddExpense.value = true
  }

  function handleOpenModalEditAccount(account: TAccount) {
    modalEditAccount.value = true
    editDraft.value = {
      ...structuredClone(toRaw(account)),
      initial_balance: account.initial_balance ?? 0.00,
      saldo_atual:  account.saldo_atual ?? 0.00
    } 
  }

  function handleOptionAccountsDisable() {
    navigateTo("/accounts/accountsDisable")
  }

  function handleOptionClick(option: TOptionAction, account: TAccount) {

    if (option.value === "edit") {
      handleOpenModalEditAccount(account)
      return 
    }

    const payload = {
      ...account,
      initial_balance: account.initial_balance ? Number(account.initial_balance) : null,
      active: false
    }

    if (option.value === 'arquivar') {
      mutate(payload)
    }

  }

</script>


<template>
    
    <CardAddAccount v-model="modalAddAccount" />

    <CardEditAccount
        v-model="modalEditAccount"
        :draft="editDraft"
    />

    <CardAddMovimentsExpenses
        v-model="modalAddExpense"
        :draft="draftAccount"
    />

    <v-container
    v-if="!isPending && !data?.length"
    class="bank-accounts-empty-state d-flex align-center justify-center mt-4"
    >
    <v-card
        class="overflow-hidden"
        rounded="xl"
        elevation="4"
        max-width="900"
        mx-auto
    >
        <v-empty-state
        icon="mdi-bank-outline"
        color="primary"
        title="Adicione sua primeira conta bancária"
        text="Cadastre suas contas para acompanhar saldos, movimentações e organizar melhor sua vida financeira."
        class="pa-6 pb-2"
        >
        <template #actions>
            <v-btn
            color="primary"
            prepend-icon="mdi-plus"
            rounded="lg"
            class="text-none font-weight-bold mt-3"
            @click="modalAddAccount = true"
            >
            Adicionar conta bancária
            </v-btn>
        </template>
        </v-empty-state>

        <v-divider class="mx-6 mt-4" />

        <section class="pa-6 pt-5">
        <div class="text-subtitle-1 font-weight-bold text-blue-grey-darken-4 mb-4">
            É simples começar
        </div>

        <v-stepper
            mobile-breakpoint="sm"
            alt-labels
            color="primary"
            :items="['Cadastre a conta', 'Registre movimentações', 'Acompanhe seus saldos']"
        >
            <template #item.1>
            <v-card flat class="text-center pa-5">
                <v-avatar
                color="primary"
                variant="tonal"
                rounded="lg"
                size="48"
                class="mb-3"
                >
                <v-icon icon="mdi-bank-plus" />
                </v-avatar>

                <div class="font-weight-bold mb-1">
                Cadastre sua conta
                </div>

                <div class="text-body-2 text-medium-emphasis">
                Informe o banco, tipo de conta e saldo inicial para começar.
                </div>
            </v-card>
            </template>

            <template #item.2>
            <v-card flat class="text-center pa-5">
                <v-avatar
                color="success"
                variant="tonal"
                rounded="lg"
                size="48"
                class="mb-3"
                >
                <v-icon icon="mdi-swap-horizontal" />
                </v-avatar>

                <div class="font-weight-bold mb-1">
                Registre movimentações
                </div>

                <div class="text-body-2 text-medium-emphasis">
                Adicione entradas, saídas e transferências para manter tudo atualizado.
                </div>
            </v-card>
            </template>

            <template #item.3>
            <v-card flat class="text-center pa-5">
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
                Acompanhe seus saldos
                </div>

                <div class="text-body-2 text-medium-emphasis">
                Visualize o saldo de cada conta e tenha mais controle sobre seu dinheiro.
                </div>
            </v-card>
            </template>
        </v-stepper>
        </section>
    </v-card>
    </v-container>

    <v-container
      fluid
      class="mt-6 pa-4 pa-md-6"
      v-else
    >
        <div class="d-flex justify-end ga-2 mb-6" >
            <v-btn
              color="primary"
              icon="mdi-plus"
              variant="tonal"
              rounded="lg"
              @click="handleOpenModalAddAccount"
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

        <v-row>
            <v-col
                cols="12"
                sm="6"
                lg="4"
            >
                <v-card
                    height="175"
                    rounded="xl"
                    variant="outlined"
                >
                    <div class="d-flex flex-column align-center justify-center h-100 ga-3">
                        <v-btn
                          color="primary"
                          icon="mdi-plus"
                          size="large"
                          variant="tonal"
                          rounded="lg"
                          @click="handleOpenModalAddAccount"
                        />

                        <span class="text-body-1 font-weight-medium text-primary">
                            Nova conta
                        </span>
                    </div>
                </v-card>
            </v-col>

            <v-col
                cols="12"
                sm="6"
                lg="4"
            >
                <v-card
                    height="175"
                    rounded="xl"
                    elevation="2"
                    :loading="isPending"
                >
                    <v-card-text class="pa-4">
                        <div class="d-flex align-center justify-space-between">
                            <div class="d-flex align-center ga-3">
                                <v-avatar
                                    color="primary"
                                    variant="tonal"
                                    rounded="lg"
                                    size="40"
                                >
                                    <v-icon icon="mdi-bank" />
                                </v-avatar>

                                <span class="text-body-2 text-medium-emphasis">
                                    Saldo atual
                                </span>
                            </div>

                            <v-chip
                                :color="totalForAccountsActive >= 0 ? 'success' : 'error'"
                                size="small"
                                variant="tonal"
                            >
                                <v-icon
                                    :icon="totalForAccountsActive >= 0 ? 'mdi-trending-up' : 'mdi-trending-down'"
                                    start
                                    size="15"
                                />

                                {{ totalForAccountsActive >= 0 ? 'Positivo' : 'Negativo' }}
                            </v-chip>
                        </div>

                        <div class="text-h6 font-weight-bold mt-5 mb-5">
                            {{ formatCurrency(totalForAccountsActive || 0.00) }}
                        </div>

                        <v-divider />

                        <div class="text-caption text-medium-emphasis mt-3">
                            Valor consolidado de todas as contas cadastradas e ativas.
                        </div>
                    </v-card-text>
                </v-card>
            </v-col>

            <v-col
                v-for="value in filteredAccounts"
                :key="value.id"
                cols="12"
                sm="6"
                lg="4"
            >
                <v-card
                    height="175"
                    :color="value.color"
                    variant="tonal"
                    rounded="xl"
                    elevation="2"
                >
                    <v-card-item class="pa-4 pb-0">
                        <template #prepend>
                            <v-avatar
                              :image="value.url_image"
                              size="40"
                            />
                        </template>

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
                                        v-for="(action, index) in getOptionsAccounts(value)"
                                        :key="index"
                                        :value="index"
                                        :prepend-icon="action.icon"
                                        rounded="lg"
                                        @click="handleOptionClick(action, value)"
                                    >
                                        <v-list-item-title>
                                            {{ action.title }}
                                        </v-list-item-title>
                                    </v-list-item>
                                </v-list>
                            </v-menu>
                        </template>
                    </v-card-item>

                    <v-card-text class="pa-4 pt-3">
                      <div class="d-flex align-center ga-6">
                          <div class="text-medium-emphasis">
                            Saldo atual
                        </div>

                        <div class="font-weight-bold mt-1">
                            {{ formatCurrency(value.saldo_atual ?? 0.00) }}
                        </div>
                      </div>
                    </v-card-text>

                    <v-divider />

                    <div class="d-flex justify-center pa-2">
                      <v-btn
                          color="primary"
                          variant="text"
                          class="font-weight-medium"
                          @click="handleOpenAddExpense(value)"
                      >
                          Adicionar despesa
                        </v-btn>
                    </div>
                </v-card>
            </v-col>
        </v-row>
    </v-container>
</template>

<style scoped>
</style>

