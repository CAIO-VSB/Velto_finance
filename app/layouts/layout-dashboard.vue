<script lang="ts" setup>

  import logo from "~~/app/assets/logo-side-bar.svg"

  import ButtonActions from '~/layouts/components/ButtonActions.vue'
  import TopBar from "~/layouts/components/TopBar.vue"
  import { useTheme } from 'vuetify'

  type ThemeMode = "light" | "dark" | "system"

  const drawer = ref(true)
  const rail = ref(false)
  const openedGroups = ref(['Visão geral'])

  const theme = useTheme()
  const themeMode = ref<ThemeMode>("light")

  function handleThemeChange(mode: ThemeMode) {
    themeMode.value = mode
    localStorage.setItem('theme', themeMode.value)
    theme.change(mode)
  }

  const mainContentClass = computed(() => ({
    'main-content': themeMode.value === 'light'
  }))

  onMounted(() => {
    const savedTheme = localStorage.getItem("theme")

    if (
      savedTheme === 'light' ||
      savedTheme === 'dark' ||
      savedTheme === 'system' 
    ) {
      themeMode.value = savedTheme
      theme.change(savedTheme)
    }
    
  })

  const nav = [
    { title: 'Visão geral', icon: 'mdi-home-analytics', value: 'Visão geral', to: '/dashboard' },
    { title: 'Transações', icon: 'mdi-swap-horizontal-bold', value: 'transacoes', to: '/transactions' },
    { title: 'Cartões de crédito', icon: 'mdi-credit-card-multiple-outline', value: 'cartoes', to: '/credit-card' },
    { title: 'Economia', icon: 'mdi-piggy-bank-outline', value: 'economia', to: '/economy' },
  ]

</script>

<template>
  <v-layout>

    <v-navigation-drawer
      v-model="drawer"
      :rail="rail"
      :width="300"
      border="end"
      color="surface"
      @click="rail = false"
    >

      <div class="drawer-logo px-6">
        <img
          :src="logo"
          alt="Velto Finance"
          class="drawer-logo-img"
        />
      </div>

      <v-divider />
      <div class="px-3 pt-4 pb-2">
        <ButtonActions
          :rail="rail"
          class="w-100"
        />
      </div>

      <v-list
        v-model:opened="openedGroups"
        density="comfortable"
        nav
        class="px-3"
      >

        <v-list-subheader class="text-uppercase text-caption font-weight-bold px-3 mb-1">
          Principal
        </v-list-subheader>

        <v-list-item
          v-for="item in nav"
          :key="item.value"
          :prepend-icon="item.icon"
          :title="item.title"
          :value="item.value"
          :to="item.to"
          rounded="lg"
          color="primary"
          class="mb-1"
        >
          <template #title>
            <span class="size-item-title">
              {{ item.title }}
            </span>
          </template>
        </v-list-item>


        <v-list-subheader
          v-if="!rail"
          class="text-uppercase text-caption font-weight-bold px-3 mt-4 mb-1"
        >
          Gestão
        </v-list-subheader>

        <v-list-item
          v-if="rail"
          prepend-icon="mdi-database-plus"
          rounded="lg"
          color="primary"
          class="mb-1"
        >
          <v-tooltip
            activator="parent"
            location="end"
          >
            Cadastros
          </v-tooltip>
        </v-list-item>

        <v-list-group
          v-else
          value="Cadastros"
        >
          <template #activator="{ props }">
            <v-list-item
              v-bind="props"
              prepend-icon="mdi-database-plus"
              rounded="lg"
              color="primary"
            >
              <template #title>
                <span class="size-item-title">
                  Cadastros
                </span>
              </template>
            </v-list-item>
          </template>

          <v-list-item
            prepend-icon="mdi-folder-outline"
            title="Categorias"
            value="categoria"
            to="/categories"
            rounded="lg"
            color="primary"
            class="mb-1"
          >
            <template #title>
              <span class="size-item-title">
                Categorias
              </span>
            </template>
          </v-list-item>

          <v-list-item
            prepend-icon="mdi-bank-outline"
            title="Contas bancárias"
            value="contas"
            to="/accounts"
            rounded="lg"
            color="primary"
            class="mb-1"
          >
            <template #title>
              <span class="size-item-title">
                Contas bancárias
              </span>
            </template>
          </v-list-item>
        </v-list-group>

        <v-list-subheader
          v-if="!rail"
          class="text-uppercase text-caption font-weight-bold px-3 mt-4 mb-1"
        >
          Atualizações
        </v-list-subheader>

        <v-list-item
          prepend-icon="mdi-update"
          title="Relatórios"
          value="relatorios"
          rounded="lg"
          to="/news"
        >
          <template #title>
            <div class="d-flex align-center justify-space-between w-100">
              <span class="size-item-title">
                Novidades
              </span>
            </div>
          </template>
        </v-list-item>

      </v-list>

    <template #append>
  <div class="px-3 pb-4">
    <v-divider class="mb-3" />

    <div class="d-flex align-center justify-center ga-2">
      <v-btn
        icon="mdi-white-balance-sunny"
        rounded="circle"
        size="small"
        :color="themeMode === 'light' ? 'primary' : undefined"
        :variant="themeMode === 'light' ? 'tonal' : 'text'"
        v-tooltip="'Tema claro'"
        @click="handleThemeChange('light')"
      />

      <v-btn
        icon="mdi-weather-night"
        rounded="circle"
        size="small"
        :color="themeMode === 'dark' ? 'primary' : undefined"
        :variant="themeMode === 'dark' ? 'tonal' : 'text'"
        v-tooltip="'Tema escuro'"
        @click="handleThemeChange('dark')"
      />

      <v-btn
        icon="mdi-theme-light-dark"
        rounded="circle"
        size="small"
        :color="themeMode === 'system' ? 'primary' : undefined"
        :variant="themeMode === 'system' ? 'tonal' : 'text'"
        v-tooltip="'Usar tema do dispositivo'"
        @click="handleThemeChange('system')"
      />
    </div>

    <div class="text-caption text-medium-emphasis text-center mt-1">
      Versão 1.5.0
    </div>
  </div>
</template>

    </v-navigation-drawer>


    <TopBar v-model="drawer" />

    <v-main
      :class="mainContentClass"
      style="overflow-y: auto; overflow-x: hidden;"
    >
      <div class="dashboard-content">
        <slot />
      </div>
    </v-main>

  </v-layout>
</template>

<style scoped>

.size-item-title {
  font-size: var(--text-base);
}

.main-content {
  background-color: #f6f7fb;
}

.drawer-logo {
  height: 88px;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.drawer-logo-img {
  width: 220px;
  height: auto;
  display: block;
}

.dashboard-content::-webkit-scrollbar {
  width: 5px;
}

.dashboard-content::-webkit-scrollbar-thumb {
  background: #dad7d7;
}
</style>