const db = require('./../libs/db');
const getParameterFromFilter = require('./../libs/getParameterFromFilter');

const getModule = require('./../libs/getModule');
const path = './../models/'; // путь к каталогу с моделями
const log = require('./../libs/log');

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
     * Логирует запрос и его параметры
     */
    setLog(sql, params, result) {
        let insert = `INSERT INTO ou.paringud (user_id, sql, params, tulemused)
                      VALUES ($4, $1::TEXT, $2::TEXT, $3::TEXT)`;
        db.queryDb(insert, [sql, params, result, this.userId]);
    }


    /**
     * Создает новый объект из модели для нового документа
     */
    async createNew() {
        let tulemused;
        if (!this.config) {
            throw new Error('No mpodel configuration found');
        }
        let sqls = [{alias: 'row', sql: this.config.select[0].sqlAsNew}];

/*
        if (this.config.logs) {
            this.setLog(sqls, [0, this.userId])
        }
*/
        tulemused = await db.executeQueries(sqls, [0, this.userId],
            Object.assign({},
                this.config.returnData));
/*
        if (this.config.logs) {
            this.setLog(sqls, [0, this.userId], tulemused)
        }
*/

        return tulemused;
    }

    /**
     * Вернет промис с данными документа
     */
    async select(config, dbConfig) {
        const _config = config ? config : this.config;

        if (!_config) {
            console.error('select !_config');
            throw new Error('No model configuration found');
        }
        const objectTemplate = Object.assign({}, _config.returnData);
        let tulemused;

        // фильтр на initial load (при загрузке документа)
        let initialLoad = _config.select.filter(row => {
            if (!row.not_initial_load) {
                return row;
            }
        });

        try {
/*
            if (_config.logs) {
                this.setLog(initialLoad, [this.documentId, this.userId])
            }
*/

            tulemused = await db.executeQueries(initialLoad, [this.documentId, this.userId], objectTemplate, dbConfig);
/*
            if (_config.logs) {
                this.setLog(initialLoad, [this.documentId, this.userId], tulemused)
            }
*/
        } catch (e) {
            console.error('error', err);
        }

        return tulemused;
    }

    /**
     * Метод сохранения документа
     * @params = {data: {}, userId: // user, asutusId: rekvId}
     */
    async save(params, isNotSelect, sqlParam) {
        // {data, user.userId, user.asutusId}

        if (!params.data || !params.userId || !params.asutusId) {
            console.error('Viga, Wrong params structure', params.userId, params.asutusId, params.data);
            return null;

            throw new Error('Wrong params structure');
        }

        let sql = sqlParam;
        if (!sql) {
            sql = this.config.saveDoc;
        }
        if (this.config.logs) {
            this.setLog(sql, [params.data, params.userId, params.asutusId]);
        }

        let data = await db.queryDb(sql, [params.data, params.userId, params.asutusId]);

        if (this.config.logs) {
            this.setLog(sql, [params.data, params.userId, params.asutusId], JSON.stringify(data));
        }

        if (data && data.error_code) {
            console.error('Viga', data.error_message, data);
            return data;
        }

        if (data && data.data && data.data[0].id && !isNotSelect) {
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

        if (this.config.logs) {
            this.setLog(sql, [_params]);
        }

        let tulemused = await db.queryDb(sql, _params);

        if (this.config.logs) {
            this.setLog(sql, [_params], JSON.stringify(tulemused));
        }
        return tulemused;
    }

    /**
     * грузит гриды
     */
    async selectDocs(sortBy, sqlWhere, limit, params = [this.rekvId, this.userId], subTotals) {
        let sql = this.config.grid.sqlString;

        try {
            let sqlParamsQantity = (this.config.grid.params == '' ? 2 : this.config.grid.params.length);
            let tulemused;

// добавим при необходимости кол-во параметром
            let paramsToAdd = sqlParamsQantity - params.length;

            if (sqlParamsQantity > 2 && params.length == 2) {
                for (let i = 0; i < paramsToAdd; i++) {
                    params.push(null)
                }
            }


            if (sqlParamsQantity > 2 && params.length == 2) {

                if (this.config.grid.params && typeof this.config.grid.params !== 'string') {
                    params = getParameterFromFilter(user.asutusId, user.userId, this.config.grid.params, params.filterData);
                }


            }
/*
            if (this.config.logs) {
                this.setLog(sql, [params, sortBy, sqlWhere, limit, subTotals]);
            }
*/
            tulemused = await db.queryDb(sql, params, sortBy, sqlWhere, limit, subTotals);

/*
            if (this.config.logs) {
                this.setLog(sql, [params, sortBy, sqlWhere, limit, subTotals], JSON.stringify(tulemused));
            }
*/

            return tulemused;

        } catch (e) {
            // logs
            let message = `selectDocs, tekkis viga, ${sql}, ${e}, ${params}`;
            log(message, 'error');
            return null;
        }
    }

    /**
     * грузит гриды
     */
    async selectLibs(sqlWhere, sqlLimit, kpv) {
        let sql = this.config.selectAsLibs,
            params = [this.rekvId],
            libGridConfig = this.config.libGridConfig ? this.config.libGridConfig.grid : [],
            libSearchFields = this.config.libGridConfig ? this.config.libGridConfig.searchFields : [];

        if (!sql) {
            return [];
        }
        if (sqlWhere && kpv) {
            // огрничение на справочник
            sqlWhere = ` ${sqlWhere} and (valid is null or valid >= '${kpv}'::date) `
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

// ищем наличии контроля
        let result = this.config.select.find(row => {
            if (row.alias && row.alias === 'validate_lib_usage') {
                return row;
            }
        });

        if (result) {
            let valid = '2000-01-01'; // проверка всех документов
            // есть запрос для валидации
            const tulemused = await db.queryDb(result.sql, [this.rekvId, this.docId, valid]);


            if (tulemused && ((tulemused.result && tulemused.result > 0) || tulemused.error_code)) {
                let report = tulemused.data.map((row, index) => {
                    return {id: index, result: 0, kas_vigane: true, error_message: row.error_message};
                });

                if (tulemused.error_code && !tulemused.data.length) {
                    // одно сообщение не массив
                    report = [{id: 1, result: 0, kas_vigane: true, error_message: tulemused.error_message}];
                }

                return report;
            }
        }
        if (this.config.logs) {
            this.setLog(sql, [params]);
        }

        let tulemused = await db.queryDb(sql, params);

        if (this.config.logs) {
            this.setLog(sql, [params], JSON.stringify(tulemused));
        }

        return tulemused;

    }

}

module.exports = Document;

