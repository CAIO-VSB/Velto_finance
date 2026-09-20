<script setup lang="ts">

    const propsCards = defineProps<{
        subtitle: string,
        loading: boolean,
        value: number | null
        color?: string,
        variant?: string,
        icon?: string,
        size?: string,
        textToolTip?: string,
        iconToolTip?: string,
        sizeIconToolTip?: string
    }>()
    
</script>

<template>
    <v-card
        rounded="xl"
        elevation="2"
        :loading="propsCards.loading"
        :v-tooltip="textToolTip"
    >
        <v-card-text class="pa-5">
            <div class="d-flex align-center justify-space-between ga-4">
                <div class="d-flex align-center ga-3">
                    <v-avatar
                        :color="propsCards.color"
                        variant="tonal"
                        :icon="propsCards.icon"
                        :size="propsCards.size"
                        rounded="lg"
                    />

                    <div>
                        <div class="text-body-2 text-medium-emphasis mb-1">
                            {{ propsCards.subtitle }}
                        </div>

                        <div style="font-size: var(--text-base);" class="text-h6 font-weight-bold text-blue-grey-darken-4">
                            {{ formatCurrency(propsCards.value) }}
                        </div>
                    </div>
                </div>

            </div>
        </v-card-text>
    </v-card>
</template>

<style scoped>
</style>