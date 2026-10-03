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
		  INNER JOIN banks_accounts ba ON ba.id = m.accounts_id AND ba.active = true
          WHERE m.is_deleted = false AND m.user_id = p_user_id 
  		),

		saldo_meta AS (
         SELECT COALESCE(sum(gm.value_paid), 0::numeric) AS total_metas
          FROM goals_movements gm
		  LEFT JOIN goals g ON g.id = gm.goals_id
		  INNER JOIN banks_accounts ba ON ba.id = gm.accounts_id
         WHERE g.user_id = p_user_id AND gm.description != 'Saldo inicial' AND COALESCE(gm.is_ignored, false) = false AND (ba.active = true)
		 )

		  SELECT COALESCE(sm.saldo_movimentos, 0::numeric) - COALESCE(smt.total_metas, 0::numeric) AS saldo_atual
		  INTO v_saldo_atual
		   FROM saldo_movimentos sm, saldo_meta smt;
		   RETURN v_saldo_atual;
END;
$BODY$;

ALTER FUNCTION public.fn_current_balance(character varying)
    OWNER TO postgres;

