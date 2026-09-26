<script setup lang="ts">

    import { useAuthStore } from '~~/store/modules/auth-store'
    import { useValidateFields } from "~/composables/useValidateFields"
    import { useHttpAuth } from "~/composables/useHttp/useHtppAuth"
    import BaseModal from '~/components/ui/BaseModal.vue'

    const props = defineProps<{
        email: string | undefined
    }>()

    const emits = defineEmits<{
        closeModal: []
    }>()

    const { emailRules, passwordRules } = useValidateFields()
    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    const { postVerifyPassword } = useHttpAuth()
    const loading = ref(false)

    const modelValue = defineModel<boolean>()
    const newEmail = ref("")
    const authStore = useAuthStore()
    const showPassword = ref(false)
    const password = ref("")
    const form = ref()

    function closeModalSubmitChangeEmail() {
        modelValue.value = false
        newEmail.value = ""
        password.value = ""
        emits("closeModal")
    }
    
    function redirectPageLogin() {
        authStore.showDialogAlertEmail = false
        navigateTo("/login-page")
        notifySuccess(
        "Sucesso",
        "Faça login novamente com seu novo e-mail.",
        5000
        )
    }
    
    async function handleUpateEmail() {
        loading.value = true

        try {

          const formValid = await form.value.validate()

          if (formValid) {
              const resultValidatePassword = await postVerifyPassword(password.value)

              if (resultValidatePassword.valid) {
                  await authStore.alterEmail(newEmail.value)
              } else {
                  notifyInfo(
                  "Atenção",
                  "Não foi possível confirmar sua identidade. Verifique sua senha atual e tente novamente.",
                  6000
                  )
              }
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
          Alterar e-mail de acesso
        </v-card-title>

        <v-card-subtitle class="mt-1">
          Confirme sua identidade para solicitar a alteração.
        </v-card-subtitle>

        <template #append>
          <v-btn
            icon="mdi-close"
            variant="text"
            size="small"
            @click="closeModalSubmitChangeEmail"
          />
        </template>
      </v-card-item>

      <v-divider />

      <v-card-text class="pa-4 pa-sm-6">
        <v-alert
          type="info"
          variant="tonal"
          density="comfortable"
          icon="mdi-information-outline"
          class="mb-6"
        >
          O processo envolve duas confirmações: uma no seu e-mail atual e
          outra no novo endereço informado.
        </v-alert>

        <v-form ref="form" class="d-flex flex-column ga-2">
          <v-text-field
            v-model="props.email"
            prepend-inner-icon="mdi-email-outline"
            readonly
            label="E-mail atual"
            variant="outlined"
            density="comfortable"
            color="primary"
            hide-details="auto"
          />

          <v-text-field
            v-model="newEmail"
            :rules="emailRules"
            prepend-inner-icon="mdi-email-check-outline"
            name="email"
            autocomplete="email"
            label="Novo e-mail"
            variant="outlined"
            density="comfortable"
            color="primary"
            hide-details="auto"
          />

          <v-text-field
            v-model="password"
            :type="showPassword ? 'text' : 'password'"
            :append-inner-icon="showPassword ? 'mdi-eye' : 'mdi-eye-off'"
            :rules="passwordRules"
            prepend-inner-icon="mdi-lock-outline"
            label="Senha de acesso"
            variant="outlined"
            density="comfortable"
            color="primary"
            hide-details="auto"
            @click:append-inner="showPassword = !showPassword"
          />
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
          @click="handleUpateEmail"
        >
          Solicitar alteração
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>

  <BaseModal
    :persistent-modal="true"
    :model-value="authStore.showDialogAlertEmail"
    title="Confirmação de alteração de e-mail"
    @close-modal="redirectPageLogin"
  >
    <div class="pa-2 text-body-2">
      <p class="mb-4">
        Para proteger sua conta, toda alteração de e-mail precisa ser
        confirmada.
      </p>

      <p class="mb-4">
        Enviaremos uma mensagem para o seu e-mail atual com as instruções
        para autorizar a mudança.
      </p>

      <p class="mb-4">
        Após a confirmação, o novo e-mail passará a ser utilizado para acessar
        sua conta e receber comunicações do Velto Finance. Por segurança, será
        necessário fazer login novamente com o novo endereço de e-mail.
      </p>

      <p class="text-caption text-medium-emphasis mb-0">
        <strong>Observação:</strong> ao clicar em <strong>OK</strong>, você
        será redirecionado para a tela de login.
      </p>
    </div>
  </BaseModal>
</template>