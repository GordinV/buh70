'use strict';

const PropTypes = require('prop-types');
const React = require('react');
const fetchData = require('./../../../libs/fetchData');

const
    DataGrid = require('./../../components/data-grid/data-grid.jsx'),
    StartMenu = require('./../../components/start-menu/start-menu.jsx'),
    BtnAdd = require('./../../components/button-register/button-register-add/button-register-add.jsx'),
    BtnEdit = require('./../../components/button-register/button-register-edit/button-register-edit.jsx'),
    BtnDelete = require('./../../components/button-register/button-register-delete/button-register-delete.jsx'),
    BtnPrint = require('./../../components/button-register/button-register-print/button-register-print.jsx'),
    BtnFilter = require('./../../components/button-register/button-register-filter/button-register-filter.jsx'),
    ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx'),
    GridFilter = require('./../../components/data-grid/grid-filter/grid-filter.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx'),
    styles = require('./documents-styles');


/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);

        this.userData = {
            userLibraryList: props.userData.userLibraryList,
            userAccessList: props.userData.userAccessList,
            asutus: props.userData.asutus,
            userName: props.userData.userName,
            id: props.userData.id
        };

        this.gridData = [];
        this.gridConfig = [];
        this.filterData = [];
        this.startMenuData = []; // здесь будут данные для старт меню
        if (props.initData) {
            this.gridData = props.initData.result.data || [];
            this.gridConfig = props.initData.gridConfig || [];
        }

        this.docTypeId = props.docTypeId;

        this.state = {
            value: this.gridData.length ? this.gridData[0].id : 0,
            sortBy: {},
            sqlWhere: '',
            getFilter: false,
            hasStartMenuVisible: false, // will show start menu
            startMenuValue: 'parentid'
        };

        this._bind('btnAddClick', 'clickHandler', 'btnEditClick', 'dblClickHandler', 'headerClickHandler',
            'headerClickHandler', 'btnFilterClick', 'modalPageBtnClick', 'filterDataHandler', 'renderFilterToolbar',
            'btnStartClickHanler', 'renderStartMenu', 'startMenuClickHandler', 'fetchData', 'prepareSqlWhereFromFilter');


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
                this.fetchData()
            });

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

        return (
            <div style={_style.doc}>
                <div style={_style.docRow}>
                    {/*рендерим частные компоненты */}
                    {this.props.render()}
                </div>
                {this.renderDocToolBar()}
                <div style={_style.gridContainer}>
                    <DataGrid ref='dataGrid'
                              style={_style.grid.mainTable}
                              gridData={this.gridData}
                              gridColumns={this.gridConfig}
                              onClick={this.clickHandler}
                              onDblClick={this.dblClickHandler}
                              onHeaderClick={this.headerClickHandler}
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
                </div>
            </div>
        );
    }

    /**
     * вызовер подгрузку данных с параметром сортировки
     * @param sortBy
     */
    headerClickHandler(sortBy) {
        this.setState({sortBy: sortBy}, () => this.fetchData());
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
        console.log('btnDeleteClick');
    }

    /**
     * Обработчик для кнопки Print
     */
    btnPrintClick() {
        console.log('btnPrintClick');
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

        this.setState({getFilter: false, sqlWhere: filterString}, () => this.fetchData());
    }


    prepareSqlWhereFromFilter() {
        let filterString = ''; // строка фильтра

        this.filterData = this.filterData.map((row) => {
            if (row.value) {
                filterString = filterString + (filterString.length > 0 ? " and " : " where ");
                switch (row.type) {

                    case 'text':
                        filterString = filterString + row.name + " ilike '%" + row.value + "%'";
                        break;
                    case 'string':
                        filterString = filterString + row.name + " ilike '" + row.value + "%'";
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
                <ToolbarContainer ref='toolbarContainer'>
                    <BtnAdd onClick={this.btnAddClick} show={toolbarParams['btnAdd'].show}
                            disable={toolbarParams['btnAdd'].disabled}/>
                    <BtnEdit onClick={this.btnEditClick} show={toolbarParams['btnEdit'].show}
                             disable={toolbarParams['btnEdit'].disabled}/>
                    <BtnDelete onClick={this.btnDeleteClick} show={toolbarParams['btnDelete'].show}
                               disable={toolbarParams['btnDelete'].disabled}/>
                    <BtnPrint onClick={this.btnPrintClick} show={toolbarParams['btnPrint'].show}
                              disable={toolbarParams['btnPrint'].disabled}/>
                    <BtnFilter onClick={this.btnFilterClick}/>
                </ToolbarContainer>
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
                                   userData={this.props.userData}
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
        return {
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
            }

        };
    }

    /**
     * Выполнит запросы
     */
    fetchData() {
        const URL = `/newApi`;

        const params = {
            parameter: this.docTypeId, // параметры
            sortBy: this.state.sortBy, // сортировка
            sqlWhere: this.state.sqlWhere, // динамический фильтр грида
            lastDocId: null,
            module: this.props.module,
            userId: this.props.userData.userId
        };
        try {
            fetchData.fetchDataPost(URL, params).then(response => {

                if (response.status && response.status == 401) {
                    document.location= `/login`;
                }

                this.gridData = response.data.result.data;

                if (response.data.gridConfig.length) {
                    this.gridConfig = response.data.gridConfig;

                    //refresh filterdata
                    this.filterData = this.gridConfig.map((row) => {
                        // props.data пустое, создаем

                        return {value: null, name: row.id, type: row.type ? row.type : 'text'};
                    });

                    //apply filter
                    if (this.props.history && this.props.history.location.state) {
                        this.filterData = this.mergeParametersWithFilter(this.filterData, this.props.history.location.state);
                    }
                }

                this.forceUpdate();
            }).catch(function (error) {
                if (error.response) {
                    // Request made and server responded
                    console.log(error.response.data);
                    console.log(error.response.status);
                    console.log(error.response.headers);
                } else if (error.request) {
                    // The request was made but no response was received
                    console.log(error.request);
                } else {
                    // Something happened in setting up the request that triggered an Error
                    console.log('Error', error.message);
                }

            });

        } catch (e) {
            console.error(e);

        }
    }

    _bind(...methods) {
        methods.forEach((method) => this[method] = this[method].bind(this));
    }
}


Documents.propTypes = {
    userData: PropTypes.shape({
        userLibraryList: PropTypes.array,
        userAccessList: PropTypes.array,
        asutus: PropTypes.string,
        userName: PropTypes.string,
        id:PropTypes.number
    }).isRequired,
    initData: PropTypes.shape({
        result: PropTypes.object,
        gridConfig: PropTypes.array
    }),
    docTypeId: PropTypes.string.isRequired
};

module.exports = (Documents);


