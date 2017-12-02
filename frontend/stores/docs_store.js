'use strict';
const flux = require('fluxify'),
    ORDER_BY = [{column: 'id', direction: 'desc'}];

const docsStore = flux.createStore({
    id: 'docsStore',
    initialState: {
        docsGrid: 0,
        docsList: '',
        name: 'vlad',
        data: [],
        sortBy: ORDER_BY,
        sqlWhere: '',
        systemMessage: null,
        userData: {},
        logedIn: false
    },
    actionCallbacks: {
        systemMessageChange: function (updater, value) {
            updater.set({systemMessage: value});
        },
        sqlWhereChange: function (updater, value) {
            updater.set({sqlWhere: value});
            requery({name: 'docsGrid', value: this.docsList});
        },
        sortByChange: function (updater, value) {
            updater.set({sortBy: value});
            requery({name: 'docsGrid', value: this.docsList, sortBy: value});
        },
        Add: function () {
            add(this.docsList);
        },
        Edit: function () {
            if (this.docsList && this.docsGrid) {
                edit(this.docsList, this.docsGrid);
            } else {
                console.error('Тип документа или документ не выбран', this.docsList,this.docsGrid );
            }
        },
        Delete: function () {
            let docTypeId = this.docsList;
            requeryForAction('delete', (err, data) => {
                if (err) {
                    flux.doAction('systemMessageChange', err); // пишем изменения в хранилище
                } else {
                    flux.doAction('systemMessageChange', null); // пишем изменения в хранилище
                    requery({name: 'docsGrid', value: docTypeId});
                }
            });
        },
        Print: function () {
            console.log('button Print cliked!');
        },
        changeName: function (updater, name) {
            // Stores updates are only made inside store's action callbacks
            updater.set({name: name});
        },
        docsGridChange: function (updater, value) {
            // Stores updates are only made inside store's action callbacks
            updater.set({docsGrid: value});
        },
        docsListChange: function (updater, value) {
            // Stores updates are only made inside store's action callbacks
            let lastValue = flux.stores.docsStore.docsList || 'DOK';
            if (value !== lastValue) {
                updater.set({docsList: value});
            }
            flux.doAction('sqlWhereChange','');
            flux.doAction('sortByChange', ORDER_BY);
            requery({name: 'docsGrid', value: value});


//            localStorage['docsList'] = value;
        },
        dataChange: function (updater, value) {
            // Stores updates are only made inside store's action callbacks
            updater.set({data: value});

            if (!this.docsGrid) {
                let gridValue = value[1].data[0].data[0].id;
                flux.doAction('docsGridChange',gridValue);
            }

            if (!this.docsList) {
                let treeValue = value[0].value;
                flux.doAction('docsListChange',treeValue);
            }
        },
        userDataChange: function (updater, value) {
            updater.set({userData: value});

            let logedIn = !!userData;
            updater.set({logedIn: logedIn});

        },

    }
});

const edit = (docTypeId, docId) => {
    document.location.href = "/document/" + docTypeId + docId;
};

const add = (docTypeId) => {
    document.location.href = "/document/" + docTypeId + '0';
};

const requeryForAction = (action, callback) => {
    const ACTION_LIST = {'delete': 'DELETE'},
        API = '/api/doc';
    if (!window.jQuery || !$) return; // для тестов

    // метод обеспечит запрос на выполнение
    let docId = docsStore.docsGrid,
        docTypeId = docsStore.docsList;

    if (!docId || typeof docId == 'string') {
        docId = 0;
    }

    if (!docId) {
        // doc not selected
        let data = docsStore.data;
        data.forEach(row => {
            //@todo Привести в божеский вид
            if (!docTypeId && row.name == 'docsList') {
                // не назначен тип документа
                docTypeId = row['value'];
                flux.doAction('docsListChange', docTypeId);
            }

            if (row.name == 'docsGrid') {
                docId = row.data[0].data[0].id;
                flux.doAction('docsGridChange', docId);
            }

        });
    }

    let parameters = {
        docId: docId,
        doc_type_id: docTypeId
    };

    $.ajax({
        url: API,
        type: ACTION_LIST[ACTION] || 'POST',
        dataType: 'json',
        data: {
            action: action,
            data: JSON.stringify(parameters)
        },
        cache: false,
        success: function (data) {
            // должны получить объект - результат
            let errorMesssage = null;
            if (data.result == 'Error') {
                errorMesssage = 'Error, ' + data.message;
            }

            callback(errorMesssage, data);
        },
        error: function (xhr, status, err) {
            console.error('/error', status, err.toString());
            callback(err, null);
        }
    });
};

const requery = (component) => {
    if (!window.jQuery) return; // для тестов

    // метод обеспечит получение данных от сервера
    // component = this.state.components[name]
    // если параметры не заданы, грузим все

    let components = docsStore.data;

    // фильтруем список компонентов
    let componentsForUpdate = components.filter((item) => {
        // ищем объект по наименованию. или вернем все если параметр не задан
        if (component.name == '' || item.name == component.name) {
            return item.name;
        }
    });

    // сортировка
    let sqlSortBy = '',
        sqlWhere = docsStore.sqlWhere || '',
        sortByArray = docsStore.sortBy;

    if (docsStore.sortBy) {
        for (let i = 0; i < sortByArray.length; i++) {
            if (i > 0) {
                sqlSortBy = sqlSortBy + ',';
            }
            sqlSortBy = sqlSortBy + sortByArray[i].column + ' ' + sortByArray[i].direction;
        }
    }

    const URL = '/api/docs';
    $.ajax({
        url: URL,
        type: "POST",
        dataType: 'json',

        data: {
            dataType: 'component',
            docTypeId: 1,
            components: JSON.stringify(componentsForUpdate), // компоненты для обновления
            parameter: component.value, // параметры
            sortBy: sqlSortBy, // сортировка
            lastDocId: docsStore.docsGrid,
            sqlWhere: sqlWhere, // динамический фильтр грида
        },
        cache: false,
        success: function (data) {
            // должны получить объект
            let components = [];
            data.forEach(function (item) {
                // find item
                // обновим данные массива компонентов
                components = docsStore.data.map(function (component) {
                    if (component.name == item.name) {
                        // found
                        component.data = item.data;
                    }
                    return component;
                });

            });
            flux.doAction('dataChange', components);


        }.bind(this),
        error: function (xhr, status, err) {
            console.error('/error', status, err.toString());
        }.bind(this)
    });

};

module.exports = docsStore;