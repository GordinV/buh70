'use strict';

const fs = require('fs');
const path = require('path');
const xml2js = require('xml2js');

const DEFAULT_INPUT_FILE = path.join(__dirname, 'e-arved.xml');
const DEFAULT_OUTPUT_FILE = path.join(__dirname, 'e_arved.json');
const DEFAULT_REKVID = 63;
const DEFAULT_USERID = 2477;
const DEFAULT_DOKLAUSID = 1874;
const DEFAULT_NOMID = 17748;

/**
 * Приводит значение к массиву
 * @param {*} val
 * @returns {Array}
 */
function toArray(val) {
    if (val === null || val === undefined) {
        return [];
    }
    return Array.isArray(val) ? val : [val];
}

/**
 * Классифицирует код затрат CostObjective
 * @param {string} val
 * @returns {'kood1'|'kood2'|'kood5'|'tp'|null}
 */
function classifyCostObjective(val) {
    if (!val) {
        return null;
    }
    const str = String(val).trim();

    // kood2: Allikas (буквенно-символьный код, например "LE-P", "RE-P")
    if (/^[A-Za-z]+-[A-Za-z]+$/.test(str) || /^[A-Za-z]{2,}/.test(str)) {
        return 'kood2';
    }

    // tp: Tehingupartner (6 цифр, обычно 800xxx или 01-99xxx)
    if (/^800\d{3}$/.test(str) || (/^\d{6}$/.test(str) && (str.indexOf('80') === 0 || str.indexOf('01') === 0 || str.indexOf('70') === 0))) {
        return 'tp';
    }

    // kood1: Tegevusala (5 цифр, например "01112")
    if (/^\d{5}$/.test(str)) {
        return 'kood1';
    }

    // kood5: Eelarve artikkel (4 цифры, например "5500", "5513")
    if (/^\d{4}$/.test(str)) {
        return 'kood5';
    }

    return null;
}

/**
 * Извлекает все строки ItemEntry из структуры Invoice
 * @param {Object} invoice
 * @returns {Array}
 */
function extractItemEntries(invoice) {
    let items = [];
    if (!invoice || !invoice.InvoiceItem) {
        return items;
    }

    const invoiceItems = toArray(invoice.InvoiceItem);
    for (let i = 0; i < invoiceItems.length; i++) {
        const invItem = invoiceItems[i];
        if (invItem.ItemEntry) {
            items = items.concat(toArray(invItem.ItemEntry));
        }
        if (invItem.InvoiceItemGroup) {
            const groups = toArray(invItem.InvoiceItemGroup);
            for (let g = 0; g < groups.length; g++) {
                if (groups[g].ItemEntry) {
                    items = items.concat(toArray(groups[g].ItemEntry));
                }
            }
        }
    }
    return items;
}

/**
 * Преобразует одну строку счета ItemEntry в структуру gridData
 * @param {Object} item
 * @param {Object} [options]
 * @returns {Object}
 */
function convertInvoiceItem(item, options) {
    const opts = options || {};
    const defaultNomid = opts.nomid !== undefined ? opts.nomid : DEFAULT_NOMID;

    const description = item && item.Description ? String(item.Description) : '';

    let kogus = 1;
    if (item && item.ItemAmount !== undefined && item.ItemAmount !== '') {
        kogus = Number(item.ItemAmount);
    }

    let kbmta = 0;
    if (item && item.ItemSum !== undefined && item.ItemSum !== '') {
        kbmta = Number(item.ItemSum);
    } else if (item && item.VAT && item.VAT.SumBeforeVAT !== undefined && item.VAT.SumBeforeVAT !== '') {
        kbmta = Number(item.VAT.SumBeforeVAT);
    }

    let hind = kbmta;
    if (item && item.ItemPrice !== undefined && item.ItemPrice !== '') {
        hind = Number(item.ItemPrice);
    } else if (kogus !== 0) {
        hind = kbmta / kogus;
    }

    let kbm = 0;
    let km = '';
    if (item && item.VAT) {
        if (item.VAT.VATSum !== undefined) {
            kbm = Number(item.VAT.VATSum);
        }
        if (item.VAT.VATRate !== undefined) {
            km = String(item.VAT.VATRate);
        }
    }

    let summa = 0;
    if (item && item.ItemTotal !== undefined) {
        summa = Number(item.ItemTotal);
    }

    // Разбор аналитики бухгалтерского учета из Accounting / JournalEntry
    let konto = '';
    let kood1 = '';
    let kood2 = '';
    let kood5 = '';
    let tp = '';

    if (item && item.Accounting && item.Accounting.JournalEntry) {
        const entries = toArray(item.Accounting.JournalEntry);
        for (let i = 0; i < entries.length; i++) {
            const entry = entries[i];
            if (entry.GeneralLedger && !konto) {
                konto = String(entry.GeneralLedger).trim();
            }
            if (entry.CostObjective) {
                const co = String(entry.CostObjective).trim();
                const type = classifyCostObjective(co);
                if (type === 'kood1') {
                    kood1 = co;
                } else if (type === 'kood2') {
                    kood2 = co;
                } else if (type === 'kood5') {
                    kood5 = co;
                } else if (type === 'tp') {
                    tp = co;
                }
            }
        }
    }

    return {
        allikas_85: 0,
        allikas_muud: 0,
        allikas_taskuraha: 0,
        allikas_vara: 0,
        formula: '',
        hind: hind,
        id: 0,
        kbm: kbm,
        kbmta: kbmta,
        km: km,
        kogus: kogus,
        konto: konto,
        kood: '',
        kood1: kood1,
        kood2: kood2,
        kood3: '',
        kood4: '',
        kood5: kood5,
        kuurs: 0,
        muud: description,
        nimetus: description,
        nomid: defaultNomid,
        objekt: '',
        omavalitsuse_osa: 0,
        proj: '',
        soodus: 0,
        sugulane_osa: 0,
        summa: summa,
        taskuraha: 0,
        tp: tp,
        tunnus: '',
        uhik: '',
        umardamine: 0,
        userid: 0,
        valuuta: '',
        vastisik: ''
    };
}

/**
 * Извлекает значение eakOppositeAccount из ItemReserve
 * @param {Object} item
 * @returns {string}
 */
function extractOppositeAccount(item) {
    if (!item || !item.ItemReserve) {
        return '';
    }
    const reserves = toArray(item.ItemReserve);
    for (let r = 0; r < reserves.length; r++) {
        const res = reserves[r];
        if (res && res.extensionId === 'eakOppositeAccount') {
            return res.InformationContent !== undefined && res.InformationContent !== null ? String(res.InformationContent).trim() : '';
        }
    }
    return '';
}

/**
 * Извлекает информацию о согласовании/подтверждении (BPM / Confirmators) из структуры Invoice
 * Формат каждого элемента: { isik: string, kpv: string, rolli: string }
 * @param {Object} invoice
 * @returns {Array<{isik: string, kpv: string, rolli: string}>}
 */
function extractBpm(invoice) {
    const bpm = [];
    if (!invoice) {
        return bpm;
    }

    const seen = new Set();
    const addEntry = (isik, kpv, rolli) => {
        const cleanIsik = String(isik || '').trim();
        const cleanKpv = String(kpv || '').trim();
        const cleanRolli = String(rolli || '').trim();
        if (!cleanIsik && !cleanKpv) {
            return;
        }
        const key = `${cleanIsik}|${cleanKpv}|${cleanRolli}`;
        if (!seen.has(key)) {
            seen.add(key);
            bpm.push({
                isik: cleanIsik,
                kpv: cleanKpv,
                rolli: cleanRolli
            });
        }
    };

    const defaultKpv = invoice.InvoiceInformation && invoice.InvoiceInformation.InvoiceDate
        ? String(invoice.InvoiceInformation.InvoiceDate).trim()
        : '';

    // 1. Поиск расширений Extension (Finbite / Omniva XML)
    const extensions = [];
    if (invoice.InvoiceInformation && invoice.InvoiceInformation.Extension) {
        extensions.push(...toArray(invoice.InvoiceInformation.Extension));
    }
    if (invoice.Extension) {
        extensions.push(...toArray(invoice.Extension));
    }
    if (invoice.InvoiceExtension) {
        extensions.push(...toArray(invoice.InvoiceExtension));
    }

    for (let i = 0; i < extensions.length; i++) {
        const ext = extensions[i];
        if (!ext) continue;

        const extId = (ext.extensionId || ext.id || '').trim();
        const content = (ext.InformationContent !== undefined && ext.InformationContent !== null)
            ? String(ext.InformationContent).trim()
            : '';
        const name = (ext.InformationName !== undefined && ext.InformationName !== null)
            ? String(ext.InformationName).trim()
            : '';

        if (!extId && !content) continue;

        const lowerExtId = extId.toLowerCase();

        if (lowerExtId === 'eakconfirmation') {
            // Формат: "47608105226|Jelena Golubeva|VERIFIED|"
            const parts = content.split('|').map(s => s.trim());
            let isik = '';
            let rolli = 'kinnitaja';

            if (parts.length >= 2 && parts[1]) {
                isik = parts[1];
            } else if (parts.length >= 1 && parts[0]) {
                isik = parts[0];
            }

            if (parts.length >= 3 && parts[2]) {
                rolli = parts[2];
            }

            const kpv = name || defaultKpv;
            addEntry(isik, kpv, rolli);
        } else if (lowerExtId === 'eakconfirmationcreator' || lowerExtId === 'eakconfirmcreator') {
            // Формат: "48612183747|Anastassia Moldon"
            const parts = content.split('|').map(s => s.trim());
            let isik = '';
            if (parts.length >= 2 && parts[1]) {
                isik = parts[1];
            } else if (parts.length >= 1 && parts[0]) {
                isik = parts[0];
            }

            const kpv = name || defaultKpv;
            const rolli = 'creator';
            addEntry(isik, kpv, rolli);
        }
    }

    // 2. Стандартные или специализированные теги ConfirmationList / ConfirmationGroup / Confirmator / bpm / v_xml_arv_confirmators
    const confirmList = invoice.ConfirmationList ||
        (invoice.InvoiceInformation && invoice.InvoiceInformation.ConfirmationList) ||
        invoice.ConfirmationGroup ||
        invoice.bpm ||
        invoice.v_xml_arv_confirmators ||
        invoice.confirmators;

    if (confirmList) {
        const rawItems = toArray(
            confirmList.Confirmation ||
            confirmList.Confirmator ||
            confirmList.confirmators ||
            confirmList.row ||
            confirmList
        );

        for (let i = 0; i < rawItems.length; i++) {
            const item = rawItems[i];
            if (!item || typeof item !== 'object') continue;

            const isik = item.isik || item.Confirmator || item.PersonName || item.Name || item.userName || '';
            const kpv = item.kpv || item.ConfirmationDate || item.Date || item.date || defaultKpv;
            const rolli = item.rolli || item.roll || item.Role || item.role || item.ConfirmationStatus || 'kinnitaja';

            addEntry(isik, kpv, rolli);
        }
    }

    return bpm;
}

/**
 * Преобразует объект счета Invoice в целевую структуру { id: 0, data: { ... } }
 * @param {Object} invoice
 * @param {Object} [options]
 * @returns {Object}
 */
function convertInvoice(invoice, options) {
    const opts = options || {};
    const defaultRekvid = opts.rekvid !== undefined ? opts.rekvid : DEFAULT_REKVID;
    const defaultUserid = opts.userid !== undefined ? opts.userid : DEFAULT_USERID;
    const defaultDoklausid = opts.doklausid !== undefined ? opts.doklausid : DEFAULT_DOKLAUSID;

    // Сведения о продавце
    const seller = invoice && invoice.InvoiceParties && invoice.InvoiceParties.SellerParty ? invoice.InvoiceParties.SellerParty : {};
    const rawSellerReg = seller.RegNumber !== undefined ? String(seller.RegNumber).trim() : '';
    // Согласно уточнению пользователя: вместо asutusid пишем RegNumber продавца (числом при возможности, иначе строка)
    let sellerRegNumber = rawSellerReg;
    if (rawSellerReg !== '' && !isNaN(Number(rawSellerReg))) {
        sellerRegNumber = Number(rawSellerReg);
    }

    // Сведения о покупателе
    const buyer = invoice && invoice.InvoiceParties && invoice.InvoiceParties.BuyerParty ? invoice.InvoiceParties.BuyerParty : {};
    let buyerRegNumber = '';
    if (buyer.RegNumber !== undefined) {
        buyerRegNumber = String(buyer.RegNumber).trim();
    } else if (invoice.regNumber !== undefined) {
        buyerRegNumber = String(invoice.regNumber).trim();
    }

    // Сведения о счете
    const info = invoice && invoice.InvoiceInformation ? invoice.InvoiceInformation : {};
    const invoiceNumber = info.InvoiceNumber ? String(info.InvoiceNumber).trim() : '';
    const invoiceDate = info.InvoiceDate ? String(info.InvoiceDate).replace(/-/g, '').trim() : '';

    // Сведения о платеже
    const payment = invoice && invoice.PaymentInfo ? invoice.PaymentInfo : {};
    const aa = payment.PayToAccount ? String(payment.PayToAccount).trim() : '';
    let dueDate = '';
    if (info.DueDate) {
        dueDate = String(info.DueDate).replace(/-/g, '').trim();
    } else if (payment.PayDueDate) {
        dueDate = String(payment.PayDueDate).replace(/-/g, '').trim();
    }

    let viitenr = '';
    if (info.PaymentReferenceNumber) {
        viitenr = String(info.PaymentReferenceNumber).trim();
    } else if (payment.PaymentRefId) {
        viitenr = String(payment.PaymentRefId).trim();
    }

    // Суммы счета
    const sumGroup = invoice && invoice.InvoiceSumGroup ? invoice.InvoiceSumGroup : {};
    let kbmta = 0;
    if (sumGroup.InvoiceSum !== undefined) {
        kbmta = Number(sumGroup.InvoiceSum);
    } else if (sumGroup.VAT && sumGroup.VAT.SumBeforeVAT !== undefined) {
        kbmta = Number(sumGroup.VAT.SumBeforeVAT);
    }

    let kbm = 0;
    if (sumGroup.VAT && sumGroup.VAT.VATSum !== undefined) {
        kbm = Number(sumGroup.VAT.VATSum);
    }

    let summa = 0;
    if (sumGroup.TotalSum !== undefined) {
        summa = Number(sumGroup.TotalSum);
    }

    // Строки счета
    const itemEntries = extractItemEntries(invoice);
    const gridData = [];
    let headerKorrKonto = '';
    for (let i = 0; i < itemEntries.length; i++) {
        const rawItem = itemEntries[i];
        if (!headerKorrKonto) {
            headerKorrKonto = extractOppositeAccount(rawItem);
        }
        gridData.push(convertInvoiceItem(rawItem, opts));
    }

    // Извлечение информации BPM / согласования
    const bpm = extractBpm(invoice);

    return {
        id: 0,
        data: {
            aa: aa,
            aadress: '',
            alus_arve_id: 0,
            arvid: 0,
            asutus: '',
            asutusid: sellerRegNumber,
            bpm: bpm,
            created: '',
            doc: '',
            doc_status: 0,
            doc_type_id: '',
            doklausid: defaultDoklausid,
            dokprop: '',
            id: 0,
            is_show_journal: 0,
            jaak: 0,
            journalid: 0,
            kbm: kbm,
            kbmkonto: '',
            kbmta: kbmta,
            kmkr: '',
            konto: '',
            koostaja: '',
            korr_konto: headerKorrKonto,
            kpv: invoiceDate,
            kr_number: '',
            lastupdate: '',
            laus_nr: 0,
            liik: 1,
            lisa: '',
            muud: '',
            number: invoiceNumber,
            objekt: '',
            objektid: 0,
            operid: 0,
            raha_saaja: '',
            regkood: '',
            rekvid: defaultRekvid,
            rekv_regkood: buyerRegNumber,
            status: '',
            summa: summa,
            tahtaeg: dueDate,
            taskuraha_kov: 0,
            tasud: '        ',
            tasudok: '',
            tyyp: '',
            umardamine: 0,
            userid: defaultUserid,
            viitenr: viitenr,
            gridData: gridData
        }
    };
}

/**
 * Находит дочернее свойство объекта без учета регистра и пространства имен
 * @param {Object} obj
 * @param {string} name
 * @returns {*}
 */
function findChild(obj, name) {
    if (!obj || typeof obj !== 'object') {
        return null;
    }
    const target = name.toLowerCase();
    const keys = Object.keys(obj);
    for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const local = key.indexOf(':') !== -1 ? key.split(':')[1] : key;
        if (local.toLowerCase() === target || key.toLowerCase() === target) {
            return obj[key];
        }
    }
    return null;
}

/**
 * Извлекает массив счетов из распарсенного объекта XML
 * @param {Object} parsedObj
 * @returns {Array}
 */
function extractInvoicesFromParsed(parsedObj) {
    if (!parsedObj) {
        return [];
    }

    let current = parsedObj;

    // Пропуск SOAP Envelope / Body
    const env = findChild(current, 'Envelope');
    if (env) {
        current = env;
    }

    const body = findChild(current, 'Body');
    if (body) {
        current = body;
    }

    // Пропуск BuyInvoiceExportResponse
    const resp = findChild(current, 'BuyInvoiceExportResponse');
    if (resp) {
        current = resp;
    }

    // Пропуск E_Invoice
    const eInvoice = findChild(current, 'E_Invoice') || findChild(current, 'EInvoice');
    if (eInvoice) {
        current = eInvoice;
    }

    const invoices = findChild(current, 'Invoice');
    if (invoices) {
        return toArray(invoices);
    }

    if (current && current.Invoice) {
        return toArray(current.Invoice);
    }

    return [];
}

/**
 * Главная функция: преобразует XML (строку или файл) в JSON массив счетов
 * @param {string|Buffer} [inputXmlOrPath] - строка XML, Buffer или путь к файлу XML
 * @param {Object} [options] - дополнительные параметры
 * @param {string|boolean|null} [options.outputFile] - путь для сохранения JSON (null или false для отключения)
 * @param {boolean} [options.asString] - вернуть в виде строки JSON
 * @param {number} [options.rekvid]
 * @param {number} [options.userid]
 * @param {number} [options.doklausid]
 * @param {number} [options.nomid]
 * @returns {Promise<Array|string>}
 */
function xmlToJson(inputXmlOrPath, options) {
    const opts = options || {};

    // Если передан пустой XML (null или пустая строка) - возвращаем пустой результат
    if (inputXmlOrPath === null || inputXmlOrPath === undefined || inputXmlOrPath === '') {
        return Promise.resolve(opts.asString ? '[]' : []);
    }

    if (typeof inputXmlOrPath === 'string' && inputXmlOrPath.trim() === '') {
        return Promise.resolve(opts.asString ? '[]' : []);
    }

    const input = inputXmlOrPath !== undefined ? inputXmlOrPath : DEFAULT_INPUT_FILE;

    return new Promise((resolve, reject) => {
        let xmlContent = '';

        if (typeof input === 'string') {
            if (input.indexOf('<') !== -1) {
                xmlContent = input.trim();
            } else {
                try {
                    xmlContent = fs.readFileSync(input, 'utf8');
                } catch (err) {
                    return reject(new Error('Не удалось прочитать файл XML [' + input + ']: ' + err.message));
                }
            }
        } else if (Buffer.isBuffer(input)) {
            xmlContent = input.toString('utf8');
        } else {
            return reject(new Error('Некорректный входной параметр: ожидалась строка XML или путь к файлу'));
        }

        // Удаление символа BOM, если он присутствует
        if (xmlContent.charCodeAt(0) === 0xFEFF) {
            xmlContent = xmlContent.substring(1);
        }

        if (!xmlContent.trim()) {
            return resolve(opts.asString ? '[]' : []);
        }

        const parser = new xml2js.Parser({
            explicitArray: false,
            mergeAttrs: true,
            trim: true
        });

        parser.parseString(xmlContent, (err, parsedResult) => {
            if (err) {
                return reject(new Error('Ошибка парсинга XML: ' + err.message));
            }

            try {
                const invoices = extractInvoicesFromParsed(parsedResult);
                const result = [];

                for (let i = 0; i < invoices.length; i++) {
                    result.push(convertInvoice(invoices[i], opts));
                }

                // Сохраняем в файл только если явно задан outputFile
                if (opts.outputFile) {
                    const jsonString = JSON.stringify(result, null, 2);
                    fs.writeFileSync(opts.outputFile, jsonString, 'utf8');
                    console.log('[xmlToJson] Результат успешно сохранен в файл:', opts.outputFile);
                }

                resolve(opts.asString ? JSON.stringify(result, null, 2) : result);
            } catch (convErr) {
                reject(convErr);
            }
        });
    });
}

// Запуск напрямую через CLI
if (require.main === module) {
    const inputFile = process.argv[2] || DEFAULT_INPUT_FILE;
    const outputFile = process.argv[3] || DEFAULT_OUTPUT_FILE;

    xmlToJson(inputFile, { outputFile: outputFile })
        .then((res) => {
            console.log('[xmlToJson] Преобразовано счетов: ' + (Array.isArray(res) ? res.length : 0));
            process.exit(0);
        })
        .catch((err) => {
            console.error('[xmlToJson] Ошибка:', err.message);
            process.exit(1);
        });
}

module.exports = xmlToJson;
module.exports.xmlToJson = xmlToJson;
module.exports.xml_to_json = xmlToJson;
module.exports.convertInvoice = convertInvoice;
module.exports.convertInvoiceItem = convertInvoiceItem;
module.exports.classifyCostObjective = classifyCostObjective;
module.exports.extractInvoicesFromParsed = extractInvoicesFromParsed;
module.exports.extractItemEntries = extractItemEntries;
module.exports.extractBpm = extractBpm;
module.exports.findChild = findChild;
module.exports.DEFAULT_INPUT_FILE = DEFAULT_INPUT_FILE;
module.exports.DEFAULT_OUTPUT_FILE = DEFAULT_OUTPUT_FILE;
module.exports.DEFAULT_REKVID = DEFAULT_REKVID;
module.exports.DEFAULT_USERID = DEFAULT_USERID;
module.exports.DEFAULT_DOKLAUSID = DEFAULT_DOKLAUSID;
module.exports.DEFAULT_NOMID = DEFAULT_NOMID;
