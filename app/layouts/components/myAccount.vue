<script setup lang="ts">

  import defaultUser from "~/assets/default-user.webp"

  const { $authClient } = useNuxtApp()

  const { data: session } = await $authClient.getSession()
  const authStore = useAuthStore()

  import { ref } from 'vue'
  import { useAuthStore } from "~~/store/modules/auth-store"

  if (!authStore.user) {
    await authStore.initUser()
  }

  const menu = ref(false)

  const authClientStore = useAuthStore()

  function handleSignOut() {
    authClientStore.logout()
  }

  function handleConfigApplication() {
    navigateTo("/config/access")
  }

</script>

<template>
  <div>
    <v-menu
      v-model="menu"
      :close-on-content-click="false"
      location="bottom end"
      offset="8"
      transition="scale-transition"
    >
      <template #activator="{ props }">
        <v-btn
          v-bind="props"
          variant="text"
          class="text-none px-2"
          rounded="lg"
          height="48"
        >
          <template #prepend>
            <v-avatar>
              <v-img
                :src="authStore.user?.image || defaultUser"
                alt="Avatar do usuário"
              />
            </v-avatar>
          </template>

          <div class="d-none d-sm-flex flex-column align-start mr-2">
            <span class="text-body-2 font-weight-bold">
              {{ authStore.user?.name }}
            </span>

            <span class="text-caption text-medium-emphasis">
              Minha conta
            </span>
          </div>

          <v-icon
            icon="mdi-chevron-down"
            size="20"
            class="text-medium-emphasis"
          />
        </v-btn>
      </template>

      <v-card
        min-width="320"
        max-width="360"
        rounded="xl"
        elevation="4"
        class="overflow-hidden"
      >
        <!-- Cabeçalho da conta -->
        <div class="pa-5">
          <div class="d-flex align-center ga-3">
            <v-avatar size="52">
              <v-img
                :src="authStore.user?.image || defaultUser"
                alt="Avatar do usuário"
              />
            </v-avatar>

            <div class="overflow-hidden">
              <div class="text-subtitle-1 font-weight-bold text-truncate">
                {{ authStore.user?.name }}
              </div>

              <div class="text-body-2 text-medium-emphasis">
                Conta pessoal
              </div>
            </div>
          </div>
        </div>

        <v-divider />

        <!-- Informações -->
        <div class="px-5 py-4">
          <div class="text-caption text-medium-emphasis mb-1">
            LOGADO COMO
          </div>

          <div class="text-body-2 font-weight-medium text-blue-grey-darken-1 text-truncate">
            {{ authStore.user?.email }}
          </div>
        </div>

        <v-divider />

        <!-- Ações -->
        <v-list
          density="comfortable"
          class="pa-2"
        >
          <v-list-item
            rounded="lg"
            prepend-icon="mdi-cog-outline"
            title="Configurações"
            subtitle="Preferências da conta"
            @click="handleConfigApplication"
          >
            <template #prepend>
              <v-avatar
                rounded="lg"
                size="36"
                color="primary-lighten-5"
                class="mr-2"
              >
                <v-icon
                  icon="mdi-cog-outline"
                  color="primary"
                  size="20"
                />
              </v-avatar>
            </template>
          </v-list-item>

          <v-list-item
            rounded="lg"
            class="mt-1"
            @click="handleSignOut"
          >
            <template #prepend>
              <v-avatar
                rounded="lg"
                size="36"
                color="red-lighten-5"
                class="mr-2"
              >
                <v-icon
                  icon="mdi-logout"
                  color="error"
                  size="20"
                />
              </v-avatar>
            </template>

            <v-list-item-title class="text-error font-weight-medium">
              Sair da conta
            </v-list-item-title>

            <v-list-item-subtitle>
              Encerrar sessão
            </v-list-item-subtitle>
          </v-list-item>
        </v-list>
      </v-card>
    </v-menu>
  </div>
</template>

<style lang="scss" scoped>
.v-list-item {
  transition: background-color 0.15s ease;
}
</style>