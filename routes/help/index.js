'use strict';
const fs = require('fs');


exports.get = async (req, res) => {
    const docTypeId = req.params.documentType || ''; // параметр тип документа
        // создать объект
        let template = `help`;
        if (docTypeId) {
            template = `help/${docTypeId.toLowerCase()}`;
        }
        console.log('help', docTypeId, template);

    try {
        // вернуть отчет
        res.render(template);
    } catch (error) {
        console.error('error:', error);
        res.send({status: 500, result: 'Error'});

    }
};
