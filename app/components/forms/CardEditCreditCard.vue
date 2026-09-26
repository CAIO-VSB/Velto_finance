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

  const { getAllAccounts } = useHttpAccounts()
  const { patchCreditCardById } = useHttpCreditsCards()
  const { validateShemaCrediCard } = useValidateSchemas()
  const { notifyError, notifyInfo, notifySuccess } = useNotify()
  const { nameRules, selectRules } = useValidateFields()

  const form = ref()
  const searchAccounts = ref("")
  const searchLogos = ref("")
  const modelAccounts = ref<number | null>(null)
  const menuAccounts = ref(false)
  const modelLogos = ref<string | null>("")
  const menuLogos = ref(false)
  const modelValue = defineModel<boolean>()
  const showAlertDueDayDffClosingDay = ref(false)
  const { invalidate } = useInvalidate()

  const props = defineProps<{
    draft: TCreditCard | null
  }>()

  const { data, error } = useQuery({
    queryKey: QUERY_KEYS.accounts.all,
    queryFn: getAllAccounts,
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

  watch(() => props.draft, (val) => {
    if (val) {
      modelAccounts.value = val.accounts_id ?? null
      modelLogos.value = val.url_logo ?? ""
    }
  }, {immediate: true})

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

  const  { mutate, isPending  } = useMutation({
    
    mutationFn: (payload: TCreditCard) => patchCreditCardById(payload.id!, payload),

    onSuccess: () => {
      invalidate(QUERY_KEYS.creditCards.all)
      invalidate(QUERY_KEYS.creditCards.disable)
      notifySuccess("Sucesso", "Cartão de crédito editado com sucesso", 6000)
      modelValue.value = false
    },

    onError: (error) => {
      handleErrorApplication(error.statusCode)
    },

  })

  async function handleEditCreditCard() {

    if (props.draft?.due_day === props.draft?.closing_day) {
      notifyInfo(
        "Atenção",
        "O dia de vencimento não pode ser igual ao dia de fechamento."
      )
      return
    }

    try {

      if (!props.draft) {
        notifyError("Ops!", "Algo não parece certo. Confira os dados e tente novamente.")
        return
      }

      const { valid } = await form.value.validate()
      const resultSchema = validateShemaCrediCard(props.draft)

      if (valid) {
        if (!props.draft.four_digits || props.draft.four_digits.length < 4) {
          notifyInfo("Atenção", "Digite os 4 últimos dígitos do cartão.", 5000)
        }
        if (resultSchema.success) {  
          mutate(props.draft)
        }
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
    v-if="props.draft"
    >
    <v-dialog
      v-model="modelValue"
      max-width="600"

    >
      <v-card
        rounded="lg" elevation="4"
      >
        <v-card-item class="pa-5 pb-2">
          <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
              Editar cartão de crédito
          </v-card-title>

          <v-card-subtitle class="mt-1">
              Preencha os dados para editar seu cartão.
          </v-card-subtitle>
        </v-card-item>

        <v-divider></v-divider>

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
                v-model="props.draft.name_identifier"
                prepend-inner-icon="mdi-card-text"
              ></v-text-field>
            </v-col>
            <v-col
              cols="12"
              md="6"
              sm="6"
            >
              <CurrencyInput variant="solo-filled" prepend-inner-icon="mdi-cash-multiple" v-model="props.draft.limit_card!" label="Limite" />
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
                isent
                counter
                :rules="fourDigitsRules"
                v-model="props.draft.four_digits"
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
                :min="1"
                :rules="dueDayRules"
                isent
                v-model="props.draft.closing_day"
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
                :max="31"
                :min="1"
                :rules="closingDayRules"
                v-model="props.draft.due_day"
                prepend-inner-icon="mdi-calendar-clock"
              ></v-number-input>
            </v-col>

            <v-col
              cols="12"
              sm="12"
            >
             <v-select
                v-model="props.draft.accounts_id"
                v-model:menu="menuAccounts"
                :items="filterAccounts"
                :rules="selectRules"
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
                      hide-details
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
                v-model="props.draft.url_logo"
                v-model:menu="menuLogos"
                :items="filterLogos"
                item-title="text"
                item-value="url"
                clearable
                variant="solo-filled"
                label="Banco*"
                persistent-hint
                :rules="selectRules"
                prepend-inner-icon="mdi-credit-card-outline"
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
                      hide-details
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
          <v-sheet border rounded="lg" class="pa-4 mt-4 mb-2">
            <div class="text-body-2 font-weight-bold text-blue-grey-darken mb-3">
              Opções da conta
            </div>
            <v-switch
              color="success"
              label="Ativo"
              hide-details
              true-icon="mdi-check"
              false-icon="mdi-close"
              v-model="props.draft.active"
            ></v-switch>
          </v-sheet>

          <small class="text-caption text-medium-emphasis">* Indica campos obrigatórios</small>
        </v-card-text>

        <v-divider></v-divider>

        <v-card-actions class="pa-5 justify-space-between">
          <v-btn
            class="text-none"
            text="Cancelar"
            variant="plain"
            @click="modelValue = false"
          ></v-btn>

          <v-btn
            class="text-none font-weight-bold"
            color="primary"
            text="Editar"
            variant="flat"
            :loading="isPending"
            @click="handleEditCreditCard"
          ></v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    </v-form>
</template>
