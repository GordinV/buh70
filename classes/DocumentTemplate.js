const db = require('./../libs/db');
const getModule = require('./../libs/getModule');
const path = './../models/'; // путь к каталогу с моделями
const async = require('async');

//class
class Document {
    constructor(docType, docId, userId, rekvId) {
        this.docTypeId = docType;
        this.config = this.setConfig(docType);
        this.documentId = docId;
        this.userId = userId;
        this.rekvId = rekvId;
        this.test = null;
    }

    /**
     * подгрузит модель
     * @param docTypeId тип локумента
     * @returns {*}
     */
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


    /**
     * Создает новый объект из модели для нового документа
     */
    async createNew() {
        if (!this.config) {
            return null;
        }
        let sqls = [{alias: 'row', sql: this.config.select[0].sqlAsNew}];
        let data = await db.executeQueries(sqls, [0, this.userId], Object.assign({}, this.config.returnData));
        return data;
    }

    /**
     * Вернет промис с данными документа
     */
    async select() {
        if (!this.config) {
            return null;
        }

        const objectTemplate = Object.assign({}, this.config.returnData);
        let data = await db.executeQueries(this.config.select, [this.documentId, this.userId], objectTemplate);
        return data;
    }

    /**
     * Метод сохранения документа
     * @params = {data: {}, userId: // user, asutusId: rekvId}
     */
    async save(params) {
        // {data, user.userId, user.asutusId}
        if (!params.data || !params.userId || !params.asutusId) {
            throw new Error('Wrong params structure');
        }

        let sql = this.config.saveDoc;
        let data = await db.queryDb(sql, [params.data, params.userId, params.asutusId]);
        this.documentId = data.data[0].id;
        data = await this.select();
        return data;
    }

    /**
     * выполнит задачу
     */
    executeTask() {

    }

    /**
     * грузит гриды
     */
    selectDocs(sortBy, sqlWhere) {
        let sql = this.config.grid.sqlString,
            params = [this.rekvId, this.userId];

        return db.queryDb(sql, params, sortBy, sqlWhere);

    }

    /**
     * грузит гриды
     */
    selectLibs() {
        let sql = this.config.selectAsLibs,
            params = [];

        return db.queryDb(sql, params);

    }
}

module.exports = Document;

