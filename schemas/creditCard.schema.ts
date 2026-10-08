import * as z from "zod";

export const schemaCreditCard = z.object({
    id: z.number("ID da conta ausente").optional(),
    accounts_id: z.number("ID da conta ausente").min(1),
    name_identifier: z.string().max(55, "Limite de caractere excedido").min(1, "Nome da conta é obrigatório"),
    url_logo: z.string("URL logo ausente").min(3),
    due_day: z.number("Numero do fechamento ausente").min(1),
    closing_day: z.number("Numero do vencimento").min(1),
    limit_card: z.coerce.number(),
    active: z.boolean().default(true),
    four_digits: z.string("Campo ultimos 4 ditigos faltando").min(4)
})