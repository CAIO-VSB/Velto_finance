export type TGoalsMovements = {
  id?: number
  goals_id?: number | null
  description: string
  value_paid: number
  date_movement: Date
  accounts_id: number | null
  active?: boolean | null,
  is_ignored?: boolean | null
}

export type TgoalsMovementsSumary = {
  id?: number
  goals_id?: number | null
  description: string
  value_paid: number
  date_movement: string
  accounts_id: number | null
  active?: boolean | null
  is_ignored?: boolean | null

  id_goals: number | null
  name_identifier: string | null
  suggested_value: number | null
  goal_value: number | null
  start_date: string | null
  end_date: string | null,
  name_account: string | null
  url_image: string | null
}