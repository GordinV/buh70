'use strict';
const db = require('./../libs/db');

exports.get = async (req, res) => {
    let ids = (req.params.id || 0); // параметр id документа
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const docTypeId = req.params.documentType || ''; // параметр тип документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = require('../middleware/userData')(req, uuid); // данные пользователя
    let filterData = []; // параметр filter документов;
    let template = docTypeId; // jade template
    const limit = 1000;
    let id;

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

console.log('filter', filterData);
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

        res.render(template, {title: 'Tunnused', data: data, user: user, filter: filterData});

    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({status: 500, result: 'Error'});

    }
};
