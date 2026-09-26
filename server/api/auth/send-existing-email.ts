import { Resend } from "resend"

const resend = new Resend(process.env.RESEND_API_KEY)

type User = {
  email: string
}

export const sendExistingUserSignUpAlert = async (user: User) => {
  const htmlTemplate = `
    <div style="margin:0; padding:56px 16px; background:#FFFFFF; font-family:Arial, Helvetica, sans-serif;">
      <table
        role="presentation"
        border="0"
        cellpadding="0"
        cellspacing="0"
        width="100%"
        style="max-width:520px; margin:0 auto; background:#FFFFFF;"
      >
        <tr>
          <td style="padding:0 0 30px;">
            <div style="margin-top:14px; font-size:26px; line-height:1.2; font-weight:700; color:#2563EB; letter-spacing:-0.6px;">
              Velto Finance
            </div>
          </td>
        </tr>

        <tr>
          <td style="padding:0 0 30px;">
            <p style="margin:0; font-size:14px; line-height:1.6; color:#7A7F87;">
              Olá, <strong style="color:#111827;">${user.email}</strong>.
            </p>
          </td>
        </tr>

        <tr>
          <td style="padding:0 0 28px;">
            <p style="margin:0; font-size:16px; line-height:1.55; color:#111827; font-weight:600;">
              Identificamos uma tentativa de criar uma conta usando este endereço de e-mail.
            </p>
          </td>
        </tr>

        <tr>
          <td style="padding:0 0 28px;">
            <div style="background:#EFF6FF; border:1px solid #BFDBFE; border-radius:10px; padding:14px 16px;">
              <p style="margin:0; font-size:14px; line-height:1.55; color:#1E40AF;">
                <strong style="color:#1E3A8A;">Se foi você:</strong>
                sua conta já existe. Acesse a página de login para entrar ou use a opção de recuperação de senha caso necessário.
              </p>
            </div>
          </td>
        </tr>

        <tr>
          <td style="padding:0 0 28px;">
            <div style="background:#F8FAFC; border:1px solid #E2E8F0; border-radius:10px; padding:14px 16px;">
              <p style="margin:0; font-size:14px; line-height:1.55; color:#475569;">
                <strong style="color:#111827;">Se não foi você:</strong>
                não é preciso fazer nada. Nenhuma alteração foi realizada na sua conta.
              </p>
            </div>
          </td>
        </tr>

        <tr>
          <td style="padding-top:22px; border-top:1px solid #EEF2F7;">
            <p style="margin:0; font-size:12px; line-height:1.5; color:#9CA3AF;">
              Este é um aviso automático de segurança do Velto Finance.
            </p>
          </td>
        </tr>
      </table>
    </div>
  `

  try {
    const { data, error } = await resend.emails.send({
      from: "Segurança Velto Finance <time@veltofinance.bid>",
      to: user.email,
      subject: "Tentativa de cadastro identificada",
      text: "Identificamos uma tentativa de criar uma conta usando este endereço de e-mail. Se foi você, acesse sua conta ou recupere sua senha. Caso contrário, nenhuma ação é necessária.",
      html: htmlTemplate,
    })

    if (error) {
      console.error({ error })
      return
    }

    console.log({ data })
  } catch (error) {
    console.error("Falha ao enviar o e-mail:", error)
  }
}