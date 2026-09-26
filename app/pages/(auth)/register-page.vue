<script setup lang="ts">

  import type { TRegisterForm } from "~~/types/user/Tuser.types";
  import logoLogin from "~/assets/logo-login.svg"
  import logoGoogle from "~/assets/logo-google.svg"
  import logoDiscord from "~/assets/logo-discord.svg"

  import { useValidateFields } from "~/composables/useValidateFields";
  import { useValidateSchemas } from "~/composables/useValidateSchema"
  import { useAuthStore } from "~~/store/modules/auth-store";
  import Password from "vue-password-strength-meter"
  import 'vue-password-strength-meter/style.css'


  const { notifyError, notifyInfo, notifySuccess } = useNotify()
  const { nameRules, emailRules, passwordRules,  } = useValidateFields()
  const { validateSchemaSignUp } = useValidateSchemas()

  const loadingGoogle = ref(false);
  const loadingFacebook = ref(false)
  const loading = ref(false);
  const showPassword = ref(false);
  const form = ref();
  const showValidatePassword = ref(false)
  const registerForm = ref<TRegisterForm>({
    id: "",
    name: "",
    email: "",
    password: "",
    confirmPassword: "",
  });

  const authStore = useAuthStore();

  const confirmPasswordRules = ref([
    (val: string) => !!val || "Campo confirmar senha é obrigatório",
    (val: string) =>
      val === registerForm.value.password || "As senha não coincidem",
  ]);

  function resetForm() {
    registerForm.value.name = ""
    registerForm.value.email = ""
    registerForm.value.password = ""
    registerForm.value.confirmPassword = ""
  }

  const regexValidateNumber = computed(() => {
    return /\d/.test(registerForm.value.password)
  })

  const regexValidateMaiuscula = computed(() => {
    return /[A-Z]/.test(registerForm.value.password)
  })

  const regexValidateMinuscula = computed(() => {
    return /[a-z]/.test(registerForm.value.password)
  })

  const regexValidateEspecial = computed(() => {
    return /[^A-Za-z0-9]/.test(registerForm.value.password)
  })

  const regexValidateMinimoSeis = computed(() => {
    return registerForm.value.password.length >= 6
  })

  function validateRulesPassword() {
    regexValidateEspecial
    regexValidateMaiuscula
    regexValidateMinimoSeis
    regexValidateMinuscula
    regexValidateNumber
    showValidatePassword.value = true
  }
  
  async function handleRegisterUser() {
    try {
      loading.value = true;

      const formValid = await form.value.validate();

      const resultSchema = validateSchemaSignUp(registerForm.value);

      if (formValid) {
        if (resultSchema.success) {
          await authStore.register(registerForm.value);
          resetForm()
        }
      }
    } catch (error) {
      notifyError("Algo deu errado", "Ocorreu um erro inesperado. Tente novamente em alguns instantes.")
    } finally {
      loading.value = false;
    }
  }

    async function handleWidthGoogle() {
    try {
      loadingGoogle.value = true

      await authStore.loginGoogle()
      
    } catch (error) {
      notifyError("Algo deu errado", "Ocorreu um erro inesperado. Tente novamente em alguns instantes.")
    } finally {
      loadingGoogle.value = true;
    }
  }

  async function handleWidthDiscord() {
    try {
      loadingFacebook.value = true

      await authStore.loginDiscord()

    } catch (error) {
      notifyError("Algo deu errado", "Ocorreu um erro inesperado. Tente novamente em alguns instantes.")
    } finally {
      loadingFacebook.value = false
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

            <p
              class="login-visual__description text-blue-grey-darken-1 mb-0"
            >
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
                COMECE AGORA
              </div>

              <h2
                class="text-h4 text-sm-h3 font-weight-bold text-blue-grey-darken-4 mb-3"
              >
                Crie sua conta
              </h2>

              <p class="text-body-1 bg-white text-medium-emphasis mb-0">
                Crie sua conta e comece a organizar suas finanças.
              </p>
            </header>

            <v-form
              ref="form"
              validate-on="submit"
              class="d-flex flex-column ga-4"
            >
              <div>
                <label
                  class="text-body-2 font-weight-bold d-block mb-2"
                  for="register-name"
                >
                  Nome
                </label>

                <v-text-field
                  id="register-name"
                  v-model="registerForm.name"
                  variant="outlined"
                  density="comfortable"
                  placeholder="Seu nome"
                  prepend-inner-icon="mdi-account-outline"
                  :rules="nameRules"
                  autocomplete="name"
                  name="name"
                  hide-details="auto"
                  clearable
                  color="primary"
                  base-color="blue-grey-lighten-3"
                  bg-color="blue-grey-lighten-5"
                  @keyup.enter="handleRegisterUser"
                />
              </div>

              <div>
                <label
                  class="text-body-2 font-weight-bold d-block mb-2"
                  for="register-email"
                >
                  E-mail
                </label>

                <v-text-field
                  id="register-email"
                  v-model="registerForm.email"
                  variant="outlined"
                  density="comfortable"
                  placeholder="seu@email.com"
                  prepend-inner-icon="mdi-email-outline"
                  :rules="emailRules"
                  autocomplete="email"
                  inputmode="email"
                  name="email"
                  hide-details="auto"
                  clearable
                  color="primary"
                  base-color="blue-grey-lighten-3"
                  bg-color="blue-grey-lighten-5"
                  @keyup.enter="handleRegisterUser"
                >
                  <template #append-inner>
                    <v-tooltip location="top" max-width="280">
                      <template #activator="{ props }">
                        <v-icon
                          icon="mdi-information-outline"
                          size="20"
                          v-bind="props"
                        />
                      </template>
                      <span>
                        Não recebeu o email de confirmação? Confira também a caixa de spam —
                        às vezes ele acaba caindo lá por engano.
                      </span>
                    </v-tooltip>
                  </template>
                </v-text-field>
              </div>

              <div>
                <label
                  class="text-body-2 font-weight-bold d-block mb-2"
                  for="register-password"
                >
                  Senha
                </label>

                <v-text-field
                  id="register-password"
                  v-model="registerForm.password"
                  variant="outlined"
                  density="comfortable"
                  placeholder="Crie uma senha segura"
                  prepend-inner-icon="mdi-lock-outline"
                  :type="showPassword ? 'text' : 'password'"
                  :append-inner-icon="
                    showPassword ? 'mdi-eye' : 'mdi-eye-off'
                  "
                  :rules="passwordRules"
                  autocomplete="new-password"
                  hide-details="auto"
                  color="primary"
                  base-color="blue-grey-lighten-3"
                  bg-color="blue-grey-lighten-5"
                  @click:append-inner="showPassword = !showPassword"
                  @keyup="validateRulesPassword"
                  @keyup.enter="handleRegisterUser"
                />

                <div class="mt-2">
                  <Password
                    v-model="registerForm.password"
                    :strength-meter-only="true"
                  />
                </div>

                <v-expand-transition>
                  <div
                    v-if="showValidatePassword"
                    class="d-flex flex-column ga-1 mt-2 text-body-2 text-medium-emphasis"
                  >
                    <div class="d-flex align-center ga-2">
                      <v-icon
                        :color="regexValidateMinimoSeis ? 'success' : 'error'"
                        :icon="
                          regexValidateMinimoSeis
                            ? 'mdi-check-circle-outline'
                            : 'mdi-close-circle-outline'
                        "
                        size="16"
                      />

                      <span>Pelo menos 6 caracteres</span>
                    </div>

                    <div class="d-flex align-center ga-2">
                      <v-icon
                        :color="regexValidateMaiuscula ? 'success' : 'error'"
                        :icon="
                          regexValidateMaiuscula
                            ? 'mdi-check-circle-outline'
                            : 'mdi-close-circle-outline'
                        "
                        size="16"
                      />

                      <span>Uma letra maiúscula</span>
                    </div>

                    <div class="d-flex align-center ga-2">
                      <v-icon
                        :color="regexValidateMinuscula ? 'success' : 'error'"
                        :icon="
                          regexValidateMinuscula
                            ? 'mdi-check-circle-outline'
                            : 'mdi-close-circle-outline'
                        "
                        size="16"
                      />

                      <span>Uma letra minúscula</span>
                    </div>

                    <div class="d-flex align-center ga-2">
                      <v-icon
                        :color="regexValidateNumber ? 'success' : 'error'"
                        :icon="
                          regexValidateNumber
                            ? 'mdi-check-circle-outline'
                            : 'mdi-close-circle-outline'
                        "
                        size="16"
                      />

                      <span>Um número</span>
                    </div>

                    <div class="d-flex align-center ga-2">
                      <v-icon
                        :color="regexValidateEspecial ? 'success' : 'error'"
                        :icon="
                          regexValidateEspecial
                            ? 'mdi-check-circle-outline'
                            : 'mdi-close-circle-outline'
                        "
                        size="16"
                      />

                      <span>Um caractere especial</span>
                    </div>
                  </div>
                </v-expand-transition>
              </div>
              <div>
                <label
                  class="text-body-2 font-weight-bold d-block mb-2"
                  for="register-confirm-password"
                >
                  Confirmar senha
                </label>

                <v-text-field
                  id="register-confirm-password"
                  v-model="registerForm.confirmPassword"
                  variant="outlined"
                  density="comfortable"
                  placeholder="Digite sua senha novamente"
                  prepend-inner-icon="mdi-lock-check-outline"
                  :type="showPassword ? 'text' : 'password'"
                  :append-inner-icon="
                    showPassword ? 'mdi-eye' : 'mdi-eye-off'
                  "
                  :rules="confirmPasswordRules"
                  autocomplete="new-password"
                  hide-details="auto"
                  color="primary"
                  base-color="blue-grey-lighten-3"
                  bg-color="blue-grey-lighten-5"
                  @click:append-inner="showPassword = !showPassword"
                  @keyup.enter="handleRegisterUser"
                />
              </div>

              <v-btn
                :disabled="authStore.disableButton"
                :loading="loading"
                color="primary"
                size="large"
                height="52"
                rounded="lg"
                block
                elevation="2"
                class="mt-1"
                @click="handleRegisterUser"
              >
                Criar minha conta

                <v-icon
                  end
                  icon="mdi-arrow-right"
                />
              </v-btn>

              <div
                class="d-flex align-center ga-3 text-medium-emphasis text-caption"
              >
                <v-divider />

                <span class="text-no-wrap">
                  ou continue com
                </span>

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
                  class="text-none"
                  @click="handleWidthGoogle"
                >
                  <template #prepend>
                    <v-avatar
                      :image="logoGoogle"
                      size="20"
                      color="white"
                    />
                  </template>

                  Criar conta com Google
                </v-btn>

                <v-btn
                  :disabled="authStore.disableButton"
                  :loading="loadingFacebook"
                  variant="outlined"
                  color="blue-grey-darken-2"
                  size="large"
                  height="52"
                  rounded="lg"
                  block
                  class="text-none"
                  @click="handleWidthDiscord"
                >
                  <template #prepend>
                    <v-avatar
                      :image="logoDiscord"
                      size="22"
                      color="white"
                    />
                  </template>

                  Criar conta com Discord
                </v-btn>
              </div>

              <p
                class="text-center text-body-2 bg-white text-medium-emphasis ma-0 mt-1"
              >
                Já possui uma conta?

                <NuxtLink
                  to="/login-page"
                  class="text-primary font-weight-bold text-decoration-none"
                >
                  Entrar na plataforma
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