<script setup lang="ts">
import type { NuxtError } from '#app';
import img500 from "~/assets/img500.jpg" 

const props = defineProps({
    error: Object as () => NuxtError,
})


function onClickAction () {
    clearError({ redirect: '/login-page' })
}


const errorDetails = computed(() => {
    const statusCode = props.error?.statusCode || 500

    if (props.error?.message?.includes('fetch failed') || props.error?.message?.includes('EAI_AGAIN')) {
        return {
            title: `Código do erro: ${statusCode} (Falha de Rede)`,
            text: "Não foi possível estabelecer conexão com nossos servidores de autenticação. Por favor, verifique sua conexão ou tente novamente em alguns instantes."
        }
    }

    return {
        title: `Código do erro: ${statusCode}`,
        text: "Desculpe! Ocorreu um erro interno em nosso servidor e não conseguimos processar sua requisição no momento. Nossa equipe já foi notificada."
    }
})
</script>

<template>
    <div class="container flex-container">
        <v-empty-state
            class="text-center"
            headline="Instabilidade no Servidor"
            :title="errorDetails.title"
            :text="errorDetails.text"
            size="420px"
            :image="img500"
        >

            <v-btn
                color="primary"
                class="mt-6"
                rounded
                @click="onClickAction"
            >
                Tentar Novamente
            </v-btn>
        </v-empty-state>
    </div>
</template>

<style scoped>
.container {
    overflow-y: auto !important;
    height: 100vh;
    background-color: #fafafa; 
}

.flex-container {
    display: flex;
    align-items: center;
    justify-content: center;
}

.max-w-xl {
    max-width: 600px !important;
}

.code-text {
    font-family: monospace;
    font-size: 0.85rem;
    color: #d32f2f;
}

::v-deep(.v-empty-state__headline) {
    color: #b71c1c; 
}

::v-deep(.v-empty-state__text) {
    font-size: 1.3rem;
    max-width: 750px !important;
    margin-top: 20px;
}

::v-deep(.v-empty-state__title) {
    font-size: 1.2rem;
    margin-top: 5px;
    font-weight: 600;
}
</style>
