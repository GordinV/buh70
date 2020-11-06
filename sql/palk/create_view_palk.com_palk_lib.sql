DROP VIEW IF EXISTS palk.com_palk_lib;

CREATE VIEW palk.com_palk_lib AS
SELECT l.id,
       l.rekvid,
       l.kood,
       l.nimetus,
       l.status,
       l.library,
       l.tun1,
       l.tun5,
       (l.properties :: JSONB ->> 'liik') :: INTEGER          AS liik,
       (l.properties :: JSONB ->> 'tund') :: INTEGER          AS tund,
       (l.properties :: JSONB ->> 'maks') :: INTEGER          AS maks,
       (l.properties :: JSONB ->> 'asutusest') :: INTEGER     AS asutusest,
       (l.properties :: JSONB ->> 'palgafond') :: INTEGER     AS palgafond,
       (l.properties :: JSONB ->> 'sots') :: INTEGER          AS sots,
       (l.properties :: JSONB ->> 'round') :: NUMERIC(12, 4)  AS round,
       (l.properties :: JSONB ->> 'konto') :: VARCHAR(20)     AS konto,
       (l.properties :: JSONB ->> 'korrkonto') :: VARCHAR(20) AS korrkonto,
       (l.properties :: JSONB ->> 'tunnusid') :: INTEGER      AS tunnusId,
       (l.properties :: JSONB ->> 'elatis') :: INTEGER        AS elatis,
       (l.properties :: JSONB ->> 'uritus') :: VARCHAR(20)    AS uritus,
       (l.properties :: JSONB ->> 'proj') :: VARCHAR(20)      AS proj,
       (l.properties :: JSONB ->> 'tegev') :: VARCHAR(20)     AS tegev,
       (l.properties :: JSONB ->> 'allikas') :: VARCHAR(20)   AS allikas,
       (l.properties :: JSONB ->> 'artikkel') :: VARCHAR(20)  AS artikkel,
       (l.properties :: JSONB ->> 'tululiik') :: VARCHAR(20)  AS tululiik,
       (l.properties::JSONB ->> 'valid')::DATE                AS valid,
       l.muud
FROM libs.library l
WHERE l.library = 'PALK'
  AND l.status <> array_position(enum_range(NULL :: DOK_STATUS), 'deleted');


GRANT SELECT ON TABLE palk.com_palk_lib TO dbkasutaja;
GRANT SELECT ON TABLE palk.com_palk_lib TO dbvaatleja;
GRANT SELECT ON TABLE palk.com_palk_lib TO dbpeakasutaja;
