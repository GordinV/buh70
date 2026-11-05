'use strict';

const db = require('../../libs/db');

const VALID_HASH = '2f2b7890e7951a55d589c2bb5df2d0f59cd10877';

const TYYP_LIST = [
    { id: '1', name: 'Vanemate tasu' },
    { id: '2', name: 'Kontraagent' },
    { id: '3', name: 'Arve number' }
];

/**
 * Получить список активных учреждений для выпадающего списка
 */
async function getRekvList() {
    const sql = `
        SELECT id, nimetus 
        FROM ou.rekv 
        WHERE status <> 3 AND (parentid = 0 OR parentid < 999) 
        ORDER BY nimetus
    `;
    const res = await db.queryDb(sql, []);
    return (res && res.data) ? res.data : [];
}

/**
 * Безопасный парсинг JSON данных из результата БД
 */
function parseDbData(data) {
    if (typeof data === 'string') {
        try {
            return JSON.parse(data);
        } catch (e) {
            return data;
        }
    }
    return data;
}

/**
 * GET обработчик формы запроса viitenumber
 */
exports.get = async (req, res) => {
    const hash = req.params.hash;
    if (hash !== VALID_HASH) {
        return res.status(403).send('Juurdepääs keelatud: vigane turvakood');
    }

    try {
        const rekvList = await getRekvList();
        res.render('viitenumber', {
            title: 'Viitenumbri päring',
            hash: hash,
            rekvList: rekvList,
            tyypList: TYYP_LIST,
            inputViitenumber: '',
            selectedRekv: '',
            selectedTyyp: '1',
            objektNumber: '',
            result: null,
            error: null
        });
    } catch (err) {
        console.error('Viga get_viitenumber laadimisel:', err);
        res.status(500).send('Serveri viga');
    }
};

/**
 * POST обработчик отправки формы запроса viitenumber
 */
exports.post = async (req, res) => {
    const hash = req.params.hash;
    if (hash !== VALID_HASH) {
        return res.status(403).send('Juurdepääs keelatud: vigane turvakood');
    }

    const { viitenumber, rekv_id, tyyp, objekt_number } = req.body;
    const viiteVal = (viitenumber || '').trim();
    const objektVal = (objekt_number || '').trim();
    const rekvVal = rekv_id ? String(rekv_id).trim() : '';

    const hasViite = viiteVal.length > 0;
    const hasParams = (rekvVal.length > 0 && objektVal.length > 0);

    let result = null;
    let errorMessage = null;

    try {
        if (hasViite && hasParams) {
            errorMessage = 'Täida kas viitenumber VÕI vali asutus ja dokumendi number (mõlemat korraga ei saa täita)';
        } else if (!hasViite && !hasParams) {
            errorMessage = 'Sisesta viitenumber või täida asutus ja dokumendi number';
        } else if (hasViite) {
            // Режим 1: Обратный поиск по viitenumber
            const sql = 'SELECT libs.get_data_from_viitenumber($1::TEXT) AS data';
            const qryRes = await db.queryDb(sql, [viiteVal]);

            if (qryRes && qryRes.data && qryRes.data.length > 0) {
                result = parseDbData(qryRes.data[0].data);
                if (result && !result.viitenumber) {
                    result.viitenumber = viiteVal;
                }
            } else {
                errorMessage = 'Andmeid ei leitud';
            }
        } else {
            // Режим 2: Прямой расчет viitenumber по реквизитам
            const sql = 'SELECT libs.get_viitenumber_from_regkood($1::INTEGER, $2::TEXT, $3::TEXT) AS data';
            const qryRes = await db.queryDb(sql, [
                parseInt(rekvVal, 10),
                objektVal,
                tyyp || '1'
            ]);

            if (qryRes && qryRes.data && qryRes.data.length > 0) {
                result = parseDbData(qryRes.data[0].data);
            } else {
                errorMessage = 'Andmeid ei leitud';
            }
        }

        const rekvList = await getRekvList();
        res.render('viitenumber', {
            title: 'Viitenumbri päring',
            hash: hash,
            rekvList: rekvList,
            tyypList: TYYP_LIST,
            inputViitenumber: viiteVal,
            selectedRekv: rekvVal,
            selectedTyyp: tyyp || '1',
            objektNumber: objektVal,
            result: result,
            error: errorMessage
        });
    } catch (err) {
        console.error('Viga get_viitenumber pärimisel:', err);
        const rekvList = await getRekvList().catch(() => []);
        res.render('viitenumber', {
            title: 'Viitenumbri päring',
            hash: hash,
            rekvList: rekvList,
            tyypList: TYYP_LIST,
            inputViitenumber: viiteVal,
            selectedRekv: rekvVal,
            selectedTyyp: tyyp || '1',
            objektNumber: objektVal,
            result: null,
            error: 'Päringu teostamisel tekkis viga'
        });
    }
};
