<script lang="ts" setup>

  //Importações composables
  import { useValidateFields } from "~/composables/useValidateFields"
  import { useValidateSchemas } from "~/composables/useValidateSchema"

  //Importações components
  import type { TAccount } from "~~/types/account/TAccount.types"
  import { useSelectedBank } from "~/composables/useAccount/useSelectedBank"
  import { useSelectedColor } from "~/composables/useAccount/useSelectedColor"
  import { useHttpAccounts } from "~/composables/useHttp/useHttpAccounts"
  import { useInvalidate } from "~/composables/useInvalidate"
  import DialogAddColor from "~/components/forms/DialogAddColor.vue"
  import DialogAddFinancialInstitution from "~/components/forms/DialogAddFinancialInstitution.vue"
  import CurrencyInput from "~/components/ui/CurrencyInput.vue"
  

  const { notifyError, notifyInfo, notifySuccess } = useNotify()
  const { nameRules, } = useValidateFields()
  const { dialogAddInstitution, selectedBank } = useSelectedBank()
  const { dialogColorPicker, selectedColor } = useSelectedColor()
  const { validateSchemaAccount } = useValidateSchemas()
  const { postAccount } = useHttpAccounts()
  const { invalidate } = useInvalidate()
  

  const selectRules = ref([
    (val: string) => !!val || "Tipo de conta é obrigatório"
  ])

  const logoRules = ref([
    (val: string) => !!val || "Logo é obrigatório"
  ])

  const colorRules = ref([
    (val: string) => !!val || "Cor de identificação é obrigatório"
  ])

  const items = ref([
    'Corrente',
    'Poupança',
    'NuConta',
    'Conta Salário',
    'Conta de Pagamento',
    'Conta Digital',
    'Conta de Investimentos'
  ])

  const form = ref()

  const modelValue = defineModel<boolean>()

  const accountForm = ref<TAccount>({
    name_identifier: "",
    initial_balance: null,
    type_account: "",
    name_bank: "",
    color: "",
    url_image: "",
    active: true,
    saldo_atual: 0.00
  })


  watch(selectedBank, (bank) => {
    if (bank !== null) {
      accountForm.value.name_bank  = bank.name
      accountForm.value.url_image = bank.url
    } else {
      accountForm.value.url_image = ""
      accountForm.value.name_bank = ""
    }
  })

  watch (selectedColor, (color) => {
    if (color !== null) {
      accountForm.value.color = color
    }
  })


  function resetForm() {
    accountForm.value.name_identifier = ""
    accountForm.value.url_image = ""
    accountForm.value.type_account = ""
    accountForm.value.url_image = ""
    accountForm.value.color = ""
    accountForm.value.initial_balance = 0.00
    modelValue.value = false
  }

  const  { mutate, isPending  } = useMutation({
    
    mutationFn: postAccount,

    onSuccess: () => {
      invalidate(QUERY_KEYS.accounts.all)
      invalidate(QUERY_KEYS.accounts.getBalanceForAccount)
      notifySuccess("Sucesso", "Conta criada com sucesso", 6000)
      resetForm()
      modelValue.value = false
    },

    onError: (error) => {
      handleErrorApplication(error.statusCode)
    },

  })

  async function handleAddAccount() {
    
    try {
        
        const { valid } = await form.value.validate()
        const resultSchema = validateSchemaAccount(accountForm.value)
      
        if (valid && resultSchema.success) {
          mutate(accountForm.value)
        }

    } catch (err) {
      notifyError("Erro", "Ocorreu um erro ao validar o formulário. Por favor, tente novamente.", 6000)
    } 
  }


</script>

<template>
    <v-dialog
        v-model="modelValue"
        max-width="560"
    >
        <v-card
            rounded="xl"
            elevation="4"
        >
            <v-card-item class="pa-5 pb-2">
                <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken-4">
                    Nova conta bancária
                </v-card-title>

                <v-card-subtitle class="mt-1">
                    Preencha os dados para cadastrar sua conta.
                </v-card-subtitle>
            </v-card-item>

            <v-divider />

            <v-form
                ref="form"
                @submit.prevent
            >
                <v-card-text class="pa-5 d-flex flex-column form-fields">
                    <CurrencyInput
                        v-model="accountForm.initial_balance"
                        prepend-inner-icon="mdi-bank"
                        autocomplete="off"
                        hint="Valor atual da conta no momento do cadastro."
                        label="Saldo inicial"
                        variant="solo-filled"
                    />

                    <v-text-field
                        v-model="accountForm.name_identifier"
                        :rules="nameRules"
                        variant="solo-filled"
                        color="primary"
                        name="name"
                        autocomplete="name"
                        maxlength="30"
                        counter="30"
                        prepend-inner-icon="mdi-wallet"
                    >
                        <template #label>
                            Nome da conta <span class="required-mark">*</span>
                        </template>
                    </v-text-field>

                    <v-select
                        v-model="accountForm.type_account"
                        :items="items"
                        :rules="selectRules"
                        variant="solo-filled"
                        color="primary"
                        hint="Dúvidas sobre qual conta escolher? Clique no ícone de ajuda."
                        persistent-hint
                        prepend-inner-icon="mdi-format-list-bulleted"
                    >
                        <template #label>
                            Tipo <span class="required-mark">*</span>
                        </template>

                        <template #append>
                            <nuxt-link
                                target="_blank"
                                to="https://www.serasa.com.br/blog/conta-bancaria/"
                            >
                                <v-icon
                                    color="info"
                                    icon="mdi-chat-question"
                                    size="large"
                                />

                                <v-tooltip
                                    activator="parent"
                                    location="top"
                                >
                                    Se não tiver certeza de qual conta escolher, clique no ícone de ajuda.
                                </v-tooltip>
                            </nuxt-link>
                        </template>
                    </v-select>

                    <v-text-field
                        v-model="accountForm.name_bank"
                        :rules="logoRules"
                        hint="Selecione o banco ou a instituição financeira."
                        persistent-hint
                        readonly
                        variant="solo-filled"
                        color="primary"
                    >
                        <template #label>
                            Instituição financeira <span class="required-mark">*</span>
                        </template>

                        <template #prepend-inner>
                            <v-avatar
                                :image="accountForm.url_image || undefined"
                                size="30"
                                color="grey-lighten-3"
                                class="mr-2"
                            >
                            </v-avatar>
                        </template>

                        <template #append-inner>
                            <v-btn
                              icon="mdi-plus"
                              variant="text"
                              density="comfortable"
                              @click="dialogAddInstitution = true"
                            >
                            </v-btn>
                        </template>
                    </v-text-field>

                    <v-text-field
                        v-model="accountForm.color"
                        :rules="colorRules"
                        hint="Escolha uma cor para identificar a conta."
                        persistent-hint
                        readonly
                        variant="solo-filled"
                        color="primary"
                    >
                        <template #label>
                            Cor de identificação <span class="required-mark">*</span>
                        </template>

                        <template #prepend-inner>
                            <v-avatar
                                :color="accountForm.color"
                                size="30"
                                class="mr-2"
                            />
                        </template>

                        <template #append-inner>
                            <v-btn
                                icon="mdi-eyedropper-variant"
                                variant="text"
                                density="comfortable"
                                @click="dialogColorPicker = true"
                            >
                            </v-btn>

                            <v-btn
                              icon="mdi-help-circle-outline"
                              variant="text"
                              density="comfortable"
                              v-tooltip="'Selecione a cor desejada e clique fora da janela para confirmar.'"
                            >
                            </v-btn>
                        </template>
                    </v-text-field>

                    <div class="text-caption text-medium-emphasis">
                        * Indica campos obrigatórios.
                    </div>
                </v-card-text>

                <v-divider />

                <v-card-actions class="pa-5 justify-space-between">
                    <v-btn
                    variant="text"
                    class="text-none font-weight-medium"
                    @click="resetForm"
                    >
                    Fechar
                    </v-btn>

                    <v-btn
                    color="primary"
                    variant="flat"
                    rounded="lg"
                    class="text-none font-weight-bold"
                    :loading="isPending"
                    @click="handleAddAccount"
                    >
                        Salvar
                    </v-btn>
                </v-card-actions>
            </v-form>
        </v-card>
    </v-dialog>

    <DialogAddFinancialInstitution v-model="dialogAddInstitution" />

    <DialogAddColor v-model="dialogColorPicker" />
</template>

<style scoped>
.form-fields {
  gap: 20px;
}


</style>