'use strict';

const PropTypes = require('prop-types');
const React = require('react');
const fetchData = require('./../../../libs/fetchData');
const DocContext = require('./../../doc-context.js');
const Menu = require('./../../components/menu-toolbar/menu-toolbar.jsx');
const DocRights = require('./../../../config/doc_rights');
const checkRights = require('./../../../libs/checkRights');
const createEmptyFilterData = require('./../../../libs/createEmptyFilterData');
const prepareSqlWhereFromFilter = require('./../../../libs/prepareSqlWhereFromFilter');
const Const = require('./../../../config/constants');
const Liimit = Const.RECORDS_LIMIT;
const prepareData = require('./../../../libs/prepaireFilterData');


const
    DataGrid = require('./../../components/data-grid/data-grid.jsx'),
    StartMenu = require('./../../components/start-menu/start-menu.jsx'),
    BtnAdd = require('./../../components/button-register/button-register-add/button-register-add.jsx'),
    BtnEdit = require('./../../components/button-register/button-register-edit/button-register-edit.jsx'),
    BtnDelete = require('./../../components/button-register/button-register-delete/button-register-delete.jsx'),
    BtnPrint = require('./../../components/button-register/button-register-print/button-register-print.jsx'),
    BtnPdf = require('./../../components/button-register/button-pdf/index.jsx'),
    BtnFilter = require('./../../components/button-register/button-register-filter/button-register-filter.jsx'),
    BtnSelect = require('./../../components/button-register/button-select/index.jsx'),
    BtnEmail = require('./../../components/button-register/button-email/index.jsx'),
    BtnRefresh = require('./../../components/button-register/button-refresh/index.jsx'),
    ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx'),
    GridFilter = require('./../../components/data-grid/grid-filter/grid-filter.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx'),
    InputText = require('./../../components/input-text/input-text.jsx'),
    ModalPageDelete = require('./../../components/modalpage/modalpage-delete/modalPage-delete.jsx'),
    ModalReport = require('./../../components/modalpage/modalpage-report/index.jsx'),
    styles = require('./documents-styles');


/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.Component {
    constructor(props) {
        super(props);

        this.gridData = [];
        this.gridConfig = DocContext.gridConfig && DocContext.gridConfig[props.docTypeId] ? DocContext.gridConfig[props.docTypeId] : [];
        this.filterData = DocContext.filter && DocContext.filter[props.docTypeId] ? DocContext.filter[props.docTypeId] : [];
        this.validationError = '';

        if (props.initData && props.initData.result) {
            this.gridData = props.initData.result.data || [];
            this.gridConfig = !this.gridConfig.length ? props.initData.gridConfig : this.gridConfig;
            this.subtotals = props.initData.subtotals || [];
        } else if (props.initData && props.initData.gridData) {

            this.gridData = props.initData.gridData || [];
            this.gridConfig = !this.gridConfig.length ? props.initData.gridConfig : this.gridConfig;
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
            limit: Liimit, // default limit for query,
            isEmptyFilter: false, // если true то обнулит данные фильтра при перегрузке данных
            showSelectFields: false, //will open or close column in grid to select rows
            isReport: false, // показ модального окна при проверке использования
            txtReport: [] // данные использования
        };

        this._bind('btnAddClick', 'clickHandler', 'btnEditClick', 'dblClickHandler', 'headerClickHandler',
            'headerClickHandler', 'btnFilterClick', 'btnSelectClick', 'btnRefreshClick','modalPageBtnClick',
            'modalDeletePageBtnClick', 'filterDataHandler', 'renderFilterToolbar',
            'btnStartClickHanler', 'renderStartMenu', 'startMenuClickHandler', 'fetchData',
            'handleInputChange', 'btnEmailClick', 'modalReportePageBtnClick');


    }

    /**
     * пишем делаем запрос по итогу загрузки
     */
    componentDidMount() {
        // will save current docTypeid
        DocContext.setDocTypeId = this.docTypeId;
        let reload = false; // if reload === true then it will call to reload

        if (this.props.initData && this.props.initData.docTypeId && this.props.initData.docTypeId.toUpperCase() !== this.docTypeId.toUpperCase()) {
            reload = true;
        }

        // дефолтные значения
        if (!DocContext.getFilter && DocContext.getGridConfig) {
            let config = DocContext.getGridConfig;
            let filter = prepareData(config, this.docTypeId);

            // ищем дефолтные значения
            config.forEach(row => {
                if (row.default) {
                    let value;
                    try {
                        value = eval(row.default);
                    } catch (e) {
                        console.error('No default value')
                    }

                    if (value) {
                        // ищем и присваеваем значение
                        let idx = filter.findIndex(data => data.id == row.id);
                        if (idx) {
                            filter[idx].value = value;
                        }
                    }
                }
            });

            if (filter.length) {
                DocContext.setFilter = filter;
            }

        }


        // проверим сохраненный фильтр для этого типа
        if (DocContext.getFilter && DocContext.getFilter.length > 0) {
            this.filterData = DocContext.getFilter;
            reload = true;
        }

        if (reload || !this.props.initData || !this.gridData.length) {

            // проверим на фильтр
            let sqlWhere = prepareSqlWhereFromFilter(this.filterData, this.docTypeId);

            //делаем запрос на получение данных
            this.setState({sqlWhere: sqlWhere}, () => {
                this.fetchData('selectDocs')
            });
        }

        // if lastDocId available, will point it as selected
        if (DocContext[(this.docTypeId).toLowerCase()]) {
            let docId = DocContext[(this.docTypeId).toLowerCase()];
            this.setState({value: docId});
        }


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
                      ref='menu'
                      history={this.props.history}
                      rekvId={DocContext.getAsutusId}
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
                              custom_styling={this.props.custom_styling ? this.props.custom_styling : null}
                              isSelect={this.state.showSelectFields}
                              value={this.state.value}/>
                    {this.state.getFilter ?
                        <ModalPage ref='modalpageFilter'
                                   modalPageBtnClick={this.modalPageBtnClick}
                                   modalPageName='Filter'
                                   show={true}>
                            <GridFilter ref='gridFilter'
                                        focusElement={this.gridConfig[1].id}
                                        docTypeId={this.docTypeId}
                                        handler={this.filterDataHandler}
                                        gridConfig={this.gridConfig}
                                        validationError={this.validationError}
                                        data={this.filterData}/>
                        </ModalPage> : null
                    }
                    <ModalPageDelete
                        show={this.state.isDelete}
                        modalPageBtnClick={this.modalDeletePageBtnClick.bind(this)}>
                    </ModalPageDelete>
                    <ModalReport
                        show={this.state.isReport}
                        report={this.state.txtReport}
                        modalPageBtnClick={this.modalReportePageBtnClick}>
                    </ModalReport>

                </div>
            </div>
        );
    }


    // обработчик изменений в инпут (лимит)
    handleInputChange(name, value) {
        this.setState({limit: !value || value > Liimit ? Liimit : value});
    }

    /**
     * вызовер подгрузку данных с параметром сортировки
     * @param sortBy
     */
    headerClickHandler(sortBy) {
        if (sortBy[0].column == 'select') {
            return
        }
        // ихем тип поля, если указан
        const row = this.gridConfig.find(row => row.id == sortBy[0].column);
        if (row && row.type) {
            Object.assign(sortBy[0], {type: row.type});
        }
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
        if (!this.filterData.length) {
            this.filterData = createEmptyFilterData(this.gridConfig, this.filterData, this.docTypeId);
        }
        this.setState({getFilter: true})
    }

    /**
     * выполнит запрос и обновит данные грида
     */
    btnRefreshClick() {
        this.fetchData('selectDocs');
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
        const filterData = this.filterData.filter(row => {
            return !!row.value
        });
        let filter = encodeURIComponent(`${JSON.stringify(filterData)}`);
        if (this.filterData.length) {
            url = `/print/${this.docTypeId}/${DocContext.getUuid}/${filter}`;

        } else {
            url = `/print/${this.docTypeId}/${DocContext.getUuid}/0`;
        }
        window.open(`${url}/${params}`);

    }

    /**
     * Обработчик для кнопки Pdf
     */
    btnPdfClick() {
        let sqlWhere = this.state.sqlWhere;
        let url;
        let params = encodeURIComponent(`${sqlWhere}`);
        let filter = encodeURIComponent(`${JSON.stringify(this.filterData)}`);

        if (this.filterData.length) {
            url = `/pdf/${this.docTypeId}/${DocContext.getUuid}/${filter}`;

        } else {
            url = `/pdf/${this.docTypeId}/${DocContext.getUuid}/0`;
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
            if (!this.validationError) {
                // только при отчутствии ошибки на валидации
                // собираем данные
                filterString = prepareSqlWhereFromFilter(this.filterData, this.docTypeId);
                this.setState({
                    getFilter: false,
                    sqlWhere: filterString,
                    isEmptyFilter: !filterString
                }, () => this.fetchData('selectDocs'));
            }

        } else {
            // чистим строку фильтрации и массив фильтров
            filterString = '';
            this.filterData.forEach(row => {
                row.value = null;
                if (row.start) {
                    row.start = null;
                }
                if (row.end) {
                    row.end = null;
                }
            });

            this.setState({
                getFilter: false,
                sqlWhere: filterString,
                isEmptyFilter: !filterString
            }, () => this.fetchData('selectDocs'));

        }

    }

    /**
     * обработчик для кнопки фильтрации
     * @param btnEvent
     */
    modalDeletePageBtnClick(btnEvent) {
        this.setState({isDelete: false});
        if (btnEvent === 'Ok') {
            // delete document
            this.setState({warning: 'Töötan...', warningType: 'notValid'});
            this.fetchData('delete')
                .catch((err) => {
                    console.error('error in fetch-> ', err);
                })
                .then((data) => {
                    console.log('data', data);
                    let error;

                    if (data.error_message || (data.data && data.data.error_message)) {
                        error = data.error_message ?  data.error_message:  (data.data && data.data.error_message) ? data.data.error_message: 'Viga';
                        console.error('Viga', error);
                        this.setState({warning: `Tekkis viga: ${error}`, warningType: 'error'});
                        if (data.status && data.status == 401) {
                            setTimeout(() => {
                                document.location = `/login`;
                            }, 1000);
                        }
                    } else {
                        this.fetchData('selectDocs');
                        // если есть в кеше , то чиcтим

                        if (DocContext.getLib && DocContext.getLib.length > 0) {
                            DocContext.setLib = []
                        }

                    }
                });
        }
    }

    /**
     * обработчик для фильтра грида
     * @param data
     */
    filterDataHandler(data, validationError) {
        this.filterData = data;
        // итог валидации
        this.validationError = validationError;

        // создади обьект = держатель состояния фильтра
        if (data && data.length > 0 && this.props.history.location) {
            DocContext.setFilter = this.filterData;
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
            let kas_sisaldab = row.sqlNo && row.sqlNo == 0 ? '<>' : '=';
            if (row.start) {
                string = `${string} ${row.name}>=${row.start},${row.name}<=${row.end};`;
            } else {
                if (row.value) {
                    string = string + row.name + ':' + kas_sisaldab + ' ' + row.value + '; ';
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
                               value={String(this.state.limit) || Liimit}
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
                        <BtnPdf onClick={this.btnPdfClick.bind(this)}
                                show={toolbarParams['btnPdf'].show}
                                value={'PDF'}
                                disable={toolbarParams['btnPdf'].disabled}/>
                        <BtnEmail onClick={this.btnEmailClick.bind(this)}
                                  show={toolbarParams['btnEmail'].show}
                                  value={'Email'}
                                  docTypeId={this.docTypeId}
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
        let docRights = DocRights[this.docTypeId] ? DocRights[this.docTypeId] : {};
        let userRoles = DocContext.getRoles;

        let toolbarProps = {
            add: this.props.toolbarProps ? !!this.props.toolbarProps.add : checkRights(userRoles, docRights, 'add'),
            edit: this.props.toolbarProps ? !!this.props.toolbarProps.edit : checkRights(userRoles, docRights, 'edit'),
            delete: this.props.toolbarProps ? !!this.props.toolbarProps.delete : checkRights(userRoles, docRights, 'delete'),
            print: this.props.toolbarProps ? !!this.props.toolbarProps.print : checkRights(userRoles, docRights, 'print'),
            pdf: this.props.toolbarProps ? !!this.props.toolbarProps.pdf : true,
            email: this.props.toolbarProps ? !!this.props.toolbarProps.email : true,
            start: this.props.toolbarProps ? !!this.props.toolbarProps.start : true
        };


        // сделаем обработку для виртуального табеля
        if (this.docTypeId == 'LAPSE_TAABEL') {
            let gridTaabelRow = {};

            if (!this.state.value) {
                gridTaabelRow = this.gridData.length ? this.gridData[0] : 0;
            } else {
                gridTaabelRow = this.gridData.find(row => {
                    return row.id == this.state.value
                });
            }

            if (gridTaabelRow && gridTaabelRow.tab_tyyp && gridTaabelRow.tab_tyyp == 'Virtuaalne') {

                toolbarProps['add'] = false;
                toolbarProps['edit'] = false;
                toolbarProps['delete'] = false;
            }
        }


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
            btnPdf: {
                show: toolbarProps['pdf'],
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
                show: this.gridConfig && this.gridConfig.length ? !!this.gridConfig.find(row => row.id === 'select') : false,
                disabled: false
            }
        }, (this.props.toolbarParams ? this.props.toolbarParams : {}),);
    }

    /**
     * Выполнит запросы
     */
    fetchData(method, additionalData) {
        let URL = `/newApi`;
        let sqlWhere = this.state.sqlWhere;
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
// ставим статус
        this.setState({warning: 'Töötan...', warningType: 'notValid'});

        const params = {
            parameter: this.docTypeId, // параметры
            docTypeId: this.docTypeId, // для согласования с документом
            sortBy: this.state.sortBy, // сортировка
            limit: this.state.limit, // row limit in query
            docId: this.state.value,
            method: method,
            sqlWhere: sqlWhere, // динамический фильтр грида
            filterData: this.filterData,
            lastDocId: null,
            module: this.props.module,
            userId: DocContext.getUserId,
            uuid: DocContext.getUuid,
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
                        error_message: `error ${(response.data && response.data.error_message) ? 'response.data.error_message' : response.data.error_message}`
                    }
                }

                if (method === 'selectDocs') {
                    this.gridData = response.data.result.data;

                    if (response.data) {

                        // если задан триггер, вызовем его
                        if (this.props.trigger_select) {
                            this.props.trigger_select(this);
                        }
                    }

                    let warning = 'Edukalt';
                    if (response.data && response.data.result && response.data.result.error_message) {
                        // нет ошибки, есть извещение. Покажем его в статусной строке
                        warning = response.data.result.error_message;
                    }

                    this.setState({warning: warning, warningType: 'ok'})

                } else if (method == 'delete' && response.data && response.data.result && response.data.result.error_code) {
                    // проверка перед удалением
                    let error = `Tekkis viga: kustutamine ebaõnnestus`;
                    this.setState({
                        warning: error,
                        warningType: 'error',
                        txtReport: response.data,
                        isReport: !!(response.data.data && response.data.data.length)
                    });
                    return rejected(error);

                }
                resolved(response.data);
            }).catch((error) => {
                console.error('fetch error', error);
                // Something happened in setting up the request that triggered an Error
                this.setState({
                    warning: `Tekkis viga ${error}`,
                    warningType: 'error'
                });
                return rejected(error);

            });
        });
    }

    /**
     * обработчик для кнопки отправки почты
     */
    btnEmailClick() {
        // сохраним параметры для формирования вложения в контексте
        DocContext.setEmailParams = {
            docId: this.state.docId,
            docTypeId: this.docTypeId,
            queryType: 'sqlWhere', // ид - документ
            sqlWhere: this.state.sqlWhere,
            filterData: this.filterData
        };


        this.props.history.push(`/${this.props.module}/e-mail/0`);
    }

    /**
     * уберет окно с отчетом
     */
    modalReportePageBtnClick(event) {
        let isReport = event && event == 'Ok' ? false : true;
        this.setState({isReport: isReport})
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


Documents.defaultProps = {
    module: 'lapsed'
};


module.exports = (Documents);

