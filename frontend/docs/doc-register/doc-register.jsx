'use strict';
// грузим компоненты

//import PropTypes from 'prop-types';
const PropTypes = require('prop-types');

const React = require('react'),
    flux = require('fluxify'),
    DataGrid = require('./../../components/data-grid/data-grid.jsx'),
    BtnAdd = require('./../../components/button-register/button-register-add/button-register-add.jsx'),
    BtnEdit = require('./../../components/button-register/button-register-edit/button-register-edit.jsx'),
    BtnDelete = require('./../../components/button-register/button-register-delete/button-register-delete.jsx'),
    BtnPrint = require('./../../components/button-register/button-register-print/button-register-print.jsx'),
    BtnFilter = require('./../../components/button-register/button-register-filter/button-register-filter.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx'),
    ModalPageDelete = require('./../../components/modalpage/modalpage-delete/modalPage-delete.jsx'),
    ModalPageInfo = require('./../../components/modalpage/modalpage-info/modalPage-info.jsx'),
    TreeList = require('./../../components/tree/tree.jsx'),
    Sidebar = require('./../../components/sidebar/sidebar.jsx'),
    MenuToolBar = require('./../../mixin/menuToolBar.jsx'),
    ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx'),
    styles = require('./doc-register-styles'),
    GridFilter = require('./../../components/data-grid/grid-filter/grid-filter.jsx');


// Create a store
const docsStore = require('./../../stores/docs_store.js');

// создаем класс - держатель состояний
class Register extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            // у каждого компонента свой объект
            getFilter: false,
            getDeleteModalPage: false,
            showSystemMessage: false,
            activRowId: 0,
            isReport: false,
            treeValue: this.findComponent('docsList')[0].value,
            gridValue: 0
        };

        this.treeData = {
            data: this.findComponent('docsList')[0].data || []
        };

        this.gridData = {
            data: this.findComponent('docsGrid')[0].data[0].data,
            gridConfig: this.findComponent('docsGrid')[0].data[0].columns
        };

        this.filterData = []; // массив объектов, куда запишем параметры для фильтрации @todo вынести все в отдельный компонет для фильтрации

        this.btnAddClick = this.btnAddClick.bind(this);
        this.btnEditClick = this.btnEditClick.bind(this);
        this.btnDeleteClick = this.btnDeleteClick.bind(this);
        this.btnPrintClick = this.btnPrintClick.bind(this);
        this.btnFilterClick = this.btnFilterClick.bind(this);
        this.modalPageBtnClick = this.modalPageBtnClick.bind(this);
        this.modalPageDelBtnClick = this.modalPageDelBtnClick.bind(this);
        this.clickHandler = this.clickHandler.bind(this);
        this.dblClickHandler = this.dblClickHandler.bind(this);
        this.headerClickHandler = this.headerClickHandler.bind(this);
        this.isReports = this.isReports.bind(this);


    }

    componentDidMount() {
        const self = this;
        window.addEventListener('beforeunload', this.componentCleanup);

        // отслеживаем изменение фильтра
        docsStore.on('change:sqlWhere', (newValue) => {
            // данные изменились, обнуляем данные фильтра
            if (!newValue) {
                self.filterData = [];
            }
        });

        // создаем обработчик события на изменение даннх
        docsStore.on('change:data', (newValue) => {
            // данные изменились, меняем состояние
            this.gridData = {
                data: newValue[1].data[0].data,
                gridConfig: newValue[1].data[0].columns
            };

            this.treeData = {
                data: newValue[0].data
            };

            if (this.state.gridValue !== newValue[1].lastDocId) {
                self.setState({gridValue: newValue[1].lastDocId});

            } else {
                self.forceUpdate();
            }
        });

        // создаем обработчик события на изменение строки грида
        docsStore.on('change:docsGrid', function (newValue, previousValue) {
            // данные изменились, меняем состояние
            self.setState({gridValue: newValue});
        });

        // создаем обработчик события на изменение строки грида
        docsStore.on('change:docsList', function (newValue, previousValue) {
            // данные изменились, меняем состояние
            self.setState({treeValue: newValue});
        });

        // создаем обработчик события системный извещение
        docsStore.on('change:systemMessage', function (newValue, previousValue) {
            // данные изменились, меняем состояние
            self.setState({showSystemMessage: !!newValue});
        });

        // покажем данные

//        let lastComponent = localStorage['docsList'];
        flux.doAction('dataChange', this.props.components);
    }

    /**
     * снимет все подписки
     */
    componentCleanup() {
        docsStore.off('change:sqlWhere');
        docsStore.off('change:systemMessage');
        docsStore.off('change:docsList');
        docsStore.off('change:docsGrid');
        docsStore.off('change:data');
        docsStore.off('change:sqlWhere');
    }

    render() {
        let systemMessage = docsStore.systemMessage;

        this.getFilterFields();

        const btnParams = {
            btnStart: {
                show: false
            },
            btnLogin: {
                show: true
            }
        };

        return (<div ref="parentDiv">
                {MenuToolBar(btnParams, this.props.userData)}
                {this.renderFilterToolbar()}
                <div ref="docContainer" style={styles.container}>
                    {this.renderDocToolBar()}
                    <div style={styles.wrapper}>
                        <Sidebar width="30%" toolbar={true} ref="list-sidebar">
                            <TreeList ref='treeList'
                                      data={this.treeData['data']}
                                      name="docsList"
                                      bindDataField="kood"
                                      value={this.state.treeValue}
                                      onClickAction={this.clickHandler}
                                      onChangeAction='docsListChange'
                            />
                        </Sidebar>
                        <div style={styles.container}>
                            {this.renderAruannePage()}
                            <Sidebar toolbar={false} ref="grid-sidebar" height="400px">
                                <DataGrid ref='dataGrid'
                                          gridData={this.gridData['data']}
                                          gridColumns={this.gridData['gridConfig']}
                                          onChangeAction='docsGridChange'
                                          onClick={this.clickHandler}
                                          onDblClick={this.dblClickHandler}
                                          onHeaderClick={this.headerClickHandler}
                                          value={this.state.gridValue}
                                          url='api'/>
                                <ModalPage ref='modalpageFilter'
                                           modalPageBtnClick={this.modalPageBtnClick}
                                           modalPageName='Filter'
                                           show={this.state.getFilter}>
                                    <GridFilter ref='gridFilter'
                                                gridConfig={this.gridData['gridConfig']}
                                                data={this.filterData}/>
                                </ModalPage>
                                <ModalPageDelete ref="modalpageDelete"
                                                 modalPageBtnClick={this.modalPageDelBtnClick}
                                                 show={this.state.getDeleteModalPage}/>
                                <ModalPageInfo ref="modalpageInfo"
                                               modalPageBtnClick={this.modalPageInfoBtnClick}
                                               show={this.state.showSystemMessage}
                                               systemMessage={systemMessage}/>
                            </Sidebar>
                        </div>
                    </div>
                </div>
            </div>
        )
    }

    /**
     * Вернет компонент Отчет, если выбранная ветка содержит тип == aruanne
     * @returns {boolean|XML}
     */
    renderAruannePage() {
        let isReport = this.isReports(this.state.treeValue);
        const Component = (
            <Sidebar toolbar={true} ref="aruanne-sidebar" height="100%">
                Aruanne
            </Sidebar>
        );
        return isReport && Component;
    }

    /**
     * Вернет компонет - панель инструментов документа
     * @returns {XML}
     */
    renderDocToolBar() {
        let toolbarParams = this.prepareParamsForToolbar(); //параметры для кнопок управления, взависимости от активной строки

        return (
            <ToolbarContainer ref='toolbarContainer'>
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
        );
    }

    /**
     * Вернет компонет с данными строки фильтрации
     * @returns {XML}
     */
    renderFilterToolbar() {
        let filter = this.getFilterString();
        let component;

        if (filter) {
            component = <ToolbarContainer ref='filterToolbarContainer' position="left">
                <span> Filter: {this.getFilterString()}</span>
            </ToolbarContainer>;
        }

        return (component);
    }

    /**
     * Проанализирует свойства выбранного документа и вернет true , если тип == Aruanne
     * @param document
     * @returns {boolean}
     */
    isReports(document) {
        let data = this.findComponent('docsList')[0].data,
            documentData = data.filter(row => row.kood === document && row.props && JSON.parse(row.props).type === 'aruanne');

        return !!documentData.length;
    }

    findComponent(componentName) {
        // вернет данные компонента по его названию
        let componentData = [];

        if (this.props.components.length > 0) {
            componentData = this.props.components.filter(function (item) {
                if (item.name == componentName) {
                    return item;
                }
            });
        }

        if (!componentData[0].name == 'docsGrid'
            && componentData[0].lastDocId == '0'
            && !flux.stores.docsStore.docsGrid) {
            componentData[0].lastDocid = componentData[0].data[0].id || 0;
            // сохраним номер в сторе
            flux.doAction('docsGridChange', componentData[0].data[0].id || 0);
        }

        return componentData;

    }

    btnFilterClick() {
        // откроет модальное окно с полями для фильтрации
        this.setState({getFilter: true})
    }

    btnDeleteClick() {
        this.setState({getDeleteModalPage: true})
    }

    btnAddClick() {
        // обработчик события клик кнопки "Добавить"
        // вызовем действия на флаксе
        flux.doAction('Add');
    }

    btnEditClick() {
        // обработчик события клик кнопки "Изменить"
        // вызовем действия на флаксе
        flux.doAction('Edit');
    }

    btnPrintClick() {
        // обработчик события клик кнопки "Изменить"
        // вызовем действия на флаксе
        flux.doAction('Print');
    }

    clickHandler(action, id) {
        // сохраним в хранилище
        if (action && id) {
            flux.doAction(action, id);
        }
        if (action == 'docsGridChange') {
            this.gridData.value = id;
            this.setState({gridValue: id});
        } else {
            this.treeData.value = id;
            this.setState({treeValue: id});
        }
    }

    dblClickHandler() {
        // вызовет метод редактирования
        flux.doAction('Edit');
    }

    headerClickHandler(sortBy) {
        flux.doAction('sortByChange', sortBy);
    }

    modalPageBtnClick(btnEvent) {
        // обработчик для кнопки фильтрации
        let filterString = '';
        if (btnEvent == 'Ok') {
            // собираем данные
            let gridFilter = this.refs['gridFilter'],
                filterData = gridFilter.state.data;

            this.filterData = filterData.map((row) => {
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
    }

    modalPageDelBtnClick(btnEvent) {
        // обработчик вызова модального окна удаления
        this.setState({getDeleteModalPage: false});

        if (btnEvent == 'Ok') {
            // вызовем действия на флаксе
            flux.doAction('Delete');
        }

    }

    modalPageInfoBtnClick() {

        // обработчик вызова модального окна системного сообщения
        this.setState({showSystemMessage: false});
        // вызовем действия на флаксе
        flux.doAction('systemMessageChange', null);

    }

    /**
     * создаст из полtй грида компоненты для формирования условий фильтрации
     * @returns {Array|*}
     */
    getFilterFields() {
        let gridComponents = docsStore.data,
            gridData = [],
            previosFilter = this.filterData;

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

            gridData.map((row) => {
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

            });
        }
        return this.filterData;
    }

    getFilterString() {
        // преобразует данные филтра в строку
        let string = '';

        this.filterData.map(row => {
            if (row.value) {
                string = string + row.name + ':' + row.value + '; ';
            }
        });
        return string;
    }

    prepareParamsForToolbar() {
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
                if (row.id === this.state.gridValue) {
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

}


Register.propTypes = {
    components: PropTypes.array.isRequired
};

module.exports = Register;