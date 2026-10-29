---
name: e-tsd
description: >-
  Руководство по разработке, архитектуре, схемам и валидации налоговой декларации TSD 2026
  (APA-TSD / XBRL GL 2015-03-25). Содержит правила хранения файлов проекта, требования MTA
  и запрет на сохранение постоянных файлов в c:\temp\buh60.
---

# E-TSD (APA-TSD 2026 / XBRL GL) — Разработка и валидация

Данный скил регламентирует работу с проектом новой машиночитаемой декларации TSD (Andmepõhine TSD / APA-TSD) для Налогово-таможенного департамента Эстонии (MTA).

---

## ⚠️ КРИТИЧЕСКОЕ ПРАВИЛО РАЗМЕЩЕНИЯ ФАЙЛОВ

> [!CAUTION]
> **Категорически запрещено использовать папку `c:\temp\buh60` и `c:\temp\buh60\EDOK` для постоянного размещения файлов проекта!**
> 
> - Папка `c:\temp\buh60` и `c:\temp\buh60\EDOK` предназначена **исключительно как временный буфер** (legacy-каталог выгрузок из FoxPro).
> - **Основной постоянный каталог проекта:**
>   📂 **`C:\development\buh70\routes\ai\e-tsd\`**
> - Все проектные файлы, документация, схемы XSD, zip-архивы (`tsd_schemas_2026.zip`), отчеты и графы знаний (`graphify-out/`) должны сохраняться **только в `C:\development\buh70\routes\ai\e-tsd\`**.
> - Если промежуточные файлы создаются в `c:\temp\buh60`, они должны быть незамедлительно перенесены в каталог проекта, а временный буфер — очищен.

---

## 1. Структура проекта `e-tsd`

- **Корневой каталог:** [`C:\development\buh70\routes\ai\e-tsd\`](file:///C:/development/buh70/routes/ai/e-tsd/)
- **Документация и спецификации MTA:** [`docs/`](file:///C:/development/buh70/routes/ai/e-tsd/docs/)
  - `docs/XBRL-GL-REC-2015-03-25/` — полная таксономия XBRL GL 2015-03-25
  - `docs/APA_TSD_XSD_naidised/` — специализированные схемы от MTA с суффиксом `-apatsd.xsd`
  - `docs/Juhendid_ja_arireeglid/` — технические руководства и правила X-Road (X-Tee)
- **Архив схем для облачной валидации:** [`tsd_schemas_2026.zip`](file:///C:/development/buh70/routes/ai/e-tsd/tsd_schemas_2026.zip)
  - Публикуется в GCS бакет: `gs://check_xml_bucket/xsd/tsd_schemas_2026.zip`
- **Граф знаний проекта:** [`graphify-out/`](file:///C:/development/buh70/routes/ai/e-tsd/graphify-out/)
  - `graph.html` — интерактивная визуализация графа
  - `GRAPH_REPORT.md` — отчет о связях и сообществах
- **Генератор TSD XML (бэкенд buh70):** [`C:\development\buh70\routes\palk\calcTSDXML.js`](file:///C:/development/buh70/routes/palk/calcTSDXML.js)
- **SQL-функция данных декларации (`palk.tsd_lisa_2026`):** [`C:\development\buh70\sql\aruanned\palk\palk.tsd_2026.sql`](file:///C:/development/buh70/sql/aruanned/palk/palk.tsd_2026.sql)
- **Модель отчета TSD 2026 (`tsd_2026`):** [`C:\development\buh70\models\aruanned\palk\tsd_2026.js`](file:///C:/development/buh70/models/aruanned/palk/tsd_2026.js) и [`tsd_2026.xml`](file:///C:/development/buh70/models/aruanned/palk/tsd_2026.xml)
- **Сервис отправки в MTA по X-Road:** [`C:\development\buh70\routes\palk\sendTSD.js`](file:///C:/development/buh70/routes/palk/sendTSD.js)
- **Облачный сервис валидации XML (`check-xml`):** [`C:\development\buh70\routes\ai\e-tsd\check_xml\main.py`](file:///C:/development/buh70/routes/ai/e-tsd/check_xml/main.py)
  - Endpoint: `https://check-xml-1088344506167.europe-north1.run.app` (GCP проект: `project-76db5b4b-6de8-4e1f-b88`, регион: `europe-north1`)
- **Парсер JSON-ответов на клиенте FoxPro:** [`C:\development\buh62\proc\jsonParse.prg`](file:///C:/development/buh62/proc/jsonParse.prg)
- **Генератор XLS-отчета сверки `saadetud_tsd.xml` и `error_report.xml` (VFP 8.0):** [`C:\development\buh62\proc\calc_tsd_2026_report_xls.prg`](file:///C:/development/buh62/proc/calc_tsd_2026_report_xls.prg)
- **План и спецификация сверки ошибок MTA (`tsd_veade_analuus.md`):** [`C:\development\buh70\routes\ai\e-tsd\tsd_veade_analuus.md`](file:///C:/development/buh70/routes/ai/e-tsd/tsd_veade_analuus.md)

---

## 2. Стандарты валидации структуры TSD 2026

При формировании и валидации декларации должны соблюдаться правила:
1. **Корень:** `<xbrli:xbrl>` со всеми пространствами имен (`xbrli`, `gl-cor`, `gl-bus`, `gl-muc`, `iso4217`).
2. **Контекст:** `<xbrli:context id="now">` с регистрационным кодом и датой instant.
3. **Период:** даты `periodCoveredStart` (`kpv1`) и `periodCoveredEnd` (`kpv2`) строго в рамках **одного календарного месяца**.
4. **Секции выплат:** номера `entryNumber` начинаются строго с `EE020100` (например, `EE0201001`, `EE0201002`, `EE0201003`).
5. **Транзакции:** в каждом `entryDetail`:
   - `accountSub` с типом `VALJAMLIIK2023ap` (вид выплаты)
   - `accountSub` с типом `TOIMINGUTYYP2023ap` (значение `R` — первичная подача, `M` — изменение, `T` — аннулирование)
   - `amount` (`<gl-cor:amount>`) — **брутто-сумма выплаты** (`row.summa`, до удержания налогов, с 2 знаками). В `palk.tsd_lisa_2026` колонка `vm_summa` содержит нетто-сумму «на руки», но в XML `<gl-cor:amount>` всегда передается **брутто-сумма (`summa`)**, так как по правилам MTA `KR_SM_01_2` и `KR_MVT_08` база соцналога `TSD_SMVM` обязана совпадать с `<gl-cor:amount>`, а удержанные налоги (`TSD_KTM`, `TSD_TK`, `TSD_KP`) и `MVT` проверяются от брутто-суммы.
   - `identifierReference` с `ISIKUKOOD` (`EE` + 11 цифр)
   - `documentDate` (`<gl-cor:documentDate>`) — дата фактической выплаты (`docDate`), устанавливается равной концу периода **`kpv2`** (должна принадлежать отчетному периоду `kpv1..kpv2`, правило `KR_XBRL_VALJAMAKSED_17`).
   - `measurable` с кодом события `TSD01` (классификатор `SYNDMUS2017ap`, тег `<gl-bus:measurableStartDateTime>`) — **дата начисления обязательства** (`earningDate` / *Arvestuse kuupäev*). По правилу MTA `KR_YLD_25` не может быть позже даты выплаты (`earningDate <= documentDate`). При выплате в том же месяце, что и начисление, `earningDate` устанавливается равной концу периода **`kpv2`**. Для секции `EE0201003` (ESD) поля `TSD01`, `documentDate` и `amount` указывать запрещено (правило `KR_YLD_09`).
6. **Налоги (`taxes`):**
   - Порядок тегов XSD строго: `<taxAmount>` ПЕРЕД `<taxCode>`!
   - Допустимые коды налогов: `TSD_SM`, `TSD_KP`, `TSD_TK`, `TSD_TTK`, `TSD_KTM`.

7. **Корректировки и возвраты выплат прошлых периодов (бывшая форма Lisa 1b):**
   В APA-TSD 2026 отдельной формы Lisa 1b нет, данные передаются отдельными проводками `<gl-cor:entryDetail>` внутри секций `EE0201001` (резиденты) или `EE0201002` (нерезиденты):
   - **Отрицательные корректировки (возвраты, удержания, сторно выплат прошлых месяцев):**
     - Все суммы (`gl-cor:amount`, базы `measurableQuantity`, налоги `taxAmount`) обязаны быть **строго отрицательными (`<= 0`)** (правило MTA `KR_YLD_24`). Обычные выплаты регулируются правилом `KR_YLD_30` (только `>= 0`).
     - **Событие `TSD02` (Tagasimakse tunnus):** Обязательно добавляется блок `<gl-bus:measurable>` с `measurableID = 'TSD02'` (классификатор `SYNDMUS2017ap`), в котором в `<gl-bus:measurableStartDateTime>` **обязательно указывается дата исходной выплаты прошлого периода** (правило MTA `KR_YLD_14`).
     - В секции `EE0201003` (ESD) указывать событие `TSD02` категорически **запрещено** (правило MTA `KR_YLD_32`).
     - **Сохранение минимального соцналога (`TSD_SMVMSK`):** Если в исходном периоде у работодателя сохранялось минимальное обязательство по соцналогу (бывший код 1400 формы Lisa 1b), передается показатель `<gl-bus:measurable>` с кодом `TSD_SMVMSK` (`measurableQuantity < 0`). Показатель `TSD_SMVMSK` разрешен **только** для строк с `TSD02` (правило `KR_SM_13`) и только для видов выплат, где предусмотрен минимальный соцналог (правило `KR_SM_14`).
     - Формула соцналога с учетом возврата (правило `KR_SM_04`):
       `SM = (TSD_SMVM - TSD_OPTV_SM_VAHENDUS - TSD_KUUMVAHENDUS + TSD_KUUMSUURENDUS - TSD_SMVMSK) * Määr%`.
   - **Положительные корректировки (доначисления за прошлые периоды):**
     - По кассовому методу TSD передаются как обычные выплаты с положительной суммой (`gl-cor:amount > 0`) **без блока `TSD02`**. В `TSD01` указывается дата начисления перерасчета, в `documentDate` — дата выплаты в текущем периоде.
   - **Запрет смешивания в одну проводку:** Запрещено объединять (сальдировать) текущие начисления и возвраты прошлых периодов в один `entryDetail`. Каждая операция возврата с датой прошлого периода должна подаваться отдельной проводкой со своим `TSD02`.

---

## 3. Архитектура облачного валидатора `check-xml` и AI-аудита (Gemini)

1. **Формат JSON-ответа (`make_json_response`):**
   - Сервис обязан возвращать JSON без алфавитной сортировки ключей (`json.dumps(..., ensure_ascii=False)`), где **первым полем всегда идет логическое `"valid": true | false`**, за ним `"errors": [...]` и при наличии промпта — `"gemini_analysis": "..."`.
   - На стороне FoxPro ([`jsonParse.prg`](file:///C:/development/buh62/proc/jsonParse.prg)) многострочные ответы `gemini_analysis` декодируются через бинарные UTF-8 чанки `STRCONV(0h..., 11)`, что исключает ошибки длины строковых литералов VFP (255 символов) и спецсимволов.

2. **Сжатие XML в компактный табличный формат (CSV/TSV) при передаче `prompt` (`format_xml_for_gemini`):**
   - Чтобы исключить ошибку **`400 The input token count exceeds the maximum number of tokens allowed 1048576`** на больших декларациях (например, сводный `tsd_2026.xml` на 5.6 МБ / ~1.6 млн токенов), сырой XML **не вставляется целиком** в промпт Gemini.
   - Если в запросе задан `prompt` (например, поиск аномалий, проверка `isikukood` и структуры), функция `format_xml_for_gemini` трансформирует документ в компактное представление:
     - Метаданные шапки и предрассчитанные парсером контрольные суммы по всем строкам;
     - Образец первого XML-элемента (`1st entryDetail` или `1st tsd_L1_A_Isik`) для аудита структуры тегов;
     - Полная таблица всех транзакций в формате CSV с разделителем `;` (сжатие объема в **6–25 раз** без потери ни одной записи).
   - Поддерживаются специализированные конвертеры для `TSD_2026` (`<xbrli:xbrl>`), `TSD_LISA1A` (`<tsd_vorm>`) и `Makseandmik` (`<Makseandmik>`), а также безопасный лимит для прочих XML-форматов.

3. **Деплой сервиса `check-xml`:**
   ```powershell
   gcloud run deploy check-xml --source "C:\development\buh70\routes\ai\e-tsd\check_xml" --region europe-north1 --project project-76db5b4b-6de8-4e1f-b88 --memory 1Gi --allow-unauthenticated
   ```

---

## 4. Правила и ограничения сверки `saadetud_tsd.xml` и `error_report.xml` в VFP 8.0

При формировании сводной таблицы `.xls` из отправленной декларации (`saadetud_tsd.xml`, формат XBRL GL) и рапорта обратной связи MTA (`error_report.xml`, схема `feedbackReport.xsd`) на стороне Visual FoxPro 8.0 ([`calc_tsd_2026_report_xls.prg`](file:///C:/development/buh62/proc/calc_tsd_2026_report_xls.prg)) действуют следующие технические ограничения и бизнес-правила:

1. **Ограничения парсинга XML и экспорта XLS в VFP 8.0:**
   - Штатная функция `XMLTOCURSOR()` в VFP 8.0 **не поддерживает** иерархические многоуровневые структуры и пространства имен XBRL GL (`gl-cor:`, `gl-bus:`). Для чтения обоих файлов обязательно используется COM-объект **`MSXML2.DOMDocument`**.
   - Штатная выгрузка `COPY TO ... TYPE XL5` игнорирует поля типа `Memo` и обрезает строковые поля до **254 символов** (`C(254)`). Поэтому для сохранения полных текстов ошибок MTA (`<info>`, `<info_EN>`, `<info_RU>`) и цветовой маркировки ошибочных строк поверх базовой выгрузки `TYPE XL5` используется постобработка через **`CREATEOBJECT("Excel.Application")`** (с безопасным fallback на `XL5`, если MS Excel не установлен).

2. **Обязательный предконтроль соответствия двух файлов друг другу:**
   Перед слиянием данных из `saadetud_tsd.xml` и `error_report.xml` проверяется:
   - **Регистрационный код организации (`regkood`):** совпадение `<xbrli:identifier>` и `<gl-bus:organizationIdentifier>` внутри `saadetud_tsd.xml`, соответствие рег. коду текущего учреждения в VFP (`qryRekv.regkood` / `v_rekv.regkood` / параметру `tcExpectedRegkood`) и рег. коду в `error_report.xml` (если присутствует).
   - **Количество операций:** общее число транзакций `<gl-cor:entryDetail>` в `saadetud_tsd.xml` обязано совпадать с числом проверенных строк `<validation>` и `<responseData>/<entryDetail>` в `error_report.xml` (например, `73 == 73`).
   - **Идентификаторы строк и личные коды:** каждый ключ `sektsioon` (`entryNumber`) + `lineInternalId` (`Tehing_1..N`) из `error_report.xml` должен существовать в `saadetud_tsd.xml`, а личный код (`EE` + 11 цифр), упомянутый в тексте ошибки `<info>`, должен совпадать с `<gl-cor:identifierCode>` соответствующей строки в `saadetud_tsd.xml`.

3. **Поведение при несоответствии файлов:**
   - Если хотя бы одна из проверок соответствия не пройдена (не совпадает рег. код организации, количество операций или ключи `Tehing_N`), слияние файлов **блокируется**.
   - Пользователю выдается предупреждение (`MESSAGEBOX` и заметная шапка в `.xls`) о том, что файлы не соответствуют друг другу, с перечислением причин расхождения.
   - В этом случае таблица `.xls` формируется **только из ошибок** файла `error_report.xml` (`errorLevel <> "OK"` или код `<data>` не начинается с `TSD_`).

4. **Поведение при пустом или не заданном файле ошибок (`error_report.xml` отсутствует):**
   - Путь к файлу декларации по умолчанию фиксирован как `C:\temp\buh60\EDOK\tsd_2026.xml` (выходной файл по умолчанию — `C:\temp\buh60\EDOK\tsd_2026_report.xls`).
   - Если файл ошибок не выбран пользователем в диалоге `GETFILE()`, не передан в параметре `tcErrorReportXml`, не существует на диске или пуст (ошибок нет), выполнение **не прерывается**: таблица `.xls` формируется целиком на основании данных декларации (`tsd_2026.xml`) со статусом `status = "OK"` по всем операциям.
   - После формирования и сохранения `.xls` файла он автоматически открывается через `launch_xls(lcOutputXls, JUSTPATH(lcOutputXls))` (`ShellExecute`).
