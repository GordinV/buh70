'use strict';

const PropTypes = require('prop-types');
const React = require('react');
const fetchData = require('./../../../libs/fetchData');
const DocContext = require('./../../doc-context.js');

const
    DataGrid = require('./../../components/data-grid/data-grid.jsx'),
    StartMenu = require('./../../components/start-menu/start-menu.jsx'),
    BtnAdd = require('./../../components/button-register/button-register-add/button-register-add.jsx'),
    BtnEdit = require('./../../components/button-register/button-register-edit/button-register-edit.jsx'),
    BtnDelete = require('./../../components/button-register/button-register-delete/button-register-delete.jsx'),
    BtnPrint = require('./../../components/button-register/button-register-print/button-register-print.jsx'),
    BtnFilter = require('./../../components/button-register/button-register-filter/button-register-filter.jsx'),
    BtnSelect = require('./../../components/button-register/button-select/index.jsx'),
    ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx'),
    GridFilter = require('./../../components/data-grid/grid-filter/grid-filter.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx'),
    InputText = require('./../../components/input-text/input-text.jsx'),
    ModalPageDelete = require('./../../components/modalpage/modalpage-delete/modalPage-delete.jsx'),
    styles = require('./documents-styles');


/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);

        this.gridData = [];
        this.gridConfig = [];
        this.filterData = [];
        this.subtotals = [];
        this.startMenuData = []; // здесь будут данные для старт меню
        if (props.initData) {
            this.gridData = props.initData.result.data || [];
            this.gridConfig = props.initData.gridConfig || [];
            this.subtotals = props.initData.subtotals || [];
        }

        this.docTypeId = props.docTypeId;

        this.state = {
            value: this.gridData.length ? this.gridData[0].id : 0,
            sortBy: {},
            sqlWhere: '',
            getFilter: false,
            isDelete: false,
            hasStartMenuVisible: false, // will show start menu
            startMenuValue: 'parentid',
            warning: '', // строка извещений
            warningType: '',
            limit: 100, // default limit for query,
            showSelectFields: false //will open or close column in grid to select rows
        };

        this._bind('btnAddClick', 'clickHandler', 'btnEditClick', 'dblClickHandler', 'headerClickHandler',
            'headerClickHandler', 'btnFilterClick', 'btnSelectClick', 'modalPageBtnClick', 'modalDeletePageBtnClick', 'filterDataHandler', 'renderFilterToolbar',
            'btnStartClickHanler', 'renderStartMenu', 'startMenuClickHandler', 'fetchData', 'prepareSqlWhereFromFilter', 'handleInputChange');

    }

    /**
     * пишем делаем запрос по итогу загрузки
     */
    componentDidMount() {
        let reload = false; // if reload === true then it will call to reload

        if (this.props.initData.docTypeId && this.props.initData.docTypeId.toUpperCase() !== this.docTypeId.toUpperCase()) {
            reload = true;
        }

        if (this.props.history && this.props.history.location.state) {
            this.filterData = this.mergeParametersWithFilter(this.filterData, this.props.history.location.state);
            reload = true;
        }

        if (reload || !this.props.initData || !this.gridData.length) {

            // проверим на фильтр
            let sqlWhere = this.prepareSqlWhereFromFilter();

            //делаем запрос на получение данных
            this.setState({sqlWhere: sqlWhere}, () => {
                this.fetchData('selectDocs')
            });

        }

        // if lastDocId available, will point it as selected
        if (DocContext[(this.props.docTypeId).toLowerCase()]) {
            let docId = DocContext[(this.props.docTypeId).toLowerCase()];
            this.setState({value: docId});
        }
    }

    // присвоит фильтру значения переданные в параметре
    mergeParametersWithFilter(filter, parameters) {
        let keys = _.keys(parameters);
        _.forEach(keys, (key) => {
            // find row in filter array
            let filterRowIndex = _.findIndex(filter, {name: key});
            if (filterRowIndex >= 0 && parameters[key]) {
                filter[filterRowIndex].value = parameters[key];
            }
        });

        return filter;
    }

    render() {
        const _style = Object.assign({}, styles, this.props.style ? this.props.style : {});
        const warningStyle = this.state.warningType && styles[this.state.warningType] ? styles[this.state.warningType] : null;

        return (
            <div style={_style.doc}>
                <div style={_style.docRow}>
                    {/*рендерим частные компоненты */}
                    {this.props.render(this)}
                </div>
                {this.renderDocToolBar()}
                {this.state.warning ?
                    <ToolbarContainer ref='toolbar-container'>
                        <div style={warningStyle}>
                            <span>{this.state.warning}</span>
                        </div>
                    </ToolbarContainer>
                    : null}

                <div style={_style.gridContainer}>
                    <DataGrid ref='dataGrid'
                              style={_style.grid.mainTable}
                              gridData={this.gridData}
                              gridColumns={this.gridConfig}
                              subtotals = {this.subtotals}
                              onClick={this.clickHandler}
                              onDblClick={this.dblClickHandler}
                              onHeaderClick={this.headerClickHandler}
                              isSelect={this.state.showSelectFields}
                              value={this.state.value}/>
                    <ModalPage ref='modalpageFilter'
                               modalPageBtnClick={this.modalPageBtnClick}
                               modalPageName='Filter'
                               show={this.state.getFilter}>
                        <GridFilter ref='gridFilter'
                                    handler={this.filterDataHandler}
                                    gridConfig={this.gridConfig}
                                    data={this.filterData}/>
                    </ModalPage>
                    <ModalPageDelete
                        show={this.state.isDelete}
                        modalPageBtnClick={this.modalDeletePageBtnClick.bind(this)}>
                    </ModalPageDelete>
                </div>
            </div>
        );
    }

    // обработчик изменений в инпут (лимит)
    handleInputChange(name, value) {
        this.setState({limit: !value || value > 1000 ? 1000 : value});
    }


    /**
     * вызовер подгрузку данных с параметром сортировки
     * @param sortBy
     */
    headerClickHandler(sortBy) {
        this.setState({sortBy: sortBy}, () => this.fetchData('selectDocs'));
    }

    /**
     * Обработчик двойного клика
     */
    dblClickHandler() {
        this.btnEditClick();
    }

    /**
     * обработчик для грида
     * @param action
     * @param docId
     * @param idx
     */
    clickHandler(action, docId, idx) {
        if (docId && typeof docId === 'number') {
            this.setState({value: docId});
        }
    }

    /**
     * откроет модальное окно с полями для фильтрации
     */
    btnFilterClick() {
        this.setState({getFilter: true})
    }

    /**
     * Обработчик для кнопки Add
     */
    btnAddClick() {
        if (this.props.btnAddClick) {
            // кастомный обработчик события
            this.props.btnAddClick(this.state.value);
        } else {
            return this.props.history.push({
                pathname: `/${this.props.module}/${this.docTypeId}/0`,
                state: {module: this.props.module}
            });

        }
    }

    /**
     * Обработчик для кнопки Edit
     */
    btnEditClick() {
        if (this.props.btnEditClick) {
            // кастомный обработчик события
            this.props.btnEditClick(this.state.value);
        } else {
            return this.props.history.push({
                pathname: `/${this.props.module}/${this.docTypeId}/${this.state.value}`,
                state: {module: this.props.module}
            });

        }
    }


    /**
     * Обработчик для кнопки Delete
     */
    btnDeleteClick() {
        this.setState({isDelete: true});
    }

    /**
     * Обработчик для кнопки Print
     */
    btnPrintClick() {
        let sqlWhere = this.state.sqlWhere;
        let sortBy = JSON.stringify(this.state.sortBy);
        let url = `/print/${this.props.docTypeId}/${DocContext.userData.uuid}/0`;
        let params = encodeURIComponent(`${sqlWhere}`);
        window.open(`${url}/${params}`);
    }

    /**
     * обработчик для кнопки фильтрации
     * @param btnEvent
     */
    modalPageBtnClick(btnEvent) {
        let filterString = ''; // строка фильтра

        if (btnEvent === 'Ok') {
            // собираем данные

            filterString = this.prepareSqlWhereFromFilter();
        } else {
            //          this.filterData = this.filterData.map((row) => row.value = null);
            filterString = '';
        }

        this.setState({getFilter: false, sqlWhere: filterString}, () => this.fetchData('selectDocs'));
    }

    /**
     * обработчик для кнопки фильтрации
     * @param btnEvent
     */
    modalDeletePageBtnClick(btnEvent) {
        this.setState({isDelete: false});
        if (btnEvent === 'Ok') {
            // delete document
            this.fetchData('delete')
                .catch((err) => {
                    console.error('error in fetch-> ', err);
                })
                .then(() => this.fetchData('selectDocs'));
        }
    }

    prepareSqlWhereFromFilter() {
        let filterString = ''; // строка фильтра

        this.filterData = this.filterData.map((row) => {
            if (row.value) {
                filterString = filterString + (filterString.length > 0 ? " and " : " where ");
                switch (row.type) {

                    case 'text':
                        filterString = `${filterString}  encode(${row.name}::bytea, 'escape')  ilike '%${row.value.trim()}%'`;
                        break;
                    case 'string':
                        filterString = `${filterString}  encode(${row.name}::bytea, 'escape')  ilike '%${row.value.trim()}%'`;
                        break;
                    case 'date':
                        filterString = filterString + row.name + " = '" + row.value + "'";
                        break;
                    case 'number':
                        filterString = filterString + row.name + " = " + row.value;
                        break;
                    case 'integer':
                        filterString = filterString + row.name + " = " + row.value;
                        break;
                }
            }
            return row;
        }, this);

        return filterString;
    }

    /**
     * обработчик для фильтра грида
     * @param data
     */
    filterDataHandler(data) {
        this.filterData = data;
    }

    /**
     * Обработчик для кнопки старт меню
     */
    btnStartClickHanler() {
        this.setState({hasStartMenuVisible: true});
    }

    /**
     * получит от стартого меню данные, спрячет меню
     */
    startMenuClickHandler(value) {
        this.setState({hasStartMenuVisible: false});
        return this.props.history.push({
            pathname: `/${this.props.module}/${value}`,
            state: {module: this.props.module}
        });

    }

    btnSelectClick() {
        this.setState({showSelectFields: !this.state.showSelectFields});

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
     * преобразует данные фильтра в строку чтоб показать ее
     * @returns {string}
     */
    getFilterString() {
        let string = '';

        this.filterData.map(row => {
            if (row.value) {
                string = string + row.name + ':' + row.value + '; ';
            }
        });
        return string;
    }

    /**
     * Вернет компонет - панель инструментов документа
     * @returns {XML}
     */
    renderDocToolBar() {
        let toolbarParams = this.prepareParamsForToolbar(); //параметры для кнопок управления, взависимости от активной строки
        return (
            <div>
                {this.renderFilterToolbar()}
                <div style={styles.docRow}>
                    <InputText ref="input-limit"
                               title='Limiit:'
                               name='limit'
                               style={styles.limit}
                               value={this.state.limit || '100'}
                               readOnly={false}
                               onChange={this.handleInputChange}/>

                    <ToolbarContainer ref='toolbarContainer'>
                        <BtnAdd onClick={this.btnAddClick} show={toolbarParams['btnAdd'].show}
                                disable={toolbarParams['btnAdd'].disabled}/>
                        <BtnEdit onClick={this.btnEditClick} show={toolbarParams['btnEdit'].show}
                                 disable={toolbarParams['btnEdit'].disabled}/>
                        <BtnDelete onClick={this.btnDeleteClick.bind(this)} show={toolbarParams['btnDelete'].show}
                                   disable={toolbarParams['btnDelete'].disabled}/>
                        <BtnPrint onClick={this.btnPrintClick.bind(this)} show={toolbarParams['btnPrint'].show}
                                  disable={toolbarParams['btnPrint'].disabled}/>
                        <BtnFilter onClick={this.btnFilterClick}/>
                        <BtnSelect
                            show={toolbarParams['btnSelect'].show}
                            value={'Valida'}
                            onClick={this.btnSelectClick}
                            ref="grid-button-select"/>

                    </ToolbarContainer>
                </div>
            </div>
        );
    }


    /**
     * Откроет стартовое меню
     * @returns {*}
     */
    renderStartMenu() {
        let component;
        if (this.state.hasStartMenuVisible) {
            component = <StartMenu ref='startMenu'
                                   value={this.state.startMenuValue}
                                   clickHandler={this.startMenuClickHandler}/>
        }
        return component
    }

    /**
     *  читаем данные со стора, формируем параметры для кнопок управления, и туда их отдаем
     * @returns {{btnAdd: {show: boolean, disabled: boolean}, btnEdit: {show: boolean, disabled: boolean}, btnDelete: {show: boolean, disabled: boolean}, btnPrint: {show: boolean, disabled: boolean}}}
     */
    prepareParamsForToolbar() {
        let params = Object.assign({
            btnAdd: {
                show: this.docTypeId !== 'DOK', //todo сделать поумнее
                disabled: false
            },
            btnEdit: {
                show: true,
                disabled: !this.state.value
            },
            btnDelete: {
                show: true,
                disabled: !this.state.value
            },
            btnPrint: {
                show: true,
                disabled: false
            },
            btnStart: {
                show: true
            },
            btnLogin: {
                show: true,
                disabled: false
            },
            btnAccount: {
                show: true,
                disabled: false
            },
            btnSelect: {
                show: !!this.gridConfig.find(row => row.id === 'select'),
                disabled: false
            }
        }, (this.props.toolbarParams ? this.props.toolbarParams : {}),);
        return params
    }

    /**
     * Выполнит запросы
     */
    fetchData(method, additionalData) {
        let URL = `/newApi`;
        switch (method) {
            case 'delete':
                URL = `/newApi/delete`;
                break;
            case 'print':
                URL = `/print/${this.docTypeId}`;
                break;
            case 'selectDocs':
                URL = `/newApi`;
                break;
            default:
                URL = `/${method}`;
        }

        const params = {
            parameter: this.docTypeId, // параметры
            docTypeId: this.docTypeId, // для согласования с документом
            sortBy: this.state.sortBy, // сортировка
            limit: this.state.limit, // row limit in query
            docId: this.state.value,
            method: method,
            sqlWhere: this.state.sqlWhere, // динамический фильтр грида
            lastDocId: null,
            module: this.props.module,
            userId: DocContext.userData.userId,
            uuid: DocContext.userData.uuid,
            data: additionalData
        };
        try {
            return new Promise((resolved, rejected) => {

                fetchData['fetchDataPost'](URL, params).then(response => {
                    if (response.status && response.status === 401) {
                        document.location = `/login`;
                    }

                    if (response.data && response.data.error_message) {
                        let error = '' + response.data.error_message ? response.data.error_message : '';
                        throw new Error(error);
                    }

                    if (method === 'selectDocs') {
                        this.gridData = response.data.result.data;

                        if (response.data.gridConfig.length) {

                            //если конфиг отличается, формируем новый фильтр грида
                            if (!this.gridConfig.length || JSON.stringify(this.gridConfig) !== JSON.stringify(response.data.gridConfig)) {
                                this.gridConfig = response.data.gridConfig;
                                this.subtotals = response.data.subtotals;

                                //refresh filterdata
                                this.filterData = this.gridConfig.map((row) => {
                                    // props.data пустое, создаем

                                    return {value: null, name: row.id, type: row.type ? row.type : 'text'};
                                });

                            }

                            //apply filter
                            if (this.props.history && this.props.history.location.state) {
                                this.filterData = this.mergeParametersWithFilter(this.filterData, this.props.history.location.state);
                            }
                        }
                        this.forceUpdate()

                    } else {
                        this.setState({warning: 'Edukalt', warningType: 'ok'})
                    }
                    resolved(response.data);
                }).catch((error) => {
                    // Something happened in setting up the request that triggered an Error
                    this.setState({
                        warning: `Tekkis viga ${error}`,
                        warningType: 'error'
                    });
                    rejected(error);

                    console.error('Error', error);
                });
            });
        } catch (e) {
            console.error(e);
            this.setState({
                warning: `Tekkis viga ${e}`,
                warningType: 'error'
            });

        }
    }

    _bind(...methods) {
        methods.forEach((method) => this[method] = this[method].bind(this));
    }


}


Documents.propTypes = {
    initData: PropTypes.shape({
        result: PropTypes.object,
        gridConfig: PropTypes.array
    }),
    docTypeId: PropTypes.string.isRequired
};

module.exports = (Documents);


