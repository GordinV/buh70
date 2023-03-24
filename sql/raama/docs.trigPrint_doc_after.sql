
DROP FUNCTION if exists docs.trigPrint_doc_after();

CREATE OR REPLACE FUNCTION docs.trigPrint_doc_after()
    RETURNS trigger AS
$BODY$
declare
    lnCount int;
    lcErr varchar;
    v_docs record;
    a_ids integer[];
begin
    -- ставим статус представлен



    return new;

end;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;

DROP TRIGGER IF EXISTS trigD_doc_after ON docs.doc;

CREATE TRIGGER trigD_doc_after
    after DELETE
    ON docs.doc
    FOR EACH ROW
EXECUTE PROCEDURE docs.trigPrint_doc_after();



-- test
/*
delete from docs.doc where id = 78

select * from docs.doc d
where d.docs_ids @> array[78]

"{39,82,82,82}"

*/
--select * from libs.library order by id limit 100