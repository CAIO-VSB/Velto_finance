DROP FUNCTION public.fn_evolucao_saldo(character varying, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_evolucao_saldo(
	p_user_id character varying,
	p_month integer,
	p_year integer)
    RETURNS TABLE(mes_referencia date, saldo_acumulado numeric) 
    LANGUAGE 'sql'
    COST 100
    STABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
    WITH resultado_movements AS (
        SELECT
            date_trunc('month', m.date_transaction)::date AS mes,
            SUM(
                CASE
                    WHEN m.type_transaction = 'receita' AND m.status_transaction = 'recebido' THEN m.value_transaction
                    WHEN m.type_transaction IN ('despesa', 'pagamento_fatura') AND m.status_transaction = 'pago' THEN -m.value_transaction
                    ELSE 0
                END
            ) AS resultado_mes
        FROM movements m
        JOIN banks_accounts ba ON ba.id = m.accounts_id AND ba.active = true
        WHERE m.user_id = p_user_id
            AND m.is_deleted = false
            AND m.type_transaction != 'saldo inicial'
        GROUP BY date_trunc('month', m.date_transaction)
    ),
    resultado_goals AS (
        SELECT
            date_trunc('month', gm.date_movement)::date AS mes,
            SUM(gm.value_paid) AS valor_reservado
        FROM goals_movements gm
        JOIN goals g ON g.id = gm.goals_id
        LEFT JOIN banks_accounts ba ON ba.id = gm.accounts_id
        WHERE g.user_id = p_user_id
            AND gm.description != 'Saldo inicial'
            AND (ba.id IS NULL OR ba.active = true)
        GROUP BY date_trunc('month', gm.date_movement)
    ),
    saldo_inicial AS (
        SELECT COALESCE(SUM(m.value_transaction), 0) AS valor
        FROM movements m
        JOIN banks_accounts ba ON ba.id = m.accounts_id AND ba.active = true
        WHERE m.user_id = p_user_id
            AND m.is_deleted = false
            AND m.type_transaction = 'saldo inicial'
    ),
    meses_unificados AS (
        SELECT mes FROM resultado_movements
        UNION
        SELECT mes FROM resultado_goals
    ),
    resultado_por_mes AS (
        SELECT
            mu.mes,
            COALESCE(rm.resultado_mes, 0) AS resultado_mes,
            COALESCE(rg.valor_reservado, 0) AS valor_reservado
        FROM meses_unificados mu
        LEFT JOIN resultado_movements rm ON rm.mes = mu.mes
        LEFT JOIN resultado_goals rg ON rg.mes = mu.mes
    ),
    acumulado AS (
        SELECT
            rpm.mes,
            (SELECT valor FROM saldo_inicial)
                + SUM(rpm.resultado_mes) OVER (ORDER BY rpm.mes)
                - SUM(rpm.valor_reservado) OVER (ORDER BY rpm.mes) AS saldo_acumulado
        FROM resultado_por_mes rpm
    )

    SELECT mes, saldo_acumulado
    FROM acumulado
    WHERE mes BETWEEN (make_date(p_year, p_month, 1) - interval '5 months')::date
                   AND make_date(p_year, p_month, 1)
    ORDER BY mes;
$BODY$;

ALTER FUNCTION public.fn_evolucao_saldo(character varying, integer, integer)
    OWNER TO postgres;