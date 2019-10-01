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
        let sqls = this.config.select,
            docBpm = [], // БП документа
            returnData = this.config.returnData;

        if (this.config.bpm) {
            docBpm = this.config.bpm;
        }


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

module.exports = PrepaireData;