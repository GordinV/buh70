'use strict';
/**
 * Чтение данных организаций из локальной таблицы libs.ariregister и метаданных libs.ariregister_meta.
 * Реализует интерфейс клиента реестра (getBundle / getUsage), совместимый с libs/inforegister.js.
 * Код совместим с Node < 14 (без ?? и ?.).
 */
const db = require('./db');
const inforegister = require('./inforegister');
const config = require('./inforegisterConfig');

function defaultQueryFn(sqlString, params) {
    return db.queryDb(sqlString, params, null, null, null, null, config);
}

function str(v) {
    if (v === null || v === undefined) return null;
    const s = String(v).trim();
    return s === '' ? null : s;
}

function formatDateOnly(val) {
    if (!val) return null;
    if (val instanceof Date) {
        return isNaN(val.getTime()) ? null : val.toISOString().slice(0, 10);
    }
    const s = String(val).trim();
    if (!s) return null;
    if (/^\d{4}-\d{2}-\d{2}/.test(s)) return s.slice(0, 10);
    const d = new Date(s);
    return isNaN(d.getTime()) ? s : d.toISOString().slice(0, 10);
}

function firstCityPart(ehakTekst) {
    const s = str(ehakTekst);
    if (!s) return null;
    const first = s.split(',')[0].trim();
    return first === '' ? null : first;
}

function buildAddress(row) {
    const full = str(row.taisaadress);
    const street = str(row.asukoht);
    const city = firstCityPart(row.ehak_tekst);

    let fullAddress = full;
    if (!fullAddress) {
        const parts = [street, str(row.ehak_tekst), str(row.indeks)].filter(Boolean);
        fullAddress = parts.length ? parts.join(', ') : str(row.aadress);
    }

    if (!fullAddress && !city && !street) {
        return null;
    }

    return {
        fullAddress: fullAddress || null,
        city: city,
        street: street
    };
}

/**
 * Преобразует строку libs.ariregister в формат summarizeBundle из libs/inforegister.js.
 */
function toBundle(row, year) {
    if (!row) return null;
    const isDeleted = row.deleted_at !== null && row.deleted_at !== undefined;
    const registryStatus = isDeleted ? 'Kustutatud' : str(row.staatus_tekst);

    return {
        name: str(row.nimi),
        regCode: str(row.regkood),
        registryStatus: registryStatus,
        businessType: str(row.oiguslik_vorm),
        vatNumber: str(row.kmkr_nr),
        address: buildAddress(row),
        contacts: {emails: [], phones: [], webs: []},
        latestEmployeeCount: null,
        latestPeriod: null,
        year: year !== undefined && year !== null ? year : inforegister.defaultDataYear()
    };
}

async function readMeta(queryFn) {
    const q = queryFn || defaultQueryFn;
    const res = await q(
        'SELECT file_date::text AS file_date, applied_at, rows_total FROM libs.ariregister_meta WHERE id = 1 LIMIT 1',
        []
    );
    if (res && res.error_code) {
        throw new Error(res.error_message || 'Failed to read libs.ariregister_meta');
    }
    return res && res.data && res.data[0] ? res.data[0] : null;
}

async function readByRegkood(regkood, queryFn) {
    const q = queryFn || defaultQueryFn;
    const code = String(regkood === undefined || regkood === null ? '' : regkood).trim();
    const res = await q(
        'SELECT regkood, nimi, oiguslik_vorm, oigusliku_vormi_alaliik, kmkr_nr, ' +
        'staatus, staatus_tekst, esmakande_kpv, aadress, asukoht, ehak_kood, ehak_tekst, ' +
        'indeks, ads_adr_id, ads_ads_oid, taisaadress, link, file_date, loaded_at, deleted_at ' +
        'FROM libs.ariregister WHERE regkood = $1 LIMIT 1',
        [code]
    );
    if (res && res.error_code) {
        throw new Error(res.error_message || 'Failed to read libs.ariregister');
    }
    return res && res.data && res.data[0] ? res.data[0] : null;
}

function createStoreClient(options) {
    const opts = options || {};
    const queryFn = opts.queryFn || defaultQueryFn;

    async function getBundle(regCode, year) {
        const clean = String(regCode === undefined || regCode === null ? '' : regCode).trim();
        if (!inforegister.REG_CODE_RE.test(clean)) {
            return {
                ok: false,
                regCode: clean,
                reason: 'invalid_reg_code',
                error: 'Reg.kood ei ole 8-kohaline',
                source: 'ariregister'
            };
        }

        const meta = await readMeta(queryFn);
        if (!meta) {
            return {
                ok: false,
                regCode: clean,
                reason: 'registry_not_loaded',
                error: 'Äriregistri lokaalne koopia on laadimata',
                source: 'ariregister'
            };
        }

        const row = await readByRegkood(clean, queryFn);
        if (!row) {
            return {
                ok: false,
                regCode: clean,
                reason: 'not_found',
                error: 'Organisatsiooni ei leitud Äriregistrist',
                source: 'ariregister'
            };
        }

        return {
            ok: true,
            regCode: clean,
            data: toBundle(row, year),
            source: 'ariregister',
            fetchedAt: formatDateOnly(meta.file_date),
            remainingYear: null
        };
    }

    function getUsage() {
        return {spent: 0, remainingYear: null};
    }

    return {
        getBundle: getBundle,
        getUsage: getUsage
    };
}

exports.toBundle = toBundle;
exports.readMeta = readMeta;
exports.readByRegkood = readByRegkood;
exports.createStoreClient = createStoreClient;
exports.config = config;
