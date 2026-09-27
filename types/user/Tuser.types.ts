export type TLoginForm = {
    email: string,
    password: string,
    rememberMe: false
}

export type TRegisterForm = {
    id: string,
    name: string,
    email: string,
    password: string,
    confirmPassword: string
}

export type TResetForm = Omit<TRegisterForm, "name" | "email" | "id"> // Esse tipo lida com a page de nova senha

export type TRecoveryForm = Omit<TLoginForm, "password"> // Esse tipo lida com a page onde é inserio o e-mail de recuperação