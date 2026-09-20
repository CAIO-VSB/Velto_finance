import * as z from "zod";

export const schemaGoalsMovements = z.object({
  id: z.number("ID da movimentação ausente").optional(),
  goals_id: z.number("ID da meta ausente").min(1, "ID da meta inválido").nullish(),
  description: z.string().max(255, "Limite de caracteres excedido").min(1, "Descrição é obrigatória").nullish(),
  value_paid: z.number("Valor da movimentação ausente").min(0.01, "O valor deve ser maior que zero").nullish(),
  date_movement: z.string("Data da movimentação ausente"),
  accounts_id: z.number("ID da conta ausente").min(1, "ID da conta inválido").nullish(),
  is_ignored: z.boolean().nullish()
});

export type TGoalsMovementsPayload = z.infer<typeof schemaGoalsMovements>;