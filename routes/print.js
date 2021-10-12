'use strict';
const db = require('./../libs/db');
const getParameterFromFilter = require('./../libs/getParameterFromFilter');
const getGroupedData = require('./../libs/getGroupedData');

exports.get = async (req, res) => {
    let ids = (req.params.id || 0); // параметр id документа
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const docTypeId = req.params.documentType || ''; // параметр тип документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = require('../middleware/userData')(req, uuid); // данные пользователя
    let filterData = []; // параметр filter документов;
    let template = docTypeId; // jade template
    const limit = 10000;
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

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    try {
        // создать объект
        const Doc = require('./../classes/DocumentTemplate');
        const doc = new Doc(docTypeId, (id ? id : null), user.userId, user.asutusId, 'lapsed');

        // установим таймаут для ожидания тяжелых отчетов
        res.setTimeout(400000);

        const printTemplates = doc.config.print;

        let templateObject;
        if (printTemplates) {
            templateObject = printTemplates.find(templ => templ.params === (id ? 'id' : 'sqlWhere'));
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
        let gridParams;

        if (method === 'selectDocs'  && doc.config.grid.params && typeof doc.config.grid.params !== 'string') {
            gridParams = getParameterFromFilter(user.asutusId,  user.userId, doc.config.grid.params , filterData);
        }

        let filterTotals = doc.config.grid.totals ? doc.config.grid.totals : null;
        let result = await doc[method]('', sqlWhere, limit, gridParams, filterTotals);

        let data = id ? {...result.row, ...result} : result.data;

        // усли указан конвертер, то отдаем данные туда на обработку
        if (templateObject && templateObject.converter) {
            data = templateObject.converter(data);
        }

        // groups
        if (templateObject.group) {
            //преобразуем данные по группам
            data = getGroupedData(data,templateObject.group);
        }

        // вернуть отчет
        res.render(template, {title: 'Tunnused', data: data, user: user, filter: filterData});

    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({status: 500, result: 'Error'});

    }
};
