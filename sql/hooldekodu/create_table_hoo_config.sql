-- auto-generated definition
DROP TABLE IF EXISTS hooldekodu.hoo_config;

CREATE TABLE hooldekodu.hoo_config (
    id         SERIAL      NOT NULL,
    summa      NUMERIC(12, 2) DEFAULT 0,
    kpv        DATE        NOT NULL,
    library    VARCHAR(20) NOT NULL,
    properties JSONB,
    ajalugu    JSONB,
    muud       TEXT,
    status     INTEGER        DEFAULT 1,
    CONSTRAINT hoo_config_pkey PRIMARY KEY (id)
);

ALTER TABLE hooldekodu.hoo_config
    OWNER TO postgres;

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE hooldekodu.hoo_config TO dbpeakasutaja;
GRANT SELECT ON TABLE hooldekodu.hoo_config TO dbvaatleja;
GRANT SELECT, UPDATE, INSERT, DELETE, TRIGGER ON TABLE hooldekodu.hoo_config TO dbkasutaja;

GRANT ALL ON TABLE hooldekodu.hoo_config TO hkametnik;
GRANT ALL ON TABLE hooldekodu.hoo_config TO soametnik;


ALTER SEQUENCE IF EXISTS hooldekodu.hoo_config_id_seq
    OWNED BY NONE;

--GRANT ALL ON SEQUENCE hooldekodu.hoo_config_id_seq TO dbkasutaja;
GRANT ALL ON SEQUENCE hooldekodu.hoo_config_id_seq TO dbadmin;
GRANT ALL ON SEQUENCE hooldekodu.hoo_config_id_seq TO hkametnik;
GRANT ALL ON SEQUENCE hooldekodu.hoo_config_id_seq TO soametnik;

--delete from ou.menupohi where properties->>'name' = 'Kesk pension' and bar = '9';

INSERT into ou.menupohi (pad, bar, idx, properties)
values ('Library', '9', 0,
        '{"name": "Kesk pension", "proc": "oKeskPension =nObjekt(\"kesk_pension\",\"oKeskPension\",0)", "user": "vlad", "vene": "Средние пенсии", "eesti": "Kesk pensionid", "level": 1, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')

INSERT into ou.menupohi (pad, bar, idx, properties)
values ('kesk_pension', '4', 0,
        '{"name": "Print", "proc": "gcWindow.print", "user": "vlad", "vene": "Печать", "eesti": "Trükkimine", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')


INSERT into ou.menupohi (pad, bar, idx, properties)
values ('kesk_pension', '1', 0,
        '{"name": "Add", "proc": "gcWindow.add", "user": "vlad", "vene": "Добавить", "eesti": "Lisamine", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')

INSERT into ou.menupohi (pad, bar, idx, properties)
values ('kesk_pension', '2', 0,
        '{"name": "Edit", "proc": "gcWindow.edit", "user": "vlad", "vene": "Редактировать", "eesti": "Muuda", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')

INSERT into ou.menupohi (pad, bar, idx, properties)
values ('kesk_pension', '2', 0,
        '{"name": "Delete", "proc": "gcWindow.delete", "user": "vlad", "vene": "Удвлить", "eesti": "kustuta", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')

delete from ou.menupohi where properties->>'name' = 'Hoolduskulud' and bar = '91';

INSERT into ou.menupohi (pad, bar, idx, properties)
values ('Library', '91', 0,
        '{"name": "Hoolduskulud", "proc": "oRiigiToetus =nObjekt(\"riigi_toetus\",\"oRiigiToetus\",0)", "user": "vlad", "vene": "Hoolduskulud", "eesti": "Hoolduskulud", "level": 1, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')

INSERT into ou.menupohi (pad, bar, idx, properties)
values ('riigi_toetus', '4', 0,
        '{"name": "Print", "proc": "gcWindow.print", "user": "vlad", "vene": "Печать", "eesti": "Trükkimine", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')


INSERT into ou.menupohi (pad, bar, idx, properties)
values ('riigi_toetus', '1', 0,
        '{"name": "Add", "proc": "gcWindow.add", "user": "vlad", "vene": "Добавить", "eesti": "Lisamine", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')

INSERT into ou.menupohi (pad, bar, idx, properties)
values ('riigi_toetus', '2', 0,
        '{"name": "Edit", "proc": "gcWindow.edit", "user": "vlad", "vene": "Редактировать", "eesti": "Muuda", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')

INSERT into ou.menupohi (pad, bar, idx, properties)
values ('riigi_toetus', '2', 0,
        '{"name": "Delete", "proc": "gcWindow.delete", "user": "vlad", "vene": "Удвлить", "eesti": "kustuta", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')


delete from ou.menupohi where properties->>'name' = 'kov_piirimaar' and bar = '92';

INSERT into ou.menupohi (pad, bar, idx, properties)
values ('Library', '92', 0,
        '{"name": "kov_piirimaar", "proc": "oKovPiirimaar =nObjekt(\"kov_piirimaar\",\"oKovPiirimaar\",0)", "user": "vlad", "vene": "KOV Piirimäär", "eesti": "KOV Piirimäär", "level": 1, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')

INSERT into ou.menupohi (pad, bar, idx, properties)
values ('kov_piirimaar', '4', 0,
        '{"name": "Print", "proc": "gcWindow.print", "user": "vlad", "vene": "Печать", "eesti": "Trükkimine", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')


INSERT into ou.menupohi (pad, bar, idx, properties)
values ('kov_piirimaar', '1', 0,
        '{"name": "Add", "proc": "gcWindow.add", "user": "vlad", "vene": "Добавить", "eesti": "Lisamine", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')

INSERT into ou.menupohi (pad, bar, idx, properties)
values ('kov_piirimaar', '2', 0,
        '{"name": "Edit", "proc": "gcWindow.edit", "user": "vlad", "vene": "Редактировать", "eesti": "Muuda", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')

INSERT into ou.menupohi (pad, bar, idx, properties)
values ('kov_piirimaar', '2', 0,
        '{"name": "Delete", "proc": "gcWindow.delete", "user": "vlad", "vene": "Удвлить", "eesti": "kustuta", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')
