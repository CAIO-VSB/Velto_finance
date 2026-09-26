<script setup lang="ts">

  import logoLogin from "~/assets/logo-login.svg"
  import logoGoogle from "~/assets/logo-google.svg"
  import logoDiscord from "~/assets/logo-discord.svg"

  import { useValidateFields } from "~/composables/useValidateFields";
  import { useValidateSchemas } from "~/composables/useValidateSchema"
  import { useAuthStore } from "~~/store/modules/auth-store";
  import type { TLoginForm } from "~~/types/user/Tuser.types";

  const { notifyError, notifyInfo, notifySuccess } = useNotify()

  const loadingEmail = ref(false);
  const loadingGoogle = ref(false);
  const loadingDiscord = ref(false)
  const showPassword = ref(false);
  const form = ref();
  const loginForm = ref<TLoginForm>({
    email: "",
    password: "",
  });

  const authStore = useAuthStore();

  const { emailRules, passwordRules} = useValidateFields()
  const { validateSchemaSignIn} = useValidateSchemas()

  async function handleWidthEmailAndPassword() {

    try {
      loadingEmail.value = true

      const formValid = await form.value.validate()
      const resultSchema = validateSchemaSignIn(loginForm.value)

      if (formValid) {
        if (resultSchema.success) {

          const result = await authStore.login(loginForm.value)

          if (result?.success) {
            navigateTo({ path: "/dashboard" });
          }
        }
      }
    } catch (error) {
    notifyError(
      "Não foi possível realizar o login",
      "Ocorreu um erro interno ao tentar acessar sua conta. Tente novamente em alguns instantes.",
      7000
    )
    } finally {
      loadingEmail.value = false
    }
  }

  async function handleWidthGoogle() {
    try {
      loadingGoogle.value = true

      await authStore.loginGoogle()
      
    } catch (error) {
      notifyError(
      "Não foi possível realizar o login",
      "Ocorreu um erro interno ao tentar acessar sua conta. Tente novamente em alguns instantes.",
      7000
    )
    }
  }

  async function handleWidthDiscord() {
    try {
      loadingDiscord.value = true

      await authStore.loginDiscord()

    } catch (error) {
      notifyError(
      "Não foi possível realizar o login",
      "Ocorreu um erro interno ao tentar acessar sua conta. Tente novamente em alguns instantes.",
      7000
    )
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

          <div class="position-relative d-flex align-center ga-2 text-blue-grey-darken-1 text-body-2">
            <v-icon icon="mdi-shield-check-outline" color="primary" size="20" />
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
                BEM-VINDO DE VOLTA
              </div>

              <h2 class="text-h4 text-sm-h3 font-weight-bold text-blue-grey-darken-4 mb-3">
                Acesse sua conta
              </h2>

              <p class="text-body-1 text-medium-emphasis mb-0">
                Tenha controle total sobre sua vida financeira.
              </p>
            </header>

            <v-form ref="form" class="d-flex flex-column ga-5">
              <div>
                <label
                  class="text-body-2 font-weight-bold d-block mb-2"
                  for="login-email"
                >
                  E-mail
                </label>

                <v-text-field
                  id="login-email"
                  v-model="loginForm.email"
                  variant="outlined"
                  density="comfortable"
                  placeholder="Seu@email.com"
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

              <div>
                <div class="d-flex justify-space-between align-center ga-3 mb-2">
                  <label class="text-body-2 font-weight-bold" for="login-password">
                    Senha
                  </label>

                  <NuxtLink
                    to="/recover-password-page"
                    class="text-primary text-body-2 font-weight-bold"
                  >
                    Esqueceu a senha?
                  </NuxtLink>
                </div>

                <v-text-field
                  id="login-password"
                  v-model="loginForm.password"
                  variant="outlined"
                  density="comfortable"
                  placeholder="Digite sua senha"
                  prepend-inner-icon="mdi-lock-outline"
                  :type="showPassword ? 'text' : 'password'"
                  :append-inner-icon="showPassword ? 'mdi-eye' : 'mdi-eye-off'"
                  :rules="passwordRules"
                  autocomplete="current-password"
                  hide-details="auto"
                  color="primary"
                  base-color="blue-grey-lighten-3"
                  bg-color="blue-grey-lighten-5"
                  @click:append-inner="showPassword = !showPassword"
                />
              </div>

              <v-btn
                :disabled="authStore.disableButton"
                :loading="loadingEmail"
                color="primary"
                size="large"
                height="52"
                rounded="lg"
                block
                elevation="2"
                @click="handleWidthEmailAndPassword"
              >
                Entrar na plataforma
                <v-icon end icon="mdi-arrow-right" />
              </v-btn>

              <div class="d-flex align-center ga-3 text-medium-emphasis text-caption">
                <v-divider />
                <span class="text-no-wrap">ou continue com</span>
                <v-divider />
              </div>

              <div class="d-flex flex-column ga-3">
                <v-btn
                  :disabled="authStore.disableButton"
                  :loading="loadingGoogle"
                  variant="outlined"
                  color="blue-grey-darken-2"
                  size="large"
                  height="52"
                  rounded="lg"
                  block
                  @click="handleWidthGoogle"
                >
                  <template #prepend>
                    <v-avatar color="white" :image="logoGoogle" size="20" />
                  </template>

                  Entrar com Google
                </v-btn>

                <v-btn
                  :disabled="authStore.disableButton"
                  :loading="loadingDiscord"
                  variant="outlined"
                  color="blue-grey-darken-2"
                  size="large"
                  height="52"
                  rounded="lg"
                  block
                  @click="handleWidthDiscord"
                >
                  <template #prepend>
                    <v-avatar color="white" :image="logoDiscord" size="22" />
                  </template>

                  Entrar com Discord
                </v-btn>
              </div>

              <p class="text-center bg-white text-body-2 text-medium-emphasis ma-0">
                Ainda não tem uma conta?
                <NuxtLink
                  to="/register-page"
                  class="text-primary font-weight-bold text-decoration-none"
                >
                  Cadastre-se
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
    linear-gradient(135deg, rgb(255 255 255 / 62%), rgb(230 239 255 / 72%)),
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