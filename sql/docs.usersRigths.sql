-- Function: docs.sp_lausendikontrol(json)

-- DROP FUNCTION docs.sp_lausendikontrol(json);

CREATE OR REPLACE FUNCTION docs.usersRigths(docId integer, command text, userId integer)
  RETURNS boolean AS
$BODY$
	select (d.rigths -> command) @>  to_jsonb(array[userId]) 
		from docs.doc d where id = docId
		
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;

GRANT EXECUTE ON FUNCTION docs.usersRigths(docId integer, command text, userId integer) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.usersRigths(docId integer, command text, userId integer) TO dbpeakasutaja;

/*
select rigths, docs.usersRigths(d.id, 'select', 1) from docs.doc d where id = 201

select d.rigths, (d.rigths -> 'select') @> to_jsonb(array[3]) 
		from docs.doc d where id = 201

		*/