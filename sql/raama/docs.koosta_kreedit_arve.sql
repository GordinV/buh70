DROP FUNCTION IF EXISTS docs.koosta_kreedit_arve(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.koosta_kreedit_arve(IN user_id INTEGER,
                                                    IN alus_arve_id INTEGER,
                                                    OUT error_code INTEGER,
                                                    OUT result INTEGER,
                                                    OUT doc_type_id TEXT,
                                                    OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$
DECLARE
    doc_id_kreedit INTEGER;
BEGIN

    -- готовим кредитовый счет как копию с отрицательным знаком
    doc_id_kreedit = docs.sp_kooperi_arv(user_id, alus_arve_id, -1, true);

    IF doc_id_kreedit IS NULL OR empty(doc_id_kreedit)
    THEN
        error_code = 2;
        error_message = 'Viga:,kreedit arve salvestamine ebaõnnestus';
        RAISE EXCEPTION 'Viga:,kreedit arve salvestamine ebaõnnestus';
    END IF;

-- увязываем со счетом основанием
    PERFORM docs.kas_kreedit_arve(doc_id_kreedit, user_id, alus_arve_id);

    -- проверяем наличие связи с род.платой
    if exists
    (
        select id
        from lapsed.liidestamine l
        where l.docid = alus_arve_id
    ) then
        --связываем с кредитовым счетом
        insert into lapsed.liidestamine (parentid, docid)
        select
            parentid,
            doc_id_kreedit
        from
            lapsed.liidestamine l
        where
            l.docid = alus_arve_id;
    end if;

    -- контировка
    PERFORM docs.gen_lausend_arv(doc_id_kreedit, user_id);

    result = doc_id_kreedit;
    error_code = 0;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.koosta_kreedit_arve(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.koosta_kreedit_arve(INTEGER, INTEGER) TO dbpeakasutaja;


/*
-- 6475856
SELECT docs.koosta_kreedit_arve(5302, 6475856)
-- 6526397

SELECT * from docs.arv where parentid = 6526394



*/