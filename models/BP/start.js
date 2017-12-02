'use strict';
const ACTIVE_STATUS = 1,
    DocDataObject = require('../documents'),
    setBpmStatuses = require('./setBpmStatus');

const start =(docId, userId, doc)=> {
    // реализует старт БП документа
    const DOC_STATUS = ACTIVE_STATUS, // устанавливаем активный статус для документа
        SQL_UPDATE = 'update docs.doc set status = $1, bpm = $2, history = $4 where id = $3';

    let  bpm = setBpmStatuses(0, userId, doc), // выставим актуальный статус для следующего процесса
        history = {user: userId, updated: Date.now()};

    // выполнить запрос и вернуть промис
    return DocDataObject.executeSqlQueryPromise(SQL_UPDATE, [DOC_STATUS, JSON.stringify(bpm), docId, JSON.stringify(history)]);

};

module.exports = start;