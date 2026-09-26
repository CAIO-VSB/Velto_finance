<script lang="ts" setup>

    
  const props = defineProps<{
    title?: string,
    text?: string,
    subtitle?: string,
    loading?: boolean,
    width?: number,
    heiht?: number | string
  }>()


</script>

<template>
    <v-card 
    :text="props.text"
    :loading="props.loading"
    rounded="xl"
    :width="props.width"
    :height="props.heiht"
    :elevation="2"
    >

    <v-card-item class="pa-5 pb-0">
        <v-card-title>
            {{props.title}}
        </v-card-title>

        <v-card-subtitle class="mt-1">
            {{ props.subtitle }}
        </v-card-subtitle>
    </v-card-item>
    
    <div>
        <slot></slot>
    </div>

    </v-card>

</template>

<style scoped>

</style>