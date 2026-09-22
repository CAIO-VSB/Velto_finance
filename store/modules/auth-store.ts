import { defineStore } from "pinia"
import type { TUser } from "../../types/auth/Tauth.types";
import type { TLoginForm, TRegisterForm } from "../../types/user/Tuser.types";
import { reloadNuxtApp } from '#imports'


export const useAuthStore = defineStore('auth', () => {
    const { $authClient } = useNuxtApp()
    const user = ref<TUser>()
    const isAuthenticated = ref<boolean>(false)
    const disableButton = ref<boolean>(false)
    const showDialogAlertEmail = ref<boolean>(false)
    const showDialogAlertPassword = ref<boolean>(false)

    const { notifyError, notifyInfo, notifySuccess } = useNotify()

    const setUser = async (userData: TUser): Promise<void> => {
        user.value = userData
        sessionStorage.setItem("user", JSON.stringify(userData))
    }
    
    const setAuthenticated = async (value: boolean): Promise<void> => {
        isAuthenticated.value = value
        sessionStorage.setItem('isAuthenticated', JSON.stringify(value))
    }

    const initUser = async () => {
        const { data: session } = await $authClient.getSession()
        if (session?.user) {
            user.value = session.user
        }
        return session
    }

    const updateUserImage = (imageUrl: string) => {
        if (user.value) {
            user.value.image = imageUrl
        }
    }

    const login = async (data: TLoginForm) => {
        try {
            const response = await $authClient.signIn.email(data, {
                onError(context) {
                    if (context.error.status === 401) {
                        notifyError("Não foi possível fazer login", "E-mail ou senha incorretos. Verifique os dados e tente novamente", 7000)
                        return
                    } else if (context.error.status === 403) {
                        notifyInfo(
                        "E-mail não verificado",
                        "Enviamos um novo e-mail de verificação. Acesse sua caixa de entrada e confirme seu e-mail para continuar.",
                        8000
                        )
                        return
                    }  
                    else if (context.error.status === 429) {
                        notifyInfo(
                        "Limite de tentativas atingido",
                        "Para proteger sua conta, aguarde 10 segundos antes de realizar uma nova tentativa",
                        10000,
                        false,
                        false
                        )
                        return
                    } 
                    else if (context.error.status === 500) {
                        notifyError(
                            "Não foi possível realizar o login",
                            "Ocorreu um erro interno ao tentar acessar sua conta. Tente novamente em alguns instantes.",
                            7000
                        )
                    }
                    else {
                        handleErrorApplication(context.error.status)
                        return
                    }
                }
            })

            const token = response.data?.token

            if (token) {

                if (response.data?.user) {
                    await setUser(response.data.user)
                    await setAuthenticated(true)
                    return {success: true, message: "Validação realizada com sucesso"}
                }
            } 

        } catch (error) {
            notifyError("Erro interno", "Ocorreu um erro inesperado. Tente novamente em alguns instantes.")
        }
    }

    const loginGoogle = async () => {

        $authClient.signIn.social({
            provider: "google",
            callbackURL: "https://app.veltofinance.bid/dashboard"
        }, {
            onError(context) {
                if (context.error.status === 500) {
                    notifyError(
                        "Não foi possível realizar o login",
                        "Ocorreu um erro interno ao tentar acessar sua conta. Tente novamente em alguns instantes.",
                        7000
                    )

                    return
                }
            },
        })

    }

    const loginDiscord = async () => {

        $authClient.signIn.social({
            provider: "discord",
            callbackURL: "https://app.veltofinance.bid/dashboard"
        }, {
            onError(context) {
                if (context.error.status === 500) {
                    notifyError(
                        "Não foi possível realizar o login",
                        "Ocorreu um erro interno ao tentar acessar sua conta. Tente novamente em alguns instantes.",
                        7000
                    )

                    return
                }
            },   
        })

    }

    const register = async (data: TRegisterForm) => {

        try {

            await $authClient.signUp.email(data, {
                onError(context) {
                    if (context.error.status === 422) {
                        notifyError("E-mail já cadastrado", "Este endereço de e-mail já está em uso. Utilize outro e-mail ou faça login.", 8000)
                        return
                    } else if (context.error.status === 500) {
                        notifyError(
                            "Não foi possível realizar o cadastro",
                            "Ocorreu um erro interno ao tentar criar sua conta. Tente novamente em alguns instantes.",
                            7000
                        )
                    }
                },

                onSuccess() {
                    notifySuccess("E-mail enviado", "Enviamos um e-mail de verificação para sua caixa de entrada. Caso não o encontre, verifique a pasta de spam.", 9000)
                }
            })

            return {success: true, message: "Conta criada com sucesso"}

        } catch (error) {
            notifyError("Erro interno", "Ocorreu um erro inesperado. Tente novamente em alguns instantes.")
        }
    }

    const alterUser = async (data: Partial<TUser>) => {
        await $authClient.updateUser({
            name: data.name,
        }, {
            onSuccess() {
                notifySuccess("Sucesso", "Nome alterado com sucesso", 6000)
                reloadNuxtApp({
                    path: "/config/access"
                })
            },
            onError(context) {
                notifyError("Erro interno", "Ocorreu um erro inesperado. Tente novamente em alguns instantes.", 7000)
                console.log("Erro ao modificar nome" + JSON.stringify(context.error))
            },
        })
    }
    
    const alterEmail = async (newEmail: string) => {

        try {
            await $authClient.changeEmail({
            newEmail: newEmail,
            callbackURL: "/confirmEmail"
        }, {
            onSuccess() {

                showDialogAlertEmail.value = true
            },
            onError(context) {

                if (context.error.status === 400 && context.error.message === "Invalid body parameters") {
                    notifyInfo("Atenção", "O e-mail inserido é inválido. Tente novamente", 5000)
                    return
                }

                if (context.error.status === 400 && context.error.message === "Email is the same") {
                    notifyError("Email já cadastrado", "O novo e-mail deve ser diferente do e-mail atual", 5000)
                    return
                }

                notifyError("Erro interno", "Ocorreu um erro inesperado. Tente novamente em alguns instantes.", 7000)
                
            },
        })
        
        } catch (e) {
            notifyError("Erro interno", "Ocorreu um erro inesperado. Tente novamente em alguns instantes.")
        }
        
    }

    const alterPassword = async (newPassowrd: string, currentPassword: string) => {

        try {
            await $authClient.changePassword({
            newPassword: newPassowrd,
            currentPassword: currentPassword,
            revokeOtherSessions: true
        }, {
            onSuccess() {
                showDialogAlertPassword.value = true
            },
            onError(context) {

                if (context.error.status === 400 && context.error.message === "Invalid password") {
                    console.log("Erro" + JSON.stringify(context.error))
                    notifyInfo(
                    "Atenção",
                    "A senha atual informada está incorreta. Tente novamente.",
                    5000
                    )
                    return
                }

                if (context.error.status === 400 && context.error.message === "Password too short") {
                    console.log("Erro" + JSON.stringify(context.error))
                   notifyInfo(
                    "Atenção",
                    "A senha é muito curta. Utilize pelo menos 6 caracteres.",
                    5000
                    )
                    return
                }

                notifyError("Erro interno", "Ocorreu um erro inesperado. Tente novamente em alguns instantes.", 7000)
                
            },
        })
        
        } catch (e) {
            notifyError("Erro interno", "Ocorreu um erro inesperado. Tente novamente em alguns instantes.")
        }
        
    }

    const logout  = async () => {
        await $authClient.signOut({
            fetchOptions: {
                onSuccess: () => {
                    navigateTo({ path: "/login-page" });
                }
            }
        })
    }


    return { login, loginGoogle, loginDiscord, register, logout, alterUser, alterEmail, alterPassword, isAuthenticated, user, disableButton, showDialogAlertEmail, showDialogAlertPassword, initUser, updateUserImage }

})