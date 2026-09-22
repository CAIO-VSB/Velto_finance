<script setup lang="ts">

import Restricted from "~/assets/img-error-401.svg"

const goToLogin = () => {
  navigateTo("/login-page")
}

</script>

<template>
  <main class="restricted-page">
    <v-card
      class="restricted-card overflow-hidden"
      rounded="xl"
      elevation="4"
      max-width="680"
      width="100%"
    >
      <v-card-item class="pa-5 pb-3">
        <template #prepend>
          <v-avatar
            color="warning"
            variant="tonal"
            rounded="lg"
            size="46"
          >
            <v-icon
              icon="mdi-lock-outline"
              color="warning"
            />
          </v-avatar>
        </template>

        <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken-4">
          Acesso restrito
        </v-card-title>

        <v-card-subtitle class="mt-1">
          Código do erro: 401
        </v-card-subtitle>
      </v-card-item>

      <v-divider />

      <v-empty-state
        :image="Restricted"
        class="pa-6 pa-sm-8"
        size="280px"
        title="Você precisa fazer login"
        text="Você precisa estar autenticado para acessar esta página. Faça login para continuar acompanhando suas finanças com segurança."
      >
        <template #actions>
          <v-btn
            class="text-none font-weight-bold mt-4"
            color="primary"
            variant="flat"
            rounded="lg"
            prepend-icon="mdi-login"
            @click="goToLogin"
          >
            Ir para o login
          </v-btn>
        </template>
      </v-empty-state>
    </v-card>
  </main>
</template>

<style scoped>

.restricted-page {
  min-height: 100vh;
  display: flex;
  justify-content: center;
  padding: 24px;
  overflow: auto;
}

.restricted-card {
  border: 1px solid rgba(var(--v-theme-warning), 0.16);
}

::v-deep(.v-empty-state__image) {
  margin-bottom: 8px;
}

::v-deep(.v-empty-state__title) {
  color: rgb(var(--v-theme-blue-grey-darken-4));
  font-size: 1.35rem;
  font-weight: 700;
}

::v-deep(.v-empty-state__text) {
  max-width: 520px;
  margin-top: 12px;
  font-size: 1rem;
  line-height: 1.65;
}
</style>