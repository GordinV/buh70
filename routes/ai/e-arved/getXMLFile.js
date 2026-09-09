'use strict';

const https = require('https');
const fs = require('fs');
const path = require('path');

const DEFAULT_URL = 'https://app.finbite.eu/finance/erp';
const DEFAULT_AUTH_PHRASE = '106549:elbevswsackajyafdoupavfwewuiafbeeiqatgvyqcqdqxairz';
const DEFAULT_STATE = 'VERIFIED';
const DEFAULT_MAX_ITERATIONS = 10;
const DEFAULT_DELAY_MS = 15000; // 15 sekundit pausi Error 93 (Request rate too high) vältimiseks
const DEFAULT_OUTPUT_FILE = path.join(__dirname, 'e-arved.xml');

/**
 * Vormindab kuupäeva stringi kujule YYYY-MM-DD HH:mm:ss (Node 13.* ühilduv)
 * Toetab formaate: Date, DD.MM.YYYY, DD/MM/YYYY, YYYYMMDD, YYYY-MM-DD, ISO string jne.
 * @param {Date|string|number} [date]
 * @returns {string}
 */
function formatCurrentDate(date) {
    if (!date) {
        const d = new Date();
        const year = d.getFullYear();
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        return `${year}-${month}-${day} 00:00:00`;
    }

    if (date instanceof Date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}-${month}-${day} 00:00:00`;
    }

    const str = String(date).trim();

    // Formaat: DD.MM.YYYY (nt 06.09.2026 või 6.9.2026), valikuliselt kellaajaga DD.MM.YYYY HH:mm:ss
    const ddmmyyyyDotMatch = str.match(/^(\d{1,2})\.(\d{1,2})\.(\d{4})(?:\s+(\d{2}:\d{2}(?::\d{2})?))?$/);
    if (ddmmyyyyDotMatch) {
        const day = ddmmyyyyDotMatch[1].padStart(2, '0');
        const month = ddmmyyyyDotMatch[2].padStart(2, '0');
        const year = ddmmyyyyDotMatch[3];
        const time = ddmmyyyyDotMatch[4] ? (ddmmyyyyDotMatch[4].length === 5 ? ddmmyyyyDotMatch[4] + ':00' : ddmmyyyyDotMatch[4]) : '00:00:00';
        return `${year}-${month}-${day} ${time}`;
    }

    // Formaat: DD/MM/YYYY (nt 06/09/2026)
    const ddmmyyyySlashMatch = str.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})(?:\s+(\d{2}:\d{2}(?::\d{2})?))?$/);
    if (ddmmyyyySlashMatch) {
        const day = ddmmyyyySlashMatch[1].padStart(2, '0');
        const month = ddmmyyyySlashMatch[2].padStart(2, '0');
        const year = ddmmyyyySlashMatch[3];
        const time = ddmmyyyySlashMatch[4] ? (ddmmyyyySlashMatch[4].length === 5 ? ddmmyyyySlashMatch[4] + ':00' : ddmmyyyySlashMatch[4]) : '00:00:00';
        return `${year}-${month}-${day} ${time}`;
    }

    // Formaat: YYYYMMDD (nt 20260908)
    const yyyymmddMatch = str.match(/^(\d{4})(\d{2})(\d{2})$/);
    if (yyyymmddMatch) {
        return `${yyyymmddMatch[1]}-${yyyymmddMatch[2]}-${yyyymmddMatch[3]} 00:00:00`;
    }

    // Formaat: YYYY-MM-DD (nt 2026-09-08 või 2026-9-8)
    const yyyy_mm_ddMatch = str.match(/^(\d{4})-(\d{1,2})-(\d{1,2})$/);
    if (yyyy_mm_ddMatch) {
        const year = yyyy_mm_ddMatch[1];
        const month = yyyy_mm_ddMatch[2].padStart(2, '0');
        const day = yyyy_mm_ddMatch[3].padStart(2, '0');
        return `${year}-${month}-${day} 00:00:00`;
    }

    // Formaat: YYYY-MM-DD HH:mm (ilma sekunditeta)
    const yyyy_mm_dd_hh_mm = str.match(/^(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})$/);
    if (yyyy_mm_dd_hh_mm) {
        return `${yyyy_mm_dd_hh_mm[1]} ${yyyy_mm_dd_hh_mm[2]}:00`;
    }

    // Formaat: ISO string (nt 2026-09-06T12:00:00.000Z)
    if (str.includes('T')) {
        const d = new Date(str);
        if (!isNaN(d.getTime())) {
            const year = d.getFullYear();
            const month = String(d.getMonth() + 1).padStart(2, '0');
            const day = String(d.getDate()).padStart(2, '0');
            const hours = String(d.getHours()).padStart(2, '0');
            const minutes = String(d.getMinutes()).padStart(2, '0');
            const seconds = String(d.getSeconds()).padStart(2, '0');
            return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
        }
    }

    // Kui on juba kellaaeg YYYY-MM-DD HH:mm:ss või teine vorming
    return str;
}

/**
 * Loob SOAP Envelope päringu keha BuyInvoiceExportRequest
 * @param {Object} params
 * @param {string} params.since
 * @param {string} params.authPhrase
 * @param {string} params.state
 * @returns {string}
 */
function buildSoapEnvelope(params) {
    const since = params && params.since ? formatCurrentDate(params.since) : formatCurrentDate();
    const authPhrase = params && params.authPhrase ? params.authPhrase : DEFAULT_AUTH_PHRASE;
    const state = params && params.state ? params.state : DEFAULT_STATE;

    return '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"\n' +
        '   xmlns:erp="http://e-arvetekeskus.eu/erp">\n' +
        '   <soapenv:Header/>\n' +
        '   <soapenv:Body>\n' +
        '   <erp:BuyInvoiceExportRequest since="' + since + '" authPhrase="' + authPhrase + '">\n' +
        '   <erp:state>' + state + '</erp:state>\n' +
        '   </erp:BuyInvoiceExportRequest>\n' +
        '   </soapenv:Body>\n' +
        '   </soapenv:Envelope>';
}

/**
 * Saadab POST SOAP-päringu määratud hostile
 * @param {string} urlString
 * @param {string} xmlPayload
 * @returns {Promise<{statusCode: number, body: string}>}
 */
function sendSoapRequest(urlString, xmlPayload) {
    return new Promise((resolve, reject) => {
        try {
            const urlObj = new URL(urlString);
            const options = {
                hostname: urlObj.hostname,
                port: urlObj.port || 443,
                path: urlObj.pathname + (urlObj.search || ''),
                method: 'POST',
                headers: {
                    'Content-Type': 'text/xml;charset=UTF-8',
                    'Content-Length': Buffer.byteLength(xmlPayload),
                    'SOAPAction': '""'
                }
            };

            const req = https.request(options, (res) => {
                let responseData = '';
                res.setEncoding('utf8');

                res.on('data', (chunk) => {
                    responseData += chunk;
                });

                res.on('end', () => {
                    resolve({
                        statusCode: res.statusCode,
                        body: responseData
                    });
                });
            });

            req.on('error', (err) => {
                reject(err);
            });

            req.write(xmlPayload);
            req.end();
        } catch (err) {
            reject(err);
        }
    });
}

/**
 * Eraldab metaandmed Finbite XML-vastusest
 * @param {string} xmlString
 * @returns {{includesLatest: string|null, latestChange: string|null, isFault: boolean, faultString: string|null, faultCode: string|null}}
 */
function parseResponseMeta(xmlString) {
    if (!xmlString || typeof xmlString !== 'string') {
        return {
            includesLatest: null,
            latestChange: null,
            isFault: false,
            faultString: null,
            faultCode: null
        };
    }

    const isFault = xmlString.indexOf('<SOAP-ENV:Fault>') !== -1 || xmlString.indexOf('<soapenv:Fault>') !== -1;
    let faultString = null;
    let faultCode = null;

    if (isFault) {
        const codeMatch = xmlString.match(/<faultcode[^>]*>([^<]+)<\/faultcode>/i);
        const stringMatch = xmlString.match(/<faultstring[^>]*>([^<]+)<\/faultstring>/i);
        faultCode = codeMatch ? codeMatch[1].trim() : null;
        faultString = stringMatch ? stringMatch[1].trim() : null;
    }

    const matchIncludes = xmlString.match(/includesLatest="([^"]+)"/i);
    const includesLatest = matchIncludes ? matchIncludes[1].toUpperCase() : null;

    const matchLatestChange = xmlString.match(/latestChange="([^"]+)"/i);
    const latestChange = matchLatestChange ? matchLatestChange[1] : null;

    return {
        includesLatest: includesLatest,
        latestChange: latestChange,
        isFault: isFault,
        faultString: faultString,
        faultCode: faultCode
    };
}

/**
 * Paus määratud millisekunditeks
 * @param {number} ms
 * @returns {Promise<void>}>
 */
function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Ühendab elemente <Invoice> mitmest vastusest ühte dokumenti
 * @param {Array<string>} xmlList
 * @returns {string}
 */
function mergeXmlResponses(xmlList) {
    if (!xmlList || xmlList.length === 0) {
        return '';
    }
    if (xmlList.length === 1) {
        return xmlList[0];
    }

    const baseXml = xmlList[0];
    const invoiceRegex = /<Invoice\b[\s\S]*?<\/Invoice>/gi;
    const allInvoices = [];

    for (let i = 0; i < xmlList.length; i++) {
        const currentXml = xmlList[i];
        let match;
        while ((match = invoiceRegex.exec(currentXml)) !== null) {
            allInvoices.push(match[0]);
        }
    }

    // Kui arveid ei leitud, tagastame baas-XML-i
    if (allInvoices.length === 0) {
        return baseXml;
    }

    // Asendame esimeses E_Invoice-s olevad arved ühendatud arvete nimekirjaga
    const eInvoiceOpenRegex = /<E_Invoice\b[^>]*>/i;
    const eInvoiceCloseRegex = /<\/E_Invoice>/i;

    const openMatch = baseXml.match(eInvoiceOpenRegex);
    const closeMatch = baseXml.match(eInvoiceCloseRegex);

    if (!openMatch || !closeMatch) {
        return baseXml;
    }

    const headerMatch = baseXml.match(/<Header>[\s\S]*?<\/Header>/i);
    const headerContent = headerMatch ? headerMatch[0] : '';

    // Uuendame TotalNumberInvoices päises (Header) ühendamisel
    let updatedHeader = headerContent;
    if (updatedHeader) {
        updatedHeader = updatedHeader.replace(
            /<TotalNumberInvoices>[^<]*<\/TotalNumberInvoices>/i,
            '<TotalNumberInvoices>' + allInvoices.length + '</TotalNumberInvoices>'
        );
    }

    const prefix = baseXml.substring(0, openMatch.index + openMatch[0].length);
    const suffix = baseXml.substring(closeMatch.index);

    const mergedBody = '\n' + updatedHeader + '\n' + allInvoices.join('\n') + '\n';
    return prefix + mergedBody + suffix;
}

/**
 * Põhifunktsioon arvete pärimiseks Finbite'ist ja salvestamiseks XML-faili
 * @param {string|Object} [authPhraseOrOptions] - Autentimise räsisõne või options objekt
 * @param {string} [urlParam] - Teenuse host/URL (näiteks https://app.finbite.eu/finance/erp)
 * @param {Object|string|number|Date} [optionsParam] - Lisaparameetrid (since, state, maxIterations, delayMs, outputFile) või alguskuupäev
 * @returns {Promise<string>} - Tagastab saadud XML-i sõnena
 */
async function getXMLFile(authPhraseOrOptions, urlParam, optionsParam) {
    let authPhrase;
    let url;
    let opts;

    if (typeof authPhraseOrOptions === 'object' && authPhraseOrOptions !== null) {
        opts = authPhraseOrOptions;
        authPhrase = opts.authPhrase || opts.auth || DEFAULT_AUTH_PHRASE;
        url = opts.url || opts.host || DEFAULT_URL;
    } else {
        authPhrase = authPhraseOrOptions || DEFAULT_AUTH_PHRASE;
        url = urlParam || DEFAULT_URL;
        if (typeof optionsParam === 'string' || typeof optionsParam === 'number' || optionsParam instanceof Date) {
            opts = { since: optionsParam };
        } else {
            opts = optionsParam || {};
        }
    }

    let currentSince = formatCurrentDate(opts.since);
    const state = opts.state || DEFAULT_STATE;
    const maxIterations = typeof opts.maxIterations === 'number' ? opts.maxIterations : DEFAULT_MAX_ITERATIONS;
    const delayMs = typeof opts.delayMs === 'number' ? opts.delayMs : DEFAULT_DELAY_MS;
    const outputFile = opts.outputFile !== undefined ? opts.outputFile : DEFAULT_OUTPUT_FILE;

    const collectedXmls = [];
    let iteration = 0;
    let includesLatest = null;

    console.log('[getXMLFile] E-arvete allalaadimise algus. Host:', url, ', authPhrase:', (authPhrase ? authPhrase.substring(0, 10) + '...' : 'none'));
    console.log('[getXMLFile] Alguskuupäev since:', currentSince);

    while (iteration < maxIterations) {
        iteration++;
        console.log('[getXMLFile] Iteratsioon ' + iteration + '/' + maxIterations + ' (since: ' + currentSince + ')...');

        const xmlPayload = buildSoapEnvelope({
            since: currentSince,
            authPhrase: authPhrase,
            state: state
        });

        let response;
        try {
            response = await sendSoapRequest(url, xmlPayload);
        } catch (netErr) {
            console.error('[getXMLFile] Võrgupäringu viga iteratsioonil ' + iteration + ':', netErr.message);
            throw netErr;
        }

        const bodyStr = response && response.body ? String(response.body).trim() : '';

        // Kontroll: kui Finbite server tagastas SOAP XML asemel HTML-i (lüüsipäringu tõrge)
        const isHtml = bodyStr.indexOf('<html') !== -1 || bodyStr.indexOf('<!DOCTYPE') !== -1;
        if (isHtml) {
            let errorMsg = 'Finbite server tagastas HTML vealehe';
            const spanMatches = bodyStr.match(/<span>([^<]+)<\/span>/gi);
            if (spanMatches && spanMatches.length > 0) {
                const msgs = spanMatches.map((s) => s.replace(/<\/?span>/gi, '').trim());
                errorMsg += ': ' + msgs.join(' / ');
            }
            throw new Error(errorMsg + ' (HTTP ' + (response ? response.statusCode : 'unknown') + ')');
        }

        if (bodyStr.indexOf('<') === -1) {
            throw new Error('Vigane Finbite vastus: oodati XML-i, saadi tühi või mitte-XML vastus (HTTP ' + (response ? response.statusCode : 'unknown') + ')');
        }

        const meta = parseResponseMeta(response.body);

        if (meta.isFault) {
            console.error('[getXMLFile] SOAP Fault saadud: [' + meta.faultCode + '] ' + meta.faultString);

            // Viga 93: "Request rate too high" - paus ja sama iteratsiooni korduskatse
            if (meta.faultCode && meta.faultCode.indexOf('93') !== -1) {
                console.log('[getXMLFile] Päringute limiit ületatud (Error 93). Ootamine ' + (delayMs / 1000) + ' sek enne kordamist...');
                await sleep(delayMs);
                iteration--; // ajutise piirangu korral ei kuluta katset
                continue;
            }

            // Viga 70: "No invoices to return" - määratud perioodil arveid ei ole
            if (meta.faultCode && meta.faultCode.indexOf('70') !== -1) {
                console.log('[getXMLFile] Määratud perioodi kohta arved puuduvad (ns0:70: No invoices to return).');
                if (collectedXmls.length > 0) {
                    break;
                }
                return '';
            }

            throw new Error('SOAP Fault: [' + meta.faultCode + '] ' + meta.faultString);
        }

        collectedXmls.push(response.body);
        includesLatest = meta.includesLatest;

        console.log('[getXMLFile] Vastus saadud. includesLatest:', includesLatest, ', latestChange:', meta.latestChange);

        if (includesLatest === 'YES') {
            console.log('[getXMLFile] Jõutud lipuni includesLatest="YES". Kogumine lõpetatud.');
            break;
        }

        if (meta.latestChange) {
            currentSince = meta.latestChange;
        } else {
            console.warn('[getXMLFile] latestChange puudub vastuses, tsükli lõpetamine.');
            break;
        }

        if (iteration < maxIterations) {
            console.log('[getXMLFile] Ootamine ' + (delayMs / 1000) + ' sek Finbite API limiitide järgimiseks...');
            await sleep(delayMs);
        }
    }

    if (collectedXmls.length === 0) {
        throw new Error('Finbite\'ilt arvete andmete saamine ebaõnnestus');
    }

    const finalXml = mergeXmlResponses(collectedXmls);

    return finalXml;
}

// Käivitamine otse CLI kaudu
if (require.main === module) {
    let cliAuth = null;
    let cliUrl = null;
    const options = {};

    if (process.argv[2] && process.argv[2].indexOf(':') !== -1) {
        cliAuth = process.argv[2];
        cliUrl = process.argv[3] || null;
        if (process.argv[4]) {
            options.since = process.argv[4];
        }
    } else if (process.argv[2]) {
        options.since = process.argv[2];
    }

    getXMLFile(cliAuth, cliUrl, options)
        .then((xml) => {
            console.log('[getXMLFile] XML edukalt vastu võetud (pikkus: ' + (xml ? xml.length : 0) + ' tähemärki)');
            process.exit(0);
        })
        .catch((err) => {
            console.error('[getXMLFile] Viga:', err && err.message ? err.message : err);
            process.exit(1);
        });
}

module.exports = getXMLFile;
module.exports.getXMLFile = getXMLFile;
module.exports.getXmlFile = getXMLFile;
module.exports.buildSoapEnvelope = buildSoapEnvelope;
module.exports.sendSoapRequest = sendSoapRequest;
module.exports.parseResponseMeta = parseResponseMeta;
module.exports.formatCurrentDate = formatCurrentDate;
module.exports.mergeXmlResponses = mergeXmlResponses;
module.exports.DEFAULT_URL = DEFAULT_URL;
module.exports.DEFAULT_AUTH_PHRASE = DEFAULT_AUTH_PHRASE;
module.exports.DEFAULT_STATE = DEFAULT_STATE;
module.exports.DEFAULT_MAX_ITERATIONS = DEFAULT_MAX_ITERATIONS;
module.exports.DEFAULT_DELAY_MS = DEFAULT_DELAY_MS;
module.exports.DEFAULT_OUTPUT_FILE = DEFAULT_OUTPUT_FILE;
