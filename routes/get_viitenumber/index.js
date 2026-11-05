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

    const { rekv_id, tyyp, objekt_number } = req.body;
    let result = null;
    let errorMessage = null;

    console.log('params:', rekv_id, tyyp, objekt_number);

    try {
        if (!rekv_id || !objekt_number || !objekt_number.trim()) {
            errorMessage = 'Kõik väljad peavad olema täidetud';
        } else {
            const sql = 'SELECT libs.get_viitenumber_from_regkood($1::INTEGER, $2::TEXT, $3::TEXT) AS data';
            const qryRes = await db.queryDb(sql, [
                parseInt(rekv_id, 10),
                objekt_number.trim(),
                tyyp || '1'
            ]);

            console.log('qryRes:', qryRes);

            if (qryRes && qryRes.data && qryRes.data.length > 0) {
                let rowData = qryRes.data[0].data;
                if (typeof rowData === 'string') {
                    try {
                        rowData = JSON.parse(rowData);
                    } catch (e) {
                        // оставить как есть
                    }
                }
                result = rowData;
                console.log('result:', result);

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
            selectedRekv: rekv_id,
            selectedTyyp: tyyp || '1',
            objektNumber: objekt_number || '',
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
            selectedRekv: rekv_id,
            selectedTyyp: tyyp || '1',
            objektNumber: objekt_number || '',
            result: null,
            error: 'Päringu teostamisel tekkis viga'
        });
    }
};
