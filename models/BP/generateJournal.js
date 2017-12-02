'use strict';
const setBpmStatuses = require('./setBpmStatus');

const generateJournal = (docId, userId, doc)=> {
    // реализует контировка

    const ACTUAL_STEP_STATUS = 1, // актуальный шаг БП
        SQL_GENERATE_LAUSEND = doc.generateJournal['command'],
        SQL_UPDATE_DOCUMENT_BPM = 'update docs.doc set bpm = $2, history = $3  where id = $1',
        DocDataObject = require('../documents');

    let   bpm = setBpmStatuses(ACTUAL_STEP_STATUS, userId, doc),
        tasks = [],
        history = {user: userId, updated: Date.now()};

    // выполнить запрос и вернуть промис
    return Promise.all([
        DocDataObject.executeSqlQueryPromise(SQL_GENERATE_LAUSEND, [docId, userId]),
        DocDataObject.executeSqlQueryPromise(SQL_UPDATE_DOCUMENT_BPM, [docId, JSON.stringify(bpm), JSON.stringify(history)])
    ]);
};

module.exports = generateJournal;