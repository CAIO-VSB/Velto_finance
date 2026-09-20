<script setup lang="ts">

    import { useOnFileChange } from '~/composables/useFileChange.js'

    const props = defineProps<{
        loading: boolean
    }>()

    const modelValue = defineModel<boolean>()
    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    const { submitImage, isUploading } = useOnFileChange()
    const file = ref<File[]>([])

    const emit = defineEmits<{
        submitImage: [url: string],
        closeModal: []
    }>()

    async function onChangeFile() {

        if (!file.value.length) {
          notifyInfo(
            "Atenção",
            "Selecione uma imagem para continuar.",
            5000
          )
          return
        }

        const urlResult = await submitImage(file.value)

        if (!urlResult) return

        modelValue.value = false
        emit('submitImage', urlResult)
    }

    function closeModal() {
        modelValue.value = false
        emit("closeModal")
    }

</script>


<template>

    <v-dialog max-width="500" v-model="modelValue" persistent>
        <template v-slot:default="{ isActive }">
            <v-card class="pa-2">

                <div class="position-relative pa-4 mb-3">
                    <v-btn
                    color="primary"
                    variant="plain"
                    class="position-absolute"
                    style="top: 0px; right: -15px;"
                    prepend-icon="mdi-close"
                    @click="closeModal"
                    >
                    </v-btn>
                </div>

                <v-file-upload :disabled="isUploading" :loading="isUploading" accept="image/*" show-size clearable v-model="file"  variant="comfortable"></v-file-upload>

                <v-btn
                color="primary"
                variant="flat"
                rounded="lg"  
                @click="onChangeFile"
                prepend-icon="mdi-content-save-check"
                :disabled="isUploading"
                >
                    Salvar
                </v-btn>

            </v-card>
        </template>
    </v-dialog> 

</template>