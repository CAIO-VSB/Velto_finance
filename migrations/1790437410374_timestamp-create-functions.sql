-- ============================================================================
-- MIGRATION: Consolidação de Functions e Views
-- ============================================================================
-- Este arquivo agrupa todas as funções e views criadas manualmente via pgAdmin.
-- Todas as funções usam CREATE OR REPLACE, portanto são seguras para re-execução.
--
-- ÍNDICE:
--   [Cartão de Crédito]
--     1. fn_credit_card_invoice_total
--     2. fn_credit_card_movements
--     3. fn_dashboard_total_credit_card
--
--   [Saldo / Dashboard]
--     4. fn_current_balance
--     5. fn_dashboard_summary
--     6. fn_despesas_por_categoria
--     7. fn_receitas_por_categoria
--     8. fn_evolucao_saldo
--     9. fn_gastos_3_meses
--
--   [Movimentações]
--     10. fn_last_movements
--     11. fn_movements
--     12. fn_movements_filter
--     13. fn_movements_only_expenses
--     14. fn_movements_only_expenses_by_filter
--     15. fn_movements_only_revenues
--     16. fn_movements_only_revenues_by_filter
--
--   [Metas]
--     17. fn_movements_goals
--
--   [Transferências]
--     18. fn_transfer
--
--   [Faturas / Notificações]
--     19. fn_info_invoice_by_email
--     20. fn_refresh_invoice_status
--
--   [Views]
--     21. vw_balance_for_account
--     22. vw_balance_for_goals
-- ============================================================================


-- ============================================================================
-- SEÇÃO: CARTÃO DE CRÉDITO
-- ============================================================================

-- FUNCTION: public.fn_credit_card_invoice_total(character varying, integer, integer, integer, integer)

-- DROP FUNCTION IF EXISTS public.fn_credit_card_invoice_total(character varying, integer, integer, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_credit_card_invoice_total(
	p_user_id character varying,
	p_month integer,
	p_year integer,
	p_credit_card_id integer,
	p_invoice_id integer)
    RETURNS numeric
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
    SELECT COALESCE(
		SUM(
			CASE 
				WHEN status_movement IN ('estorno', 'adiantado', 'parcial') THEN -value_transaction 
				ELSE value_transaction 
			END),
			0	
		)
	FROM credit_card_movements
	WHERE invoice_id = p_invoice_id AND status_movement IN ('ativa', 'estorno', 'estornada', 'adiantado', 'parcial')
$BODY$;

ALTER FUNCTION public.fn_credit_card_invoice_total(character varying, integer, integer, integer, integer)
    OWNER TO postgres;


-- FUNCTION: public.fn_credit_card_movements(character varying, integer, integer)

-- DROP FUNCTION IF EXISTS public.fn_credit_card_movements(character varying, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_credit_card_movements(
	p_user_id character varying,
	p_credit_card_id integer,
	p_invoice_id integer)
    RETURNS TABLE(id integer, user_id character varying, credit_card_id integer, invoice_id integer, categorie_id integer, categorie_name character varying, description_credit character varying, value_transaction numeric, purchase_date date, installment_number integer, recurrence_id integer, status_movement character varying, observation character varying, total_installments integer, type_recurrence character varying, status_invoice character varying, id_invoice integer, installment_total integer, invoice_month integer, invoice_year integer, refund_of_movement_id integer, description_reversal character varying) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN 
    RETURN QUERY 
    SELECT 
		cc.id,
		cc.user_id,
		cc.credit_card_id,
		cc.invoice_id, 
		cc.categorie_id,
		c.name_identifier AS categorie_name,
		cc.description_credit,
		cc.value_transaction,
		cc.purchase_date,
		cc.installment_number,
		cc.recurrence_id,
		cc.status_movement,
		cc.observation,
		r.total_installments,
		r.type_recurrence,
		ci.status_invoice,
		ci.id as id_invoice,
		cc.installment_total,
		ci.invoice_month,
		ci.invoice_year,
		cc.refund_of_movement_id,
		cc.description_reversal
    FROM credit_card_movements cc
    LEFT JOIN categories c ON c.id = cc.categorie_id
	LEFT JOIN recurrence r ON r.id = cc.recurrence_id
	INNER JOIN credit_card_invoices ci ON ci.id = cc.invoice_id
    WHERE cc.user_id = p_user_id 
		AND cc.credit_card_id = p_credit_card_id
		AND ci.id = p_invoice_id;
END;
$BODY$;

ALTER FUNCTION public.fn_credit_card_movements(character varying, integer, integer)
    OWNER TO postgres;


-- FUNCTION: public.fn_dashboard_total_credit_card(character varying, integer, integer)

-- DROP FUNCTION IF EXISTS public.fn_dashboard_total_credit_card(character varying, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_dashboard_total_credit_card(
	p_user_id character varying,
	p_month integer,
	p_year integer)
    RETURNS TABLE(t_cartoes numeric) 
    LANGUAGE 'sql'
    COST 100
    STABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
    SELECT
        COALESCE(SUM(ccm.value_transaction), 0.00) AS t_cartoes
    FROM credit_card_movements ccm
    JOIN credit_card_invoices cci
        ON cci.id = ccm.invoice_id
    JOIN credit_cards cc
        ON cc.id = cci.credit_card_id
    WHERE cc.user_id = p_user_id
        AND ccm.status_movement != 'deletada'
        AND cci.invoice_month = p_month
        AND cci.invoice_year = p_year
        AND cci.status_invoice IN ('aberta', 'paga', 'parcial', 'fechada', 'vencida')
$BODY$;

ALTER FUNCTION public.fn_dashboard_total_credit_card(character varying, integer, integer)
    OWNER TO postgres;


-- ============================================================================
-- SEÇÃO: SALDO / DASHBOARD
-- ============================================================================

-- FUNCTION: public.fn_current_balance(character varying)

-- DROP FUNCTION IF EXISTS public.fn_current_balance(character varying);

CREATE OR REPLACE FUNCTION public.fn_current_balance(
	p_user_id character varying)
    RETURNS numeric
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE 
	v_saldo_atual numeric(10, 2);
BEGIN 
 
  WITH saldo_movimentos AS (
	         SELECT COALESCE(sum(
                CASE
                    WHEN m.type_transaction::text = 'saldo inicial'::text THEN m.value_transaction
                    ELSE 0::numeric
                END), 0::numeric) + COALESCE(sum(
                CASE
                    WHEN m.type_transaction::text = 'transferencia_entrada'::text AND m.status_transaction::text = 'entrada'::text THEN m.value_transaction
                    ELSE 0::numeric
                END), 0::numeric) + COALESCE(sum(
                CASE
                    WHEN m.type_transaction::text = 'receita'::text AND m.status_transaction::text = 'recebido'::text THEN m.value_transaction
                    ELSE 0::numeric
                END), 0::numeric) - COALESCE(sum(
                CASE
                    WHEN m.type_transaction::text = 'transferencia_saida'::text AND m.status_transaction::text = 'saida'::text THEN m.value_transaction
                    ELSE 0::numeric
                END), 0::numeric) - COALESCE(sum(
                CASE
                    WHEN m.type_transaction::text = 'despesa'::text AND m.status_transaction::text = 'pago'::text THEN m.value_transaction
                    ELSE 0::numeric
                END), 0::numeric) - COALESCE(sum(
                CASE
                    WHEN m.type_transaction::text = 'pagamento_fatura'::text AND m.status_transaction::text = 'pago'::text THEN m.value_transaction
                    ELSE 0::numeric
                END), 0::numeric) AS saldo_movimentos
          FROM movements m
          WHERE m.is_deleted = false AND m.user_id = p_user_id 
  		),

		saldo_meta AS (
         SELECT COALESCE(sum(gm.value_paid), 0::numeric) AS total_metas
          FROM goals_movements gm
		  LEFT JOIN goals g ON g.id = gm.goals_id
         WHERE g.user_id = p_user_id AND gm.description != 'Saldo inicial' AND COALESCE(gm.is_ignored, false) = false
		 )

		  SELECT COALESCE(sm.saldo_movimentos, 0::numeric) - COALESCE(smt.total_metas, 0::numeric) AS saldo_atual
		  INTO v_saldo_atual
		   FROM saldo_movimentos sm, saldo_meta smt;

		   RETURN v_saldo_atual;
END;
$BODY$;

ALTER FUNCTION public.fn_current_balance(character varying)
    OWNER TO postgres;


-- FUNCTION: public.fn_dashboard_summary(character varying, integer, integer)

-- DROP FUNCTION IF EXISTS public.fn_dashboard_summary(character varying, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_dashboard_summary(
	p_user_id character varying,
	p_month integer,
	p_year integer)
    RETURNS TABLE(t_receitas numeric, t_despesas numeric, balanco_mensal numeric) 
    LANGUAGE 'sql'
    COST 100
    STABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
    SELECT

        COALESCE(
            SUM(
                CASE
                    WHEN type_transaction = 'receita'
                    THEN value_transaction
                END
            ),
            0.00
        ) AS t_receitas,

        COALESCE(
            SUM(
                CASE
                    WHEN type_transaction IN ('despesa', 'pagamento_fatura')
                    THEN value_transaction
                END
            ),
            0.00
        ) AS t_despesas,

        COALESCE(
            SUM(
                CASE
                    WHEN type_transaction = 'receita'
                    THEN value_transaction
                END
            ),
            0.00
        )
        -
        COALESCE(
            SUM(
                CASE
                    WHEN type_transaction IN ('despesa', 'pagamento_fatura')
                    THEN value_transaction
                END
            ),
            0.00
        ) AS balanco_mensal

    FROM movements

    WHERE user_id = p_user_id
        AND is_deleted = false
        AND type_transaction != 'saldo inicial'
        AND EXTRACT(MONTH FROM date_transaction) = p_month
        AND EXTRACT(YEAR FROM date_transaction) = p_year;
$BODY$;

ALTER FUNCTION public.fn_dashboard_summary(character varying, integer, integer)
    OWNER TO postgres;


-- FUNCTION: public.fn_despesas_por_categoria(character varying, integer, integer)

-- DROP FUNCTION IF EXISTS public.fn_despesas_por_categoria(character varying, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_despesas_por_categoria(
	p_user_id character varying,
	p_month integer,
	p_year integer)
    RETURNS TABLE(categoria character varying, valor numeric) 
    LANGUAGE 'sql'
    COST 100
    STABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
    SELECT
        COALESCE(c.name_identifier, 'Sem categoria') AS categoria,
        COALESCE(SUM(m.value_transaction), 0.00) AS valor
    FROM movements m
    LEFT JOIN categories c ON c.id = m.categorie_id
    WHERE m.type_transaction IN ('despesa', 'pagamento_fatura')
      AND m.user_id = p_user_id
      AND m.is_deleted = false
      AND EXTRACT(MONTH FROM m.date_transaction) = p_month
      AND EXTRACT(YEAR FROM m.date_transaction) = p_year
    GROUP BY c.name_identifier
    ORDER BY valor DESC;
$BODY$;

ALTER FUNCTION public.fn_despesas_por_categoria(character varying, integer, integer)
    OWNER TO postgres;


-- FUNCTION: public.fn_receitas_por_categoria(character varying, integer, integer)

-- DROP FUNCTION IF EXISTS public.fn_receitas_por_categoria(character varying, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_receitas_por_categoria(
	p_user_id character varying,
	p_month integer,
	p_year integer)
    RETURNS TABLE(categoria character varying, valor numeric) 
    LANGUAGE 'sql'
    COST 100
    STABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
    SELECT
        COALESCE(c.name_identifier, 'Sem categoria') AS categoria,
        COALESCE(SUM(m.value_transaction), 0.00) AS valor
    FROM movements m
    LEFT JOIN categories c ON c.id = m.categorie_id
    WHERE m.type_transaction = 'receita'
      AND m.user_id = p_user_id
      AND m.is_deleted = false
      AND EXTRACT(MONTH FROM m.date_transaction) = p_month
      AND EXTRACT(YEAR FROM m.date_transaction) = p_year
    GROUP BY c.name_identifier
    ORDER BY valor DESC;
$BODY$;

ALTER FUNCTION public.fn_receitas_por_categoria(character varying, integer, integer)
    OWNER TO postgres;


-- FUNCTION: public.fn_evolucao_saldo(character varying, integer, integer)

-- DROP FUNCTION IF EXISTS public.fn_evolucao_saldo(character varying, integer, integer);

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
        WHERE g.user_id = p_user_id
			AND gm.description != 'Saldo inicial'
        GROUP BY date_trunc('month', gm.date_movement)
    ),
    saldo_inicial AS (
        SELECT COALESCE(SUM(m.value_transaction), 0) AS valor
        FROM movements m
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


-- FUNCTION: public.fn_gastos_3_meses(character varying, integer, integer)

-- DROP FUNCTION IF EXISTS public.fn_gastos_3_meses(character varying, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_gastos_3_meses(
	p_user_id character varying,
	p_month integer,
	p_year integer)
    RETURNS TABLE(mes_referencia date, total numeric) 
    LANGUAGE 'sql'
    COST 100
    STABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
    WITH periodo AS (
		SELECT 
			(make_date(p_year, p_month, 1) - interval '2 months')::date AS inicio,
			(make_date(p_year, p_month, 1) + interval '1 months' - interval '1 day')::date AS fim
		)

		SELECT 
		date_trunc('month', m.date_transaction)::date AS mes_referencia,
		COALESCE(SUM(m.value_transaction), 0.00)
		FROM movements m, periodo p
		WHERE m.user_id = p_user_id
			AND m.type_transaction IN ('despesa', 'pagamento_fatura')
      		AND m.is_deleted = false
			AND m.date_transaction BETWEEN p.inicio AND p.fim
		GROUP BY date_trunc('month', m.date_transaction)
		ORDER BY mes_referencia
$BODY$;

ALTER FUNCTION public.fn_gastos_3_meses(character varying, integer, integer)
    OWNER TO postgres;


-- ============================================================================
-- SEÇÃO: MOVIMENTAÇÕES
-- ============================================================================

-- FUNCTION: public.fn_last_movements(character varying, integer, integer)

-- DROP FUNCTION IF EXISTS public.fn_last_movements(character varying, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_last_movements(
	p_user_id character varying,
	p_month integer,
	p_year integer)
    RETURNS TABLE(id integer, date_transaction date, description_transaction character varying, value_transaction numeric, type_transaction character varying, status_transaction character varying, name_accounts character varying, installment_current integer, total_installments integer, type_recurrence character varying) 
    LANGUAGE 'sql'
    COST 100
    STABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
		SELECT 
		m.id,
		m.date_transaction,
		m.description_transaction,
		m.value_transaction,
		m.type_transaction,
		m.status_transaction,
		ba.name_identifier as name_accounts,
		m.installment_current,
		r.total_installments,
		r.type_recurrence
		FROM movements m
		LEFT JOIN banks_accounts ba ON ba.id = m.accounts_id
		LEFT JOIN recurrence r ON r.id = m.recurrence_id
		WHERE m.user_id = p_user_id
      		AND m.is_deleted = false
			AND m.type_transaction != 'saldo inicial'
			AND EXTRACT(MONTH FROM m.date_transaction) = p_month
    		AND EXTRACT(YEAR FROM m.date_transaction) = p_year
		ORDER BY m.date_transaction DESC, m.id DESC
$BODY$;

ALTER FUNCTION public.fn_last_movements(character varying, integer, integer)
    OWNER TO postgres;


-- FUNCTION: public.fn_movements(character varying, integer, integer)

-- DROP FUNCTION IF EXISTS public.fn_movements(character varying, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_movements(
	p_user_id character varying,
	p_month integer,
	p_year integer)
    RETURNS TABLE(t_receitas numeric, t_despesas numeric, balanco_mensal numeric, date_transaction date, description_transaction character varying, categorie_name character varying, account_name character varying, value_transaction numeric, status_transaction character varying, user_id character varying, accounts_id integer, categorie_id integer, type_transaction character varying, id integer, observation character varying, is_deleted boolean, transfer_id integer, installment_current integer, total_installments integer, type_recurrence character varying, recurrence_id integer, credit_card_name character varying, status_fatura character varying, url_recibo character varying) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

BEGIN 
    RETURN QUERY 
    WITH 
    total_receitas AS (
        SELECT 
			COALESCE(SUM(m_3.value_transaction), 0.00) AS t_receitas
        FROM movements m_3
        WHERE m_3.type_transaction  = 'receita'
        	AND m_3.user_id = p_user_id 
			AND m_3.is_deleted = false
        	AND EXTRACT(MONTH FROM m_3.date_transaction) = p_month
        	AND EXTRACT(YEAR FROM m_3.date_transaction) = p_year
    ), 
	
    total_despesas AS (
        SELECT 
		COALESCE(SUM(m_2.value_transaction), 0.00) AS t_despesas
        FROM movements m_2
        WHERE m_2.type_transaction IN ('despesa', 'pagamento_fatura')
			AND m_2.is_deleted = false
			AND m_2.user_id = p_user_id 
        	AND EXTRACT(MONTH FROM m_2.date_transaction) = p_month
        	AND EXTRACT(YEAR FROM m_2.date_transaction) = p_year
    )
	
    SELECT 
        total_receitas.t_receitas,
        total_despesas.t_despesas,
        total_receitas.t_receitas - total_despesas.t_despesas AS balanco_mensal,
        m.date_transaction,
        m.description_transaction,
        c.name_identifier AS categorie_name,
        a.name_identifier AS account_name,
        m.value_transaction,
        m.status_transaction,
        m.user_id,
        m.accounts_id,
        m.categorie_id,
        m.type_transaction,
		m.id,
		m.observation,
		m.is_deleted,
		m.transfer_id,
		m.installment_current,
		r.total_installments,
		r.type_recurrence,
		m.recurrence_id,
		cc.name_identifier AS credit_card_name,
		ci.status_invoice as status_fatura,
		m.url_recibo
    FROM movements m
    LEFT JOIN categories c ON c.id = m.categorie_id
    LEFT JOIN banks_accounts a ON a.id = m.accounts_id
	LEFT JOIN recurrence r ON r.id = m.recurrence_id
	LEFT JOIN credit_card_movements ca ON ca.id = m.invoice_id
	LEFT JOIN credit_card_invoices ci ON ci.id = m.invoice_id
	LEFT JOIN credit_cards cc ON cc.id = ci.credit_card_id,
    total_receitas,
    total_despesas
    WHERE NOT m.type_transaction = 'saldo inicial' 
		AND m.is_deleted = false
    	AND m.user_id = p_user_id 
    	AND m.user_id = p_user_id 
    	AND EXTRACT(MONTH FROM m.date_transaction) = p_month
    	AND EXTRACT(YEAR FROM m.date_transaction) = p_year;
END;
$BODY$;

ALTER FUNCTION public.fn_movements(character varying, integer, integer)
    OWNER TO postgres;


-- FUNCTION: public.fn_movements_filter(character varying, date, date, integer[], integer[], character varying, character varying[])

-- DROP FUNCTION IF EXISTS public.fn_movements_filter(character varying, date, date, integer[], integer[], character varying, character varying[]);

CREATE OR REPLACE FUNCTION public.fn_movements_filter(
	p_user_id character varying,
	p_start_day date,
	p_end_day date,
	p_categorie_id integer[],
	p_accounts_id integer[],
	p_situation character varying,
	p_for_type character varying[])
    RETURNS TABLE(t_receitas numeric, t_despesas numeric, balanco_mensal numeric, saldo_atual numeric, date_transaction date, description_transaction character varying, categorie_name character varying, account_name character varying, value_transaction numeric, status_transaction character varying, user_id character varying, accounts_id integer, categorie_id integer, type_transaction character varying, id integer, observation character varying, is_deleted boolean, credit_card_name character varying) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN 
    RETURN QUERY 
    WITH 
    total_receitas AS (
        SELECT COALESCE(SUM(m_3.value_transaction), 0.00) AS t_receitas
        	FROM movements m_3
				WHERE m_3.user_id = p_user_id 
					AND m_3.is_deleted = false
					AND (p_categorie_id IS NULL OR m_3.categorie_id = ANY(p_categorie_id))
					AND (p_accounts_id IS NULL OR m_3.accounts_id = ANY(p_accounts_id))
					AND (p_start_day IS NULL OR m_3.date_transaction >= p_start_day)
					AND (p_end_day IS NULL OR m_3.date_transaction <= p_end_day)
		    		AND m_3.type_transaction = 'receita'   
					AND m_3.status_transaction = 'recebido' 
    ), 
	
    total_despesas AS (
        SELECT COALESCE(SUM(m_2.value_transaction), 0.00) AS t_despesas
        	FROM movements m_2
        		WHERE m_2.type_transaction IN ('despesa', 'pagamento_fatura')
    				AND m_2.status_transaction = 'pago'  
					AND m_2.is_deleted = false
					AND m_2.user_id = p_user_id 
					AND (p_categorie_id IS NULL OR m_2.categorie_id = ANY(p_categorie_id))
					AND (p_accounts_id IS NULL OR m_2.accounts_id = ANY(p_accounts_id))
					AND (p_start_day IS NULL OR m_2.date_transaction >= p_start_day)
					AND (p_end_day IS NULL OR m_2.date_transaction <= p_end_day)
	), 
	
    valor_saldo_atual AS (
        SELECT COALESCE(SUM(CASE WHEN m3.type_transaction = 'saldo inicial' THEN m3.value_transaction ELSE 0 END), 0.00) +
	 		COALESCE(SUM(CASE WHEN m3.type_transaction = 'receita' AND m3.status_transaction = 'recebido' THEN m3.value_transaction ELSE 0 END  ), 0.00) -
		 	COALESCE(SUM(CASE WHEN m3.type_transaction = 'despesa' AND m3.status_transaction = 'pago' THEN m3.value_transaction ELSE 0 END), 0.00) AS saldo_atual
		FROM movements m3
		WHERE m3.user_id = p_user_id
			AND m3.is_deleted = false
    )
	
    SELECT 
        total_receitas.t_receitas,
        total_despesas.t_despesas,
        total_receitas.t_receitas - total_despesas.t_despesas AS balanco_mensal,
        valor_saldo_atual.saldo_atual,
        m.date_transaction,
        m.description_transaction,
        c.name_identifier AS categorie_name,
        a.name_identifier AS account_name,
        m.value_transaction,
        m.status_transaction,
        m.user_id,
        m.accounts_id,
        m.categorie_id,
        m.type_transaction,
		m.id,
		m.observation,
		m.is_deleted,
		cc.name_identifier AS credit_card_name
    FROM movements m
    LEFT JOIN categories c ON c.id = m.categorie_id
    LEFT JOIN banks_accounts a ON a.id = m.accounts_id
	LEFT JOIN recurrence r ON r.id = m.recurrence_id
	LEFT JOIN credit_card_movements ca ON ca.id = m.invoice_id
	LEFT JOIN credit_card_invoices ci ON ci.id = m.invoice_id
	LEFT JOIN credit_cards cc ON cc.id = ci.credit_card_id,
    total_receitas,
    total_despesas,
    valor_saldo_atual
    WHERE NOT m.type_transaction = 'saldo inicial' 
	AND m.is_deleted = false
    AND m.user_id = p_user_id 
    AND (p_categorie_id IS NULL OR m.categorie_id = ANY(p_categorie_id))
	AND (p_accounts_id IS NULL OR m.accounts_id = ANY(p_accounts_id))
	AND (p_situation IS NULL OR m.status_transaction = p_situation)
	AND (p_for_type IS NULL OR m.type_transaction = ANY(p_for_type))
	AND (p_start_day IS NULL OR m.date_transaction >= p_start_day)
	AND (p_end_day IS NULL OR m.date_transaction <= p_end_day);
END
$BODY$;

ALTER FUNCTION public.fn_movements_filter(character varying, date, date, integer[], integer[], character varying, character varying[])
    OWNER TO postgres;


-- FUNCTION: public.fn_movements_only_expenses(character varying, integer, integer)

-- DROP FUNCTION IF EXISTS public.fn_movements_only_expenses(character varying, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_movements_only_expenses(
	p_user_id character varying,
	p_month integer,
	p_year integer)
    RETURNS TABLE(t_despesas_efetivadas numeric, t_despesas_pendentes numeric, total_geral_despesas numeric, date_transaction date, description_transaction character varying, categorie_name character varying, account_name character varying, value_transaction numeric, status_transaction character varying, user_id character varying, type_transaction character varying, accounts_id integer, categorie_id integer, id integer, observation character varying, is_deleted boolean, installment_current integer, total_installments integer, type_recurrence character varying, recurrence_id integer, credit_card_name character varying, movement_credit_card_id integer, status_fatura character varying, url_recibo character varying) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN 
 	RETURN QUERY 
	
	WITH 
	
	total_despesas_efetivadas AS (
         SELECT COALESCE(sum(movements.value_transaction), 0.00) AS t_despesas_efetivadas
           FROM movements
          WHERE movements.type_transaction IN ('despesa', 'pagamento_fatura')
		  AND movements.status_transaction::text = 'pago'::text
		  AND movements.user_id = p_user_id 
		  AND movements.is_deleted = false
		  AND EXTRACT(MONTH FROM movements.date_transaction) = p_month
		  AND EXTRACT(YEAR FROM movements.date_transaction) = p_year
        ), 
		
		total_despesas_pendentes AS (
         SELECT COALESCE(sum(movements.value_transaction), 0.00) AS t_despesas_pendentes
           FROM movements
          WHERE movements.type_transaction IN ('despesa', 'pagamento_fatura')
		  AND movements.status_transaction::text = 'pendente'::text
		  AND movements.user_id = p_user_id 
		  AND movements.is_deleted = false
		  AND EXTRACT(MONTH FROM movements.date_transaction) = p_month
		  AND EXTRACT(YEAR FROM movements.date_transaction) = p_year
        )
		
		SELECT 
		total_despesas_efetivadas.t_despesas_efetivadas,
		total_despesas_pendentes.t_despesas_pendentes,
		total_despesas_efetivadas.t_despesas_efetivadas + total_despesas_pendentes.t_despesas_pendentes AS total_geral_despesas,
		m.date_transaction,
		m.description_transaction,
		c.name_identifier AS categorie_name,
		a.name_identifier AS account_name,
		m.value_transaction,
		m.status_transaction,
		m.user_id,
		m.type_transaction,
		m.accounts_id,
        m.categorie_id,
		m.id,
		m.observation,
		m.is_deleted,
		m.installment_current,
		r.total_installments,
		r.type_recurrence,
		m.recurrence_id,
		cc.name_identifier AS credit_card_name,
		m.movement_credit_card_id,
		ci.status_invoice as status_fatura,
        m.url_recibo
	   FROM movements m
		 LEFT JOIN categories c ON c.id = m.categorie_id
		 LEFT JOIN banks_accounts a ON a.id = m.accounts_id
		 LEFT JOIN recurrence r ON r.id = m.recurrence_id
		 LEFT JOIN credit_card_movements ca ON ca.id = m.movement_credit_card_id
         LEFT JOIN credit_card_invoices ci ON ci.id = m.invoice_id
         LEFT JOIN credit_cards cc ON cc.id = ci.credit_card_id,
		total_despesas_efetivadas,
		total_despesas_pendentes
	  WHERE NOT m.type_transaction::text = 'saldo inicial'::text 
	  AND m.type_transaction IN ('despesa', 'pagamento_fatura')
	  AND m.user_id = p_user_id 
	  AND m.is_deleted = false
	  AND EXTRACT(MONTH FROM m.date_transaction) = p_month
	  AND EXTRACT(YEAR FROM m.date_transaction) = p_year;
 END
$BODY$;

ALTER FUNCTION public.fn_movements_only_expenses(character varying, integer, integer)
    OWNER TO postgres;


-- FUNCTION: public.fn_movements_only_expenses_by_filter(character varying, date, date, integer[], integer[], character varying, character varying[])

-- DROP FUNCTION IF EXISTS public.fn_movements_only_expenses_by_filter(character varying, date, date, integer[], integer[], character varying, character varying[]);

CREATE OR REPLACE FUNCTION public.fn_movements_only_expenses_by_filter(
	p_user_id character varying,
	p_start_day date,
	p_end_day date,
	p_categorie_id integer[],
	p_accounts_id integer[],
	p_situation character varying,
	p_for_type character varying[])
    RETURNS TABLE(t_despesas_efetivadas numeric, t_despesas_pendentes numeric, total_geral_despesas numeric, date_transaction date, description_transaction character varying, categorie_name character varying, account_name character varying, value_transaction numeric, status_transaction character varying, user_id character varying, type_transaction character varying, accounts_id integer, categorie_id integer, id integer, observation character varying, is_deleted boolean, credit_card_name character varying) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN 
 	RETURN QUERY 
	
	WITH 
	
	total_despesas_efetivadas AS (
         SELECT COALESCE(sum(movements.value_transaction), 0.00) AS t_despesas_efetivadas
           FROM movements
          WHERE movements.type_transaction IN ('despesa', 'pagamento_fatura')
		  AND movements.status_transaction::text = 'pago'::text
		  AND movements.user_id = p_user_id 
		  AND movements.is_deleted = false
		  AND (p_categorie_id IS NULL OR movements.categorie_id = ANY(p_categorie_id))
		  AND (p_accounts_id IS NULL OR movements.accounts_id = ANY(p_accounts_id))
		  AND (p_start_day IS NULL OR movements.date_transaction >= p_start_day)
		  AND (p_end_day IS NULL OR movements.date_transaction <= p_end_day)
        ), 
		
		total_despesas_pendentes AS (
         SELECT COALESCE(sum(movements.value_transaction), 0.00) AS t_despesas_pendentes
           FROM movements
          WHERE movements.type_transaction IN ('despesa', 'pagamento_fatura')
		  AND movements.status_transaction::text = 'pendente'::text
		  AND movements.user_id = p_user_id 
		  AND movements.is_deleted = false
		  AND (p_categorie_id IS NULL OR movements.categorie_id = ANY(p_categorie_id))
		  AND (p_accounts_id IS NULL OR movements.accounts_id = ANY(p_accounts_id))
		  AND (p_start_day IS NULL OR movements.date_transaction >= p_start_day)
		  AND (p_end_day IS NULL OR movements.date_transaction <= p_end_day)
        )
		
		SELECT 
		total_despesas_efetivadas.t_despesas_efetivadas,
		total_despesas_pendentes.t_despesas_pendentes,
		total_despesas_efetivadas.t_despesas_efetivadas + total_despesas_pendentes.t_despesas_pendentes AS total_geral_despesas,
		m.date_transaction,
		m.description_transaction,
		c.name_identifier AS categorie_name,
		a.name_identifier AS account_name,
		m.value_transaction,
		m.status_transaction,
		m.user_id,
		m.type_transaction,
		m.accounts_id,
        m.categorie_id,
		m.id,
		m.observation,
		m.is_deleted,
		cc.name_identifier AS credit_card_name
	   FROM movements m
		 JOIN categories c ON c.id = m.categorie_id
		 JOIN banks_accounts a ON a.id = m.accounts_id
		 LEFT JOIN recurrence r ON r.id = m.recurrence_id
		LEFT JOIN credit_card_movements ca ON ca.id = m.invoice_id
		LEFT JOIN credit_card_invoices ci ON ci.id = m.invoice_id
		LEFT JOIN credit_cards cc ON cc.id = ci.credit_card_id,
		total_despesas_efetivadas,
		total_despesas_pendentes
	  WHERE NOT m.type_transaction::text = 'saldo inicial'::text 
	  AND m.type_transaction IN ('despesa', 'pagamento_fatura')
	  AND m.user_id = p_user_id 
	  AND m.is_deleted = false
	  AND (p_categorie_id IS NULL OR m.categorie_id = ANY(p_categorie_id))
	  AND (p_accounts_id IS NULL OR m.accounts_id = ANY(p_accounts_id))
	  AND (p_situation IS NULL OR m.status_transaction = p_situation)
	  AND (p_for_type IS NULL OR m.type_transaction = ANY(p_for_type))
	  AND (p_start_day IS NULL OR m.date_transaction >= p_start_day)
	  AND (p_end_day IS NULL OR m.date_transaction <= p_end_day);
 END
$BODY$;

ALTER FUNCTION public.fn_movements_only_expenses_by_filter(character varying, date, date, integer[], integer[], character varying, character varying[])
    OWNER TO postgres;


-- FUNCTION: public.fn_movements_only_revenues(character varying, integer, integer)

-- DROP FUNCTION IF EXISTS public.fn_movements_only_revenues(character varying, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_movements_only_revenues(
	p_user_id character varying,
	p_month integer,
	p_year integer)
    RETURNS TABLE(t_receitas_efetivadas numeric, t_receitas_pendentes numeric, total_geral_receitas numeric, date_transaction date, description_transaction character varying, categorie_name character varying, account_name character varying, value_transaction numeric, status_transaction character varying, user_id character varying, type_transaction character varying, accounts_id integer, categorie_id integer, id integer, observation character varying, is_deleted boolean, installment_current integer, total_installments integer, type_recurrence character varying, recurrence_id integer, url_recibo character varying) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN 
 
 	RETURN QUERY 
     WITH 
	 
	 total_receitas_efetivadas AS (
         SELECT COALESCE(sum(movements.value_transaction), 0.00) AS t_receitas_efetivadas
           FROM movements
          WHERE movements.type_transaction::text = 'receita'::text 
		  AND movements.status_transaction::text = 'recebido'::text
		  AND movements.is_deleted = false
		  AND movements.user_id = p_user_id 
		  AND EXTRACT(MONTH FROM movements.date_transaction) = p_month
		  AND EXTRACT(YEAR FROM movements.date_transaction) = p_year
        ), 
		
		total_receitas_pendentes AS (
         SELECT COALESCE(sum(movements.value_transaction), 0.00) AS t_receitas_pendentes
           FROM movements
          	WHERE movements.type_transaction::text = 'receita'::text 
			AND movements.status_transaction::text = 'pendente'::text
			AND movements.is_deleted = false
			AND movements.user_id = p_user_id 
		    AND EXTRACT(MONTH FROM movements.date_transaction) = p_month
		    AND EXTRACT(YEAR FROM movements.date_transaction) = p_year
        )
		
		SELECT 
		total_receitas_efetivadas.t_receitas_efetivadas,
		total_receitas_pendentes.t_receitas_pendentes,
		total_receitas_efetivadas.t_receitas_efetivadas + total_receitas_pendentes.t_receitas_pendentes AS total_geral_receitas,
		m.date_transaction,
		m.description_transaction,
		c.name_identifier AS categorie_name,
		a.name_identifier AS account_name,
		m.value_transaction,
		m.status_transaction,
		m.user_id,
		m.type_transaction,
		m.accounts_id,
        m.categorie_id,
		m.id,
		m.observation,
		m.is_deleted,
		m.installment_current,
		r.total_installments,
		r.type_recurrence,
		m.recurrence_id,
        m.url_recibo
  	   FROM movements m
		LEFT JOIN categories c ON c.id = m.categorie_id
		LEFT JOIN banks_accounts a ON a.id = m.accounts_id
		LEFT JOIN recurrence r ON r.id = m.recurrence_id,
		total_receitas_efetivadas,
		total_receitas_pendentes
	  WHERE NOT m.type_transaction::text = 'saldo inicial'::text 
	  AND m.type_transaction::text = 'receita'::text
	  AND m.is_deleted = false
	  AND m.user_id = p_user_id 
	  AND EXTRACT(MONTH FROM m.date_transaction) = p_month
	  AND EXTRACT(YEAR FROM m.date_transaction) = p_year;
 END
$BODY$;

ALTER FUNCTION public.fn_movements_only_revenues(character varying, integer, integer)
    OWNER TO postgres;


-- FUNCTION: public.fn_movements_only_revenues_by_filter(character varying, date, date, integer[], integer[], character varying, character varying[])

-- DROP FUNCTION IF EXISTS public.fn_movements_only_revenues_by_filter(character varying, date, date, integer[], integer[], character varying, character varying[]);

CREATE OR REPLACE FUNCTION public.fn_movements_only_revenues_by_filter(
	p_user_id character varying,
	p_start_day date,
	p_end_day date,
	p_categorie_id integer[],
	p_accounts_id integer[],
	p_situation character varying,
	p_for_type character varying[])
    RETURNS TABLE(t_receitas_efetivadas numeric, t_receitas_pendentes numeric, total_geral_receitas numeric, date_transaction date, description_transaction character varying, categorie_name character varying, account_name character varying, value_transaction numeric, status_transaction character varying, user_id character varying, type_transaction character varying, accounts_id integer, categorie_id integer, id integer, observation character varying, is_deleted boolean) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN 
 
 	RETURN QUERY 
     WITH 
	 
	 total_receitas_efetivadas AS (
         SELECT COALESCE(sum(movements.value_transaction), 0.00) AS t_receitas_efetivadas
           FROM movements
			  WHERE movements.type_transaction::text = 'receita'::text 
			  AND movements.status_transaction::text = 'recebido'::text
			  AND movements.is_deleted = false
			  AND movements.user_id = p_user_id 
			  AND (p_categorie_id IS NULL OR movements.categorie_id = ANY(p_categorie_id))
			  AND (p_accounts_id IS NULL OR movements.accounts_id = ANY(p_accounts_id))
			  AND (p_start_day IS NULL OR movements.date_transaction >= p_start_day)
			  AND (p_end_day IS NULL OR movements.date_transaction <= p_end_day)
        ), 
		
		total_receitas_pendentes AS (
         SELECT COALESCE(sum(movements.value_transaction), 0.00) AS t_receitas_pendentes
           FROM movements
          	WHERE movements.type_transaction::text = 'receita'::text 
			AND movements.status_transaction::text = 'pendente'::text
			AND movements.is_deleted = false
			AND movements.user_id = p_user_id 
		    AND (p_categorie_id IS NULL OR movements.categorie_id = ANY(p_categorie_id))
		    AND (p_accounts_id IS NULL OR movements.accounts_id = ANY(p_accounts_id))
		    AND (p_start_day IS NULL OR movements.date_transaction >= p_start_day)
		    AND (p_end_day IS NULL OR movements.date_transaction <= p_end_day)
        )
		
		SELECT 
		total_receitas_efetivadas.t_receitas_efetivadas,
		total_receitas_pendentes.t_receitas_pendentes,
		total_receitas_efetivadas.t_receitas_efetivadas + total_receitas_pendentes.t_receitas_pendentes AS total_geral_receitas,
		m.date_transaction,
		m.description_transaction,
		c.name_identifier AS categorie_name,
		a.name_identifier AS account_name,
		m.value_transaction,
		m.status_transaction,
		m.user_id,
		m.type_transaction,
		m.accounts_id,
        m.categorie_id,
		m.id,
		m.observation,
		m.is_deleted
	   FROM movements m
		LEFT JOIN categories c ON c.id = m.categorie_id
		LEFT JOIN banks_accounts a ON a.id = m.accounts_id,
		total_receitas_efetivadas,
		total_receitas_pendentes
	  WHERE NOT m.type_transaction::text = 'saldo inicial'::text 
	  AND m.type_transaction::text = 'receita'::text
	  AND m.is_deleted = false
	  AND m.user_id = p_user_id 
	  AND (p_categorie_id IS NULL OR m.categorie_id = ANY(p_categorie_id))
	  AND (p_accounts_id IS NULL OR m.accounts_id = ANY(p_accounts_id))
	  AND (p_situation IS NULL OR m.status_transaction = p_situation)
	  AND (p_for_type IS NULL OR m.type_transaction = ANY(p_for_type))
	  AND (p_start_day IS NULL OR m.date_transaction >= p_start_day)
	  AND (p_end_day IS NULL OR m.date_transaction <= p_end_day);
 END
$BODY$;

ALTER FUNCTION public.fn_movements_only_revenues_by_filter(character varying, date, date, integer[], integer[], character varying, character varying[])
    OWNER TO postgres;


-- ============================================================================
-- SEÇÃO: METAS
-- ============================================================================

-- FUNCTION: public.fn_movements_goals(character varying, integer, integer, integer)

-- DROP FUNCTION IF EXISTS public.fn_movements_goals(character varying, integer, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_movements_goals(
	p_user_id character varying,
	p_goals_id integer,
	p_month integer,
	p_year integer)
    RETURNS TABLE(id integer, goals_id integer, description character varying, value_paid numeric, date_movement date, accounts_id integer, id_goals integer, name_identifier character varying, suggested_value numeric, goal_value numeric, start_date date, end_date date, active boolean, name_account character varying, url_image character varying, is_ignored boolean) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN 
    RETURN QUERY 
    SELECT
		gm.id,
		gm.goals_id,
		gm.description,
		gm.value_paid,
		gm.date_movement,
		gm.accounts_id,
		g.id as id_goals,
		g.name_identifier,
		g.suggested_value,
		g.goal_value,
		g.start_date,
		g.end_date,
		g.active,
		ba.name_identifier as name_account,
		ba.url_image,
		gm.is_ignored
    FROM goals_movements gm
	LEFT JOIN goals g ON g.id = gm.goals_id
	LEFT JOIN banks_accounts ba ON ba.id = gm.accounts_id
    WHERE g.active = true
		AND gm.description != 'Saldo inicial'
    	AND g.user_id = p_user_id 
		AND gm.goals_id = p_goals_id
    	AND EXTRACT(MONTH FROM gm.date_movement) = p_month
    	AND EXTRACT(YEAR FROM gm.date_movement) = p_year;
END;
$BODY$;

ALTER FUNCTION public.fn_movements_goals(character varying, integer, integer, integer)
    OWNER TO postgres;


-- ============================================================================
-- SEÇÃO: TRANSFERÊNCIAS
-- ============================================================================

-- FUNCTION: public.fn_transfer(character varying, integer, integer)

-- DROP FUNCTION IF EXISTS public.fn_transfer(character varying, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_transfer(
	p_user_id character varying,
	p_month integer,
	p_year integer)
    RETURNS TABLE(date_transfer date, observation character varying, account_origin_name character varying, account_destination_name character varying, value_transfer numeric, is_deleted boolean, logo_origem character varying, logo_destino character varying, account_origin integer, account_destination integer, id integer) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
		RETURN QUERY
		SELECT 
			t.date_transfer,
			t.observation,
			origem.name_identifier AS account_origin_name,
        	destino.name_identifier AS account_destination_name,
			t.value_transfer,
			t.is_deleted,
			origem.url_image as logo_origem,
			destino.url_image as logo_destino,
			t.account_origin,
			t.account_destination,
			t.id
		FROM transfer t
			LEFT JOIN banks_accounts origem ON origem.id = t.account_origin
			LEFT JOIN banks_accounts destino ON destino.id = t.account_destination
			WHERE NOT t.is_deleted = true
			AND EXTRACT(MONTH FROM t.date_transfer) = p_month
			AND EXTRACT(YEAR FROM t.date_transfer) = p_year
			AND t.user_id = p_user_id;
	END;
$BODY$;

ALTER FUNCTION public.fn_transfer(character varying, integer, integer)
    OWNER TO postgres;


-- ============================================================================
-- SEÇÃO: FATURAS / NOTIFICAÇÕES
-- ============================================================================

-- FUNCTION: public.fn_info_invoice_by_email()

-- DROP FUNCTION IF EXISTS public.fn_info_invoice_by_email();

CREATE OR REPLACE FUNCTION public.fn_info_invoice_by_email(
	)
    RETURNS TABLE(user_email character varying, card_name character varying, closing_day integer, due_day integer) 
    LANGUAGE 'sql'
    COST 100
    STABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
		SELECT 
			u.email as user_email,
			CC.name_identifier as card_name,
			cc.closing_day,
			cc.due_day
		FROM credit_cards cc
		LEFT JOIN banks_accounts ba ON ba.id = cc.accounts_id
		LEFT JOIN public.user u ON u.id = ba.user_id
		WHERE cc.closing_day = EXTRACT(DAY FROM CURRENT_DATE)
$BODY$;

ALTER FUNCTION public.fn_info_invoice_by_email()
    OWNER TO postgres;


-- FUNCTION: public.fn_refresh_invoice_status()

-- DROP FUNCTION IF EXISTS public.fn_refresh_invoice_status();

CREATE OR REPLACE FUNCTION public.fn_refresh_invoice_status(
	)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN

    UPDATE credit_card_invoices
    SET status_invoice = 'fechada'
    WHERE status_invoice = 'aberta'
        AND closing_date < CURRENT_DATE;

    UPDATE credit_card_invoices cci
    SET status_invoice = 'aberta'
    FROM (
        SELECT DISTINCT ON (credit_card_id) id, credit_card_id
        FROM credit_card_invoices
        WHERE status_invoice = 'parcial'
        ORDER BY credit_card_id, invoice_year, invoice_month
    ) AS proxima
    WHERE cci.id = proxima.id
        AND NOT EXISTS (
            SELECT 1 FROM credit_card_invoices cci2
            WHERE cci2.credit_card_id = proxima.credit_card_id
                AND cci2.status_invoice = 'aberta'
        );

    UPDATE credit_card_invoices cci
    SET status_invoice = 'vencida'
    FROM credit_cards cc
    WHERE cc.id = cci.credit_card_id
        AND cci.status_invoice = 'fechada'
        AND make_date(cci.invoice_year, cci.invoice_month, cc.due_day) < CURRENT_DATE;

END;
$BODY$;

ALTER FUNCTION public.fn_refresh_invoice_status()
    OWNER TO postgres;


-- ============================================================================
-- SEÇÃO: VIEWS
-- ============================================================================

-- View: public.vw_balance_for_account

-- DROP VIEW public.vw_balance_for_account;

CREATE OR REPLACE VIEW public.vw_balance_for_account
 AS
 WITH saldo_movimentos AS (
         SELECT m.accounts_id,
            COALESCE(sum(
                CASE
                    WHEN m.type_transaction::text = 'saldo inicial'::text THEN m.value_transaction
                    ELSE 0::numeric
                END), 0::numeric) + COALESCE(sum(
                CASE
                    WHEN m.type_transaction::text = 'transferencia_entrada'::text AND m.status_transaction::text = 'entrada'::text THEN m.value_transaction
                    ELSE 0::numeric
                END), 0::numeric) + COALESCE(sum(
                CASE
                    WHEN m.type_transaction::text = 'receita'::text AND m.status_transaction::text = 'recebido'::text THEN m.value_transaction
                    ELSE 0::numeric
                END), 0::numeric) - COALESCE(sum(
                CASE
                    WHEN m.type_transaction::text = 'transferencia_saida'::text AND m.status_transaction::text = 'saida'::text THEN m.value_transaction
                    ELSE 0::numeric
                END), 0::numeric) - COALESCE(sum(
                CASE
                    WHEN m.type_transaction::text = 'despesa'::text AND m.status_transaction::text = 'pago'::text THEN m.value_transaction
                    ELSE 0::numeric
                END), 0::numeric) - COALESCE(sum(
                CASE
                    WHEN m.type_transaction::text = 'pagamento_fatura'::text AND m.status_transaction::text = 'pago'::text THEN m.value_transaction
                    ELSE 0::numeric
                END), 0::numeric) AS saldo_movimentos
           FROM movements m
          WHERE m.is_deleted = false
          GROUP BY m.accounts_id
        ), saldo_meta AS (
         SELECT gm.accounts_id,
            COALESCE(sum(gm.value_paid), 0::numeric) AS total_metas
           FROM goals_movements gm
          WHERE COALESCE(gm.is_ignored, false) = false
          GROUP BY gm.accounts_id
        )
 SELECT ba.id AS accounts_id,
    COALESCE(sm.saldo_movimentos, 0::numeric) - COALESCE(smt.total_metas, 0::numeric) AS saldo_atual
   FROM banks_accounts ba
     LEFT JOIN saldo_movimentos sm ON sm.accounts_id = ba.id
     LEFT JOIN saldo_meta smt ON smt.accounts_id = ba.id;

ALTER TABLE public.vw_balance_for_account
    OWNER TO postgres;


-- View: public.vw_balance_for_goals

-- DROP VIEW public.vw_balance_for_goals;

CREATE OR REPLACE VIEW public.vw_balance_for_goals
 AS
 SELECT g.id,
    gm.goals_id,
    g.goal_value AS meta,
    COALESCE(sum(gm.value_paid), 0::numeric) AS total_lancado,
    round(COALESCE(sum(gm.value_paid), 0::numeric) / NULLIF(g.goal_value, 0::numeric) * 100.0, 0) AS percentual
   FROM goals g
     LEFT JOIN goals_movements gm ON gm.goals_id = g.id
  GROUP BY g.goal_value, g.id, gm.goals_id;

ALTER TABLE public.vw_balance_for_goals
    OWNER TO postgres;