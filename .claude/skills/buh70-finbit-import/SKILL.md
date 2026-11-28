---
name: buh70-finbit-import
description: Импорт входящих счетов на оплату из FinBit (e-arved) в buh70 — цепочка выкачка → импорт → уведомления, формат JSON счета и батчей, правила docs.sp_loe_earved, статусы ou.task, логи ou.logs, письма бухгалтерам и известные ловушки. Применять при любой правке getEarvedFromFinBit.js, xml_to_json.js, getXMLFile.js, importEarved.js, sendFinBitReport.js, docs.sp_loe_earved*, ou.execute_task, docs.get_arve_kinnitaja и при разборе ошибок импорта.
---

# buh70: импорт счетов из FinBit

Импортируются **входящие счета на оплату** (покупка). Код бэкенда — Node < 14 (см. скилл `buh70-node-runtime`), таблицы и роли — скилл `buh70-db-tables`.

## Главное правило: покупатель = учреждение выкачки

Счет импортируется в то учреждение, **по чьему hash сделана выкачка**. `BuyerRegNumber` из XML (`data.rekv_regkood`) для выбора учреждения **не использовать** и в `docs.sp_salvesta_arv` **не передавать**.

Почему: поставщики часто выставляют счет на регкод вышестоящего. Пример из БД: школа rekv 106 (regkood 75008611, parentid 119) получает в своей выкачке счета с покупателем 75024260 — это регкод Kultuuriosakond (rekv 119); так было у 93 из 102 счетов. Маршрутизация по `rekv_regkood` (коммит f17db5e7) отбрасывала их как «Asutust regkoodiga … ei leitud», а проверка `'Viga: vale asutus'` в `sp_salvesta_arv` (regkood → `ou.rekv` с `parentid < 999` → 119 ≠ 106) их отвергала. Откат — 343d55ba.

Контрагент (продавец) ищется в `libs.asutus` по `regkood = data.asutusid`, `staatus < 3`.

## Цепочка и точки входа

| Путь | Кто запускает | Что делает |
|---|---|---|
| **UI** (`!isAgent`) | пользователь из интерфейса, `POST` в `routes/raama/getEarvedFromFinBit.js` (`post`) с `user_id`, `rekv_id`, `date_query_from` | выкачка только учреждения пользователя (`u.id = $1`, при `rekv_id` — `r.id = $2`) → задача `ou.task` (`ou.sp_salvesta_task`) → фоном `runPostTaskInBackground` → `ou.execute_task` → письмо об ошибке → отчет `sendFinBitReport.executeReport` |
| **Агент** (`is_agent=true`) | оркестратор `routes/ai/ai_task` (genkit) по расписанию | `getEarved` (~05:00, только выкачка в лог) → `check_asutus` → `import_earved` (~06:30, `routes/raama/importEarved.js`) → `sendFinBitReport` (~07:00) |

Агент работает под пользователем `Earved robot` (11770 и роботы учреждений; сейчас робот есть у rekv 3 и 63). Агентский путь выкачивает все учреждения с hash, где есть пользователь-робот или вызывающий пользователь. **`routes/ai/ai_task` (genkit) без явного решения пользователя не менять.**

Каждое учреждение с hash → **свой batch со всеми счетами своей выкачки**. Без дедупликации и без перекладывания между учреждениями.

## Выкачка (`routes/ai/e-arved/getXMLFile.js`)

- SOAP `BuyInvoiceExportRequest since="<дата>" authPhrase="<hash>"` на хост `ou.config.properties->>'earved'` (по умолчанию `https://app.finbite.eu/finance/erp`).
- `hash` = `ou.rekv.properties->>'earved'` учреждения. Учреждение без hash не выкачивается.
- `date_query_from` — дата «с»; в агенте окно ограничено (не раньше сегодня − 5 дней). Поэтому один и тот же счет приходит в нескольких запусках подряд — повтор отсекает проверка дублей в `sp_loe_earved` (см. ниже).
- `XMLtoJson(xml, {rekvid, userid})` (`routes/ai/e-arved/xml_to_json.js`) проставляет всем счетам `rekvid`/`userid` учреждения выкачки.

## Формат счета (выход `XMLtoJson`, вход `docs.sp_loe_earved`)

Массив элементов `{ "id": 0, "data": { ... } }`. Ключевые поля `data`:

| Поле | Источник XML | Смысл / нюансы |
|---|---|---|
| `number` | `InvoiceInformation.InvoiceNumber` | номер счета; уникален только у продавца |
| `kpv` | `InvoiceDate` | строка `YYYYMMDD` (дефисы убраны), в SQL `::date` |
| `tahtaeg` | `DueDate` / `PaymentInfo.PayDueDate` | `YYYYMMDD` |
| `asutusid` | `SellerParty.RegNumber` | **регкод продавца** (число, если похоже на число), не id! В SQL ищется `libs.asutus.regkood` |
| `rekv_regkood` | `BuyerParty.RegNumber` | регкод покупателя из XML — **не использовать** (см. главное правило) |
| `rekvid`, `userid` | опции `XMLtoJson` | учреждение и пользователь выкачки |
| `aa`, `viitenr` | `PaymentInfo.PayToAccount`, `PaymentReferenceNumber`/`PaymentRefId` | IBAN и ссылочный номер |
| `kbmta`, `kbm`, `summa` | `InvoiceSumGroup` (`InvoiceSum`/`VAT.SumBeforeVAT`, `VAT.VATSum`, `TotalSum`) | суммы |
| `korr_konto` | первый `OppositeAccount` строк | корр. счет; если пусто — `gridData[0].korr_konto`, иначе `'201000'` |
| `liik` | — | всегда `1` (входящий счет) |
| `doklausid` | — | дефолт; в SQL переопределяется по `libs.dokprop` |
| `bpm` | ConfirmationList / Confirmator и т.п. (`extractBpm`) | `[{isik, kpv, rolli}]`, последний элемент — последний согласующий; сохраняется в документ как `bpm.omniva` |
| `gridData` | строки счета (`convertInvoiceItem`) | `nomid`, `kogus`, `hind`, `kbmta`, `kbm`, `summa`, `konto`, `kood1..kood5`, `tp`, `objekt`, `nimetus`, `muud`, `Accounting.JournalEntry` |
| `Accounting`, `JournalEntry`, `CostObjective` | `Accounting` счета или первой строки | контировка |

`JournalEntry` — `[{Sum, CostObjective, GeneralLedger}]`. Полный живой пример — комментарий в конце `sql/raama/docs.sp_loe_earved.sql`.

## Формат батчей

- **UI-путь → `ou.task.sql`:** один вызов
  `select * from docs.sp_loe_earved_batches($$[{"user_id": 5429, "data": [<счета>]}, ...]$$::jsonb)`
  (`buildBatchesTaskSql`; если в JSON встречается `$$`, тег долларовой кавычки — `$finbit$`, `$finbit_1$`, …). Задача сохраняется параметризованно `ou.sp_salvesta_task($1::text, $2::text, $3::integer)` с именем `'Loe FinBit arved'`.
- **Агент → лог `getEarved`:** `propertis.arved = [{rekvId, userId, count, arved: [<счета>]}]`, плюс `result.totalFetched`, `invoiceNumbers`, `batches`. Этот формат читают `check_asutus` и `import_earved` в `ai_task` — **не менять**.

## `docs.sp_loe_earved(user_id, arved)` — правила импорта

Выход: `error_code`, `result` (= число созданных документов), `error_message`, `imported [{doc_id, number, rekv_id}]`, `errors [{number, asutusid, rekv_id, raamatupidaja, error}]`.

1. Пустой массив → `result = 0`, `error_message = 'Arved ei ole'`.
2. Пользователь должен иметь `roles->>'is_kasutaja'` и `status < 3`, иначе `error_code = 4`, `'Puudub õigused'`. `rekvid` берется **из пользователя**, а не из счета.
3. Если пользователь `vlad`/`temp` — документы создаются от робота учреждения (`kasutaja ilike '%robot%'`).
4. Пишет служебный лог `ou.logs` **без `flow`** (`{'e-arve': ...}`) — его нельзя использовать как `log_id` цепочки.
5. **Дубль** = в учреждении уже есть `docs.arv` с тем же `number`, годом `kpv`, регкодом продавца и `liik = 1` → счет **молча пропускается** (нет ни в `imported`, ни в `errors`). Поэтому «Imporditud 0 arvet» при повторной выкачке — норма.
6. Продавец не найден в `libs.asutus` → ошибка `'Viga: asutus ei leidnud, regkood …'`.
7. `CostObjective` из `JournalEntry` раскладывается по `libs.library` (`status < 3`) в порядке: `TULUDEALLIKAD`→`kood5`, `TEGEV`→`kood1`, `ALLIKAD`→`kood2`, `RAHA`→`kood3`, `TUNNUS`→`tunnus`*, `PROJ`→`proj`*, `URITUS`→`kood4`*, `OBJEKT`→`objekt`*, `TP`→`tp` (* — с `rekvid` учреждения).
8. Номенклатура — по умолчанию `libs.nomenklatuur` `dok = 'ARV'`, `kood = 'OMNIVA'` учреждения; нет → ошибка `'nomenklatuuri kood OMNIVA ei leidnud'`.
9. `doklausid` — `libs.dokprop` с `parentid = 53`, `registr = 1`, `details->>'konto' = korr_konto`.
10. Сохранение `docs.sp_salvesta_arv` (без `rekv_regkood`!), проводка `docs.gen_lausend_arv`, BPM → `docs.sp_update_doc_bpm_data(..., {omniva: bpm})`.
11. **Подтранзакция на каждый счет**: ошибка одного счета откатывает только его и попадает в `errors` (с `raamatupidaja` = последний `isik` из `bpm`).

Типичные ошибки данных (не баги кода): неверный/устаревший код TP (`'TP kood ei ole kehtiv'`), нет контрагента, нет номенклатуры OMNIVA, нет `dokprop` для корр. счета.

## `docs.sp_loe_earved_batches(jsonb)`

Вход `[{user_id, data}]`. Каждый batch в своей подтранзакции. Выход одной строкой: `result` (всего создано), `error_code` (> 0 **только если отказали все батчи**), `error_message = 'Imporditud M arvet, vigu N'`, `imported`, `errors`. Batch без `user_id` → ошибка `'Puudub user_id'` (код 4). Пустой batch / `'Arved ei ole'` → отказ batch.

## `ou.task` и `ou.execute_task`

- Статусы: `0` Ootel; `1` без `finished` — Arvestan (выполняется; `executeTask` ставит 1 **до** вызова — так задумано); `1` с `finished` — Edukalt; `2` Vigane; `3` скрыта. `tulemused` показывается в UI как «viga».
- **`error_code > 0` — признак ошибки** (решение пользователя).
- Правила статуса: `error_code > 0` → 2; есть массив `errors`: непустой и 0 созданных → 2, непустой и есть созданные → 1 с текстом `'Imporditud M arvet, vigu N: …'`, пустой → 1 и `tulemused = NULL`; иначе `result = 0` + `error_message` → 2; прочее → 1. `tulemused` обрезается до 2000. В `properties` — `error_code`, `imported_count`, `imported`, `errors`, `execute_time`.
- Каждая задача выполняется в **своей подтранзакции**: в пакетном режиме (`doc_id = null`) падение одной задачи не откатывает остальные.

## Логи `ou.logs` (`propertis.flow`)

- `getEarved` — выкачка агента (массив счетов).
- `docs.sp_loe_earved` — итог импорта: `result.imported`, `result.errors`, `totalImported`, `totalFailed`, в UI-пути также `ou_task_id`. По `result.imported` работает `docs.get_arve_kinnitaja`.
- `sendFinBitReport` — рассылка, `result.sendResults`.
- UI-путь пишет `docs.sp_loe_earved` **под пользователем UI**, агент — под роботом; проверки оркестратора (`checkTaskAlreadyRunToday`, `guardAgainstDuplicate`) идут по `user_id`, поэтому не пересекаются.

## Письма

- **SMTP** — только из карточки `ou.userid` (`getUserMailAccount`, затем `getRobotSmtpConfig`). Никаких зашитых паролей и `.env`.
- **Письмо об ошибке (UI-путь)** — при `status = 2` или непустых `errors`: тема `'Loe FinBit arved: VIGA (task N)'` / `'… osaliselt imporditud (task N)'`, текст на эстонском. Получатель — email инициатора (`ou.userid.properties->>'email'`), иначе email учреждения.
- **Копия того же письма бухгалтеру из BPM** счета с ошибкой: `raamatupidaja` → `ou.userid.ametnik` (без регистра; `status < 3`; непустой email; сначала карточка учреждения счета). Отдельная отправка; если адрес совпал с инициатором — не дублируется. В агентском пути письма об ошибке нет.
- **Отчет о созданных счетах** (`sendFinBitReport` через `docs.get_arve_kinnitaja`): бухгалтеру из `d.bpm->'omniva'->-1->>'isik'`, иначе инициатору, роботу, учреждению. При 0 созданных — no-op (успех без писем).
- **Имена в BPM и `ametnik` расходятся**: BPM `JELENA VEREŠTŠAGINA`, карточка `Jelena Verestsagina`. В поиске копии письма об ошибке сравнение с заменой `Š Ž Õ Ä Ö Ü → S Z O A O U`. `docs.get_arve_kinnitaja` **не менять** — пользователи поправят `ametnik` в БД (решение пользователя).
- **Адреса-заглушки** (`BLOCKED_EMAILS` в `sendFinBitReport.js`, сейчас `vigane@narva.ee`): на них ничего не отправлять. В отчете такая строка — `success + skipped` (без повтора), в письме об ошибке берется следующий адрес.

## Права

Роль `arvestaja` не имеет права создавать счета — `EXECUTE` на `docs.sp_loe_earved*` ей не выдавать. В проекте нет `REVOKE … FROM PUBLIC`, поэтому PostgreSQL по умолчанию дает `EXECUTE` роли `PUBLIC`; фактически запретить вызов можно только `REVOKE` (решение за пользователем).

## Известные открытые вопросы

- `getEarvedFromFinBit.js` работает через `config/narvalv.json`, а `routes/task/executePostTask.js` — через `config/default.json`. Если они указывают на разные БД, задача сохранится в одной, а выполнится в другой (локально сейчас `db_test` и `db`).
- В агентском пути при полном провале импорта отчет `sendFinBitReport` оркестратор не запускает.

## Проверка

- Тесты: `test/getEarvedFromFinBit.test.js`, `test/sendFinBitReport.test.js`, `test/importEarved.test.js` — jest 29 из `routes/ai/ai_task` (команда в скилле `buh70-node-runtime`). `jest.clearAllMocks()` **не сбрасывает** очередь `mockReturnValueOnce`: лишний `Once` протекает в следующий тест, а лишний `Promise.reject` роняет весь набор — в каждом тесте мокать ровно столько вызовов, сколько делает код.
- Реальные данные: SQL задачи `ou.task.sql` содержит полный JSON батчей; `tulemused` — итог. Читать БД только в режиме read-only; SQL-функции проверять на `db_test` в транзакции с `ROLLBACK`.
- Выкладка: SQL (`docs.sp_loe_earved` → `docs.sp_loe_earved_batches` → `ou.execute_task`) выполняет пользователь, затем бэкенд (PM2). `ai_task` — отдельно (Docker).
