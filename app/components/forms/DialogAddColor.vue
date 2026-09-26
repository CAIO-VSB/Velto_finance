<script lang="ts" setup>

  import { useSelectedColor } from '~/composables/useAccount/useSelectedColor';

  const modelValue = defineModel<boolean>()

  const { selectColor } = useSelectedColor()

  const currentColor = ref('#1867C0')

  function handleConfirm() {
    selectColor(currentColor.value)
    modelValue.value = false
  }

</script>

<template>
    <v-dialog
        v-model="modelValue"
        max-width="360"
    >
        <v-card
            rounded="xl"
            elevation="4"
            class="overflow-hidden"
        >
            <v-card-item class="pa-5 pb-2">
                <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
                    Selecione uma cor
                </v-card-title>

                <v-card-subtitle class="mt-1">
                    Escolha a cor de identificação para sua conta.
                </v-card-subtitle>
            </v-card-item>

            <v-divider />

            <v-card-text class="pa-5 d-flex justify-center">
                <v-color-picker
                    v-model="currentColor"
                    hide-inputs
                    show-swatches
                />
            </v-card-text>

            <v-divider />

            <v-card-actions class="pa-5 justify-space-between">
                <v-btn
                    variant="text"
                    class="text-none font-weight-medium"
                    @click="modelValue = false"
                >
                    Fechar
                </v-btn>

                <v-btn
                    color="primary"
                    variant="flat"
                    rounded="lg"
                    class="text-none font-weight-bold"
                    @click="handleConfirm"
                >
                    Selecionar
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<style scoped>
</style>