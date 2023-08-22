-- {"name": "Arvesta arved", "proc": "gcWindow.arvesta_arved", "user": "vlad", "vene": "Arvesta arved", "eesti": "Arvesta arved", "level": 2, "users": [], "groups": ["HK_AMETNIK"], "created": "2022-12-27T12:19:36.603595+02:00", "modules": ["HOOLDEKODU"], "submenu": null, "keyshortcut": null}

INSERT into ou.menupohi (pad, bar, idx, properties)
values ('Hooldekodu', '7', 8,
        '{"name": "Arvesta taskuraha", "proc": "gcWindow.arvesta_taskuraha", "user": "vlad", "vene": "Arvesta taskuraha", "eesti": "Arvesta taskuraha", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')

INSERT into ou.menupohi (pad, bar, idx, properties)
values ('Hooldekodu', '8', 81,
        '{"name": "Maksta taskuraha", "proc": "gcWindow.koosta_mk", "user": "vlad", "vene": "Maksta taskuraha", "eesti": "Maksta taskuraha", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')


INSERT into ou.menupohi (pad, bar, idx, properties)
values ('Hooldekodu', '82', 82,
        '{"name": "Maksta (KASSA) taskuraha", "proc": "gcWindow.koosta_vorder", "user": "vlad", "vene": "Maksta (Kassa) taskuraha", "eesti": "Maksta (Kassa) taskuraha", "level": 2, "users": [], "groups": ["SA_AMETNIK"], "created": "2023-07-31T16:31:28.708848+02:00", "modules": ["HOOLDEKODU"], "keyshortcut": null}')



