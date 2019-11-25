'use strict';
const db = require('./../libs/db');
const wkhtmltopdf = require('wkhtmltopdf');
const jade = require('jade');
const createPDF = async function createFile(html, fileName = 'doc') {

    const options = {
        pageSize: 'letter',
    };
    let outFile = path.join(__dirname, '..', 'public', 'pdf', `${fileName}.pdf`);

    console.log('outFile', outFile);
    try {
        await exportHtml(html, outFile, options);
    } catch (error) {
        console.log(`ERROR: Handle rejected promise: '${error}' !!!`);
        outFile = null;
    }
    return outFile;
};


exports.get = async (req, res) => {
    const id = Number(req.params.id || 0); // параметр id документа
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const docTypeId = req.params.documentType || ''; // параметр тип документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = require('../middleware/userData')(req, uuid); // данные пользователя


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

        if (printTemplates) {
            const templateObject = printTemplates.find(templ => templ.params === (id ? 'id' : 'sqlWhere'));
            template = templateObject.view;

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
        let result = await doc[method]('', sqlWhere, limit);
        const data = id ? {...result.row, ...result} : result.data;
        // вернуть отчет

        const html = jade.render(template, {title: 'Tunnused', data: data, user: user});


        res.render(template, {title: 'PDF print', data: data, user: user}, async (err, html) => {

            //attachment
            let filePDF = await createPDF(printHtml, `doc`);
            if (!filePDF) {
                // error in PDF create
                throw new Error('PDF faili viga');
            }

            res.sendFile(filePDF)
        });

    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({status: 500, result: 'Error'});

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
