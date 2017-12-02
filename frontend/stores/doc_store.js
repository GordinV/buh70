'use strict';

const flux = require('fluxify');

const docStore = flux.createStore({
    id: 'docStore',
    initialState: {
        gridCellEdited: 0, // отслеживаем в гриде редактируемую ячейку
        data: [],
        details: [],// данные на грид
        relations: [],// данные на связанные документы
        gridConfig: [], // конфигурация грида
        gridName: '',
        docId: 0,
        deleted: false,
        edited: false,
        saved: true,
        gridRowId: 0,
        libs: [
            {
                id: 'asutused',
                data: [],
                params: []
//                data:[{id:1, name:"Asutus 1"},{id:2, name:"Asutus 2"},{id:3, name:"Asutus 3"} ]
            },
            {
                id: 'nomenclature',
                data: [],
                params: []
            },
            {
                id: 'kontod',
                data: [],
                params: []
            },
            {
                id: 'project',
                data: [],
                params: []
            },
            {
                id: 'tunnus',
                data: [],
                params: []
            },
            {
                id: 'aa',
                data: [],
                params: []
            },
            {
                id: 'kassa',
                data: [],
                params: []
            },
            {
                id: 'arvedSisse',
                data: [],
                params: [null, null],
                fields: ['asutusid', 'arvid'] // ид контр-агента и номер счета
            },
            {
                id: 'arvedValja',
                data: [],
                params: [null, null],
                fields: ['asutusid', 'arvid'] // ид контр-агента и номер счета
            },
            {
                id: 'users',
                data: [],
                params: []
            },
            {
                id: 'dokProps',
                data: [],
                params: [null, null],
                fields: ['doc_type_id', 'rekvid']// тип документа и ид учреждения
            }

        ],
        bpm: [], // данные БП документа
        task: {}, // текущая задача
        backup: {} // хранит неизмененное состояние документа
    },
    actionCallbacks: {
        backupChange: function (updater, value) {
            // хранит начальные данных документа
            updater.set({backup: value});
        },

        setLibsFilter: function (updater, libName, filter) {

            // ищем справочник
            let libs = this.libs;

            for (let i = 0; i < libs.length; i++) {
                if (libs[i].id == libName) {
                    if (filter) {
                        libs[i].filter = filter;
                        flux.doAction('loadLibs', libName); //новые данные
                    }
                    break;
                }
            }
        },
        gridRowIdChange: function (updater, value) {
            //           console.log('gridRowIdChange called:' + value);
            updater.set({gridRowId: value});
        },
        loadLibs: function (updater, libsToUpdate) {
            // грузим справочники
            let libs = this.libs.filter((item) => {
                if (!libsToUpdate || item.id == libsToUpdate) {
                    return item;
                }
            });

            // вызываем обновление справочника с сервера
            libs.forEach((item) => {
                let libParams = [];
                if (item.params) {
                    libParams = item.params;
                    // установим параметры для запроса
                    for (let i = 0; i < libParams.length; i++) {
                        libParams[i] = this.data[item.fields[i]];
                    }
                }
                loadLibs(item.id, libParams);
            });

        },
        saveData: function (updater) {
            saveDoc();
        },
        executeTask: function (updater, task) {
            executeTask(task);
        },
        deleteDoc: function (updater) {
            deleteDoc();
        },
        gridCellEditedChange: function (updater, value) {
//           console.log('called gridCellEditedChange:' + value);
            updater.set({gridCellEdited: value});
        },
        docIdChange: function (updater, value) {
            // Stores updates are only made inside store's action callbacks
            // чистим данные грида
            try {
                updater.set({docId: value});

            } catch (e) {
                console.error('docIdChange viga', e);
            }
        },
        dataChange: function (updater, value) {
            if (typeof value.arvid !== 'undefinite') {
                // если контрагент отсутсвует, то и параметр контрагента также обнулим
                value.arvid = value.asutusid ? value.arvid : null;
            }
            // Отслеживает загрузку данных документа
            updater.set({data: value});

        },
        bpmChange: function (updater, value) {
            // Загрузка БП
//            console.log('bpmChange', value);
            updater.set({bpm: value});
        },
        relationsChange: function (updater, value) {
            // Отслеживает загрузку данных зависимостей документа
            updater.set({relations: value});
        },
        detailsChange: function (updater, value) {
            // Отслеживает загрузку данных грида документа
            updater.set({details: value});
        },
        gridConfigChange: function (updater, value) {
            // Отслеживает загрузку конфигурации грида
            updater.set({gridConfig: value});

        },
        deletedChange: function (updater, value) {
            // была вызвана кнопка Delete
            updater.set({deleted: value});
        },
        editedChange: function (updater, value) {
            // Меняется режим редактирования документа
            updater.set({edited: value});
            if (value) {
                backupDoc();
            } else {
                flux.doAction('backupChange', {docData: null, gridData: null});
            }
        },
        savedChange: function (updater, value) {
            // Отслеживает изменения в данных и из сохранение
            updater.set({saved: value});
        },
        libsChange: function (updater, value) {
            // Отслеживает изменения в справочниках
//            console.log('libsChange called', value);
            if (value) {
                updater.set({libs: value});
            }
        },
        gridNameChange: function (updater, value) {
            updater.set({gridName: value});
        },
        requery(action, params) {
            return requery(action, JSON.stringify(params));
        },
        addDoc: function () {
            if (document) {
                Object.defineProperty(window.location, 'href', {
                    writable: true,
                    value: "/document/" + flux.stores.docStore.data.doc_type_id + '0'
                });
//                document.location.href = "/document/" + flux.stores.docStore.data.doc_type_id + '0';
            } else {
                console.log('called add');
            }
        }
    }
});

/**
 * сохраняет копию данных
 */
function backupDoc() {
    let docData = JSON.stringify(docStore.data),
        gridData = JSON.stringify(docStore.details);

    flux.doAction('backupChange', {docData: docData, gridData: gridData});
}

function deleteDoc() {
    // вызывает метод удаления документа
    // вернемся в регистр
    //requery('delete', null);
    document.location = '/documents'
}


/**
 * Выполнит запрос на исполнение задачи
 * @param task
 */
function executeTask(task) {
    const tasksParameters = {
        docId: docStore.data.id,
        tasks: task,
        doc_type_id: docStore.data.doc_type_id
    };

    requery('execute', JSON.stringify(tasksParameters), function (err, data) {
        if (err || data.result == 'Error') {
            return err;
        }

        try {
            // при успешном выполнении задачи, выполнить перегрузку документа (временно)
            //@todo подтянуть изменения без перегрузки страницы
            reloadDocument(docStore.data.id);
        } catch (e) {
            console.error('requery, reloadDocument', e);
        }
    })
}

/**
 * вызывает метод сохранения документа
 */
function saveDoc() {
    const saveData = {
        id: docStore.data.id,
        doc_type_id: docStore.data.doc_type_id, // вынесено для подгрузки модели
        data: docStore.data,
        details: docStore.details
    };

    requery('save', JSON.stringify(saveData), function (err, data) {
        if (err) return err;

        try {
            let newId = data[0].id;
            // обновим ид
            saveData.data.id = newId;

            flux.doAction('dataChange', saveData.data); //новые данные
            flux.doAction('docIdChange', newId); // новое ид
            flux.doAction('savedChange', true); // устанавливаем режим сохранен
            flux.doAction('editedChange', false); // устанавливаем режим сохранен


            // reload document
            reloadDocument(newId); //@todo выполнить перегрузку данных перез перегрузки страницы

        } catch (e) {
            console.error('tekkis viga', e);
        }
    });
}

/**
 * reload document
 * @param docId
 */
function reloadDocument(docId) {
    if (docId) {
        document.location.href = "/document/" + docStore.data.doc_type_id + docId;
    }
}

function loadLibs(libraryName, libParams) {
    try {

        requery('selectAsLibs', JSON.stringify({
            doc_type_id: libraryName,
            id: 0,
            params: libParams
        }), function (err, data) {
            if (err) throw err;

            let newLibs = docStore.libs.map(function (item) {
                // ищем данные справолчника, которые обновили
                let returnData = item;

                if (item.id == libraryName) {
                    returnData.data = data;
                }
                return returnData;
            });

            if (newLibs.length > 0) {
                flux.doAction('libsChange', newLibs); // пишем изменения в хранилище
            }
        });
    } catch (e) {
        console.error('tekkis viga', e);
    }
}

/**
 * метод обеспечит получение данных от сервера
 * @param action
 * @param parameters
 * @param callback
 */
function requery(action, parameters, callback) {
    if (!window.jQuery) {
        return;
    }

    const URL = '/api/doc';
    $.ajax({
        url: URL,
        type: "POST",
        dataType: 'json',
        data: {
            action: action,
            data: parameters
        },
        cache: false,
        success: function (data) {
            // должны получить объект
            try {
                callback(null, data);
            } catch (e) {
                console.error('Requery error:', e)
            }

        }.bind(this),
        error: function (xhr, status, err) {
            console.error('/error', status, err.toString());
            return callback(err, null);
        }.bind(this)
    });

}


module.exports = docStore;