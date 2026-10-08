import client from "~/utils/db"
import { TRecurrencePayload } from "~~/schemas/recurrence.schema"
import { TMovementsPayload } from "~~/schemas/movements.schema"
import { TMovementCreditCardPayload } from "~~/schemas/movementCreditCard.schema"

export const recurrenceRepository = {

    async create(userId: string, data: TRecurrencePayload | null, dataMovements: TMovementsPayload[] | null) {

        const conn = await client.connect()

        try {
            await conn.query('BEGIN')

            const recurrenceResult = await conn.query(
                `INSERT INTO recurrence(user_id, value_recurrence, description_recurrence, accounts_id, categorie_id, type_recurrence, frequency_recurrence, total_installments, day_maturity, is_active) 
                VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) 
                RETURNING id`,
                [userId, data?.value_recurrence, data?.description_recurrence, data?.accounts_id, data?.categorie_id, data?.type_recurrence, data?.frequency_recurrence, data?.total_installments, data?.day_maturity, data?.is_active]
            )

            const recurrenceId = recurrenceResult.rows[0].id

            if (data?.type_recurrence === "fixa" && dataMovements) {
                for (const movement of dataMovements) {
                    await conn.query(
                        `INSERT INTO movements(user_id, type_transaction, value_transaction, date_transaction, description_transaction, categorie_id, accounts_id, observation, url_recibo, status_transaction, is_deleted, recurrence_id) 
                        VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
                        [userId, movement.type_transaction, movement.value_transaction, movement.date_transaction, movement.description_transaction, movement.categorie_id, movement.accounts_id, movement.observation, movement.url_recibo, movement.status_transaction, movement.is_deleted, recurrenceId]
                    )
                }
            }

            if (data?.type_recurrence === "parcelada" && dataMovements) {
                for (const [indice, valor] of dataMovements.entries()) {
                    await conn.query(
                        `INSERT INTO movements(user_id, type_transaction, value_transaction, date_transaction, description_transaction, categorie_id, accounts_id, observation, url_recibo, status_transaction, is_deleted, recurrence_id, installment_current) 
                        VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)`,
                        [userId, valor.type_transaction, valor.value_transaction, valor.date_transaction, valor.description_transaction, valor.categorie_id, valor.accounts_id, valor.observation, valor.url_recibo, valor.status_transaction, valor.is_deleted, recurrenceId, indice + 1]
                    )
                }
            }

            await conn.query('COMMIT')

            return { message: "Recorrência criada com sucesso", status: 200, recurrenceId }

        } catch (error) {
            await conn.query('ROLLBACK')
            throw error
        } finally {
            conn.release()
        }
    },

    //---------------------------------------------------------------------------------------------------------------------------

    async createRecorrenceCreditCard(userId: string, data: TRecurrencePayload | null, dataMovementsCreditCard: TMovementCreditCardPayload[] | null) {


        const conn = await client.connect()

        try {
            await conn.query('BEGIN')

            const recurrenceResult = await conn.query(
                `INSERT INTO recurrence(user_id, value_recurrence, description_recurrence, accounts_id, categorie_id, type_recurrence, frequency_recurrence, total_installments, day_maturity, is_active) 
                VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) 
                RETURNING id`,
                [userId, data?.value_recurrence, data?.description_recurrence, data?.accounts_id, data?.categorie_id, data?.type_recurrence, data?.frequency_recurrence, data?.total_installments, data?.day_maturity, data?.is_active]
            )

            const recurrenceId = recurrenceResult.rows[0].id

            if (data?.type_recurrence === "fixa" && dataMovementsCreditCard) {

               for (const [indice, movement] of dataMovementsCreditCard.entries()) {

                    const creditCardResult = await conn.query(
                    `SELECT closing_day
                    FROM credit_cards
                    WHERE id = $1
                    `,[movement.credit_card_id]
                    )

                    if (creditCardResult.rows.length === 0) {
                        throw new Error("Cartão de crédito não encontrado")
                    }

                    const closingDayValue = creditCardResult.rows?.[0].closing_day

                    const creditCardId = movement.credit_card_id
                    const baseDate = new Date(movement.invoice_year!, movement.invoice_month! - 1 + indice, 1)
                    const invoiceMonth = baseDate.getMonth() + 1
                    const invoiceYear = baseDate.getFullYear()
                    const purchaseDateOriginal = dataMovementsCreditCard[0]?.purchase_date

                    if (closingDayValue === null) {
                        throw new Error(
                            `Dia de fechamento não informado para o cartão ${movement.credit_card_id}`
                        )
                    }

                    const existingInvoice = await conn.query(
                        `SELECT id FROM credit_card_invoices WHERE credit_card_id = $1 AND invoice_month = $2 AND invoice_year = $3`,
                        [creditCardId, invoiceMonth, invoiceYear]
                    )

                    let invoiceId: number

                    if (existingInvoice.rows.length > 0) {
                        invoiceId = existingInvoice.rows[0].id
                    } else {
                        const closingDate = new Date(invoiceYear, invoiceMonth - 1, closingDayValue ?? 1)

                        const newInvoice = await conn.query(
                            `INSERT INTO credit_card_invoices(credit_card_id, invoice_month, invoice_year, status_invoice, closing_date, total_value)
                            VALUES($1, $2, $3, $4, $5, $6)
                            RETURNING id`,
                            [creditCardId, invoiceMonth, invoiceYear, 'parcial', closingDate, 0]
                        )
                        
                        invoiceId = newInvoice.rows[0].id
                    }

                    await conn.query(
                        `INSERT INTO credit_card_movements(user_id, credit_card_id, invoice_id, categorie_id, description_credit, value_transaction, purchase_date, installment_number, recurrence_id, status_movement, observation) 
                        VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
                        RETURNING id `,
                        [userId, movement.credit_card_id, invoiceId, movement.categorie_id, movement.description_credit, movement.value_transaction, purchaseDateOriginal, null, recurrenceId, movement.status_movement, movement.observation]
                    )


                }
            }

            //---------------------------------------------------------------------------------------------------------------------------

            if (data?.type_recurrence === "parcelada" && dataMovementsCreditCard) {

                for (const [indice, valor] of dataMovementsCreditCard.entries()) {

                    const creditCardResult = await conn.query(
                    `SELECT closing_day
                    FROM credit_cards
                    WHERE id = $1
                    `,[valor.credit_card_id]
                    )

                    if (creditCardResult.rows.length === 0) {
                        throw new Error("Cartão de crédito não encontrado")
                    }

                    const closingDayValue = creditCardResult.rows?.[0].closing_day

                    const baseDate = new Date(valor.invoice_year!, valor.invoice_month! - 1 + indice, 1)
                    const invoiceMonth = baseDate.getMonth() + 1
                    const invoiceYear = baseDate.getFullYear()
                    const creditCardId = valor.credit_card_id
                    const purchaseDateOriginal = dataMovementsCreditCard[0]?.purchase_date

                    const existingInvoice = await conn.query(
                        `SELECT id FROM credit_card_invoices WHERE credit_card_id = $1 AND invoice_month = $2 AND invoice_year = $3`,
                        [creditCardId, invoiceMonth, invoiceYear]
                    )

                    let invoiceId: number

                    if (existingInvoice.rows.length > 0) {
                        invoiceId = existingInvoice.rows[0].id
                    } else {
                        const closingDate = new Date(invoiceYear, invoiceMonth - 1, closingDayValue ?? 1)

                        const newInvoice = await conn.query(
                            `INSERT INTO credit_card_invoices(credit_card_id, invoice_month, invoice_year, status_invoice, closing_date, total_value)
                            VALUES($1, $2, $3, $4, $5, $6)
                            RETURNING id`,
                            [creditCardId, invoiceMonth, invoiceYear, 'parcial', closingDate, 0]
                        )
                        
                        invoiceId = newInvoice.rows[0].id
                    }

                    
                    await conn.query(
                        `INSERT INTO credit_card_movements(user_id, credit_card_id, invoice_id, categorie_id, description_credit, value_transaction, purchase_date, installment_number, recurrence_id, status_movement, observation, installment_total) 
                        VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
                        RETURNING id `,
                        [userId, valor.credit_card_id, invoiceId, valor.categorie_id, valor.description_credit, valor.value_transaction, purchaseDateOriginal, indice + 1, recurrenceId, valor.status_movement, valor.observation, indice + 1]
                    )


                }
            }

            await conn.query('COMMIT')

            return { message: "Recorrência criada com sucesso", status: 200}

        } catch (error) {
            await conn.query('ROLLBACK')
            throw error
        } finally {
            conn.release()
        }
    },

    //---------------------------------------------------------------------------------------------------------------------------
    async DeleteOnlyMovementRecurrence(id:number, data: TMovementsPayload, choiceOption: string, userId: string, recurrenceId: number) {

        await client.query('BEGIN')

        try {

            if (choiceOption === "somente_esta") {

                await client.query( 
                `DELETE FROM movements WHERE id = $1 AND user_id = $2`, [id, userId])

            } else if (choiceOption === "pendentes") {

                await client.query( 
                `DELETE FROM movements WHERE user_id = $1 AND recurrence_id = $2 AND status_transaction = 'pendente'`, [userId, recurrenceId])
            
            } else if (choiceOption === "todas") {

                const statusValues = data.type_transaction === 'despesa'
                ? ['pendente', 'pago']
                : ['pendente', 'recebido']

                await client.query( 
                `DELETE FROM movements WHERE user_id = $1 AND recurrence_id = $2 AND status_transaction = ANY($3)`, [userId, recurrenceId, statusValues])
            }

            await client.query('COMMIT')

        } catch (error) {

            await client.query('ROLLBACK')
            throw error
        }

    },

    //---------------------------------------------------------------------------------------------------------------------------
    async updateOnlyMovementRecurrence(id:number, data: TMovementsPayload, choiceOption: string, userId: string, recurrenceId: number) {

        await client.query('BEGIN')

        try {

            if (choiceOption === "somente_esta") {

                await client.query( 
                `UPDATE movements 
                    SET 
                        type_transaction = $1,
                        value_transaction = $2,
                        date_transaction = $3,
                        description_transaction = $4,
                        categorie_id = $5,
                        accounts_id = $6,
                        observation = $7,
                        url_recibo = $8,
                        status_transaction = $9,
                        is_deleted = $10
                    WHERE id = $11 AND user_id = $12
                `, [data.type_transaction, data.value_transaction, data.date_transaction, data.description_transaction, data.categorie_id, data.accounts_id, data.observation, data.url_recibo, data.status_transaction, data.is_deleted, id, userId])

            } else if (choiceOption === "pendentes") {

                await client.query( 
                `UPDATE movements 
                    SET 
                        value_transaction = $1,
                        description_transaction = $2,
                        categorie_id = $3,
                        accounts_id = $4,
                        observation = $5
                    WHERE user_id = $6 AND recurrence_id = $7 AND status_transaction = 'pendente'
                `, [data.value_transaction, data.description_transaction, data.categorie_id, data.accounts_id, data.observation, userId, recurrenceId])
            
            } else if (choiceOption === "todas") {

                const statusValues = data.type_transaction === 'despesa'
                ? ['pendente', 'pago']
                : ['pendente', 'recebido']

                await client.query( 
                `UPDATE movements 
                    SET 
                        value_transaction = $1,
                        description_transaction = $2,
                        categorie_id = $3,
                        accounts_id = $4,
                        observation = $5
                    WHERE user_id = $6 AND recurrence_id = $7 AND status_transaction = ANY($8)
                `, [data.value_transaction, data.description_transaction, data.categorie_id, data.accounts_id, data.observation, userId, recurrenceId, statusValues])

            }

            await client.query('COMMIT')

        } catch (error) {

            await client.query('ROLLBACK')
            throw error
        }

    },

    //---------------------------------------------------------------------------------------------------------------------------
    async updateOnlyMovementRecurrenceCreditCard(id:number, data: TMovementCreditCardPayload, choiceOption: string, userId: string, recurrenceId: number) {

        const conn = await client.connect() 

        try {

            await conn.query('BEGIN')

            const invoiceMonth = data.invoice_month
            const invoiceYear = data.invoice_year

            const existingInvoice = await conn.query(
                `SELECT id FROM credit_card_invoices WHERE credit_card_id = $1 AND invoice_month = $2 AND invoice_year = $3`,
                [data.credit_card_id, invoiceMonth, invoiceYear]
            )

            let invoiceId: number

            if (existingInvoice.rows.length > 0) {

                invoiceId = existingInvoice.rows[0].id

            } else {

                if (!invoiceMonth || !invoiceYear) {
                    throw new Error("Mês ou ano da fatura ausentes")
                }
    
                const closingDate = new Date(invoiceYear, invoiceMonth - 1, data.closingDay ?? undefined)

                const newInvoice = await conn.query(
                    `INSERT INTO credit_card_invoices(credit_card_id, invoice_month, invoice_year, status_invoice, closing_date, total_value)
                    VALUES($1, $2, $3, $4, $5, $6)
                    RETURNING id`,
                    [data.credit_card_id, invoiceMonth, invoiceYear, 'parcial', closingDate, null]
                )
                
                invoiceId = newInvoice.rows[0].id
            }

            if (choiceOption === "somente_esta") {
                
                await conn.query(
                `UPDATE credit_card_movements
                    SET 
                        value_transaction = $1,
                        description_credit = $2,
                        categorie_id = $3,
                        credit_card_id = $4,
                        invoice_id = $5,
                        observation = $6,
                        status_movement = $7,
                        purchase_date = $8
                    WHERE id = $9 AND user_id = $10
                `, [data.value_transaction, data.description_credit, data.categorie_id, data.credit_card_id, invoiceId, data.observation, data.status_movement, data.purchase_date, id, userId])


                if (data.status_movement === 'deletada') {
                    await conn.query(`DELETE FROM movements WHERE user_id = $1 AND movement_credit_card_id = $2`, [userId, id])
                }

            } else if (choiceOption === "esta_futuras") {

                await conn.query(
                    `UPDATE credit_card_movements
                        SET 
                            value_transaction = $1,
                            description_credit = $2,
                            categorie_id = $3,
                            credit_card_id = $4,
                            invoice_id = $5,
                            observation = $6,
                            status_movement = $7
                        WHERE id = $8 AND user_id = $9
                    `, [data.value_transaction, data.description_credit, data.categorie_id, data.credit_card_id, invoiceId, data.observation, data.status_movement, id, userId])

                    
                if (data.status_movement === 'deletada') {
                    await conn.query(`DELETE FROM movements WHERE user_id = $1 AND movement_credit_card_id = $2`, [userId, id])
                }

                const futureMovements = await conn.query(
                    `SELECT id, purchase_date FROM credit_card_movements
                    WHERE user_id = $1 AND recurrence_id = $2 AND status_movement = 'ativa' AND id != $3 AND purchase_date > $4`,
                    [userId, recurrenceId, id, data.purchase_date]
                )
            
                for (const row of futureMovements.rows) {

                    const rowDate = new Date(row.purchase_date) 
                    const rowMonth = rowDate.getMonth() + 1
                    const rowYear = rowDate.getFullYear()
                            
                    const existingRowInvoice = await conn.query(
                        `SELECT id FROM credit_card_invoices WHERE credit_card_id = $1 AND invoice_month = $2 AND invoice_year = $3`,
                        [data.credit_card_id, rowMonth, rowYear]
                    )

                    let rowInvoiceId: number

                    if (existingRowInvoice.rows.length) {
                        rowInvoiceId = existingRowInvoice.rows[0].id
                    } else {
                        const rowClosingDate = new Date(rowYear, rowMonth - 1, data.closingDay ?? 1)
                        const newRowInvoice = await conn.query(
                            `INSERT INTO credit_card_invoices(credit_card_id, invoice_month, invoice_year, status_invoice, closing_date, total_value)
                            VALUES($1, $2, $3, $4, $5, $6)
                            RETURNING id`,
                            [data.credit_card_id, rowMonth, rowYear, 'parcial', rowClosingDate, null]
                        )

                        rowInvoiceId = newRowInvoice.rows[0].id
                    }

                    await conn.query(
                    `UPDATE credit_card_movements
                        SET 
                            value_transaction = $1,
                            description_credit = $2,
                            categorie_id = $3,
                            credit_card_id = $4,
                            invoice_id = $5,
                            observation = $6,
                            status_movement = $7
                        WHERE id = $8 AND user_id = $9
                    `, [data.value_transaction, data.description_credit, data.categorie_id, data.credit_card_id, rowInvoiceId, data.observation, data.status_movement, row.id, userId])

                    if (data.status_movement === 'deletada') {
                        await conn.query(`DELETE FROM movements WHERE user_id = $1 AND movement_credit_card_id = $2`, [userId, row.id])
                    }

                }

            } else if (choiceOption === "todas") {

                const statusValues = ['ativa', 'estorno', 'estornada']

                await conn.query( 
                `UPDATE credit_card_movements
                    SET 
                        description_credit = $1,
                        categorie_id = $2,
                        observation = $3,
                        status_movement = $4
                    WHERE user_id = $5 AND recurrence_id = $6 AND status_movement = ANY($7)
                `, [data.description_credit, data.categorie_id, data.observation, data.status_movement, userId, recurrenceId, statusValues])

            }

            await conn.query('COMMIT')

        } catch (error) {

            await client.query('ROLLBACK')
            throw error

        } finally {

            conn.release()  
        }


    },
}