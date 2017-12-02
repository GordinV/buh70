const db = require('./db');
const getModule = require('./getModule');
const path = '../models/';

/**
 * Подготовит запрос
 * @type {{}}
 */
class PrepaireData {
    constructor(docTypeId) {
        this.docTypeId = docTypeId;
        this.config = this.setConfig(docTypeId);
        this.select = this.select.bind(this);
    }

   setConfig(docTypeId) {
        let config;
        // check if exists model for this type
        try {
            config = getModule(docTypeId, null, path);
        } catch (e) {
            console.error(e);
            return null;
        }
        return config;
    }

    select(params) {
        console.log('select', this);

        let sqls = this.config.select,
            docBpm = [], // БП документа
            returnData = this.config.returnData;

        if (this.config.bpm) {
            docBpm = this.config.bpm;
        }

        sqls.forEach(sql => {
            console.log('sql:', sql);
        });


//        const result = await db()
        /*
         // выполним запрос
         if (typeof sql === 'object') {
         try {
         Doc.executeSqlQueries(sql, params, returnData, (err, data) => {
         if (err) {
         console.error('got error', err);
         return callback(err, null);
         }
         callback(err, data, docBpm);
         });
         } catch (err) {
         console.error('catched error', err);
         return callback(err);
         }
         } else {
         try {
         Doc.executeSqlQuery(sql, params, (err, data) => {
         if (err) {
         return callback(err);
         }
         callback(err, data.rows, docBpm);
         });
         } catch (err) {
         console.error('error catched', err);
         return callback(err);
         }
         }
         */
        return {};
    }

    selectAsLibs() {

    }

    save() {
    }

    execute() {

    }

    delete() {

    }

}
;

module.exports = PrepaireData;