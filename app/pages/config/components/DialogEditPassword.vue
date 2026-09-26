<script setup lang="ts">

    import { useAuthStore } from '~~/store/modules/auth-store'
    import { useValidateFields } from "~/composables/useValidateFields"
    import BaseModal from '~/components/ui/BaseModal.vue';

    const emits = defineEmits<{
        closeModal: []
    }>()

    const { passwordRules } = useValidateFields()
    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    const loading = ref(false)

    const modelValue = defineModel<boolean>()
    const authStore = useAuthStore()
    const newPassword = ref("")
    const confirmPassword = ref("")
    const currentPassword = ref("")
    const showPassword = ref(false)
    const form = ref()

    const confirmPasswordRules = ref([
        (val: string) => !!val || "Campo confirmar senha é obrigatório",
        (val: string) =>
        val === newPassword.value || "As senha não coincidem",
    ]);

    const regexValidateNumber = computed(() => {
        return /\d/.test(newPassword.value)
    })

  const regexValidateMaiuscula = computed(() => {
        return /[A-Z]/.test(newPassword.value)
    })

  const regexValidateMinuscula = computed(() => {
        return /[a-z]/.test(newPassword.value)
    })

  const regexValidateEspecial = computed(() => {
        return /[^A-Za-z0-9]/.test(newPassword.value)
    })

  const regexValidateMinimoSeis = computed(() => {
        return newPassword.value.length >= 6
    })

    function closeModalSubmitChangePassword() {
        modelValue.value = false
        emits("closeModal")
        currentPassword.value = ""
        newPassword.value = ""
        confirmPassword.value = ""
    }

    function redirectPageLogin() {
        authStore.showDialogAlertPassword = false
        navigateTo("/login-page")
        notifySuccess(
        "Sucesso",
        "Faça login novamente com sua nova senha.",
        5000
        )
    }
    
    async function handleUpatePassword() {

        loading.value = true

        try {

            const formValid = await form.value.validate()

            if (formValid) {
                await authStore.alterPassword(newPassword.value, currentPassword.value)
            }

        } catch (e) {
            console.log("Erro ao enviar solicitação" + e)
            notifyInfo("Erro", "Algo deu errado. Tente novamente em instantes.", 7000)
        } finally {
            loading.value = false
        }

    }

</script>


<template>
  <v-dialog
    v-model="modelValue"
    persistent
    transition="dialog-top-transition"
    max-width="520"
  >
    <v-card rounded="lg" elevation="8">
      <v-card-item class="pa-4 pb-2">
        <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
          Alterar senha de acesso
        </v-card-title>

        <v-card-subtitle class="mt-1">
          Escolha uma senha forte para manter sua conta protegida.
        </v-card-subtitle>

        <template #append>
          <v-btn
            icon="mdi-close"
            variant="text"
            size="small"
            @click="closeModalSubmitChangePassword"
          />
        </template>
      </v-card-item>

      <v-divider />

      <v-card-text class="pa-4 pa-sm-6">
        <v-alert
          type="warning"
          variant="tonal"
          density="comfortable"
          icon="mdi-shield-alert-outline"
          class="mb-6"
        >
          Todas as sessões ativas serão desconectadas após a alteração.
        </v-alert>

        <v-form ref="form" class="d-flex flex-column ga-2">
          <v-text-field
            v-model="currentPassword"
            :type="showPassword ? 'text' : 'password'"
            :append-inner-icon="showPassword ? 'mdi-eye' : 'mdi-eye-off'"
            :rules="passwordRules"
            autocomplete="current-password"
            prepend-inner-icon="mdi-lock-question"
            label="Senha atual"
            variant="outlined"
            density="comfortable"
            color="primary"
            hide-details="auto"
            @click:append-inner="showPassword = !showPassword"
          />

          <v-text-field
            v-model="newPassword"
            :type="showPassword ? 'text' : 'password'"
            :append-inner-icon="showPassword ? 'mdi-eye' : 'mdi-eye-off'"
            :rules="passwordRules"
            autocomplete="new-password"
            prepend-inner-icon="mdi-lock-check-outline"
            label="Nova senha"
            variant="outlined"
            density="comfortable"
            color="primary"
            hide-details="auto"
            @click:append-inner="showPassword = !showPassword"
          />

          <v-text-field
            v-model="confirmPassword"
            :type="showPassword ? 'text' : 'password'"
            :append-inner-icon="showPassword ? 'mdi-eye' : 'mdi-eye-off'"
            :rules="confirmPasswordRules"
            autocomplete="new-password"
            prepend-inner-icon="mdi-lock-outline"
            label="Confirmar nova senha"
            variant="outlined"
            density="comfortable"
            color="primary"
            hide-details="auto"
            @click:append-inner="showPassword = !showPassword"
          />

          <v-sheet
            rounded="lg"
            border
            class="pa-4 mt-2"
          >
            <div class="text-body-2 font-weight-bold text-blue-grey-darken mb-2">
              Sua senha deve conter no mínimo:
            </div>

            <v-expand-transition>
              <v-list
                density="compact"
                bg-color="transparent"
                class="pa-0 text-body-2"
              >
                <v-list-item class="px-0 min-height-auto">
                  <template #prepend>
                    <v-icon
                      :color="regexValidateMinimoSeis ? 'success' : 'error'"
                      :icon="regexValidateMinimoSeis
                        ? 'mdi-check-circle-outline'
                        : 'mdi-close-circle-outline'"
                      size="small"
                    />
                  </template>
                  <v-list-item-title>6 caracteres</v-list-item-title>
                </v-list-item>

                <v-list-item class="px-0 min-height-auto">
                  <template #prepend>
                    <v-icon
                      :color="regexValidateMaiuscula ? 'success' : 'error'"
                      :icon="regexValidateMaiuscula
                        ? 'mdi-check-circle-outline'
                        : 'mdi-close-circle-outline'"
                      size="small"
                    />
                  </template>
                  <v-list-item-title>Uma letra maiúscula</v-list-item-title>
                </v-list-item>

                <v-list-item class="px-0 min-height-auto">
                  <template #prepend>
                    <v-icon
                      :color="regexValidateMinuscula ? 'success' : 'error'"
                      :icon="regexValidateMinuscula
                        ? 'mdi-check-circle-outline'
                        : 'mdi-close-circle-outline'"
                      size="small"
                    />
                  </template>
                  <v-list-item-title>Uma letra minúscula</v-list-item-title>
                </v-list-item>

                <v-list-item class="px-0 min-height-auto">
                  <template #prepend>
                    <v-icon
                      :color="regexValidateNumber ? 'success' : 'error'"
                      :icon="regexValidateNumber
                        ? 'mdi-check-circle-outline'
                        : 'mdi-close-circle-outline'"
                      size="small"
                    />
                  </template>
                  <v-list-item-title>Um número</v-list-item-title>
                </v-list-item>

                <v-list-item class="px-0 min-height-auto">
                  <template #prepend>
                    <v-icon
                      :color="regexValidateEspecial ? 'success' : 'error'"
                      :icon="regexValidateEspecial
                        ? 'mdi-check-circle-outline'
                        : 'mdi-close-circle-outline'"
                      size="small"
                    />
                  </template>
                  <v-list-item-title>Um caractere especial</v-list-item-title>
                </v-list-item>
              </v-list>
            </v-expand-transition>
          </v-sheet>
        </v-form>
      </v-card-text>

      <v-divider />

      <v-card-actions class="pa-4 justify-end">
        <v-btn
          :loading="loading"
          color="primary"
          variant="flat"
          rounded="lg"
          class="text-none"
          @click="handleUpatePassword"
        >
          Solicitar alteração
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>

  <BaseModal
    :persistent-modal="true"
    :model-value="authStore.showDialogAlertPassword"
    title="Senha alterada com sucesso"
    @close-modal="redirectPageLogin"
  >
    <div class="pa-2 text-body-2">
      <p class="mb-4">
        Sua senha foi alterada com sucesso.
      </p>

      <p class="mb-4">
        Por motivos de segurança, sua sessão atual foi encerrada.
      </p>

      <p class="mb-0">
        Ao clicar em <strong>OK</strong>, você será redirecionado para a tela
        de login. Utilize sua nova senha para acessar sua conta novamente.
      </p>
    </div>
  </BaseModal>
</template>

<style scoped>
.min-height-auto {
  min-height: auto;
}
</style>