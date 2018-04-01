drop table if exists palk.palk_tmpl;

CREATE TABLE palk.palk_tmpl
(
  id       SERIAL,
  parentid INTEGER,  --amet
  libid    INTEGER,
  percent_ INTEGER DEFAULT 0        NOT NULL,
  summa    NUMERIC(12, 4) DEFAULT 0 NOT NULL,
  tulumaar INTEGER,
  tulumaks INTEGER,
  tunnus varchar(20),
  ajalugu jsonb,
  properties jsonb,
  muud text,
  status dok_status default 'active'
);

CREATE INDEX palk_tmpl_ametid
  ON palk.palk_tmpl (parentid);


CREATE INDEX palk_tmpl_libid
  ON palk.palk_tmpl (libid);
