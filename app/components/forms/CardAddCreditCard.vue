<script lang="ts" setup>

  import { useHttpAccounts } from "~/composables/useHttp/useHttpAccounts"
  import banks from "~~/shared/banks/catalog"
  import type { TCreditCard } from "~~/types/credit_card/TCredit-card"
  import CurrencyInput from "~/components/ui/CurrencyInput.vue"
  import { useHttpCreditsCards } from "~/composables/useHttp/useHttpCreditCard"
  import { useValidateSchemas } from "~/composables/useValidateSchema"
  import { useValidateFields } from "~/composables/useValidateFields"
  import { useInvalidate } from "~/composables/useInvalidate"
  import flags from "~~/shared/flags/catalog"

  const { getAccountsOnlyActive } = useHttpAccounts()
  const { postCreditCard } = useHttpCreditsCards()
  const { validateShemaCrediCard } = useValidateSchemas()
  const { notifyError, notifyInfo, notifySuccess } = useNotify()
  const { nameRules, currencyRules } = useValidateFields()
  const { invalidate } = useInvalidate()


  const form = ref()
  const searchAccounts = ref("")
  const searchLogos = ref("")
  const modelAccounts = ref<number | null>(null)
  const menuAccounts = ref(false)
  const modelLogos = ref<string | null>(null)
  const menuLogos = ref(false)
  const showAlertDueDayDffClosingDay = ref(false)
  const modelValue = defineModel<boolean>()
  const cardCredit = ref<TCreditCard>({
    name_identifier: "",
    limit_card: null,
    due_day: null,
    closing_day: null,
    accounts_id: 0,
    url_logo: "",
    active: true,
    four_digits: "" 
  })

  const { data, error } = useQuery({
    queryKey: QUERY_KEYS.accounts.all,
    queryFn: getAccountsOnlyActive,
  })

  const fourDigitsRules = ref([
    (val: string) => !!val || "Campo obrigatório",
    (val: string) => val.length <= 4 || "O valor deve conter no máximo 4 caracteres",
    (val: string) => /^[0-9]+$/.test(val) || "Informe apenas números"
  ])

  const dueDayRules = ref([
    (val: number) => !!val || "Campo obrigatório"
  ])

  const closingDayRules = ref([
    (val: number) => !!val || "Campo obrigatório"
  ])

  const accountDebitRules = ref([
    (val: string) => !!val || "Campo obrigatório"
  ])

  const logoCreditCardRules = ref([
    (val: string) => !!val || "Campo obrigatório"
  ])


  watch(cardCredit, (val) => {
    if (val) return val.name_identifier = ""
  })

  /**
   * Observa a mudança do menu, e com base no status, ele limpa o campo de pesquisa
   * @param menuAccounts
   */
  watch(menuAccounts, (val) => {
    if (!val) searchAccounts.value = ""
  })

  watch(menuLogos, (val) => {
    if (!val) searchLogos.value = ""
  })

  /**
   * Responsavel por filtrar as contas com base no valor digitado pelo usuario
   * @returns Retorna os dados já filtrados
   */
  const filterAccounts = computed(() => {
    return data.value?.filter(item => item.name_identifier.toLowerCase().includes(searchAccounts.value?.toLowerCase() ?? ''))
  })

  const filterLogos = computed(() => {
    return banks.filter(item => item.text.toLowerCase().includes(searchLogos.value.toLowerCase()))
  })

  function resetForm() {
    cardCredit.value.closing_day = null
    cardCredit.value.due_day = null
    cardCredit.value.four_digits = ""
    cardCredit.value.limit_card = null
    cardCredit.value.name_identifier = ""
    modelAccounts.value = 0
    modelLogos.value = ""
    modelValue.value = false
    showAlertDueDayDffClosingDay.value = true
  }

  const  { mutate, isPending  } = useMutation({
    
    mutationFn: postCreditCard,

    onSuccess: () => {
      resetForm()
      invalidate(QUERY_KEYS.creditCards.all)
      notifySuccess("Sucesso", "Cartão de crédito criado com sucesso", 6000)
      showAlertDueDayDffClosingDay.value = false
    },

    onError: (error) => {
      handleErrorApplication(error.statusCode)
    },

  })

  async function handleAddCreditCard() {

    cardCredit.value.accounts_id = toRaw(modelAccounts.value ?? -1)
    cardCredit.value.url_logo = toRaw(modelLogos.value ?? "")

    const { valid } = await form.value.validate()
    const resultSchema = validateShemaCrediCard(cardCredit.value)

    if (!cardCredit.value.four_digits || cardCredit.value.four_digits?.length < 4 ) {
      notifyInfo("Atenção", "Digite os 4 últimos dígitos do cartão.", 5000)
    }

    if (cardCredit.value.due_day === cardCredit.value.closing_day) {
      showAlertDueDayDffClosingDay.value = true
      return
    }

    try {
      
      if (valid && resultSchema.success) {
        mutate(cardCredit.value)
      }

    } catch (error) {
      notifyError("Erro", "Ocorreu um erro ao validar o formulário. Por favor, tente novamente.", 6000)
    }
  
}

</script>

<template>
    <v-form
    @submit.prevent
    ref="form"
    validate-on="submit"
    >
    
    <v-dialog
      v-model="modelValue"
      max-width="640"
    >
      <v-card
      rounded="xl"
      >
        <v-card-item class="pa-5 pb-2">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
              Novo cartão de crédito
            </v-card-title>

            <v-card-subtitle class="mt-1">
              Preencha os dados para cadastrar seu cartão.
            </v-card-subtitle>
        </v-card-item>
        <v-divider />
        <v-card-text>
          <v-row >

            <v-col
              cols="12"
              md="12"
              sm="12"
            >
              <v-text-field
                label="Nome do cartão de crédito*"
                variant="solo-filled"
                :rules="nameRules"
                name="cc-name"
                v-model="cardCredit.name_identifier"
                autocomplete="cc-name"
                maxlength="30"
                counter="30"
                prepend-inner-icon="mdi-card-text"
              ></v-text-field>
            </v-col>
            <v-col
              cols="12"
              md="6"
              sm="6"
            >
            
            <CurrencyInput prepend-inner-icon="mdi-cash-multiple"  autocomplete="limite" name="limite" v-model="cardCredit.limit_card!" label="Limite"
            variant="solo-filled" />

            </v-col>
            <v-col
              cols="12"
              md="6"
              sm="6"
            >
              <v-text-field
                label="Últimos 4 dígitos*"
                variant="solo-filled"
                hint="Ajuda a diferenciar este cartão quando você possui vários cadastrados"
                persistent-hint
                autocomplete="off"
                isent
                :counter="4"
                maxlength="4"
                :rules="fourDigitsRules"
                v-model="cardCredit.four_digits"
                prepend-inner-icon="mdi-credit-card-lock"
              ></v-text-field>
            </v-col>

            <v-col
              cols="12"
              md="6"
              sm="6"
            >
              <v-number-input
                label="Dia do fechamento*"
                variant="solo-filled"
                maxlength="2"
                :max="31"
                autocomplete="off"
                :min="1"
                :rules="dueDayRules"
                isent
                v-model="cardCredit.closing_day"
                prepend-inner-icon="mdi-calendar-remove"
              ></v-number-input>
            </v-col>

            <v-col
              cols="12"
              md="6"
              sm="6"
            >
              <v-number-input
                label="Dia do vencimento*"
                variant="solo-filled"
                isent
                maxlength="2"
                autocomplete="off"
                :max="31"
                :min="1"
                :rules="closingDayRules"
                v-model="cardCredit.due_day"
                prepend-inner-icon="mdi-calendar-clock"
                :error-messages="(cardCredit.closing_day && cardCredit.due_day === cardCredit.closing_day) ? ['O dia de vencimento deve ser diferente do fechamento'] : []"
              ></v-number-input>
            </v-col>

            <v-col
              cols="12"
              sm="12"
            >
             <v-select
                v-model="modelAccounts"
                v-model:menu="menuAccounts"
                :items="filterAccounts"
                :rules="accountDebitRules"
                item-title="name_identifier"
                item-value="id"
                clearable
                variant="solo-filled"
                label="Conta vinculada*"
                hint="Os débitos do cartão serão debitados desta conta"
                persistent-hint
                prepend-inner-icon="mdi-bank-transfer"
              >
                <template v-slot:selection="{item}">
                  <v-avatar  style="width: 30px; height: 30px; margin-right: 12px;"> 
                    <v-img  :src="item.url_image" :alt="item.name_identifier"></v-img>
                  </v-avatar>
                  <span>{{ item.name_identifier }}</span>
                </template>

                <template v-slot:item="{props, item}">
                  <v-list-item  v-bind="props">
                    <template v-slot:prepend>
                      <v-avatar>
                        <v-img :src="item.url_image" :alt="item.name_identifier"></v-img>
                      </v-avatar>
                    </template>
                  </v-list-item>
                </template>

                <template v-slot:prepend-item>
                  <div class="pa-2 border-b">
                    <v-text-field
                      v-model="searchAccounts"
                      :error="!!searchAccounts && !filterAccounts?.length"
                      density="compact"
                      placeholder="Buscar..."
                      prepend-inner-icon="mdi-magnify"
                      variant="outlined"
                      clearable
                      @click.stop
                      @keydown.stop
                      @mousedown.stop
                      hide-details="auto"
                      
                    >                 
                  </v-text-field>
                  </div>
                </template>

                <template v-slot:append-item>
                  <div class="d-flex align-center pa-2 pl-4 border-t">
                    <span v-if="searchAccounts" class="text-body-2">
                      {{ filterAccounts?.length }} resultado encontrados de {{ data?.length }}
                    </span>
                  </div>
                </template>
              </v-select>
            </v-col>

            <v-col
              cols="12"
              sm="12"
            >
              <v-select
                v-model="modelLogos"
                v-model:menu="menuLogos"
                :items="filterLogos"
                item-title="text"
                item-value="url"
                clearable
                variant="solo-filled"
                label="Banco*"
                :rules="logoCreditCardRules"
                prepend-inner-icon="mdi-bank"
              >
                <template v-slot:selection="{item}">
                  <v-avatar style="width: 30px; height: 30px; margin-right: 12px;"> 
                    <v-img :src="item.url" :alt="item.text"></v-img>
                  </v-avatar>
                  <span>{{ item.text }}</span>
                </template>

                <template v-slot:item="{props, item}">
                  <v-list-item v-bind="props">
                    <template v-slot:prepend>
                      <v-avatar>
                        <v-img :src="item.url" :alt="item.text"></v-img>
                      </v-avatar>
                    </template>
                  </v-list-item>
                </template>

                <template v-slot:prepend-item>
                  <div class="pa-2 border-b">
                    <v-text-field
                      v-model="searchLogos"
                      :error="!!searchLogos && !filterLogos?.length"
                      density="compact"
                      placeholder="Buscar..."
                      prepend-inner-icon="mdi-magnify"
                      variant="outlined"
                      clearable
                      @click.stop
                      @keydown.stop
                      @mousedown.stop
                      hide-details="auto"
                    >                 
                  </v-text-field>
                  </div>
                </template>

                <template v-slot:append-item>
                  <div class="d-flex align-center pa-2 pl-4 border-t">
                    <span v-if="searchLogos" class="text-body-2">
                      {{ filterLogos?.length }} resultado encontrados de {{ data?.length }}
                    </span>
                  </div>
                </template>
              </v-select>
            </v-col>
          </v-row>

          <small class="text-caption text-medium-emphasis">* Indica campos obrigatórios</small>
        </v-card-text>

        <v-divider></v-divider>

        <v-card-actions class="pa-5 justify-space-between">
          <v-btn
            class="text-none"
            text="Cancelar"
            variant="plain"
            @click="resetForm"
          ></v-btn>
          <v-btn
            class="text-none font-weight-bold"
            color="primary"
            text="Salvar"
            variant="flat"
            :loading="isPending"
            @click="handleAddCreditCard"
          ></v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    </v-form>
</template>
