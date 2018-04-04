DROP VIEW IF EXISTS cur_tahtpaevad;

CREATE VIEW cur_tahtpaevad AS
  SELECT
    l.id,
    l.nimetus,
    l.rekvid,
    (l.properties :: JSONB ->> 'paev') :: INTEGER  AS paev,
    (l.properties :: JSONB ->> 'kuu') :: INTEGER   AS kuu,
    (l.properties :: JSONB ->> 'aasta') :: INTEGER AS aasta
  FROM libs.library l
  WHERE l.library = 'TAHTPAEV'
        AND l.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted');
