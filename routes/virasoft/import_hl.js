const db = require('./../../libs/db');
const Doc = require("../../classes/DocumentTemplate");

module.exports = async (req, res) => {

    console.log('import hl start .')

    //async (file, mimeType) => {
    const Doc = require('./../../classes/DocumentTemplate');
    const Document = new Doc('puudumine', null, null, null, 'palk');

    let rows = [];
    let file = req.body;
    let params = req.params;
//    console.log('req', JSON.stringify(req));

    console.log('import hl got file', file, params);

    // контроль структуры
    let error = '';


    error = error + !file ? 'File is empty or wrong structure' : '';
    error = error + !file.fileId ? 'FileId is not found' : '';
    error = error + !file.userId ? 'UserId is not found' : '';
    error = error + file.data.length === 0 ? 'data is not found or empty' : '';


    if (!error || error === '') {
        rows = file.data;
    } else {
        console.error('File structure is wrong', error);
        throw new Error(`File structure is wrong ${error}`)
    }

    var returnObject = {};
    // контроль пользователя

    let sql = `SELECT *
               FROM
                   ou.userid
               WHERE
                     parool = '${file.userId}'
                 AND status < 3
               ORDER BY
                   roles ->> 'is_kasutaja'
               LIMIT 1`;

    console.log('rows', rows)

    try {

        let user = await db.queryDb(sql, null, null, null, null, null);


        if (!user || !user.data[0].id) {
            // ошибка пользователмя
            returnObject = {
                error_message: `Viga: vale userId`,
                result: 0,
                data: []
            }
            return res.status(401).send(returnObject);

        }

        var saved = 0;
        let response = [];
        var returnData;

        returnObject = {
            error_message: null,
            result: 0,
            data: []
        };
        console.log(rows, returnObject.error_message)

        if (rows.length && !returnObject.error_message) {
            // сохраняем

            const params = {
                userId: user.data[0].id,
                asutusId: 63,
                data: JSON.stringify({file: rows, fileId: file.FileId}),
            };

            let sql = Document.config.importDoc.command;

            response = await Document.save(params, true, sql);

            if (response && response.data && response.data.length > 0) {
                saved = response.data[0].result;
                returnData = response.data[0];

                returnObject = {
                    error_message: `Kokku leidsin ${rows.length} maksed, salvestatud kokku: ${saved}`,
                    result: saved,
                    data: returnData
                };
                return res.status(200).send(returnObject);

            } else {
                returnObject = {
                    error_message: response.error_message,
                    result: response.result,
                    data: []
                };
                return res.status(500).send(returnObject);

            }

        }
        return res.status(500).send(returnObject);

    } catch (e) {
        console.error(e);
        returnObject = {
            error_message: `Viga ${e}`,
            result: 0,
            data: []
        };
        return res.status(500).send(returnObject);

    }

};

