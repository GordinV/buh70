---
name: buh70-db-tables
description: Где в БД buh70 лежат покупатели/контрагенты, учреждения и пользователи и как отбирать активные записи. Применять при написании SQL и JS-кода, который ищет покупателя, контрагента, учреждение или пользователя (импорт e-arved/FinBit, маршрутизация по regkood, проверки asutus).
---

# buh70: таблицы справочников

## Покупатели (контрагенты) — `libs.asutus`

Покупатели лежат в таблице `libs.asutus`. Активные записи — **`staatus < 3`** (3 = удалена/скрыта). Колонка называется именно `staatus` — колонки `status` в `libs.asutus` нет (в `ou.userid`, `ou.task`, `libs.library` — `status`).

Поиск покупателя (контрагента) по регкоду:

```sql
select id, regkood, nimetus
from libs.asutus
where btrim(regkood) = $1
  and staatus < 3;
```

`regkood` и `nimetus` — `char` с хвостовыми пробелами: сравнивать через `btrim`.

Не искать покупателя в `ou.rekv` — там учреждения (организации-пользователи системы), а не покупатели.

## Учреждения — `ou.rekv`

Учреждения системы (организации, в которых работают пользователи). Регкод — `ou.rekv.regkood`; hash FinBit — `ou.rekv.properties->>'earved'`. Проверка учреждения в `docs.sp_salvesta_arv`: `regkood = ... and parentid < 999`.

## Роли БД и GRANT

Роль `arvestaja` **не имеет права создавать счета**: не выдавать ей `EXECUTE` на функции, которые создают документы (импорт e-arved `docs.sp_loe_earved_batches`, `docs.sp_loe_earved`, сохранение счетов). Для таких функций — `dbkasutaja`, `dbpeakasutaja`, `dbadmin`. Не добавлять GRANT «для единообразия» с соседними файлами без проверки, что роль должна иметь это право.

## Пользователи — `ou.userid`

Запись пользователя привязана к одному учреждению (`ou.userid.rekvid`). Активные — `status < 3`. Робот импорта e-arved — `kasutaja = 'Earved robot'`.
