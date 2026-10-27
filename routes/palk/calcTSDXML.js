'use strict';
const xmlbuilder = require('xmlbuilder');
const xml2js = require('xml2js');
const moment = require('moment');
const getNow = require('../../libs/getNow');
const db = require("../../libs/db");

const FLOW_NAME = 'calcTSDXML';

//const config = require("../../config/default.json");
const config = require("../../config/narvalv.json");

/**
 * Проверка флага агентского режима в параметрах запроса
 * @param {Object} params
 * @returns {boolean}
 */
function checkIsAgent(params) {
    const val = params.is_agent !== undefined
        ? params.is_agent
        : (params.isAgent !== undefined ? params.isAgent : params.agent);

    if (val !== undefined && val !== null) {
        return val === true || val === 'true' || val === 1 || val === '1';
    }
    return params.mode === 'agent';
}

/**
 * Получение данных TSD декларации из БД
 * @param {number} userId
 * @param {string} execDate
 * @param {number} isSummary
 * @returns {Promise<Array<Object>>}
 */
async function getTSDData(userId, execDate = getNow(), isSummary = 0) {
    const sql = `with
                     params as (
                         select
                             date(year($1::date), month($1::date), 1) as kpv1,
                             get_last_day($1)::date                   as kpv2,
                             r.id                                     as rekv_id,
                             $3::integer                              as kond,
                             r.regkood
                         from
                             ou.rekv   r,
                             ou.userid u
                         where
                               u.id = $2::integer
                           and r.id = u.rekvid::integer
                     )
                 select
                     p.regkood::text as regkood,
                     p.kpv1,
                     p.kpv2,
                     year(p.kpv2)    as aasta,
                     month(p.kpv2)   as kuu,
                     qry.*
                 from
                     params p,
                     palk.tsd_lisa_2026(p.kpv1::date, p.kpv2::date, p.rekv_id::integer, p.kond::integer) qry
                 order by
                     qry.sektsioon, qry.isikukood, qry.tululiik;`;

    const tsd_data = await db.queryDb(sql, [execDate, userId, isSummary], null, null, null, null, config);
    return tsd_data && tsd_data.data ? tsd_data.data : [];
}

/**
 * Форматирование денежных и числовых величин для XML (XBRL GL)
 * @param {number|string} val
 * @returns {string}
 */
function formatAmount(val) {
    if (val === undefined || val === null || isNaN(val)) return '0';
    const num = Math.round(Number(val) * 100) / 100;
    if (Number.isInteger(num)) return num.toString();
    return num.toFixed(2);
}

/**
 * Безопасное форматирование даты в формат YYYY-MM-DD
 * @param {Date|string} val
 * @returns {string}
 */
function formatDate(val) {
    if (!val) return moment().format('YYYY-MM-DD');
    return moment(val).format('YYYY-MM-DD');
}

/**
 * Извлечение текстового значения из узла xml2js
 * @param {*} node
 * @returns {string}
 */
function getText(node) {
    if (node === null || node === undefined) return '';
    if (typeof node === 'string') return node.trim();
    if (typeof node === 'number') return String(node);
    if (typeof node === 'object') {
        if (node._ !== undefined) return String(node._).trim();
        if (Array.isArray(node) && node.length > 0) return getText(node[0]);
    }
    return String(node).trim();
}

/**
 * Преобразование букв эстонского алфавита (õ, ä, ö, ü, š, ž, Õ, Ä, Ö, Ü, Š, Ž)
 * и других не-ASCII символов в стандартные числовые XML-сущности (numeric character references)
 * Гарантирует корректную передачу без появления знаков '?' в среде Windows-1251 и FoxPro
 * @param {string} str
 * @returns {string}
 */
function escapeEstonianXmlEntities(str) {
    if (!str) return '';
    return String(str).replace(/[^\x00-\x7F]/g, char => `&#${char.charCodeAt(0)};`);
}

/**
 * Преобразование данных TSD в формат XML (XBRL GL 2015-03-25) согласно требованиям MTA
 * @param {Array<Object>} tsdData
 * @param {Object} [options]
 * @returns {Promise<string>}
 */
async function convertToXML(tsdData, options = {}) {
    if (!tsdData || !Array.isArray(tsdData) || tsdData.length === 0) {
        throw new Error('Puuduvad TSD andmed XML genereerimiseks');
    }

    const firstRow = tsdData[0];
    const regkood = (firstRow.regkood || options.regkood || '').trim();
    if (!regkood) {
        throw new Error('Puudub asutuse registrikood (regkood)');
    }

    const nowDate = formatDate(options.createdDate || new Date());
    const periodCoveredStart = formatDate(firstRow.kpv1 || options.kpv1);
    const periodCoveredEnd = formatDate(firstRow.kpv2 || options.kpv2);
    const docDate = formatDate(options.documentDate || firstRow.kpv2 || options.kpv2);
    const earningDate = formatDate(options.earningDate || firstRow.kpv2 || options.kpv2);

    const uniqueId = `${regkood}-${moment().format('YYYY-MM-DDTHH:mm:ss')}`;
    const creator = options.creator || 'Buh70';
    const sourceApp = options.sourceApplication || 'Raamatupidamistarkvara Buh70';

    const root = xmlbuilder.create('xbrli:xbrl', { encoding: 'utf-8' })
        .att('xmlns:xbrli', 'http://www.xbrl.org/2003/instance')
        .att('xmlns:xlink', 'http://www.w3.org/1999/xlink')
        .att('xmlns:xbrll', 'http://www.xbrl.org/2003/linkbase')
        .att('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance')
        .att('xmlns:gl-usk', 'http://www.xbrl.org/int/gl/usk/2015-03-25')
        .att('xmlns:gl-cor', 'http://www.xbrl.org/int/gl/cor/2015-03-25')
        .att('xmlns:gl-ext', 'http://www.xbrl.org/int/gl/ext/2015-03-25')
        .att('xmlns:iso639', 'http://www.xbrl.org/2005/iso639')
        .att('xmlns:iso4217', 'http://www.xbrl.org/2003/iso4217')
        .att('xmlns:gl-plt', 'http://www.xbrl.org/int/gl/plt/2015-03-25')
        .att('xmlns:gl-bus', 'http://www.xbrl.org/int/gl/bus/2015-03-25')
        .att('xmlns:gl-muc', 'http://www.xbrl.org/int/gl/muc/2015-03-25')
        .att('xsi:schemaLocation', 'http://www.xbrl.org/int/gl/plt/2015-03-25 https://www.xbrl.org/taxonomy/int/gl/2015-03-25/plt/case-c-b-m-u-t/gl-plt-all-2015-03-25.xsd');

    // schemaRef
    root.ele('xbrll:schemaRef', {
        'xlink:href': '../plt/case-c-b-m-e/gl-plt-2015-03-25.xsd',
        'xlink:arcrole': 'http://www.w3.org/1999/xlink/properties/linkbase',
        'xlink:type': 'simple'
    });

    // context "now"
    const context = root.ele('xbrli:context', { id: 'now' });
    context.ele('xbrli:entity')
        .ele('xbrli:identifier', { scheme: 'http://www.ariregister.rik.ee' }, regkood);
    context.ele('xbrli:period')
        .ele('xbrli:instant', nowDate);

    // units
    root.ele('xbrli:unit', { id: 'eur' })
        .ele('xbrli:measure', 'iso4217:EUR');
    root.ele('xbrli:unit', { id: 'NotUsed' })
        .ele('xbrli:measure', 'pure');

    // accountingEntries
    const entries = root.ele('gl-cor:accountingEntries');

    // documentInfo
    const docInfo = entries.ele('gl-cor:documentInfo');
    docInfo.ele('gl-cor:entriesType', { contextRef: 'now' }, 'other');
    docInfo.ele('gl-cor:uniqueID', { contextRef: 'now' }, uniqueId);
    docInfo.ele('gl-cor:language', { contextRef: 'now' }, 'iso639:et');
    docInfo.ele('gl-cor:creationDate', { contextRef: 'now' }, nowDate);
    docInfo.ele('gl-bus:creator', { contextRef: 'now' }, creator);
    docInfo.ele('gl-cor:entriesComment', { contextRef: 'now' }).raw('Andmep&#245;hise aruandluse v&#228;ljamaksete andmed MTA-le');
    docInfo.ele('gl-cor:periodCoveredStart', { contextRef: 'now' }, periodCoveredStart);
    docInfo.ele('gl-cor:periodCoveredEnd', { contextRef: 'now' }, periodCoveredEnd);
    docInfo.ele('gl-bus:sourceApplication', { contextRef: 'now' }, sourceApp);
    docInfo.ele('gl-muc:defaultCurrency', { contextRef: 'now' }, 'iso4217:eur');

    // entityInformation
    const entityInfo = entries.ele('gl-cor:entityInformation');
    const orgIds = entityInfo.ele('gl-bus:organizationIdentifiers');
    orgIds.ele('gl-bus:organizationIdentifier', { contextRef: 'now' }, regkood);
    orgIds.ele('gl-bus:organizationDescription', { contextRef: 'now' }, 'ARIREGISTRIKOOD');

    // Группировка строк по секциям (EE0201001, EE0201002, EE0201003)
    const sectionsMap = new Map();
    for (const row of tsdData) {
        const sec = (row.sektsioon || 'EE0201001').trim();
        if (!sectionsMap.has(sec)) {
            sectionsMap.set(sec, []);
        }
        sectionsMap.get(sec).push(row);
    }

    let globalCounter = 0;

    for (const [section, sectionRows] of sectionsMap.entries()) {
        const entryHeader = entries.ele('gl-cor:entryHeader');
        entryHeader.ele('gl-cor:entryNumber', { contextRef: 'now' }, section);

        let counterWithinHeader = 0;

        for (const row of sectionRows) {
            globalCounter++;
            counterWithinHeader++;

            const entryDetail = entryHeader.ele('gl-cor:entryDetail');

            // 1. lineNumber
            entryDetail.ele('gl-cor:lineNumber', { contextRef: 'now' }, `Tehing_${globalCounter}`);

            // 2. lineNumberCounter
            entryDetail.ele('gl-cor:lineNumberCounter', { contextRef: 'now', unitRef: 'NotUsed' }, counterWithinHeader);

            // 3. account (accountSub elements)
            const account = entryDetail.ele('gl-cor:account');
            const tululiikSub = account.ele('gl-cor:accountSub');
            tululiikSub.ele('gl-cor:accountSubID', { contextRef: 'now' }, String(row.tululiik || '10'));
            tululiikSub.ele('gl-cor:accountSubType', { contextRef: 'now' }, 'VALJAMLIIK2023ap');

            const actionSub = account.ele('gl-cor:accountSub');
            actionSub.ele('gl-cor:accountSubID', { contextRef: 'now' }, 'R');
            actionSub.ele('gl-cor:accountSubType', { contextRef: 'now' }, 'TOIMINGUTYYP2023ap');

            // 4. amount
            const summa = Number(row.summa || 0);
            entryDetail.ele('gl-cor:amount', { contextRef: 'now', decimals: '2', unitRef: 'eur' }, formatAmount(summa));

            // 5. identifierReference
            const ik = (row.isikukood || '').trim();
            const idCode = ik.startsWith('EE') ? ik : (ik.length === 11 ? `EE${ik}` : ik);
            const identRef = entryDetail.ele('gl-cor:identifierReference');
            identRef.ele('gl-cor:identifierCode', { contextRef: 'now' }, idCode);
            identRef.ele('gl-cor:identifierDescription', { contextRef: 'now' }, 'ISIKUKOOD');

            // 6. documentDate
            entryDetail.ele('gl-cor:documentDate', { contextRef: 'now' }, docDate);

            // 7. measurable
            // 7.1. Sündmus TSD01
            const eventMeasurable = entryDetail.ele('gl-bus:measurable');
            eventMeasurable.ele('gl-bus:measurableID', { contextRef: 'now' }, 'TSD01');
            eventMeasurable.ele('gl-bus:measurableIDSchema', { contextRef: 'now' }, 'SYNDMUS2017ap');
            eventMeasurable.ele('gl-bus:measurableStartDateTime', { contextRef: 'now' }, earningDate);

            // 7.2. Maksuvaba tulu (MVT)
            const tulubaas = Number(row.tulubaas || 0);
            if (tulubaas > 0 && row.mvt_kood) {
                const mvtMeasurable = entryDetail.ele('gl-bus:measurable');
                mvtMeasurable.ele('gl-bus:measurableDescription', { contextRef: 'now' }, row.mvt_kood);
                mvtMeasurable.ele('gl-bus:measurableQuantity', { contextRef: 'now', decimals: '2', unitRef: 'eur' }, formatAmount(tulubaas));
            }

            // 7.3. Sotsiaalmaksu arvestuse alus (TSD_SMVM)
            const smArv = Number(row.sm_arv || 0);
            if (smArv > 0 && summa > 0) {
                const smvmMeasurable = entryDetail.ele('gl-bus:measurable');
                smvmMeasurable.ele('gl-bus:measurableDescription', { contextRef: 'now' }, 'TSD_SMVM');
                smvmMeasurable.ele('gl-bus:measurableQuantity', { contextRef: 'now', decimals: '2', unitRef: 'eur' }, formatAmount(summa));
            }

            // 7.4. Sotsiaalmaksu kuumäära suurendus (TSD_KUUMSUURENDUS)
            const arvMinSots = Number(row.arv_min_sots || 0);
            const minSotsAlus = Number(row.min_sots_alus || 0);
            if (arvMinSots > 0 && minSotsAlus > 0) {
                const kuumMeasurable = entryDetail.ele('gl-bus:measurable');
                kuumMeasurable.ele('gl-bus:measurableDescription', { contextRef: 'now' }, 'TSD_KUUMSUURENDUS');
                kuumMeasurable.ele('gl-bus:measurableQuantity', { contextRef: 'now', decimals: '2', unitRef: 'eur' }, formatAmount(minSotsAlus));
            }

            // 8. taxes (vastavalt XSD järjekorrale: taxAmount, seejärel taxCode)
            const sm = Number(row.sm || 0);
            const totalSm = sm + arvMinSots;
            if (totalSm > 0) {
                const smTax = entryDetail.ele('gl-cor:taxes');
                smTax.ele('gl-cor:taxAmount', { contextRef: 'now', decimals: '2', unitRef: 'eur' }, formatAmount(totalSm));
                smTax.ele('gl-cor:taxCode', { contextRef: 'now' }, 'TSD_SM');
            }

            const pm = Number(row.pm || 0);
            if (pm > 0) {
                const pmTax = entryDetail.ele('gl-cor:taxes');
                pmTax.ele('gl-cor:taxAmount', { contextRef: 'now', decimals: '2', unitRef: 'eur' }, formatAmount(pm));
                pmTax.ele('gl-cor:taxCode', { contextRef: 'now' }, 'TSD_KP');
            }

            const tki = Number(row.tki || 0);
            if (tki > 0) {
                const tkiTax = entryDetail.ele('gl-cor:taxes');
                tkiTax.ele('gl-cor:taxAmount', { contextRef: 'now', decimals: '2', unitRef: 'eur' }, formatAmount(tki));
                tkiTax.ele('gl-cor:taxCode', { contextRef: 'now' }, 'TSD_TK');
            }

            const tka = Number(row.tka || 0);
            if (tka > 0) {
                const tkaTax = entryDetail.ele('gl-cor:taxes');
                tkaTax.ele('gl-cor:taxAmount', { contextRef: 'now', decimals: '2', unitRef: 'eur' }, formatAmount(tka));
                tkaTax.ele('gl-cor:taxCode', { contextRef: 'now' }, 'TSD_TTK');
            }

            const tm = Number(row.tm || 0);
            if (tm > 0 || String(row.tululiik) === '24') {
                const tmTax = entryDetail.ele('gl-cor:taxes');
                tmTax.ele('gl-cor:taxAmount', { contextRef: 'now', decimals: '2', unitRef: 'eur' }, formatAmount(tm));
                tmTax.ele('gl-cor:taxCode', { contextRef: 'now' }, 'TSD_KTM');
            }
        }
    }

    const xml = root.end({ pretty: true });
    return escapeEstonianXmlEntities(xml);
}

/**
 * Валидация сформированного XML по правилам MTA (XBRL GL)
 * @param {string} xmlString
 * @returns {Promise<boolean>}
 */
async function validateXML(xmlString) {
    if (!xmlString || typeof xmlString !== 'string') {
        throw new Error('XML sisu on tühi või vigane');
    }

    const parsed = await new Promise((resolve, reject) => {
        xml2js.parseString(xmlString, { explicitArray: false }, (err, result) => {
            if (err) return reject(err);
            resolve(result);
        });
    });

    const root = parsed['xbrli:xbrl'] || parsed['xbrl'];
    if (!root) {
        throw new Error('XML juurelement puudub või ei ole xbrli:xbrl');
    }

    const context = root['xbrli:context'] || root['context'];
    if (!context) {
        throw new Error('xbrli:context element puudub');
    }

    const entity = context['xbrli:entity'] || context['entity'];
    const regkood = entity ? getText(entity['xbrli:identifier'] || entity['identifier']) : '';
    if (!regkood) {
        throw new Error('xbrli:identifier (registrikood) puudub');
    }

    const entries = root['gl-cor:accountingEntries'] || root['accountingEntries'];
    if (!entries) {
        throw new Error('gl-cor:accountingEntries element puudub');
    }

    const docInfo = entries['gl-cor:documentInfo'] || entries['documentInfo'];
    if (!docInfo) {
        throw new Error('gl-cor:documentInfo element puudub');
    }

    const startKpv = getText(docInfo['gl-cor:periodCoveredStart'] || docInfo['periodCoveredStart']);
    const endKpv = getText(docInfo['gl-cor:periodCoveredEnd'] || docInfo['periodCoveredEnd']);
    if (!startKpv || !endKpv) {
        throw new Error('periodCoveredStart või periodCoveredEnd puudub');
    }

    if (startKpv.slice(0, 7) !== endKpv.slice(0, 7)) {
        throw new Error('TSD aruandeperiood peab olema ühe kalendrikuu piires');
    }

    const rawHeaders = entries['gl-cor:entryHeader'] || entries['entryHeader'];
    if (!rawHeaders) {
        throw new Error('gl-cor:entryHeader puudub');
    }

    const headers = Array.isArray(rawHeaders) ? rawHeaders : [rawHeaders];
    if (headers.length === 0) {
        throw new Error('Vähemalt üks gl-cor:entryHeader peab olema määratud');
    }

    const validTaxCodes = new Set(['TSD_SM', 'TSD_KP', 'TSD_TK', 'TSD_TTK', 'TSD_KTM']);

    for (const h of headers) {
        const entryNum = getText(h['gl-cor:entryNumber'] || h['entryNumber']);
        if (!entryNum || !entryNum.startsWith('EE020100')) {
            throw new Error(`Vigane entryNumber: ${entryNum} (peab algama EE020100)`);
        }

        const rawDetails = h['gl-cor:entryDetail'] || h['entryDetail'];
        if (!rawDetails) {
            throw new Error(`Sektsioonis ${entryNum} puuduvad tehingud (entryDetail)`);
        }
        const details = Array.isArray(rawDetails) ? rawDetails : [rawDetails];

        for (const d of details) {
            const lineNum = getText(d['gl-cor:lineNumber'] || d['lineNumber']);
            if (!lineNum) {
                throw new Error('entryDetail lineNumber puudub');
            }

            const idRef = d['gl-cor:identifierReference'] || d['identifierReference'];
            if (!idRef) {
                throw new Error(`entryDetail identifierReference puudub (${lineNum})`);
            }
            const idCode = getText(idRef['gl-cor:identifierCode'] || idRef['identifierCode']);
            if (!idCode) {
                throw new Error(`entryDetail identifierCode puudub (${lineNum})`);
            }

            // Kontrollime kontot (account)
            const account = d['gl-cor:account'] || d['account'];
            if (!account) {
                throw new Error(`entryDetail account puudub (${lineNum})`);
            }
            const rawSubs = account['gl-cor:accountSub'] || account['accountSub'];
            if (!rawSubs) {
                throw new Error(`entryDetail accountSub puudub (${lineNum})`);
            }
            const subs = Array.isArray(rawSubs) ? rawSubs : [rawSubs];
            const subTypes = subs.map(s => getText(s['gl-cor:accountSubType'] || s['accountSubType']));
            if (!subTypes.includes('VALJAMLIIK2023ap')) {
                throw new Error(`accountSub VALJAMLIIK2023ap puudub (${lineNum})`);
            }
            if (!subTypes.includes('TOIMINGUTYYP2023ap')) {
                throw new Error(`accountSub TOIMINGUTYYP2023ap puudub (${lineNum})`);
            }

            // Kontrollime makse (taxes) kui olemas
            const rawTaxes = d['gl-cor:taxes'] || d['taxes'];
            if (rawTaxes) {
                const taxes = Array.isArray(rawTaxes) ? rawTaxes : [rawTaxes];
                for (const t of taxes) {
                    const code = getText(t['gl-cor:taxCode'] || t['taxCode']);
                    if (!validTaxCodes.has(code)) {
                        throw new Error(`Tundmatu maksukood: ${code} tehingus ${lineNum}`);
                    }
                    const amount = getText(t['gl-cor:taxAmount'] || t['taxAmount']);
                    if (isNaN(Number(amount))) {
                        throw new Error(`Vigane maksu summa: ${amount} tehingus ${lineNum}`);
                    }
                }
            }
        }
    }

    return true;
}

/**
 * Проверка авторизации пользователя по uuid (паролю) в БД
 * @param {string} uuid
 * @returns {Promise<boolean>}
 */
async function checkUserAuth(uuid) {
    if (!uuid) return false;
    const sql = `SELECT 1 FROM ou.userid WHERE parool = $1 AND status < 3 LIMIT 1;`;
    const res = await db.queryDb(sql, [uuid], null, null, null, null, config);
    return !!(res && res.data && res.data.length > 0);
}

/**
 * Основной роут генерации XML декларации TSD
 */
const post = async (req, res) => {
    try {
        const params = Object.assign({}, req.query, req.body, req.params);
        const uuid = params.uuid;

        // 1. uuid - обязательный параметр
        if (!uuid) {
            return res.send({status: 401, result: null, error_message: 'Puudub kohustuslik parameeter: uuid'});
        }

        // 2. Проверка uuid по таблице ou.userid (where parool = $1 and status < 3 limit 1)
        const isAuthorized = await checkUserAuth(uuid);
        if (!isAuthorized) {
            return res.send({status: 403, result: null, error_message: 'Juurdepääsu viga: vale autentimise parool (uuid)'});
        }

        const userId = params.userid_id || params.user_id || params.userId;
        const execDate = params.date_query_from ? params.date_query_from : getNow();
        const is_summary = params.is_summary ? params.is_summary : 0;
        const isAgent = checkIsAgent(params);

        console.log('[calcTSDXML] Start request:', execDate, params, 'isAgent:', isAgent);

        if (!userId && !isAgent) {
            return res.send({status: 500, result: null, error_message: 'User ID is missing'});
        }

        // получаем данные декларации
        const rows = await getTSDData(userId, execDate, is_summary);

        if (!rows || !rows.length) {
            return res.send({status: 500, result: null, error_message: 'Viga: puuduvad TSD andmed'});
        }

        // преобразовываем в XML
        let xml = await convertToXML(rows);

        // валидация XML
        let xmlValidationResult = await validateXML(xml);
        if (!xmlValidationResult) {
            return res.send({status: 500, result: null, error_message: 'Viga: XML valideerimise viga'});
        }

        // ответ
        return res.send({
            status: 200,
            result: 1,
            data: {
                action: 'calcXML',
                result: {
                    error_code: 0,
                    error_message: null,
                },
                data: xml
            }
        });

    } catch (err) {
        console.error('[calcTSDXML] Error:', err);
        return res.send({status: 500, result: null, error_message: err.message || err});
    }
};

/**
 * Функция прямого выполнения (для тестов и CLI)
 */
async function executeCalculation(userId, execDate = getNow(), isSummary = 0) {
    const rows = await getTSDData(userId, execDate, isSummary);
    if (!rows || !rows.length) {
        throw new Error('Puuduvad TSD andmed');
    }
    const xml = await convertToXML(rows);
    const isValid = await validateXML(xml);
    if (!isValid) {
        throw new Error('XML valideerimise viga');
    }
    return xml;
}

// Запуск при прямом вызове из командной строки (CLI)
if (require.main === module) {
    const defaultUserId = 2477;
    executeCalculation(defaultUserId)
        .then((result) => {
            console.log('[calcTSDXML] Finished successfully');
            process.exit(0);
        })
        .catch((error) => {
            console.error('[calcTSDXML] Error in execution:', error);
            process.exit(1);
        });
}

exports.post = post;
exports.main = post;
exports.getTSDData = getTSDData;
exports.checkUserAuth = checkUserAuth;
exports.convertToXML = convertToXML;
exports.validateXML = validateXML;
exports.executeCalculation = executeCalculation;
exports.FLOW_NAME = FLOW_NAME;
exports.checkIsAgent = checkIsAgent;
exports.escapeEstonianXmlEntities = escapeEstonianXmlEntities;
