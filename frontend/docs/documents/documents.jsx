'use strict';

const PropTypes = require('prop-types');
const React = require('react');
const fetchData = require('./../../../libs/fetchData');
const DocContext = require('./../../doc-context.js');
const Menu = require('./../../components/menu-toolbar/menu-toolbar.jsx');

const
    DataGrid = require('./../../components/data-grid/data-grid.jsx'),
    StartMenu = require('./../../components/start-menu/start-menu.jsx'),
    BtnAdd = require('./../../components/button-register/button-register-add/button-register-add.jsx'),
    BtnEdit = require('./../../components/button-register/button-register-edit/button-register-edit.jsx'),
    BtnDelete = require('./../../components/button-register/button-register-delete/button-register-delete.jsx'),
    BtnPrint = require('./../../components/button-register/button-register-print/button-register-print.jsx'),
    BtnFilter = require('./../../components/button-register/button-register-filter/button-register-filter.jsx'),
    BtnSelect = require('./../../components/button-register/button-select/index.jsx'),
    BtnEmail = require('./../../components/button-register/button-email/index.jsx'),
    BtnRefresh = require('./../../components/button-register/button-refresh/index.jsx'),
    ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx'),
    GridFilter = require('./../../components/data-grid/grid-filter/grid-filter.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx'),
    InputText = require('./../../components/input-text/input-text.jsx'),
    ModalPageDelete = require('./../../components/modalpage/modalpage-delete/modalPage-delete.jsx'),
    styles = require('./documents-styles');


/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.Component {
    constructor(props) {
        super(props);

        this.gridData = [];
        this.gridConfig = [];
        this.filterData = [];
        this.subtotals = [];
        this.startMenuData = []; // здесь будут данные для старт меню

        if (props.initData && props.initData.result) {
            this.gridData = props.initData.result.data || [];
            this.gridConfig = props.initData.gridConfig || [];
            this.subtotals = props.initData.subtotals || [];
        } else if (props.initData && props.initData.gridData) {

            this.gridData = props.initData.gridData || [];
            this.gridConfig = props.initData.gridConfig || [];
            this.subtotals = [];
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
            isEmptyFilter: false, // если true то обнулит данные фильтра при перегрузке данных
            showSelectFields: false //will open or close column in grid to select rows
        };

        this._bind('btnAddClick', 'clickHandler', 'btnEditClick', 'dblClickHandler', 'headerClickHandler',
            'headerClickHandler', 'btnFilterClick', 'btnSelectClick', 'btnRefreshClick', 'modalPageBtnClick', 'modalDeletePageBtnClick', 'filterDataHandler', 'renderFilterToolbar',
            'btnStartClickHanler', 'renderStartMenu', 'startMenuClickHandler', 'fetchData', 'prepareSqlWhereFromFilter',
            'handleInputChange', 'btnEmailClick');

    }

    /**
     * пишем делаем запрос по итогу загрузки
     */
    componentDidMount() {

        if (!DocContext.filter) {
            DocContext.filter = {};
        }

        let reload = false; // if reload === true then it will call to reload

        if (this.props.initData.docTypeId && this.props.initData.docTypeId.toUpperCase() !== this.docTypeId.toUpperCase()) {
            reload = true;
        }

        if (this.props.history && this.props.history.location.state) {
            this.filterData = this.mergeParametersWithFilter(this.filterData, this.props.history.location.state);
            reload = true;

        } else {
            // проверим сохраненный фильтр для этого типа
            if (DocContext.filter[this.props.docTypeId] && DocContext.filter[this.props.docTypeId].length > 0) {
                this.filterData = DocContext.filter[this.props.docTypeId];
                reload = true;
            }
        }

        if (reload || !this.props.initData || !this.gridData.length || !this.props.initData.docTypeId) {

            // проверим на фильтр
            let sqlWhere = this.prepareSqlWhereFromFilter();

            //делаем запрос на получение данных
            this.setState({sqlWhere: sqlWhere}, () => {
                this.fetchData('selectDocs')
            });

        }

        // will save current docTypeid
        DocContext['docTypeId'] = this.props.docTypeId;

        // if lastDocId available, will point it as selected
        if (DocContext[(this.props.docTypeId).toLowerCase()]) {
            let docId = DocContext[(this.props.docTypeId).toLowerCase()];
            this.setState({value: docId});
        }
    }

    // присвоит фильтру значения переданные в параметре
    mergeParametersWithFilter(filter, parameters) {
        let keys = Object.keys(parameters);
        keys.forEach((key) => {
            // find row in filter array
            let filterRowIndex = filter.findIndex(row => row.name === key);

            if (filterRowIndex >= 0 && parameters[key]) {
                filter[filterRowIndex].value = parameters[key];
            }
        });

        return filter;
    }

    render() {
        const _style = Object.assign({}, styles, this.props.style ? this.props.style : {});
        const warningStyle = this.state.warningType && styles[this.state.warningType] ? styles[this.state.warningType] : null;
        const btnParams = {
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
            }

        };
        return (
            <div style={_style.doc}>
                <Menu params={btnParams}
                      history={this.props.history}
                      rekvId={DocContext.userData ? DocContext.userData.asutusId : 0}
                      module={this.props.module}/>

                <div style={_style.docRow}>
                    {/*рендерим частные компоненты */}
                    {this.props.render(this)}
                </div>
                {this.renderFilterToolbar()}
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
                              subtotals={this.subtotals}
                              onClick={this.clickHandler}
                              onDblClick={this.dblClickHandler}
                              onHeaderClick={this.headerClickHandler}
                              isSelect={this.state.showSelectFields}
                              value={this.state.value}/>
                    {this.state.getFilter ?
                        <ModalPage ref='modalpageFilter'
                                   modalPageBtnClick={this.modalPageBtnClick}
                                   modalPageName='Filter'
                                   show={true}>
                            <GridFilter ref='gridFilter'
                                        focusElement={this.gridConfig[1].id}
                                        docTypeId={this.props.docTypeId}
                                        handler={this.filterDataHandler}
                                        gridConfig={this.gridConfig}
                                        data={this.filterData}/>
                        </ModalPage> : null
                    }
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
     * выполнит запрос и обновит данные грида
     */
    btnRefreshClick() {
        this.fetchData('selectDocs').then(() => {
            this.setState({warning: 'Edukalt', warningType: 'ok'});
        });
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
        let url;
        let params = encodeURIComponent(`${sqlWhere}`);
        let filter = encodeURIComponent(`${JSON.stringify(this.filterData)}`);

        if (this.filterData.length) {
            url = `/print/${this.props.docTypeId}/${DocContext.userData.uuid}/${filter}`;

        } else {
            url = `/print/${this.props.docTypeId}/${DocContext.userData.uuid}/0`;
        }
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
            filterString = '';

        }

        this.setState({
            getFilter: false,
            sqlWhere: filterString,
            isEmptyFilter: !filterString
        }, () => this.fetchData('selectDocs'));
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
                .then((data) => {
                    if (data.error_message) {
                        this.setState({warning: `Tekkis viga: ${data.error_message}`, warningType: 'error'});
                        if (data.status && data.status == 401) {
                            setTimeout(() => {
                                document.location = `/login`;
                            },1000);
                        }
                    } else {
                        this.fetchData('selectDocs')
                    }
                });
        }
    }

    prepareSqlWhereFromFilter() {
        let filterString = ''; // строка фильтра

        this.filterData = this.filterData.map((row) => {
            if (row.value) {
                filterString = filterString + (filterString.length > 0 ? " and " : " where ");
                switch (row.type) {

                    case 'text':

                        let prepairedParameter = row.value.split(',').map(str => `'${str.trim()}'`).join(',');

                        // если параметры раздедены, то множественный параметр
                        if (row.value.match(/,/)) {
                            filterString = `${filterString} ${row.name} in (${prepairedParameter})`;
                        } else {
                            filterString = `${filterString}  encode(${row.name}::bytea, 'escape')  ilike '%${row.value.trim()}%'`;
                        }
                        break;
                    case 'string':
                        filterString = `${filterString}  encode(${row.name}::bytea, 'escape')  ilike '%${row.value.trim()}%'`;
                        break;
                    case 'date':
                        if ('start' in row) {
                            filterString = `${filterString} format_date(${row.name}::text)  >=  format_date('${row.start}'::text) and format_date(${row.name}::text)  <=  format_date('${row.end}'::text)`;
                        } else {
                            filterString = filterString + row.name + " = '" + row.value + "'";
                        }

                        break;
                    case 'number':
                        if ('start' in row) {
                            filterString = `${filterString} ${row.name}  >=  ${row.start} and ${row.name}  <=  ${row.end} `;
                        } else {
                            filterString = filterString + row.name + " = " + row.value;
                        }
                        break;
                    case 'integer':
                        if ('start' in row) {
                            filterString = `${filterString} ${row.name}  >=  ${row.start} and ${row.name}  <=  ${row.end} `;
                        } else {
                            filterString = filterString + row.name + " = " + row.value;
                        }
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

        // создади обьект = держатель состояния фильтра
        if (!DocContext.filter) {
            DocContext.filter = {};
        }

        if (!DocContext.filter[this.props.docTypeId]) {
            DocContext.filter[this.props.docTypeId] = [];
        }

        if (data && data.length > 0 && this.props.history.location && this.props.history.location.state) {
            DocContext.filter[this.props.docTypeId] = this.filterData;
        }

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
            if (row.start) {
                string = `${string} ${row.name}>=${row.start},${row.name}<=${row.end};`;
            } else {
                if (row.value) {
                    string = string + row.name + ':' + row.value + '; ';
                }
            }
        });
        return string;
    }

    /**
     * Вернет компонет - панель инструментов документа
     * @returns {XML}
     */
    renderDocToolBar() {
        let filter = this.getFilterString();

        let toolbarParams = this.prepareParamsForToolbar(); //параметры для кнопок управления, взависимости от активной строки
        return (
            <div>
                <div style={styles.docRow}>
                    <InputText ref="input-limit"
                               title='Limiit:'
                               name='limit'
                               style={styles.limit}
                               value={String(this.state.limit) || '100'}
                               readOnly={false}
                               onChange={this.handleInputChange}/>

                    <ToolbarContainer ref='toolbarContainer'>
                        <BtnAdd onClick={this.btnAddClick}
                                show={toolbarParams['btnAdd'].show}
                                disable={toolbarParams['btnAdd'].disabled}/>
                        <BtnEdit onClick={this.btnEditClick}
                                 value={'Muuda'}
                                 show={toolbarParams['btnEdit'].show}
                                 disable={toolbarParams['btnEdit'].disabled}/>
                        <BtnDelete onClick={this.btnDeleteClick.bind(this)}
                                   show={toolbarParams['btnDelete'].show}
                                   disable={toolbarParams['btnDelete'].disabled}/>
                        <BtnPrint onClick={this.btnPrintClick.bind(this)}
                                  show={toolbarParams['btnPrint'].show}
                                  value={'Trükk'}
                                  disable={toolbarParams['btnPrint'].disabled}/>
                        <BtnEmail onClick={this.btnEmailClick.bind(this)}
                                  show={toolbarParams['btnEmail'].show}
                                  value={'Email'}
                                  docTypeId={this.props.docTypeId}
                                  disable={toolbarParams['btnEmail'].disabled}/>
                        <BtnFilter onClick={this.btnFilterClick}/>
                        <BtnRefresh onClick={this.btnRefreshClick}/>
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
        let toolbarProps = {
            add: this.props.toolbarProps  ? !!this.props.toolbarProps.add: true,
            edit: this.props.toolbarProps ? !!this.props.toolbarProps.edit: true,
            delete: this.props.toolbarProps ? !!this.props.toolbarProps.delete: true,
            print: this.props.toolbarProps  ? !!this.props.toolbarProps.print: true,
            email: this.props.toolbarProps  ? !!this.props.toolbarProps.email: true,
            start: this.props.toolbarProps ? !!this.props.toolbarProps.start: true
        };

        return Object.assign({
            btnAdd: {
                show: toolbarProps['add'],
                disabled: false
            },
            btnEdit: {
                show: toolbarProps['edit'],
                disabled: !this.state.value
            },
            btnDelete: {
                show: toolbarProps['delete'],
                disabled: !this.state.value
            },
            btnPrint: {
                show: toolbarProps['print'],
                disabled: false
            },
            btnEmail: {
                show: toolbarProps['email'],
                disabled: false
            },
            btnStart: {
                show: toolbarProps['start']
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
            filterData: this.filterData,
            lastDocId: null,
            module: this.props.module,
            userId: DocContext.userData.userId,
            uuid: DocContext.userData.uuid,
            data: additionalData
        };
        return new Promise((resolved, rejected) => {

            fetchData['fetchDataPost'](URL, params).then(response => {
                if (response.status && response.status === 401) {
                    document.location = `/login`;
                }

                // error handling
                if (response.status !== 200) {
                    this.setState({warning: `${response.error_message}`, warningType: 'error'});

                    return {
                        result: null,
                        status: response.status,
                        error_message: `error ${(response.data && response.data.error_message) ? 'response.data.error_message' : response.error_message}`
                    }
                }

                if (method === 'selectDocs') {
                    this.gridData = response.data.result.data;

                    if (response.data && response.data.gridConfig && response.data.gridConfig.length) {

                        //если конфиг отличается, формируем новый фильтр грида или надо очистить фильтр
                        if (!this.gridConfig.length ||
                            JSON.stringify(this.gridConfig) !== JSON.stringify(response.data.gridConfig) ||
                            this.state.isEmptyFilter) {

                            this.gridConfig = response.data.gridConfig;
                            this.subtotals = response.data.subtotals;

                            //refresh filterdata
                            if (!this.state.isEmptyFilter &&
                                DocContext.filter &&
                                DocContext.filter[this.props.docTypeId] &&
                                this.filterData &&
                                this.gridConfig.length === this.filterData.length) {

                                // есть сохраненный фильтр
                                this.filterData = DocContext.filter[this.props.docTypeId];
                            } else {
                                this.setState({isEmptyFilter: false});

                                this.filterData = this.gridConfig.map((row) => {
                                    // props.data пустое, создаем
                                    let value = row.value ? row.value : null;
                                    return {value: value, name: row.id, type: row.type ? row.type : 'text'};
                                });
                                DocContext.filter[this.props.docTypeId] = this.filterData;

                            }
                        }

                        //apply filter
                        if (this.props.history && this.props.history.location.state) {
                            this.filterData = this.mergeParametersWithFilter(this.filterData, this.props.history.location.state);
                            this.props.history.location.state = null;
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

                console.error('Error in fetch', error);
            });
        });
    }

    /**
     * обработчик для кнопки отправки почты
     */
    btnEmailClick() {
        // сохраним параметры для формирования вложения в контексте
        DocContext['email-params'] = {
            docId: this.state.docId,
            docTypeId: this.props.docTypeId,
            queryType: 'sqlWhere', // ид - документ
            sqlWhere: this.state.sqlWhere,
            filterData: this.filterData
        };


        this.props.history.push(`/${this.props.module}/e-mail/0`);
    }

    _bind(...methods) {
        methods.forEach((method) => this[method] = this[method].bind(this));
    }


}


function prepareData(gridConfig, docTypeId) {
    let data = [];


    if (!DocContext.filter) {
        DocContext.filter = {};
    }

    if (!DocContext.filter[docTypeId]) {
        DocContext.filter[docTypeId] = [];
    }

    // проверим, если фильтр уже сохранен, то вернем уже ранее сохжанный массив
    if (docTypeId && DocContext.filter[docTypeId].length > 0) {
        data = DocContext.filter[docTypeId];
    } else {
        gridConfig.map((row) => {
            const field = {
                value: row.value ? row.value : null,
                name: row.id,
                type: row.type ? row.type : 'text',
                interval: !!row.interval,
                start: row.value ? row.value : null,
                end: row.value ? row.value : null
            };

            data.push(field);

        });
    }

    return data;

}


Documents.propTypes = {
    initData: PropTypes.shape({
        result: PropTypes.object,
        gridConfig: PropTypes.array
    }),
    docTypeId: PropTypes.string.isRequired
};


Documents.defaultProps = {
    module: 'lapsed'
};


module.exports = (Documents);


