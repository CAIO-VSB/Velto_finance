
const { $authClient } = useNuxtApp()
const { notifyError, notifyInfo } = useNotify()

export function handleErrorApplication(statusCode: number | undefined) {

    switch (statusCode) {
        case 400:
            notifyInfo("Solicitação inválida", "Verifique os dados informados e tente novamente", 6000)
            break;
        case 401:
            handleSessionExpired()
            break;
        case 403:
            notifyError("Acesso negado", "Você não tem permissão para realizar esta ação", 6000)
            break;
        case 404:
            notifyError("Recurso não encontrado", "O recurso solicitado não foi encontrado", 6000)
            break;
        case 409:
            notifyError("Operação não permitida", "Não foi possível concluir a operação devido a um conflito de dados", 6000)
            break;
        case 422:
            notifyInfo("Dados inválidos", "Revise as informações informadas e tente novamente", 6000)
            break;
        case 429:
            notifyInfo(
                "Limite de tentativas atingido",
                "Para proteger sua conta, aguarde 5 segundos antes de realizar uma nova tentativa",
                5000,
                false,
                false
                )
            break;
        case 500:
            notifyError("Algo deu errado", "Ocorreu um erro inesperado. Tente novamente em alguns instantes", 6000)
            break;
        case 503:
            notifyError("Serviço indisponível", "O serviço está temporariamente indisponível. Tente novamente mais tarde", 6000)
            break;
        default:
        notifyError("Erro", "Erro não catalogado", 6000)
    }
   
}

async function handleSessionExpired() {
    
    const { data: session} = await $authClient.getSession()
    
    if (!session?.session.token) {
        notifyError("Sessão expirada", "Sua sessão expirou. Faça login novamente para continuar", 5000)
        await navigateTo("/login-page")
    }

}
