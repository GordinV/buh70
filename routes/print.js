'use strict';

exports.get = async (req, res) => {
    const id = Number(req.params.id || 0); // параметр id документа
    const sqlWhere = req.params.params  || '';// параметр sqlWhere документа
    const docTypeId = req.params.documentType || ''; // параметр тип документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = require('../middleware/userData')(req, uuid); // данные пользователя
    let template =  docTypeId; // jade template
    const limit = 1000;

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    try {
        // создать объект
        const Doc = require('./../classes/DocumentTemplate');
        const doc = new Doc(docTypeId, (id ? id: null), user.userId, user.asutusId, 'lapsed');

        const printTemplates = doc.config.print;
        if (printTemplates) {
            template = printTemplates.find(templ => templ.params === id ? 'id': 'sqlWhere').view;
        }

        // вызвать метод
        const method = id ? 'select': 'selectDocs';
        let result = await doc[method]('', sqlWhere, limit);

        const data = id? result.row: result.data;
        // вернуть отчет
        res.render(template, {title: 'Tunnused', tunnused: data, user: user });

    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({status: 500, result: 'Error'});

    }
};