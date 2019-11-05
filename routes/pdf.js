'use strict';
const db = require('./../libs/db');
const pdf = require('html-pdf');
const jade = require('jade');


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


        res.render(template, {title: 'PDF print', data: data, user: user}, (err, html) => {
                /*
                                pdf.create(html, {format: 'A4'}).toFile('./public/pdf/arve.pdf', (err, res) => {
                                    if (err) {
                                        console.log(err);
                                    } else {
                                        console.log(res);
                                    }
                                });

                                res.sendfile('./public/pdf/arve.pdf');
                  */
                pdf.create(html, {format: 'A4'}).toStream((err, stream) => {
                    if (err) return res.end(err.stack);
                    res.setHeader('Content-type', 'application/pdf');
                    stream.pipe(res)

                });

            }
        );

    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({status: 500, result: 'Error'});

    }
};
