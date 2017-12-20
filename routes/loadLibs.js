'use strict';

exports.post = async (req, res) => {
    let user = require('../middleware/userData')(req); // данные пользователя
    let documentType = req.params.documentType.toUpperCase(); // получим из параметра тип документа

    if (!user) {
        user = {
            userId: 1,
            asutusId: 1
        }
    }

    const Doc = require('./../classes/DocumentTemplate');
    const Document = new Doc(documentType, null, user.userId, user.asutusId);

    let result = {result: await Document.selectLibs()};

    res.send({result: result}); //пока нет новых данных

};