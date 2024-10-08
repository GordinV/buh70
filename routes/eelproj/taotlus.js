'use strict';
const db = require('./../../libs/db');
const config = require('./../../config/narvalv.json');
const wkhtmltopdf = require('wkhtmltopdf');
const jade = require('jade');
const path = require('path');
const fs = require('fs');
const DocContext = require('./../../frontend/doc-context.js');
const crypto = require('crypto');


exports.get = async (req, res) => {
    let hash = (req.params.hash || 0); // параметр id документа
    let ids = (req.params.id || 0); // параметр id документа
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const docTypeId = 'TAOTLUS'; // параметр тип документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
//    const user = await require('../middleware/userData')(req, uuid); // данные пользователя
    const user = {'nimi': 'vlad', 'rekvid': 63}; // данные пользователя
    let filterData = []; // параметр filter документов;
    let template = docTypeId; // jade template
    let isPdf = true;
    const limit = 10000;
    let id;
    const userId = 2477;
    let rekvId = await getRekvIdFromHash(hash);

    if (ids && !sqlWhere) {
        // only 1 id
        id = Number(ids);
    } else {
        filterData = JSON.parse(ids).filter(row => {
            if (row.value) {
                return row;
            }
        });
    }

    // проверим на пароль
    if (!rekvId) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    let rekvAndmedSql = require('./../../models/ou/rekv').select[0].sql;

    try {
        // создать объект
        const Doc = require('./../../classes/DocumentTemplate');
        const doc = new Doc(docTypeId, id, null, null, 'eelproj');

        // установим таймаут для ожидания тяжелых отчетов
        res.setTimeout(400000);


        let templateObject;

        // вызвать метод
        let params = [id, userId];

        let sql_ = doc.config.select.find(sqls => sqls.alias == 'row');
        let sql = sql_.sql;
        const docData = {};
        // документ
        let data = await db.queryDb(sql, params, null, null, null, null, config);

        docData.data = {...data.data['0']};
        let rekvData = await db.queryDb(rekvAndmedSql, [rekvId, userId], null, null, null, null, config);
        docData.data.rekv = {...rekvData.data['0']};

        // details
        let detailSql_ = doc.config.select.find(sqls => sqls.alias == 'details');
        let detailSql = detailSql_.sql;

        let detailsData = await db.queryDb(detailSql, params, null, null, null, null, config);

        let summa_kokku = 0;
        let kassa_kokku = 0;
        let oodatav_kokku = 0;

        detailsData.data.forEach(row => {
            summa_kokku = summa_kokku + Number(row.summa);
            kassa_kokku = kassa_kokku + Number(row.summa_kassa);
            oodatav_kokku = oodatav_kokku + Number(row.oodatav_taitmine);
        });

        detailsData.data = detailsData.data.map(row => {
            row.summa_kokku = summa_kokku;
            row.kassa_kokku = kassa_kokku;
            row.oodatav_kokku = oodatav_kokku;
            return row;
        });

        docData.data.details = {...detailsData.data};
        let printTemplates = docData.data.tunnus ? 'taotlus_hidden_oodav': 'taotlus';
        // вернуть отчет
        if (isPdf) {
            var printHtml;

            res.render(printTemplates, {data: docData.data, user: user, filter: filterData}, (err, html) => {
                printHtml = html;
            });

            //attachment
            let l_file_name = `taotlus_${id}`;


            let filePDF = await createPDF(printHtml, l_file_name);

            if (filePDF) {
                const stream = await fs.createReadStream(filePDF);

                res.setHeader('Content-disposition', `inline; filename="${filePDF}"`);
                res.setHeader('Content-type', 'application/pdf');

                stream.pipe(res);

            } else {
                res.send({status: 500, result: 'Puudub fail'});
            }


        } else {
            // вернуть отчет
            res.render(printTemplates, {title: 'Report', data: docData.data, user: user, filter: filterData});
        }

    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({status: 500, result: 'Error'});

    }
};

exports.post = async (req, res) => {
    let parameter = (req.body); // параметр id документа
    const id = req.params.id || '';// параметр sqlWhere документа
    let hash = (req.params.hash || 0); // параметр id документа

//    let ids = (req.params.id || 0); // параметр id документа
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const docTypeId = 'TAOTLUS'; // параметр тип документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
//    const user = await require('../middleware/userData')(req, uuid); // данные пользователя
    const user = {'nimi': 'vlad', 'rekvid': 63}; // данные пользователя
    let filterData = []; // параметр filter документов;
    let template = docTypeId.toLowerCase(); // jade template
    let isPdf = true;
    const limit = 10000;


    const userId = 2477;

    let rekvAndmedSql = require('./../../models/ou/rekv').select[0].sql;

    // проверим на пароль
    if (!checkForAccess(hash)) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    try {
        // создать объект
        const Doc = require('./../../classes/DocumentTemplate');
        const doc = new Doc(docTypeId, id, null, null, 'eelproj');

        // установим таймаут для ожидания тяжелых отчетов
        res.setTimeout(400000);

        const printTemplates = doc.config.print;

        let templateObject;

        // вызвать метод
        let params = [id, userId];

        let sql_ = doc.config.select.find(sqls => sqls.alias == 'row');
        let sql = sql_.sql;
        const docData = {};
        // документ
        let data = await db.queryDb(sql, params, null, null, null, null, config);

        docData.data = {...data.data['0']};
        let rekvData = await db.queryDb(rekvAndmedSql, [docData.data.rekvid, userId], null, null, null, null, config);
        docData.data.rekv = {...rekvData.data['0']};

        // details
        let detailSql_ = doc.config.select.find(sqls => sqls.alias == 'details');
        let detailSql = detailSql_.sql;

        let detailsData = await db.queryDb(detailSql, params, null, null, null, null, config);

        // усли указан конвертер, то отдаем данные туда на обработку
        if (templateObject && templateObject.converter) {
            detailsData.data = templateObject.converter(detailsData.data);
        }

        docData.data.details = {...detailsData.data};

        // вернуть отчет
        if (isPdf) {
            var printHtml;

            res.render(template, {data: docData.data, user: user, filter: filterData}, (err, html) => {
                printHtml = html;
            });

            //attachment
            let l_file_name = `taotlus_${id}`;


            let filePDF = await createPDF(printHtml, l_file_name);

            if (filePDF) {
                //ответ
                res.send({
                    status: 200, result: 1, data: {
                        action: 'taotlus_pdf',
                        result: {
                            doc_id: id,
                            error_code: 0,
                            error_message: null,
                        }
                    }
                });

            } else {
                res.send({status: 500, result: 'Puudub fail'});
            }


        } else {
            // вернуть отчет
            res.render(template, {title: 'Report', data: docData.data, user: user, filter: filterData});

        }

    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({status: 500, result: 'Error'});

    }
};

const createPDF = async function createFile(html, fileName = 'doc') {

    const options = {
        pageSize: 'letter',
    };
    let outFile = path.join(__dirname, '../../', 'public', 'pdf', `${fileName}.pdf`);

    try {
        await exportHtml(html, outFile, options);
    } catch (error) {
        console.error(`ERROR: Handle rejected promise: '${error}' !!!`);
        outFile = null;
    }
    return outFile;
};

function exportHtml(html, file, options) {
    return new Promise((resolve, reject) => {
        wkhtmltopdf(html, options, (err, stream) => {
            if (err) {
                reject(err);
            } else {
                stream.pipe(fs.createWriteStream(file));
                resolve();
            }
        });
    });
}


async function generateHash() {
    const rekvHash = {};
    let rekvIds = await getRekvIds();
    rekvIds.forEach(rekv => {
        let hashParool = crypto.createHmac('sha1','').update(rekv.id.toString()).digest('hex');
        rekvHash[hashParool] = rekv.id;
    });
    return rekvHash;
}

async function  getRekvIds() {
    let aHash = [];
    let sql = 'select id from ou.rekv where parentid < 999';

    let rekvIds = await db.queryDb(sql, null, null, null, null, null, config);

    return rekvIds.data;
}

async function getRekvIdFromHash(hash) {
    if (!DocContext.rekvHash) {
        DocContext.rekvHash = await generateHash();
    }

    return DocContext.rekvHash[hash];
}