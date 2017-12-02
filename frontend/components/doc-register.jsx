'use strict';
// грузим компоненты

const React = require('react'),
    flux = require('fluxify'),
    DataGrid = require('../data-grid/data-grid.jsx'),
    BtnAdd = require('./button-register/button-register-add/button-register-add.jsx'),
    BtnEdit = require('./button-register/button-register-edit/button-register-edit.jsx'),
    BtnDelete = require('./button-register/button-register-delete/button-register-delete.jsx'),
    BtnPrint = require('./button-register/button-register-print/button-register-print.jsx'),
    BtnFilter = require('./button-register/button-register-filter/button-register-filter.jsx'),
    ModalPage = require('./modalpage/modalPage.jsx'),
    ModalPageDelete = require('./modalpage/modalpage-delete/modalPage-delete.jsx'),
    ModalPageInfo = require('./modalpage/modalpage-info/modalPage-info.jsx'),
    DataList = require('./datalist/datalist.jsx'),
    Sidebar = require('./sidebar/sidebar.jsx'),
    ToolbarContainer = require('./toolbar-container/toolbar-container.jsx'),
    styles = require('../docs/register/register-styles'),
    GridFilter = require('../components/data-grid/grid-filter/grid-filter.jsx');

let myComponents = [];

if (!typeof window === 'undefined') {
    // берем данные с локального хранилища
    myComponents = JSON.parse(localStorage['docsStore']);
}

// Create a store
var docsStore = require('../stores/docs_store.js');

// создаем класс - держатель состояний
var Parent = React.createClass({
    displayName: 'Parent',

    filterData: [], // массив объектов, куда запишем параметры для фильтрации @todo вынести все в отдельный компонет для фильтрации

    getInitialState: function getInitialState() {
        return {
            // у каждого компонента свой объект
            components: this.props.components, // @todo вынести в отдельный файл компонента
            getFilter: false,
            getDeleteModalPage: false,
            showSystemMessage: false,
            activRowId: 0,
            filterString: null
        };
    },

    componentDidMount: function () {
        var self = this;

        // создаем обработчик события на изменение даннх
        docsStore.on('change:data', function (newValue, previousValue) {
            // данные изменились, меняем состояние
            self.setState({components: docsStore.data})
        })

        // создаем обработчик события на изменение строки грида
        docsStore.on('change:docsGrid', function (newValue, previousValue) {
            // данные изменились, меняем состояние
            self.setState({activRowId: docsStore.docsGrid})
        })

        // создаем обработчик события системный извещение
        docsStore.on('change:systemMessage', function (newValue, previousValue) {
            // данные изменились, меняем состояние
            let systemMessageStatus = newValue ? true : false;
            self.setState({showSystemMessage: systemMessageStatus});
        })

        // покажем данные

        let lastComponent = localStorage['docsList'];
        flux.doAction('dataChange', this.props.components);
        if (lastComponent) {
            flux.doAction('docsListChange', lastComponent);
        }
    },

    findComponent: function (componentName) {
        // вернет данные компонента по его названию
        let components = this.state.components,
            componentData = [];

        if (components.length > 0) {
            componentData = components.filter(function (item) {
                if (item.name == componentName) {
                    return item;
                }
            });
        }
        return componentData;

    },

    btnFilterClick: function () {
        // откроет модальное окно с полями для фильтрации
        this.setState({getFilter: true})
    },

    btnDeleteClick() {
        this.setState({getDeleteModalPage: true})
    },

    btnAddClick() {
        // обработчик события клик кнопки "Добавить"
        // вызовем действия на флаксе
        flux.doAction('Add');
    },

    btnEditClick() {
        // обработчик события клик кнопки "Изменить"
        // вызовем действия на флаксе
        flux.doAction('Edit');
    },

    btnPrintClick() {
        // обработчик события клик кнопки "Изменить"
        // вызовем действия на флаксе
        flux.doAction('Print');
    },

    render: function render() {
        let myListValue = '',
            myListData = this.findComponent('docsList') || [];

        if (myListData.length > 0) {
            myListValue = myListData[0].value;
        }

        if (myListData.length > 0 && myListData[0].data.length > 0) {
            myListData = myListData[0].data;
        }

        let myGrid = this.findComponent('docsGrid') || [],
            myGridColums = [],
            myGridData = [],
            systemMessage = flux.stores.docsStore.systemMessage;

        // проверим наличие данных, если есть пропихнем компонентам
        if (myGrid.length > 0 && myGrid[0].data.length > 0) {
            myGridColums = myGrid[0].data[0].columns;
            myGridData = myGrid[0].data[0].data;
        }

        // получим параметры для кнопок управления, взависимости от активной строки
        let toolbarParams = this.prepareParamsForToolbar(),
            filterData = this.getFilterFields(),
            filterString = this.getFilterString();

        return (<div id="parentDiv">
                <span>Filter: {filterString}</span>
                <div id="docContainer" style={styles.container}>
                    <ToolbarContainer>
                        <div>
                            <BtnAdd onClick={this.btnAddClick} show={toolbarParams['btnAdd'].show}
                                    disable={toolbarParams['btnAdd'].disabled}/>
                            <BtnEdit onClick={this.btnEditClick} show={toolbarParams['btnEdit'].show}
                                     disable={toolbarParams['btnEdit'].disabled}/>
                            <BtnDelete onClick={this.btnDeleteClick} show={toolbarParams['btnDelete'].show}
                                       disable={toolbarParams['btnDelete'].disabled}/>
                            <BtnPrint onClick={this.btnPrintClick} show={toolbarParams['btnPrint'].show}
                                      disable={toolbarParams['btnPrint'].disabled}/>
                            <BtnFilter onClick={this.btnFilterClick}/>
                        </div>
                    </ToolbarContainer>

                    <div style={styles.wrapper}>
                        <Sidebar width="30%" toolbar={true} ref="list-sidebar">
                            <DataList data={myListData}
                                      name="docsList"
                                      bindDataField="kood"
                                      value={myListValue}
                                      onChangeAction='docsListChange'
                            />
                        </Sidebar>
                        <Sidebar width="100%" toolbar={false} ref="grid-sidebar">
                            <div>
                                <DataGrid
                                    gridData={myGridData}
                                    gridColumns={myGridColums}
                                    onChangeAction='docsGridChange'
                                    url='api'/>
                                <ModalPage
                                    modalPageBtnClick={this.modalPageBtnClick}
                                    modalPageName='Filter'
                                    show={this.state.getFilter}>
                                    <GridFilter ref= 'gridFilter' gridConfig = {myGridColums} data = {filterData}/>
                                </ModalPage>
                                <ModalPageDelete modalPageBtnClick={this.modalPageDelBtnClick}
                                                 show={this.state.getDeleteModalPage}/>
                                <ModalPageInfo
                                    modalPageBtnClick={this.modalPageInfoBtnClick}
                                    show={this.state.showSystemMessage}
                                    systemMessage={systemMessage}/>
                            </div>
                        </Sidebar>
                    </div>
                </div>
            </div>
        )
    },

    modalPageBtnClick: function (btnEvent) {
        // обработчик для кнопки фильтрации
        let filterString = '';
        if (btnEvent == 'Ok') {
            // собираем данные
            let gridFilter = this.refs['gridFilter'],
                filterData = gridFilter.state.data;

            this.filterData = filterData.map((row) => {
                console.log('row', row);
                if (row.value) {
                    filterString = filterString + (filterString.length > 0 ? " and " : " where ");
                    switch (row.type) {

                        case 'text':
                            filterString = filterString + row.refs + " ilike '%" + row.value + "%'";
                            break;
                        case 'string':
                            filterString = filterString + row.refs + " ilike '" + row.value + "%'";
                            break;
                        case 'date':
                            filterString = filterString + row.refs + " = '" + row.value + "'";
                            break;
                        case 'number':
                            filterString = filterString + row.refs + " = " + row.value;
                            break;
                        case 'integer':
                            filterString = filterString + row.refs + " = " + row.value;
                            break;
                    }
                }
                return row;
            }, this);
            // применем фильтр
            flux.doAction('sqlWhereChange', filterString);
        }
        this.setState({getFilter: false})
    },

    modalPageDelBtnClick(btnEvent) {
        // обработчик вызова модального окна удаления
        this.setState({getDeleteModalPage: false});

        if (btnEvent == 'Ok') {
            // вызовем действия на флаксе
            flux.doAction('Delete');
        }

    },

    modalPageInfoBtnClick() {

        // обработчик вызова модального окна системного сообщения
        this.setState({showSystemMessage: false});
        // вызовем действия на флаксе
        flux.doAction('systemMessageChange', null);

    },

    getFilterFields: function () {
        // создаст из полtй грида компоненты для формирования условий фильтрации
        let gridComponents = docsStore.data,
            gridData = [],
            previosFilter = this.filterData,
            filterFields;

        for (let i = 0; i < gridComponents.length; i++) {
            if (gridComponents[i]['name'] == 'docsGrid') {
                // ищем поле columns
                for (let field in gridComponents[i].data[0]) {
                    if (field == 'columns') {
                        gridData = gridComponents[i].data[0].columns;
                        break;
                    }
                }
                break;
            }
        }

        if (gridData) {
            this.filterData = []; // обнулим массив
            filterFields =
                gridData.map((row, index) => {
                    let componentType = 'text',
                        componentObjektValue;

                    for (let i = 0; i < previosFilter.length; i++) {
                        // ищем "старое" значение фильтра и если есть, то отдаем его value
                        if (previosFilter[i].refs == row.id) {
                            componentObjektValue = previosFilter[i].value;
                            break;
                        }
                    }

                    if (row.type) {
                        componentType = row.type;
                    }

                    // соберем массив объектов
                    this.filterData.push({
                        name: row.name,
                        value: componentObjektValue || null,
                        type: componentType,
                        refs: row.id
                    });

                })
        }
        // обновим строку фильтрации
        this.getFilterString();
        return this.filterData;
    },

    getFilterString: function() {
        console.log('getFilterString');
    // преобразует данные филтра в строку
        let string = '';

        this.filterData.map(row => {
           if (row.value) {
               string = string + row.name + ':' + row.value + '; ';
           }
        });
        console.log('filterString', string);
        return string;
},

    prepareParamsForToolbar: function () {
        // читаем данные со стора, формируем параметры для кнопок управления, и туда их отдаем
//docsGridChange (flux.stores.docsStore.)
        let grid = this.findComponent('docsGrid') || [],
            lastRowId = this.state.activRowId,
            data = [],
            dataRow = [],
            toolbarParams = {
                btnAdd: {
                    show: true,
                    disabled: false
                },
                btnEdit: {
                    show: true,
                    disabled: false
                },
                btnDelete: {
                    show: true,
                    disabled: false
                },
                btnPrint: {
                    show: true,
                    disabled: false
                }
            };

// проверим наличие данных, если есть пропихнем компонентам

        if (grid.length > 0 && grid[0].data.length > 0) {
            data = grid[0].data[0].data;
            dataRow = data.filter(row => {
                if (row.id === lastRowId) {
                    return row;
                }
            });
        } else {
            return toolbarParams;
        }

        if (dataRow.length > 0 && dataRow[0].status == 'Проведен') {
            // удалять нельзя
            toolbarParams.btnDelete.show = false;
        }
        return toolbarParams;

    }

});

module.exports = Parent;