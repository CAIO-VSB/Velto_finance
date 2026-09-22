<script lang="ts" setup>

  import logo from "~~/app/assets/logo-side-bar.svg"

  import ButtonActions from './components/ButtonActions.vue'
  import TopBar from "~/layouts/components/TopBar.vue"

  const drawer = ref(true)
  const rail = ref(false)
  const openedGroups = ref(['Visão geral'])

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
      :width="280"
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

          <div
            class="d-flex align-center px-3 text-medium-emphasis"
          >
            <v-icon
              icon="mdi-information-outline"
              size="18"
              class="mr-2"
            />

            <span class="text-caption">
              Velto Finance
            </span>

            <v-spacer />

            <span class="text-caption">
              v1.0.7
            </span>
          </div>

        </div>
      </template>

    </v-navigation-drawer>


    <TopBar v-model="drawer" />

    <v-main
      class="bg-backgroundPrimary"
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