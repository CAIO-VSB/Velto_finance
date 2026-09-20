import client from "~/utils/db"
import { type TGoalsPayload } from "~~/schemas/goals.schema"
import { type TGoalsMovementsPayload } from "~~/schemas/goalsMovements.schema"

export const goalsRepository = {

    async create(userId: string, data: TGoalsPayload) {

        const conn = await client.connect() 

        try {
            
            await conn.query('BEGIN')

            const result = await conn.query(`
                INSERT INTO goals(user_id, name_identifier, suggested_value, goal_value, start_date, end_date, active, value_initial) 
                VALUES($1, $2, $3, $4, $5, $6, $7, $8) 
                RETURNING id`,[userId, data.name_identifier, data.suggested_value, data.goal_value, data.start_date, data.end_date, data.active, data.value_initial]
            )

            const idGoals = result.rows[0].id

            if (data.value_initial) {
                await conn.query(`
                    INSERT INTO goals_movements(goals_id, description, value_paid, date_movement, accounts_id) 
                    VALUES($1, $2, $3, $4, $5) 
                    RETURNING id`,[idGoals, 'Saldo inicial', data.value_initial, data.start_date, null]
                )
            }

            await conn.query('COMMIT')

            return { message: "Economia criada com sucesso" }

        } catch (error) {
            await conn.query('ROLLBACK')
            throw error
        } finally {
            conn.release()  
        }

    },

    async findAll(userId: string) {

        const conn = await client.connect() 

        try {
            
            await conn.query('BEGIN')

            const result = await conn.query(`
                SELECT * FROM goals WHERE user_id = $1
            `,[userId]
            )

            await conn.query('COMMIT')

            return result.rows

        } catch (error) {
            await conn.query('ROLLBACK')
            throw error
        } finally {
            conn.release()  
        }

    },

    async update(userId: string, id: number, data: TGoalsPayload) {

        const conn = await client.connect() 

        try {
            
            await conn.query('BEGIN')

            await conn.query(`
                UPDATE goals
                    SET name_identifier = $1,
                        suggested_value = $2,
                        goal_value = $3,
                        start_date = $4,
                        end_date = $5,
                        value_initial = $6
                    WHERE id = $7 AND user_id = $8
                `,[data.name_identifier, data.suggested_value, data.goal_value, data.start_date, data.end_date, data.value_initial, id, userId]
            )

            const existing = await conn.query(`
                SELECT id FROM goals_movements
                WHERE goals_id = $1 AND description = 'Saldo inicial' AND accounts_id IS NULL
            `, [id])

            if (data.value_initial) {
                if (existing.rows.length > 0) {
                    // já existia -> atualiza valor e data
                    await conn.query(`
                        UPDATE goals_movements
                            SET value_paid = $1, date_movement = $2
                            WHERE id = $3
                    `, [data.value_initial, data.start_date, existing.rows[0].id])
                } else {
                    // não existia -> cria agora
                    await conn.query(`
                        INSERT INTO goals_movements(goals_id, description, value_paid, date_movement, accounts_id) 
                        VALUES($1, $2, $3, $4, $5)
                    `, [id, 'Saldo inicial', data.value_initial, data.start_date, null])
                }
            } else if (existing.rows.length > 0) {
                // valor inicial foi zerado -> remove a movimentação
                await conn.query(`DELETE FROM goals_movements WHERE id = $1`, [existing.rows[0].id])
            }

            await conn.query('COMMIT')

            return { message: "Economia atualizada com sucesso" }

        } catch (error) {
            await conn.query('ROLLBACK')
            throw error
        } finally {
            conn.release()  
        }

    },

    async updateMovementsGoals(id: number, data: TGoalsMovementsPayload) {

        const conn = await client.connect() 

        try {
            
            await conn.query(`
                UPDATE goals_movements
                    SET goals_id = $1,
                        description = $2,
                        value_paid = $3,
                        date_movement = $4,
                        accounts_id = $5
                    WHERE id = $6
                `,[data.goals_id, data.description, data.value_paid, data.date_movement, data.accounts_id, id]
            )

            await conn.query('COMMIT')

            return { message: "Movimentação atualizada com sucesso" }

        } catch (error) {
            await conn.query('ROLLBACK')
            throw error
        } finally {
            conn.release()  
        }

    },

    async archive(userId: string, id: number, active: boolean) {

        const conn = await client.connect() 

        try {
            
            await conn.query(`
                UPDATE goals SET active = $1 WHERE id = $2 AND user_id = $3`,[active, id, userId]
            )

            await conn.query('COMMIT')

            return { message: "Economia atualizada com sucesso" }

        } catch (error) {
            await conn.query('ROLLBACK')
            throw error
        } finally {
            conn.release()  
        }

    },

    async createMovementsGoals(data: TGoalsMovementsPayload) {


        const conn = await client.connect() 

        try {
            
            await conn.query('BEGIN')

            await conn.query(`
                INSERT INTO goals_movements(goals_id, description, value_paid, date_movement, accounts_id, is_ignored) 
                VALUES($1, $2, $3, $4, $5, $6) 
                RETURNING id`,[data.goals_id, data.description, data.value_paid, data.date_movement, data.accounts_id, data.is_ignored]
            )

            await conn.query('COMMIT')

            return { message: "Movimentação de meta criada com sucesso" }

        } catch (error) {
            await conn.query('ROLLBACK')
            throw error
        } finally {
            conn.release()  
        }
        
    },

    async getAllMovementsGoals(userId: string,  goalsId: number, month: number, year: number) {

        const conn = await client.connect() 

        try {
            
            await conn.query('BEGIN')

            const text = 
            `SELECT * FROM fn_movements_goals($1, $2, $3, $4) ORDER BY date_movement ASC`

            const result = await conn.query(text, [userId, goalsId, month, year])

            await conn.query('COMMIT')

            return result.rows

        } catch (error) {
            await conn.query('ROLLBACK')
            throw error
        } finally {
            conn.release()  
        }
        
    },


    async getBalanceForGoals(userId: string) {

        const text = `
           SELECT g.id,
            COALESCE(v.total_lancado, 0) AS total_lancado,
            COALESCE(v.percentual, 0) AS percentual,
            COALESCE(v.meta, 0) AS meta
            FROM vw_balance_for_goals v
            LEFT JOIN goals g ON g.id = v.goals_id
            WHERE g.user_id = $1
        `

        const values = [userId]

        const goalsBalance = client.query(text, values)

        const result = (await goalsBalance).rows

        console.log("Valores da view rsrs " + JSON.stringify((await goalsBalance).rows))

        return result    
    },

    async deleteGoalsMovement(id: number) {

        await client.query(`
            DELETE FROM goals_movements WHERE id = $1
        `,[id])

        return {message: "Movimentaçõ deletada com sucesso"}
    },

}