<script lang="ts" setup>

  import { useSelectedIcon } from "~/composables/useCategorie/useSelectedIcon"
  import { useValidateFields } from "~/composables/useValidateFields"
  import { useHttpCategories } from "~/composables/useHttp/useHttpCategories"
  import type { TCategorie } from "~~/types/categorie/TCategorie"
  import { useSelectedCategorie } from "~/composables/useCategorie/useSelectedCategorie"
  import CardAddIconCategorie from "~/components/forms/CardAddIconCategorie.vue"
  import { useValidateSchemas } from "~/composables/useValidateSchema"
  import { useInvalidate } from "~/composables/useInvalidate"

  const { notifyError, notifyInfo, notifySuccess } = useNotify()
  const { nameRules } = useValidateFields() 
  const { validateSchemaCategorie  } = useValidateSchemas()
  const { selectedIcon } = useSelectedIcon()
  const { selectedCategorie  } = useSelectedCategorie()
  const {  patchCategorieById } = useHttpCategories()  
  const { invalidate } = useInvalidate()

  const items = ref([
    'Despesa',
    'Receita',
  ])

  const props = defineProps<{
    draft: TCategorie | null
  }>()

  const selectRules = ref([
    (val: string) => !!val || "Campo tipo é obrigatório",
  ])

  const modalAddIconCategorie = ref(false)
  const form = ref()
  const modelValue = defineModel<boolean>()
  const switchValue = ref(true)
  const labelSwitch = ref("Ativo")

  watch(selectedIcon, (newIcon) => {
    if (props.draft !== null && newIcon !== null) {
      props.draft.url_icon = newIcon.icon
      modalAddIconCategorie.value = false
    }
  })

  watch(selectedCategorie, (newcategoire) => {
    if (props.draft !== null && newcategoire !== null ) {
      props.draft.name_identifier = newcategoire?.name
      props.draft.type_categorie = newcategoire.type_categorie
    }
  })

  watch(() => props.draft, (val) => {
    if (props.draft) switchValue.value = val?.active ?? true
  })

  watch(switchValue, (val) => {
    if (val === true) {
      labelSwitch.value = "Ativo"
      if (props.draft) props.draft.active = switchValue.value
    } else if (val === false) {
      labelSwitch.value = "Inativar"
      if (props.draft) props.draft.active = switchValue.value
    }
  })

  const  { mutate, isPending  } = useMutation({

    mutationFn: (payload: TCategorie) => patchCategorieById(payload.id!, payload),

    onSuccess: () => {
      invalidate(QUERY_KEYS.categories.all)
      notifySuccess("Sucesso", "Categoria editada com sucesso", 6000)
      modelValue.value = false
    },

    onError: (error) => {
      handleErrorApplication(error.statusCode)
    },

  })

  async function handleAddAccount() {

    if(!props.draft) {
      notifyError("Atenção", "O objeto passado é inválido. Tente novamente.")
      return
    }

    try {
      const { valid } = await form.value.validate()
      const resultSchema = validateSchemaCategorie(props.draft)
      
      if (valid) {
        if (resultSchema.success) {  
          mutate(props.draft)
        }
      }
    } catch (err) {
      notifyError("Erro", "Ocorreu um erro ao validar o formulário. Por favor, tente novamente.", 6000)
    }

  }

</script>

<template>
  <div class="text-center">
    <v-form
    @submit.prevent
    ref="form"
    v-if="props.draft"
    >
      <v-dialog persistent v-model="modelValue" max-width="600">
        <v-card rounded="xl" elevation="4">
          <v-card-item class="pa-5 pb-2">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
                Editar categoria
            </v-card-title>

            <v-card-subtitle class="mt-1">
                Preencha os dados para editar sua categoria.
            </v-card-subtitle>
          </v-card-item>
          <v-divider></v-divider>
          <v-card-text>
            <form>
              <v-text-field
                label="Nome da categoria *"
                variant="solo-filled"
                color="primary"
                v-model="props.draft.name_identifier"
                :rules="nameRules"
                hint="Clique no ícone ao lado para alterá-lo."
                persistent-hint
                :counter="30" 
                maxlength="30"
                prepend-inner-icon="mdi-rename"
                class="mb-4"
              >

               <template #append-inner>
                <v-icon @click.stop="modalAddIconCategorie = true" class="cursor-pointer" :icon=" props.draft.url_icon || 'mdi-plus'" color="primary" size="large"></v-icon>
                <v-tooltip
                activator="parent"
                location="top"
                >Escolha um ícone de identificação
                </v-tooltip>

                </template>
              </v-text-field>

              <v-select prepend-inner-icon="mdi-tag" :rules="selectRules" v-model="props.draft.type_categorie" color="primary" persistent-hint hint="Selecione o tipo de categoria" label="Tipo *" :items="items" variant="solo-filled">
              </v-select>

              <v-sheet border rounded="lg" class="pa-4 mt-4 mb-2">
                <div class="text-body-2 font-weight-bold text-blue-grey-darken mb-3">
                  Opções da categoria
                </div>

                <v-switch
                  v-model="switchValue"
                  color="primary"
                  :label="labelSwitch"
                  true-icon="mdi-check"
                  false-icon="mdi-close"
                  hide-details
                ></v-switch>
              </v-sheet>

            </form>

            <small class="text-caption text-medium-emphasis"
              >* Indica campos obrigatórios</small
            >
          </v-card-text>

          <v-divider></v-divider>

          <v-card-actions class="pa-5 justify-space-between">
            <v-btn
              class="text-none font-weight-medium"
              text="Fechar"
              variant="text"
              @click="modelValue = false"
            ></v-btn>
            <v-btn
              class="text-none font-weight-bold"
              color="primary"
              text="Editar"
              variant="flat"
              rounded="lg"
              :loading="isPending"
              @click="handleAddAccount"
            ></v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-form>
    <CardAddIconCategorie v-model="modalAddIconCategorie" />
  </div>
</template>


<style scoped>

.icon-add-logo:hover {
  background-color: rgba(128, 128, 128, 0.267);
  border-radius: 60%;
}

::v-deep(.v-field__field) {
  align-items: center;
}

::v-deep(.v-card-title) {
  align-items: center;
}


</style>
