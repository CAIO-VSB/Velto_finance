<script setup lang="ts">

  import InfoUser from './myAccount.vue'
  
  const emits = defineEmits(['drawer'])

  const drawer = defineModel<boolean>()

  const routes = useRoute()

  function handleEmitsDrawer() {
    drawer.value = !drawer.value
  }


</script>

<template>
  <v-app-bar
    color="surface"
    flat
    border="b"
    height="68"
  >
    <template #prepend>
      <v-btn
        icon="mdi-menu"
        variant="text"
        color="blue-grey-darken-2"
        rounded="lg"
        class="ml-1"
        @click.stop="handleEmitsDrawer"
      />
    </template>

    <template #title>
      <span class="font-weight-bold page-title">
        {{ routes.meta.title }}
      </span>
    </template>

    <template #append>
      <div class="d-flex align-center justify-center ga-7">
        <div class="d-flex align-center ga-2 mr-2">
          <InfoUser />
        </div>
      </div>
    </template>
  </v-app-bar>
</template>

<style scoped>
.page-title {
  font-size: var(--text-md);
}

.notification-item {
  transition: background-color 0.15s ease;
}
</style>