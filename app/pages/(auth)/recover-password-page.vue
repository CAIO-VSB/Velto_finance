<script setup lang="ts">

  import { useValidateFields } from "~/composables/useValidateFields";
  import type { TRecoveryForm } from "~~/types/user/Tuser.types";
  import { useValidateSchemas } from "~/composables/useValidateSchema"

  import logoLogin from "~/assets/logo-login.svg"

  //Variáveis reativas
  const loading = ref(false)
  const formEmail = ref<TRecoveryForm>({
    email: "",
  })

  const form = ref()

  const { $authClient } = useNuxtApp()
  const { notifyError, notifyInfo, notifySuccess } = useNotify()
  const { emailRules } = useValidateFields();
  const { validateSchemaEmail } = useValidateSchemas()

  async function handleRecoverPassword() {
    try {
      const formValid = await form.value.validate(formEmail.value);
      const resultSchema = validateSchemaEmail(formEmail.value);

      if (formValid) {
        if (resultSchema.success) {
          await $authClient.requestPasswordReset(
            {
              email: formEmail.value.email,
              redirectTo: "https://app.veltofinance.bid/reset-password-page",
            },
            {
              onRequest() {
                loading.value = true;
              },
              onError(error) {
                handleErrorApplication(error.response.status)
                return
              },
              onSuccess() {
                notifySuccess(
                  "Solicitação recebida",
                  "Se o e-mail informado estiver cadastrado, enviaremos um link para redefinição de senha. Verifique sua caixa de entrada e, se necessário, a pasta de spam.",
                  8000
                )
                formEmail.value.email = ""
              },
            }
          );
        }
      }
    } catch (error) {
      notifyError("Algo deu errado", "Ocorreu um erro inesperado. Tente novamente em alguns instantes.", 7000)
      console.log("Erro ao enviar e-mail de reset de senha" + error);
    } finally {
      loading.value = false;
    }
}
</script>

<template>
  <main class="login-page d-flex">
    <v-container fluid class="pa-0 d-flex">
      <v-row
        no-gutters
        class="login-layout ma-auto overflow-hidden bg-white"
      >
        <v-col
          cols="12"
          md="6"
          class="login-visual d-none d-md-flex flex-column justify-space-between"
        >
          <div class="login-visual__orb" aria-hidden="true" />

          <div class="position-relative">
            <v-img
              :src="logoLogin"
              contain
              width="300"
              height="150"
              class="mb-10"
              alt="Velto Finance"
            />

            <div class="text-overline font-weight-bold text-primary mb-3">
              CONTROLE FINANCEIRO DESCOMPLICADO
            </div>

            <h1 class="login-visual__title text-blue-grey-darken-4 mb-5">
              Sua vida financeira,
              <span class="text-primary">mais inteligente.</span>
            </h1>

            <p class="login-visual__description text-blue-grey-darken-1 mb-0">
              Organize, acompanhe e evolua suas finanças em um só lugar.
            </p>
          </div>

          <div
            class="position-relative d-flex align-center ga-2 text-blue-grey-darken-1 text-body-2"
          >
            <v-icon
              icon="mdi-shield-check-outline"
              color="primary"
              size="20"
            />

            <span>Ambiente seguro e protegido</span>
          </div>
        </v-col>

        <v-col
          cols="12"
          md="6"
          class="d-flex align-start align-md-center justify-center pa-6 pa-sm-10 pa-lg-16"
        >
          <div class="login-form-wrapper w-100">
            <header class="text-center text-md-start mb-8">

              <v-img
                :src="logoLogin"
                contain
                width="300"
                height="150"
                class="d-md-none mx-auto mb-7"
                alt="Velto Finance"
              />

              <div class="text-overline font-weight-bold text-primary mb-2">
                RECUPERAÇÃO DE ACESSO
              </div>

              <h2
                class="text-h4 text-sm-h3 font-weight-bold text-blue-grey-darken-4 mb-3"
              >
                Recuperar senha
              </h2>

              <p class="text-body-1 text-medium-emphasis mb-0 bg-white">
                Informe seu e-mail para recuperar sua senha de acesso.
              </p>
            </header>

            <v-form
              ref="form"
              validate-on="submit"
              class="d-flex flex-column ga-5"
            >
              <div>
                <label
                  class="text-body-2 font-weight-bold d-block mb-2"
                  for="recovery-email"
                >
                  E-mail
                </label>

                <v-text-field
                  id="recovery-email"
                  v-model="formEmail.email"
                  variant="outlined"
                  density="comfortable"
                  placeholder="seu@email.com"
                  prepend-inner-icon="mdi-email-outline"
                  :rules="emailRules"
                  autocomplete="email"
                  inputmode="email"
                  hide-details="auto"
                  color="primary"
                  base-color="blue-grey-lighten-3"
                  bg-color="blue-grey-lighten-5"
                />
              </div>

              <v-btn
                :loading="loading"
                color="primary"
                size="large"
                height="52"
                rounded="lg"
                block
                elevation="2"
                @click="handleRecoverPassword"
              >
                Recuperar senha

                <v-icon
                  end
                  icon="mdi-arrow-right"
                />
              </v-btn>

              <p
                class="text-center text-body-2 text-medium-emphasis ma-0 bg-white"
              >
                Lembrou sua senha?

                <NuxtLink
                  to="/login-page"
                  class="text-primary font-weight-bold text-decoration-none"
                >
                  Voltar para o login
                </NuxtLink>
              </p>
            </v-form>
          </div>
        </v-col>
      </v-row>
    </v-container>
  </main>
</template>

<style scoped>
.login-page {
  min-height: 100dvh;
  overflow-y: auto;
  background: #f6f8fc;
}

.login-layout {
  width: min(100%, 1440px);
  min-height: 100dvh;
}

.login-visual {
  position: relative;
  isolation: isolate;
  min-height: 100%;
  padding: clamp(3rem, 7vw, 6rem);
  overflow: hidden;

  background:
    linear-gradient(
      135deg,
      rgb(255 255 255 / 62%),
      rgb(230 239 255 / 72%)
    ),
    #dce9ff;
}

.login-visual__orb {
  position: absolute;
  z-index: -1;
  top: -13rem;
  right: -12rem;
  width: 34rem;
  aspect-ratio: 1;
  border-radius: 50%;
  background: rgb(31 84 255 / 14%);
  filter: blur(10px);
}

.login-visual__title {
  max-width: 11ch;
  font-size: clamp(2.5rem, 4.2vw, 4.6rem);
  font-weight: 750;
  letter-spacing: -0.065em;
  line-height: 0.98;
}

.login-visual__title span {
  display: block;
}

.login-visual__description {
  max-width: 34rem;
  font-size: clamp(1rem, 1.35vw, 1.15rem);
  line-height: 1.65;
}

.login-form-wrapper {
  max-width: 30rem;
}
</style>

