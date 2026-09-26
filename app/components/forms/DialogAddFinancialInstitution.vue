<script lang="ts" setup>

  import { useSelectedBank, type TSelectBank } from "~/composables/useAccount/useSelectedBank"
  import banks from "~~/shared/banks/catalog"

  const { selectBank } = useSelectedBank()

  const dialogFilter = ref(false)
  const valueEntered = ref("")
  const radios = ref("")
  const currentRadio = ref("")
  const loading = ref(false)

  function selectdItem(data: TSelectBank) {
    selectBank(data)
    resetStates()
  }

  watch(valueEntered, () => {
    loading.value = true
    setTimeout(() => {
      loading.value = false
    }, 2000);
  })

  const finalData = computed(() => {

    const filter =  banks.filter(item => {
      const onlyText = item.text.toLowerCase().includes(valueEntered.value.toLowerCase())
      const onlyRadio = item.type.toLowerCase().includes(currentRadio.value.toLowerCase())
      return onlyText && onlyRadio && banks
    })

    if (filter) {
      return filter
    }
  })

  function resetStates() {
    valueEntered.value = ""
    currentRadio.value = ""
    radios.value = ""
  }

  watch(radios, (newValue: string) => {
    currentRadio.value = newValue
    dialogFilter.value = false

    if (newValue === 'todos') {
      dialogFilter.value = false
      currentRadio.value = ""
      radios.value = ""

      return finalData.value
    }

  })

  const modelValue = defineModel<boolean>()

</script>

<template>
    <v-dialog
        v-model="modelValue"
        max-width="520"
        @update:model-value="resetStates"
    >
        <v-card
            rounded="xl"
            elevation="4"
            class="overflow-hidden"
        >
            <v-card-item class="pa-5 pb-2">
                <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
                    Selecione uma instituição financeira
                </v-card-title>

                <v-card-subtitle class="mt-1">
                    Escolha o banco, bandeira ou ícone que deseja utilizar.
                </v-card-subtitle>
            </v-card-item>

            <v-card-text class="pa-5">
                <v-text-field
                    v-model="valueEntered"
                    :loading="loading"
                    label="Buscar"
                    prepend-inner-icon="mdi-magnify"
                    variant="solo-filled"
                    density="comfortable"
                    autocomplete="off"
                    hide-details
                >
                </v-text-field>
            </v-card-text>

            <v-divider />

            <v-list
                lines="two"
                activatable
                class="pa-2"
            >
                <v-list-item
                    v-for="(item, index) in finalData"
                    :key="index"
                    rounded="lg"
                    @click="selectdItem({ name: item.text, url: item.url, avatar: item.avatar })"
                >
                    <template #prepend>
                        <v-avatar
                            :image="item.avatar"
                            size="48"
                            class="mr-3"
                        />
                    </template>

                    <v-list-item-title class="font-weight-medium">
                        {{ item.text }}
                    </v-list-item-title>
                </v-list-item>
            </v-list>
        </v-card>
    </v-dialog>

</template>

<style scoped>
</style>