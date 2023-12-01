'use strict';

const getParameterFromFilter = require('./../libs/getParameterFromFilter');
const Const = require('./../config/constants');
const Liimit = Const.RECORDS_LIMIT;

exports.post = async (req, res) => {
    const user = await require('../middleware/userData')(req), // данные пользователя
        parameter = req.body.parameter || '',// параметры если переданы
        module = req.body.module || 'documents',
        sortBy = req.body.sortBy, //порядок сортировки
        limit = req.body.limit ? req.body.limit : Liimit, //порядок сортировки
        method = req.body.method ? req.body.method : 'selectDocs', //порядок сортировки
        sqlWhere = req.body.sqlWhere, //динамический фильтр
        filterData = req.body.filterData || []; // параметры фильтры
    let paring_id = req.body.paring_id; // ид запроса, вернем его , если задан

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();

    }

    if (!paring_id) {
        paring_id = 0;
    }

    try {
        // создать объект
        const Doc = require('./../classes/DocumentTemplate');
        const doc = new Doc(parameter, null, user.userId, user.asutusId, module);


        let gridConfig = doc.config.grid.gridConfiguration;

        let gridParams;
        let subtotals = doc.config.grid.subtotals ? doc.config.grid.subtotals : [];
        let filterTotals = doc.config.grid.totals ? doc.config.grid.totals : null;

        if (filterData.length > 0 && doc.config.grid.params && typeof doc.config.grid.params !== 'string') {
            gridParams = getParameterFromFilter(user.asutusId, user.userId, doc.config.grid.params, filterData);
        }

        // установим таймаут для ожидания тяжелых отчетов
        res.setTimeout(400000);

        let data;
        // оставим только "заданные" параметры
        let paramsWithData = gridParams ? gridParams.filter(param => param) : [];

        let minimum = doc.config.grid.min_params ? (doc.config.grid.min_params): 4;


        if (doc.config.grid.notReloadWithoutParameters && doc.config.grid.params.length > 2 && paramsWithData.length < minimum) {
            // если задан параметр, то не делать выборку, пока нет параметров (для отчетов)
            data = {
                docTypeId: parameter,
                result: {
                    error_code: 1,
                    error_message: 'Puuduvad vajalikud parametrid',
                    data: [],
                },
                gridConfig: gridConfig,
                subtotals: subtotals,
                paring_id: paring_id
            };

        } else {
            // вызвать метод

            data = {
                docTypeId: parameter,
                result: await doc[method](sortBy, sqlWhere, limit, gridParams, filterTotals),
                gridConfig: gridConfig,
                subtotals: subtotals,
                paring_id: paring_id
            };
        }

        // усли указан конвертер, то отдаем данные туда на обработку
        if (doc.config.grid && doc.config.grid.converter && data.result && data.result.data) {
            data.result.data = doc.config.grid.converter(data.result.data);
        }

        // вернуть данные
        res.status(200).send(data);
    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({status: 500, result: 'Error', paring_id: paring_id});

    }
};

