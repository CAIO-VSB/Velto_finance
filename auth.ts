import { betterAuth } from "better-auth"
import { sendUserEmail } from "~~/server/api/auth/send-verification-email"
import { sendForgotPassword } from "~~/server/api/auth/send-reset-password"
import { Pool } from "pg"
import { sendChangeEmail } from "~~/server/api/auth/send-change-email-confirmation"
import client from "~/utils/db" 

export const auth = betterAuth({

    session: {
        expiresIn: 60 * 60 * 24 * 7,
        updateAge: 60 * 60 * 24
    },

    database: new Pool({
        connectionString: process.env.DATABASE_URL
    }),

    emailAndPassword: {
        enabled: true,
        requireEmailVerification: true,
        autoSignIn: false,
        
        sendResetPassword: async ({user, url}) => {
            void sendForgotPassword(user, url)
        }
    },

    emailVerification: {
        sendVerificationEmail: async ({ user, url }) => {
           void sendUserEmail(user, url)
        },
        sendOnSignIn: true,
        sendOnSignUp: true
    },

    user: {
        changeEmail: {
            enabled: true,
            sendChangeEmailConfirmation: async ({user, newEmail, url}) => {
                void sendChangeEmail({email: user.email, newEmail}, url)
            },
        },
    },
    
    socialProviders: {
        google: {
            clientId: process.env.GOOGLE_CLIENT_ID as string,
            clientSecret: process.env.GOOGLE_CLIENT_SECRET as string,
            prompt: "select_account",
            accessType: "offline"
        },

        discord: { 
            clientId: process.env.DISCORD_CLIENT_ID as string, 
            clientSecret: process.env.DISCORD_CLIENT_SECRET as string,
        }, 

    },

    account: {
        accountLinking: {
            enabled: true,
            trustedProviders: ["discord", "google"]
        }
    },

    onAPIError: {
        
        onError(e) {
            console.log(e)
        },
        errorURL: "/error.vue"
    },

    
})