<script lang="ts" setup>

  import { useSelectedIcon } from "~/composables/useCategorie/useSelectedIcon"
  import { useValidateFields } from "~/composables/useValidateFields"
  import { useHttpCategories } from "~/composables/useHttp/useHttpCategories"
  import type { TCategorie } from "~~/types/categorie/TCategorie"
  import CardAddIconCategorie from "~/components/forms/CardAddIconCategorie.vue"
  import { useValidateSchemas } from "~/composables/useValidateSchema"
  import { useInvalidate } from "~/composables/useInvalidate"
  

  const { notifyError, notifyInfo, notifySuccess } = useNotify()
  const { nameRules } = useValidateFields() 
  const { validateSchemaCategorie } = useValidateSchemas()
  const { selectedIcon } = useSelectedIcon()
  const { postCategorie } = useHttpCategories() 
  const { $authClient } = useNuxtApp()
  const { invalidate } = useInvalidate()
  const { data: session } = await $authClient.getSession()

  const items = ref([
    'Despesa',
    'Receita',
  ])

  const selectRules = ref([
    (val: string) => !!val || "Campo tipo é obrigatório",
  ])

  const modalAddIconCategorie = ref(false)
  const form = ref()
  const modelValue = defineModel<boolean>()
  const categorieForm = ref<TCategorie>({
    name_identifier: "",
    type_categorie: null,
    url_icon: "",
    active: true
  })

  watch(selectedIcon, (newIcon) => {
    if (newIcon !== null) {
      categorieForm.value.url_icon = newIcon.icon
      modalAddIconCategorie.value = false
    }
  })

  function resetForm() {
    categorieForm.value.name_identifier = ""
    categorieForm.value.type_categorie = ""
    categorieForm.value.url_icon = ""
    modalAddIconCategorie.value = false
    modelValue.value = false
  }

  const  { mutate, isPending  } = useMutation({

    mutationFn: (payload: TCategorie) => postCategorie(payload),

    onSuccess: () => {
      invalidate("categories")
      notifySuccess("Sucesso", "Categoria criada com sucesso", 6000)
      modelValue.value = false
      resetForm()
    },

    onError: (error) => {
      handleErrorApplication(error.statusCode)
    },

  })

  async function handleAddAccount() {

    try {

      const { valid } = await form.value.validate()
      const resultSchema = validateSchemaCategorie(categorieForm.value)

      if (categorieForm.value.url_icon === ""){
        return notifyInfo("Atenção", "Escolha um ícone que represente esta categoria", 7000)
      }
  
      if (valid && resultSchema.success) {
        mutate(categorieForm.value)
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
    >
      <v-dialog persistent v-model="modelValue" max-width="600">
        <v-card rounded="xl" elevation="4">
          <v-card-item class="pa-5 pb-2">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
                Nova categoria
            </v-card-title>

            <v-card-subtitle class="mt-1">
                Preencha os dados para cadastrar sua categoria.
            </v-card-subtitle>
          </v-card-item>
          <v-divider></v-divider>
          <v-card-text>
            <form>
              <v-text-field
                label="Nome da categoria *"
                variant="solo-filled"
                color="primary"
                v-model="categorieForm.name_identifier"
                :rules="nameRules"
                hint="Adicione uma identificação clicando no ícone ao lado"
                persistent-hint
                :counter="45" 
                maxlength="45"
                prepend-inner-icon="mdi-rename"
                class="mb-4"
              >

               <template #append-inner>
                  <v-icon @click.stop="modalAddIconCategorie = true" class="cursor-pointer" color="primary" :icon=" categorieForm.url_icon || 'mdi-plus'" size="large"></v-icon>
                  <v-tooltip
                  activator="parent"
                  location="top"
                  >Escolha um ícone de identificação
                  </v-tooltip>
                </template>
              </v-text-field>

              <v-select prepend-inner-icon="mdi-tag" :rules="selectRules" v-model="categorieForm.type_categorie" color="primary" persistent-hint hint="Selecione o tipo de categoria" label="Tipo *" :items="items" variant="solo-filled">
              </v-select>

            </form>

          </v-card-text>

          <v-divider></v-divider>

          <v-card-actions class="pa-5 justify-space-between">
            <v-btn
              class="text-none font-weight-medium"
              text="Fechar"
              variant="text"
              @click="resetForm"
            ></v-btn>
            <v-btn
              class="text-none font-weight-bold"
              color="primary"
              text="Salvar"
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
