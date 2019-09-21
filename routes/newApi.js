'use strict';

exports.post = async (req, res) => {
    const user = require('../middleware/userData')(req), // данные пользователя
        parameter = req.body.parameter || '',// параметры если переданы
        module = req.body.module || 'documents',
        sortBy = req.body.sortBy, //порядок сортировки
        sqlWhere = req.body.sqlWhere; //динамический фильтр


    if (!user.userId) {
        res.redirec('/login');
    }

    try {
        // создать объект
        const Doc = require('./../classes/DocumentTemplate');
        const doc = new Doc(parameter, null, user.userId, user.asutusId, module);
        let gridConfig = doc.config.grid.gridConfiguration;


        console.log('sqlWhere', sqlWhere);
        // вызвать метод
        let data = {
            docTypeId: parameter,
            result: await doc.selectDocs(sortBy, sqlWhere),
            gridConfig: gridConfig
        };

        // вернуть данные

        res.status(200).send(data);
    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({result:'Error'});

    }
};

/*

exports.delete = async (req, res) => {
    let user = require('../middleware/userData')(req),
        parameter = req.params.id,
        docTypePattern = /[0-9]/gi,
        docIdPattern = /[^0-9]/gi,
        docId = parameter.replace(docIdPattern, '').trim(),
        docTypeId = parameter.replace( docTypePattern, '').trim(),
        params = [user.userId, docId];

    try {
        // тут вызов метода сохранение
        let results = await DocDataObject.deleteDocPromise(docTypeId, params);
        res.send(results);
    } catch (err) {
        console.error('error:', err);
        res.send({result: 'Error'});

    }
}; //function delete
*/
