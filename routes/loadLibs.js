'use strict';
const _ = require('lodash'),
    HttpError = require('./../error').HttpError;


exports.post = async (req, res) => {
    let user = require('../middleware/userData')(req); // данные пользователя
    let documentType = req.params.documentType.toUpperCase(); // получим из параметра тип документа
    const module = req.body.module || 'lapsed';
    let sqlWhere = _.has(req.body,'sql') ? req.body.sql: null;
    let sqlLimit = _.has(req.body,'limit') ? req.body.limit: null;
    let kpv = _.has(req.body,'kpv') ? req.body.kpv: null;

    if (!user) {
        const err = new HttpError(401, 'No user');
        return res.status(401).send('Error');
    }

    const Doc = require('./../classes/DocumentTemplate');
    const Document = new Doc(documentType, null, user.userId, user.asutusId, module);

    let data = await Document.selectLibs(sqlWhere, sqlLimit, kpv);

    let local_result = Object.assign({},{result: data});

    res.send({result: local_result}); //пока нет новых данных

};