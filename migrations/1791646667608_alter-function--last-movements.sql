DROP FUNCTION IF EXISTS public.fn_last_movements(character varying, integer, integer);

CREATE OR REPLACE FUNCTION public.fn_last_movements(
	p_user_id character varying,
	p_month integer,
	p_year integer)
    RETURNS TABLE(
        id integer,
        date_transaction date,
        description_transaction character varying,
        value_transaction numeric,
        type_transaction character varying,
        status_transaction character varying,
        installment_current integer,
        total_installments integer,
        type_recurrence character varying,
        origin_type text,
        origin_name character varying)
    LANGUAGE 'sql'
    STABLE
AS $BODY$

    -- Conta (receitas, despesas, transferências)
    (SELECT
        m.id,
        m.date_transaction,
        m.description_transaction,
        m.value_transaction,
        m.type_transaction,
        m.status_transaction,
        m.installment_current,
        r.total_installments,
        r.type_recurrence,
        'account'::text,
        ba.name_identifier
    FROM movements m
    LEFT JOIN banks_accounts ba ON ba.id = m.accounts_id
    LEFT JOIN recurrence r ON r.id = m.recurrence_id
    WHERE m.user_id = p_user_id
        AND m.is_deleted = false
        AND m.type_transaction != 'saldo inicial'
        AND EXTRACT(MONTH FROM m.date_transaction) = p_month
        AND EXTRACT(YEAR FROM m.date_transaction) = p_year)

    UNION ALL

    -- Cartão de crédito
    (SELECT
        ccm.id,
        ccm.purchase_date,
        ccm.description_credit,
        ccm.value_transaction,
        'despesa_cartao'::character varying,
        ccm.status_movement,
        ccm.installment_number,
        r.total_installments,
        r.type_recurrence,
        'card'::text,
        cc.name_identifier
    FROM credit_card_movements ccm
    JOIN credit_cards cc ON cc.id = ccm.credit_card_id
    LEFT JOIN recurrence r ON r.id = ccm.recurrence_id
    WHERE ccm.user_id = p_user_id
        AND ccm.status_movement != 'deletada'
        AND EXTRACT(MONTH FROM ccm.purchase_date) = p_month
        AND EXTRACT(YEAR FROM ccm.purchase_date) = p_year)

    UNION ALL

    -- Metas
    (SELECT
        gm.id,
        gm.date_movement,
        gm.description,
        gm.value_paid,
        'meta'::character varying,
        'pago'::character varying,
        NULL::integer,
        NULL::integer,
        NULL::character varying,
        'goal'::text,
        g.name_identifier
    FROM goals_movements gm
    JOIN goals g ON g.id = gm.goals_id
    WHERE g.user_id = p_user_id
        AND gm.description != 'Saldo inicial'
        AND COALESCE(gm.is_ignored, false) = false
        AND EXTRACT(MONTH FROM gm.date_movement) = p_month
        AND EXTRACT(YEAR FROM gm.date_movement) = p_year)

    ORDER BY date_transaction DESC, id DESC
    LIMIT 7
$BODY$;

ALTER FUNCTION public.fn_last_movements(character varying, integer, integer)
    OWNER TO postgres;