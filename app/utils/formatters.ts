    import type { TTransfer } from '~~/types/transfer/TTransfer'
    import type { TMovements } from '~~/types/movements/TMovements'
    import type { TMovementCreditCard } from '~~/types/credit_card/TMovementCreditCard'
    import type { TGoalsMovements } from '~~/types/goals/TMovementsGoals'

    export function parseTransferToEdit(transfer: TTransfer):TTransfer {

        return {
            ...transfer,
            value_transfer: Number(transfer.value_transfer ?? 0),
            date_transfer:  transfer.date_transfer ? parseDateOnlyToLocalDate(String(transfer.date_transfer)) : null
        }

    }

    export function parseMovementToEdit(movements: TMovements):TMovements {

        return {
            ...movements,
            value_transaction: Number(movements.value_transaction ?? 0),
            date_transaction:  parseDateOnlyToLocalDate(String(movements.date_transaction))
        }

    }

    export function parseMovementCreditCardToEdit(movement: TMovementCreditCard): TMovementCreditCard {
        return {
            ...movement,
            value_transaction: Number(movement.value_transaction ?? 0),
            purchase_date: parseDateOnlyToLocalDate(String(movement.purchase_date))
        }
    }

    export function parseMovementGoalsToEdit(goals: TGoalsMovements): TGoalsMovements {
        return {
            ...goals,
            value_paid: Number(goals.value_paid ?? 0),
            date_movement: parseDateOnlyToLocalDate(String(goals.date_movement))
        }
    }
