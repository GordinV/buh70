'use strict';
const db = require('./../libs/db');
const wkhtmltopdf = require('wkhtmltopdf');
const jade = require('jade');
const path = require('path');
const fs = require('fs');
const getParameterFromFilter = require('./../libs/getParameterFromFilter');
const getGroupedData = require('./../libs/getGroupedData');


const createPDF = async function createFile(html, fileName = 'doc') {

    const options = {
        pageSize: 'letter',
    };
    let outFile = path.join(__dirname, '..', 'public', 'pdf', `${fileName}.pdf`);

    try {
        await exportHtml(html, outFile, options);
    } catch (error) {
        console.error(`ERROR: Handle rejected promise: '${error}' !!!`);
        outFile = null;
    }
    return outFile;
};


exports.get = async (req, res) => {
    let id = req.params.id || 0; // параметр id документа
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const docTypeId = req.params.documentType || ''; // параметр тип документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = require('../middleware/userData')(req, uuid); // данные пользователя
    let filterData = []; // параметр filter документов;

    if (id && !sqlWhere) {
        // only 1 id
        id = Number(id);
    } else {
        if (id) {
            filterData = JSON.parse(id).filter(row => {
                if (row.value) {
                    return row;
                }
            });

        }
        id = null;
    }
    let template = docTypeId; // jade template
    const limit = 1000;

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    try {
        // создать объект
        const Doc = require('./../classes/DocumentTemplate');
        const doc = new Doc(docTypeId, (id ? id : null), user.userId, user.asutusId, 'lapsed');

        const printTemplates = doc.config.print;

        let renderForm;

        let templateObject;

        if (printTemplates) {
            templateObject = printTemplates.find(templ => templ.params === (id ? 'id' : 'sqlWhere'));
            renderForm = templateObject.view;

            if (id && templateObject.register) {
                // если есть метод регистрации, отметим печать
                let sql = templateObject.register,
                    params = [id, user.userId];

                if (sql) {
                    db.queryDb(sql, params);
                }
            }
        }


        // вызвать метод
        const method = id ? 'select' : 'selectDocs';
        let gridParams;

        if (method === 'selectDocs'  && doc.config.grid.params && typeof doc.config.grid.params !== 'string') {
            gridParams = getParameterFromFilter(user.asutusId,  user.userId, doc.config.grid.params , filterData);
        }

        let result = await doc[method]('', sqlWhere, limit, gridParams);

        let data = id ? {...result.row, ...result} : result.data;

        // усли указан конвертер, то отдаем данные туда на обработку
        if (templateObject && templateObject.converter) {
            data = templateObject.converter(data);
        }

        // groups
        if (templateObject.group) {
            //преобразуем данные по группам
            data = getGroupedData(data, templateObject.group);
        }

        // вернуть отчет
        let printHtml;

        // вернуть отчет
        res.render(renderForm, {data: data, user: user, filter: filterData}, (err, html) => {
            printHtml = html;
        });

        //attachment
        let l_file_name = `doc_${Math.floor(Math.random() * 1000000)}`;

        let filePDF = await createPDF(printHtml, l_file_name);

        if (filePDF) {
            const stream = await fs.createReadStream(filePDF);

            res.setHeader('Content-disposition', 'inline; filename="doc.pdf"');
            res.setHeader('Content-type', 'application/pdf');

            stream.pipe(res);

            // удаляем файл
            await fs.unlink(filePDF, (err, data) => {
                if (err) {
                    return reject(err);
                }
            });
        } else {
            res.send({status: 500, result: 'Puudub fail'});
        }

    } catch (error) {
        console.error('error', error);
        res.send({status: 500, result: 'Error' + error.TypeError});

    }
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
