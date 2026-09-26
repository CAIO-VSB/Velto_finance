<script setup lang="ts">

  definePageMeta({
    title: "Categorias",
    layout: "layout-dashboard",
  })

  //Imports
  import { useHttpCategories } from '~/composables/useHttp/useHttpCategories'
  import type { TCategorie } from '~~/types/categorie/TCategorie'
  import BaseFab from "~/components/ui/BaseFab.vue"
  import CardEditCategorie from '~/components/forms/CardEditCategorie.vue'
  import CardAddCategorie from '~/components/forms/CardAddCategorie.vue'
  import { useInvalidate } from "~/composables/useInvalidate"


  type TOptionAction = {
    title: string;
    icon: string;
    value: boolean | string | null;
  }


  //Importações composables
  const { getAllCategories } = useHttpCategories()
  const { notifyError, notifyInfo, notifySuccess } = useNotify()
  const {  patchCategorieById } = useHttpCategories() 
  const { invalidate } = useInvalidate()

  const modalEditCategorie = ref(false)
  const modalAddCategorie = ref(false)
  const editDraft = ref<TCategorie | null>(null)
  const filterCategorieActive = ref<boolean | null>(true)
  const selectedTypeCategorie = ref("")
  const showOverflow = ref(true)

  const {isPending, data } = useQuery({
    queryKey: QUERY_KEYS.categories.all,
    queryFn: getAllCategories,
  })
  
  const  { mutate } = useMutation({

    mutationFn: (payload: TCategorie) => patchCategorieById(payload.id!, payload),

    onSuccess: () => {
      invalidate("categories")
      notifySuccess("Sucesso", "Categoria editada com sucesso", 6000)
    },

    onError: (error) => {
      handleErrorApplication(error.statusCode)
    },

  })

  /**
   * Função que intera no array e retorna o total Receitas
   */
  const totalReceitas = computed(() => {

    return (data.value || [])
    .reduce((acc, item) => {
      return item.type_categorie === "Receita" ? acc + 1 : acc
    }, 0)
  
  })

  /**
   * Função que intera no array e retorna o total de Despesas 
   */
  const totalDespesas = computed(() => {

    return (data.value || [])
    .reduce((acc, item) => {
      return item.type_categorie === "Despesa" ? acc + 1 : acc
    }, 0)
  
  })

  /**
   * Função que intera no array e retorna o total geral
   */
  const totalGeral = computed(() => {

    return (data.value || [])
    .reduce((acc, item) => {
      return item.type_categorie ? acc + 1 : acc
    }, 0)
  
  })


  //Itens fixos das opções do filtro
  const items = [
    {
      title: 'Despesas',
      value: 'despesas',
      icon: "mdi-arrow-down-thin",
      color: "error",
      total: totalDespesas
    },
    {
      title: 'Receitas',
      value: 'receitas',
      color: "green",
      icon: "mdi-arrow-up-thin",
      total: totalReceitas
    },
    {
      title: 'Geral',
      value: 'geral',
      icon: "mdi-view-dashboard",
      total: totalGeral
    },

  ]

  /**
   * Lida com a abertura do modal de edição das categorias
   * @param categorie - Categoria mandada via formulário
   * Cria uma copia da categoria a ser editada e inicia a abertura do modal
   */
  function handleOpenModalEditCategorie(categorie: TCategorie) {
    modalEditCategorie.value = true

    //Usamos structuredClone + toRaw para evitar mutar o objeto reativo do Vue
    editDraft.value = structuredClone(toRaw(categorie))
  }

  /**
   * Função principal por filtrar as categoiras com base nos filtros existentes na tela
   * @param choiceOnlyActive - Parametro para filtar por tipo ativo
   * @param choiceOnlyTypeCategorie - parametro para filtar por tipo de categoria
   */
  function filterCategorie(choiceOnlyActive?: boolean | null, choiceOnlyTypeCategorie?: string) {
    let categorie = data.value ?? []

    //Retorna as categorias com base no seu tipo
    if (choiceOnlyTypeCategorie === "despesas") {
      categorie = categorie.filter(item => item.type_categorie === "Despesa")
    } 
    
    if (choiceOnlyTypeCategorie === "receitas") {
      categorie = categorie.filter(item => item.type_categorie === "Receita")
    } 

    //Retorna somente as categorias com status ativa
    if (choiceOnlyActive === true) {
      categorie = categorie.filter(item => item.active === true)
    } 

    return categorie

  }

  /**
   * @param '' Passa uma variavel como argumento
   * @returns Chama a função de filtrar as categorias 
  */
  const filteredCategories = computed(() => {
    return filterCategorie(filterCategorieActive.value, selectedTypeCategorie.value)
  })


  /**
   * Função responsável apenas por resetar os valores ao fechar o modal
   */
  function handleCloseEditCategorie() {
    editDraft.value = null
    modalEditCategorie.value = false
  }

  /**
   * Gera opções dinâmicas baseadas no estado da categoria (ativa/desativada)
   * @param categorie - Recebe a categoria selecionada para definir as opções dinamicamente
   * @returns Retorna um array de opções com base no tipo passado
   */
  function getOptions(categorie: TCategorie): TOptionAction [] {
    return [
      {title: "Editar", icon: "mdi-lead-pencil", value: "edit"},
      {
        title: categorie.active ? "Inativar" : "Ativar",
        icon: categorie.active ? "mdi-minus-circle-off" : "mdi-check-circle",
        value: categorie.active ? false : true
      }
    ]
  }


  /**
   * Função responsável por chamar a api e setar os valores com base nas opções
   * @param option - Objeto que retorna a escolha do usuário via formulário 
   * @param data - Categoria que será modificada
   * @returns Abre o modal de edições ou seta os valores 
   */
  function handleOptionClick(option: TOptionAction, data: TCategorie) {

    //Abre o modal para edições na categoria selecionada 
    if (option.value === "edit") {
      handleOpenModalEditCategorie(data)
      return
    }

    //Usamos structuredClone + toRaw para evitar mutar o objeto reativo do Vue
    const payload = structuredClone(toRaw(data))

    //Caso a opção seja somente de inativar a categoria, passamos somente o valor boleano para à API - usando o verbo HTTP patch
    if (typeof option.value === "boolean") {
      payload.active = option.value
    }
    
    //Passa o valor da cópia do objeto para à API
    mutate(payload)

  }

</script>


<template>
    <v-container
      fluid
      class="mt-6 pa-4"
    >
      <v-row>
          <v-col
              cols="12"
              lg="4"
          >
              <v-card
                  rounded="lg"
                  elevation="2"
              >
                  <v-card-item class="pa-4 pb-2">
                      <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
                          Filtros
                      </v-card-title>

                      <v-card-subtitle class="mt-1">
                          Organize as categorias exibidas.
                      </v-card-subtitle>
                  </v-card-item>

                  <v-divider />

                  <v-list>
                      <v-list-item
                          v-for="(item, index) in items"
                          :key="index"
                          :value="item.value"
                          color="primary"
                          @click="selectedTypeCategorie = item.value"
                      >
                          <template #prepend>
                              <v-icon
                                  :icon="item.icon"
                                  :color="item.color"
                              />
                          </template>

                          <v-list-item-title>
                              {{ item.title }}
                          </v-list-item-title>

                          <template #append>
                              <v-chip
                                  size="small"
                                  class="font-weight-bold"
                              >
                                  {{ item.total }}
                              </v-chip>
                          </template>
                      </v-list-item>

                      <v-divider />

                      <v-list-item>
                          <v-list-item-title>
                              Somente ativas
                          </v-list-item-title>

                          <template #append>
                              <v-switch
                                  v-model="filterCategorieActive"
                                  color="primary"
                                  inset
                                  hide-details
                              />
                          </template>
                      </v-list-item>
                  </v-list>
              </v-card>
          </v-col>

          <v-col
              cols="12"
              lg="8"
          >
              <v-card
                  rounded="lg"
                  elevation="2"
              >
                  <v-card-item class="pa-4 pb-2">
                      <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
                          Categorias
                      </v-card-title>

                      <v-card-subtitle class="mt-1">
                          Gerencie suas categorias de receitas e despesas.
                      </v-card-subtitle>
                  </v-card-item>

                  <v-divider />

                  <template v-if="isPending">
                      <div class="pa-4">
                          <v-skeleton-loader
                              v-for="n in 12"
                              :key="n"
                              type="list-item-avatar"
                              class="mb-2"
                          />
                      </div>
                  </template>

                  <v-list
                      v-else
                      lines="three"
                      class="pa-2"
                  >
                      <template
                          v-for="(categorie, index) in filteredCategories || []"
                          :key="categorie.id"
                      >
                          <v-list-item class="py-2">
                              <template #prepend>
                                  <v-icon
                                      :icon="categorie.url_icon"
                                      size="25"
                                      class="mr-3"
                                  />
                              </template>

                              <v-list-item-title
                                  :class="{ 'text-disabled': !categorie.active }"
                                  class="font-weight-medium"
                              >
                                  {{ categorie.name_identifier }}
                              </v-list-item-title>

                              <v-list-item-subtitle class="mt-1">
                                  <v-chip
                                      :color="categorie.type_categorie === 'Despesa' ? 'error' : 'success'"
                                      size="small"
                                  >
                                      {{ categorie.type_categorie }}
                                  </v-chip>
                              </v-list-item-subtitle>

                              <template #append>
                                  <v-menu
                                      location="bottom end"
                                      offset="8"
                                  >
                                      <template #activator="{ props }">
                                          <v-btn
                                            v-bind="props"
                                            icon="mdi-dots-vertical"
                                            variant="plain"
                                            :loading="isPending"
                                          >
                                          </v-btn>
                                      </template>

                                      <v-list>
                                          <v-list-item
                                              v-for="item in getOptions(categorie)"
                                              :key="item.title"
                                              :prepend-icon="item.icon"
                                              @click="handleOptionClick(item, categorie)"
                                          >
                                              <v-list-item-title>
                                                  {{ item.title }}
                                              </v-list-item-title>
                                          </v-list-item>
                                      </v-list>
                                  </v-menu>
                              </template>
                          </v-list-item>

                          <v-divider
                              v-if="index < (filteredCategories?.length ?? 0) - 1"
                          />
                      </template>
                  </v-list>
              </v-card>
          </v-col>
      </v-row>

      <div class="fab-wrapper">
          <v-tooltip
              text="Nova categoria"
              location="left"
          >
              <template #activator="{ props }">
                  <BaseFab
                      v-bind="props"
                      color="primary"
                      icon="mdi-plus"
                      size="50"
                      @click="modalAddCategorie = true"
                  />
              </template>
          </v-tooltip>
        </div>

        <CardAddCategorie v-model="modalAddCategorie" />

        <CardEditCategorie
            v-model="modalEditCategorie"
            :draft="editDraft"
            @Close="handleCloseEditCategorie"
        />
    </v-container>
</template>

<style scoped>
.fab-wrapper {
    position: fixed;
    right: 16px;
    bottom: 10px;
    z-index: 10;
}

.text-disabled {
    text-decoration: line-through;
}
</style>