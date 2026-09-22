<script setup lang="ts">
    definePageMeta({ title: "Confirmação de e-mail" })
</script>

<template>
  <main class="confirmation-page">
    <v-card
      class="confirmation-card overflow-hidden"
      rounded="xl"
      elevation="4"
      max-width="680"
      width="100%"
    >
      <v-card-item class="pa-5 pb-3">
        <template #prepend>
          <v-avatar
            color="success"
            variant="tonal"
            rounded="lg"
            size="46"
          >
            <v-icon
              icon="mdi-email-check-outline"
              color="success"
            />
          </v-avatar>
        </template>

        <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken-4">
          Confirmação recebida
        </v-card-title>

        <v-card-subtitle class="mt-1">
          Seu e-mail foi confirmado com sucesso.
        </v-card-subtitle>
      </v-card-item>

      <v-divider />

      <v-empty-state
        class="pa-6 pa-sm-8"
        icon="mdi-check-circle-outline"
        color="success"
        title="Tudo certo por aqui!"
        text="Se esta era a última etapa pendente, seu e-mail já foi atualizado e você pode fazer login normalmente. Caso tenha recebido outro e-mail de confirmação, basta clicar nele também para concluir a alteração."
      >
        <template #actions>
          <v-btn
            color="primary"
            rounded="lg"
            variant="flat"
            class="text-none font-weight-bold mt-4"
            prepend-icon="mdi-login"
            @click="navigateTo('/login-page')"
          >
            Ir para o login
          </v-btn>
        </template>
      </v-empty-state>
    </v-card>
  </main>
</template>

<style scoped>
.confirmation-page {
  min-height: 100%;
  display: flex;
  justify-content: center;
  padding: 24px;
  overflow: auto;
}

.confirmation-card {
  border: 1px solid rgba(var(--v-theme-success), 0.12);
}

::v-deep(.v-empty-state__icon) {
  margin-bottom: 12px;
}

::v-deep(.v-empty-state__title) {
  color: rgb(var(--v-theme-blue-grey-darken-4));
  font-size: 1.35rem;
  font-weight: 700;
}

::v-deep(.v-empty-state__text) {
  max-width: 540px;
  margin-top: 12px;
  font-size: 1rem;
  line-height: 1.65;
}
</style>