const db = require('./../libs/db');
const getModule = require('./../libs/getModule');
const path = './../models/'; // путь к каталогу с моделями

//class
class Document {
    constructor(docType, docId, userId, rekvId, module) {
        this.docTypeId = docType;
        this.config = this.setConfig(docType, module);
        this.documentId = docId;
        this.userId = userId;
        this.rekvId = rekvId;
        this.test = null;

    }

    setDocumentId(id) {
        this.documentId = id;
    }

    /**
     * подгрузит модель
     * @param docTypeId тип локумента
     * @param module модуль
     * @returns {*}
     */
    setConfig(docTypeId, module) {
        let config;
        // check if exists model for this type
        try {
            config = getModule(docTypeId, null, path, module ? module : 'lapsed');
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
            throw new Error('No mpodel configuration found');
        }
        let sqls = [{alias: 'row', sql: this.config.select[0].sqlAsNew}];
        return await db.executeQueries(sqls, [0, this.userId],
            Object.assign({},
                this.config.returnData));
    }

    /**
     * Вернет промис с данными документа
     */
    async select(config) {
        const _config = config ? config : this.config;

        if (!_config) {
            console.error('select !_config');
            throw new Error('No model configuration found');
        }
        const objectTemplate = Object.assign({}, _config.returnData);
        const data =  await db.executeQueries(_config.select, [this.documentId, this.userId], objectTemplate);
        return data;
    }

    /**
     * Метод сохранения документа
     * @params = {data: {}, userId: // user, asutusId: rekvId}
     */
    async save(params, isNotSelect) {
        // {data, user.userId, user.asutusId}
        if (!params.data || !params.userId || !params.asutusId) {
            throw new Error('Wrong params structure');
        }

        let sql = this.config.saveDoc;
        let data = await db.queryDb(sql, [params.data, params.userId, params.asutusId]);

        if (data.data[0].id && !isNotSelect) {
            this.documentId = data.data[0].id;
            data = await this.select();
        }

        return data;
    }

    /**
     * выполнит задачу
     */
    async executeTask(task, params) {
        let sql = this.config[task].command;
        let _params = params ? params : [this.documentId, this.userId];

        if (!sql) {
            return {error: 'No task found'}
        }

        return await db.queryDb(sql, _params);
    }

    /**
     * грузит гриды
     */
    async selectDocs(sortBy, sqlWhere, limit) {
        let sql = this.config.grid.sqlString,
            params = [this.rekvId, this.userId];
        return await db.queryDb(sql, params, sortBy, sqlWhere, limit);
    }

    /**
     * грузит гриды
     */
    async selectLibs(sqlWhere, sqlLimit) {
        let sql = this.config.selectAsLibs,
            params = [this.rekvId],
            libGridConfig = this.config.libGridConfig ? this.config.libGridConfig.grid : [],
            libSearchFields = this.config.libGridConfig ? this.config.libGridConfig.searchFields : [];

        if (!sql) {
            return [];
        }

        return Object.assign({},
            await db.queryDb(sql, params, '', sqlWhere, sqlLimit),
            {gridConfig: libGridConfig, searchFields: libSearchFields}
        );
    }

    /**
     * грузит гриды
     */
    async delete() {
        let sql = this.config.deleteDoc,
            params = [this.userId, this.documentId];

        if (!sql) {
            return [];
        }

        return await db.queryDb(sql, params);
    }

}

module.exports = Document;

