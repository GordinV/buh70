'use strict';

const PropTypes = require('prop-types');

const React = require('react');
const fetchData = require('./../../../libs/fetchData');

const URL = '/newApi/document';

const
    Form = require('../../components/form/form.jsx'),
    ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx'),
    MenuToolBar = require('./../../components/menu-toolbar/menu-toolbar.jsx'),
    StartMenu = require('./../../components/start-menu/start-menu.jsx'),
    DocToolBar = require('./../../components/doc-toolbar/doc-toolbar.jsx'),
    styles = require('./document-styles');


/**
 * Класс реализует базовый документ .
 */
class DocumentTemplate extends React.PureComponent {
    constructor(props) {
        super(props);
        this.libs = {};
        this.state = {
            docId: this.props.docId, //если Id документа не передан, то создаем новый док
            edited: this.props.docId === 0,
            reloadData: Object.keys(props.initData).length ? false : true,
            gridRowEdit: false,
            gridRowEvent: null,
            warning: '',
            gridWarning: '',
            checked: true,
            loadedLibs: false
        };

        this.docData = Object.keys(props.initData).length ? props.initData : {id: this.props.docId};
        this.userData = Object.keys(props.userData).length ? props.userData : {};
        this.backup = {};
        this.requiredFields = props.requiredFields;
        this.pages = this.props.pages || null;

        this._bind('btnAddClick', 'btnEditClick', 'validation',
            'handleInputChange', 'prepareParamsForToolbar', 'btnDeleteClick', 'btnPrintClick',
            'btnSaveClick', 'btnCancelClick', 'fetchData', 'createLibs', 'loadLibs',
            'addRow', 'editRow', 'handleGridBtnClick', 'handleGridRowInput', 'handleGridRow', 'validateGridRow',
            'modalPageClick', 'handleGridRowChange');

        this.libs = this.createLibs(); //создаст объект для хранения справочников

        if (this.props.libs.length) {
            this.loadLibs();
        }

        this.gridRowData = {}; //будем хранить строку грида
    }

    /**
     * пишем исходные данные в хранилище, регистрируем обработчики событий
     */
    componentDidMount() {
        if (this.state.reloadData) {
            //делаем запрос на получение данных
            this.fetchData();
        }

        if (this.props.libs.length && !this.state.loadedLibs) {
            this.loadLibs();
        }

        if (this.props.docId === 0) {
            //@todo реализовать
//            this.focusElement()
        }

    }

    render() {
        let isInEditMode = this.state.edited,
            validationMessage = this.state.warning + isInEditMode ? this.validation() : '';

        return (
            <div>
                {this.renderDocToolBar()}

                <Form pages={this.pages}
                      ref="form"
                      handlePageClick={this.handlePageClick}
                      disabled={isInEditMode}>
                    <ToolbarContainer ref='toolbar-container'>
                        <div className='doc-toolbar-warning'>
                            {validationMessage ? <span>{validationMessage}</span> : null}
                        </div>
                    </ToolbarContainer>
                    <div style={styles.doc}>
                        {/*рендерим частные компоненты */}
                        {this.props.renderer ? this.props.renderer(this) : null}
                    </div>
                </Form>
            </div>
        );
    }

    /**
     * Обработчик для кнопки Добавить
     */
    btnAddClick() {
        //бекап данных
        this.makeBackup();


        if (this.props.history) {
            this.props.history.push(`/raama/${this.props.docTypeId}/0}`);
        } else {
            this.setState({docId: 0, edited: true}, () => {
                this.fetchData();
            })
        }

        console.log('called focus',this.props.focusElement );
        if (this.props.focusElement && this.refs[this.props.focusElement]) {
            this.refs[this.props.focusElement].focus();
        }

    }

    /**
     * Обработчик для кнопки редактировать
     */
    btnEditClick() {
        //в режим редактирования
        this.setState({edited: true, reloadData: true});
        //бекап данных
        this.makeBackup();

        if (this.props.focusElement && this.refs[this.props.focusElement]) {
            this.refs[this.props.focusElement].focus();
        }

    }

    btnDeleteClick() {
        console.log('btnDeleteClick');
    }

    btnPrintClick() {
        console.log('btnPrintClick');
    }

    /**
     * Обработчик для кнопки сохранить
     */
    btnSaveClick() {
        this.fetchData('Put').then(() => {
            console.log('saved -> ', this.docData.id);
            if (this.props.docId === 0 && !this.docData.id) {
                return this.setState({warning: 'Ошибка при сохранении'});
            } else {
                this.setState({edited: false, docId: this.docData.id});
            }
        });
    }

    /**
     * Обработчик события клика дял кнопки Отказ от сохранения
     */
    btnCancelClick() {
        //востановим прежнее состояние
        this.restoreFromBackup();
    }

    /**
     *
     */
    handleButtonTask() {
        console.log('handleButtonTask');
    }


    /**
     * Сделает копию текущего состояния данных
     */
    makeBackup() {
        this.backup = Object.assign({}, this.docData);
    }

    /**
     * востановить текущее состояние из копии
     */
    restoreFromBackup() {
        this.docData = Object.assign({}, this.backup);
        //режим редактирования
        this.setState({edited: false, warning: ''});
    }

    /**
     * Обработчик для инпутов.
     * @param inputName
     * @param inputValue
     * @returns {boolean}
     */
    handleInputChange(inputName, inputValue) {
        // обработчик изменений
        // изменения допустимы только в режиме редактирования
        if (!this.state.edited) {
            console.error('not in edite mode');
            return false;
        }

        this.docData[inputName] = inputValue;
        this.forceUpdate();
    }

    /**
     * вызовет метод валидации и вернет результат проверки
     * @returns {string}
     */
    validation() {

        if (!this.state.edited) return '';

        let warning = this.state.warning,
            notRequiredFields = [], // пишем в массив поля с отсутствующими данными
            notMinMaxRule = [];

        this.requiredFields.forEach((field) => {
            if (field.name in this.docData) {

                let value = this.docData[field.name];

                if (!value) {
                    notRequiredFields.push(field.name);
                }
                // проверка на мин . макс значения

                // || value && value > props.max
                let checkValue = false;

                switch (field.type) {
                    case 'D':
                        let controlledValueD = Date.parse(value);
                        if ((field.min && controlledValueD < field.min) && (field.max && controlledValueD > field.max)) {
                            checkValue = true;
                        }
                        break;
                    case 'N':
                        let controlledValueN = Number(value);

                        if (field.min && controlledValueN === 0 ||
                            ((field.min && controlledValueN < field.min) && (field.max && controlledValueN > field.max))) {
                            checkValue = true;
                        }
                        break;
                }
                if (checkValue) {
                    notMinMaxRule.push(field.name);
                }
            }
        });

        if (notRequiredFields.length > 0) {
            warning = 'puudub vajalikud andmed (' + notRequiredFields.join(', ') + ') ';
        }

        if (notMinMaxRule.length > 0) {
            warning = warning ? warning : '' + ' min/max on vale(' + notMinMaxRule.join(', ') + ') ';
        }
        return warning; // вернем извещение об итогах валидации
    }

    /**
     * Вернет компонет - панель инструментов документа
     * @returns {XML}
     */
    renderDocToolBar() {
        let toolbarParams = this.prepareParamsForToolbar(); //параметры для кнопок управления, взависимости от активной строки

        return (
            <div ref='doc-toolbar'>
                {/*
                <MenuToolBar params={toolbarParams}
                             userData={this.props.userData}
                             ref='menu-toolbar'
                             btnStartClick={this.btnStartClickHanler}/>
                {this.renderStartMenu()}
*/}
                <ToolbarContainer ref='toolbarContainer'>
                    <div>
                        <DocToolBar ref='doc-toolbar'
                                    docId={this.state.docId}
                                    edited={this.state.edited}
                                    validator={this.validation}
                                    btnAddClick={this.btnAddClick}
                                    btnEditClick={this.btnEditClick}
                                    btnCancelClick={this.btnCancelClick}
                                    btnPrintClick={this.btnPrintClick}
                                    btnSaveClick={this.btnSaveClick}/>
                    </div>
                </ToolbarContainer>
            </div>
        );
    }

    /**
     *  читаем данные со стора, формируем параметры для кнопок управления, и туда их отдаем
     * @returns {{btnAdd: {show: boolean, disabled: boolean}, btnEdit: {show: boolean, disabled: boolean}, btnDelete: {show: boolean, disabled: boolean}, btnPrint: {show: boolean, disabled: boolean}}}
     */
    prepareParamsForToolbar() {
        return {
            btnAdd: {
                show: true,
                disabled: false
            },
            btnEdit: {
                show: true,
                disabled: false
            },
            btnSave: {
                show: this.state.edited,
                disabled: false
            },
            btnDelete: {
                show: true,
                disabled: false
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
            btnRekv: {
                show: true,
                disabled: false
            }

        };
    }

    /**
     * Выполнит запросы
     */
    fetchData(protocol) {
        let url = `${URL}/${this.props.docTypeId}/${this.state.docId}`;
        let method = 'fetchDataPost';
        let params = {};
        if (protocol) {
            //request call not default
            method = 'fetchData' + protocol;
            params = this.docData;
        }

        return new Promise((resolved, rejected) => {
            fetchData[method](url, params).then(response => {
                if (response.data) {
                    let result = response.data.result;


                    if (result && result.error_code > 0) {
                        //есть результат запроса
                        let errorMessage = result.result.error_message;

                        if (!!errorMessage) {
                            this.setState({warning: errorMessage});
                            return rejected();
                        }
                    }

                    if (response.data.userData) {
                        //refresh userData (for auth purpose)
                        this.userData = response.data.userData;
                    }

                    if (response.data.data.length && Object.keys(response.data.data[0]).indexOf('id') !== -1) {
                        this.docData = response.data.data[0];
                        //should return data and called for reload
                        this.setState({reloadData: false, warning: ''});
                        resolved(response.data.data[0]);
                    } else {
                        this.setState({warning: 'Ошибка при сохранении'});
                        return rejected();
                    }

                }
            }, error => {
                console.error('Error:', error);
                return rejected();
            });
        })
    }

    /**
     * Обеспечит загрузку данных для библиотек
     */
    loadLibs() {
        const url = '/newApi/loadLibs/';
        let libs = this.props.libs.length;

        this.props.libs.forEach(lib => {
            fetchData.fetchDataPost(`/newApi/loadLibs/${lib}`, {}).then(response => {
                if (response && 'data' in response) {
                    this.libs[lib] = response.data.result.result.data;
                    libs--;
                }

                if (libs === 0) {
                    //all libs loaded;
                    this.setState({loadedLibs: true});
                }

            }).catch(error => {
                console.error('loadLibs error', error);
                rejected();
            });
        });
    }

    /**
     * вернет объект библиотек документа
     * @returns {{}}
     */
    createLibs() {
        let libs = {};
        this.props.libs.forEach((lib) => {
            libs[lib] = [];
        });
        return libs;
    }

    /**
     * Если есть в пропсах метод создания строки грида, вызовет его
     */
    createGridRow() {
        let gridRow;
        if (this.props.createGridRow) {
            gridRow = this.props.createGridRow(this);
        }
        return gridRow;
    }

    /**
     * Обработчик события клика на вкладку страницы
     * @param page
     */
    handlePageClick(page) {
        if (page.docId) {
            document.location.href = `/document/${page.docTypeId}/${page.docId}`;//@todo Обновить
        }
    }

    /**
     * обработчик событий для панели инструментов грида
     * @param btnName
     */
    handleGridBtnClick(btnName) {
        switch (btnName) {
            case 'add':
                this.addRow();
                break;
            case 'edit':
                this.editRow();
                break;
            case 'delete':
                this.deleteRow();
                break;
        }
    }

    /**
     *  управление модальным окном
     * @param gridEvent
     */
    handleGridRow(gridEvent) {
        this.setState({gridRowEdit: true, gridRowEvent: gridEvent});
    }

    /**
     * добавит в состояние новую строку
     */
    addRow() {
        //если не задан конфиг грида, то вернет фальш
        if (!this.docData.gridConfig.length) {
            return;
        }

        let gridColumns = this.docData.gridConfig,
            newRow = {};

        //создадим объект - строку грида
        for (let i = 0; i < gridColumns.length; i++) {
            let field = gridColumns[i].id;
            newRow[field] = '';
        }

        newRow.id = 'NEW' + Math.random(); // генерим новое ид

        this.gridRowData = newRow;

        // откроем модальное окно для редактирования
        this.setState({gridRowEdit: true, gridRowEvent: 'add'});
    }

    /**
     * откроет активную строку для редактирования
     */
    editRow() {
        this.gridRowData = this.docData.gridData[this.refs['data-grid'].state.activeRow];
        // откроем модальное окно для редактирования
        this.setState({gridRowEdit: true, gridRowEvent: 'edit'});
    }

    /**
     * удалит активную строку
     */
    deleteRow() {
        this.docData.gridData.splice(this.refs['data-grid'].state.activeRow, 1);

        // перерасчет итогов
        if (this.props.recalcDoc) {
            this.props.recalcDoc();
        }

        this.validation();

        // изменим состояние
        this.forceUpdate();
    }

    /**
     * Обработчик для строк грида
     * @param name
     * @param value
     */
    handleGridRowInput(name, value) {
        let columnType = this.docData.gridConfig.filter(row => {
            if (row.id === name) {
                return row;
            }
        })[0].type;

        switch (columnType) {
            case 'text':
                this.gridRowData[name] = String(value);
                break;
            case 'number':
                this.gridRowData[name] = Number(value);
                break;
            default:
                this.gridRowData[name] = (value);
        }

        this.validateGridRow();
    }

    /**
     * отслеживаем изменения данных на форме
     * @param name
     * @param value
     */
    handleGridRowChange(name, value) {
        this.gridRowData[name] = value;
        this.forceUpdate();
        this.validateGridRow();

    }


    /**
     * will check values on the form and return string with warning
     */
    validateGridRow() {
        let warning = '';

        if (this.props.gridValidator) {
            warning = this.props.gridValidator(this.gridRowData);
        }

        if (warning.length > 2) {
            // есть проблемы
            warning = 'Отсутсвуют данные:' + warning;
        }

        this.setState({checked: true, gridWarning: warning});
    }

    /**
     * отработаем Ok из модального окна
     * @param btnEvent
     * @param data
     */
    modalPageClick(btnEvent, data) {
        if (btnEvent == 'Ok') {


            // ищем по ид строку в данных грида, если нет, то добавим строку
            if (!this.docData.gridData.some(row => {
                    if (row.id === this.gridRowData.id) return true;
                })) {
                // вставка новой строки
                this.docData.gridData.splice(0, 0, this.gridRowData);
            } else {
                this.docData.gridData = this.docData.gridData.map(row => {
                    if (row.id === this.gridRowData.id) {
                        // нашли, замещаем
                        return this.gridRowData;
                    } else {
                        return row;
                    }
                });
            }

        }

        if (this.props.recalcDoc) {
            this.props.recalcDoc();
        }
        this.setState({gridRowEdit: !!this.state.warning});
    }

    _bind(...methods) {
        methods.forEach((method) => this[method] = this[method].bind(this));
    }

}

DocumentTemplate.propTypes = {
    initData: PropTypes.object, //Содержание документа
    requiredFields: PropTypes.array, // обязательные поля
    edited: PropTypes.bool, //режим редактирования
    userData: PropTypes.object.isRequired,//пользователь
    docTypeId: PropTypes.string.isRequired, //тип документа
    docId: PropTypes.number.isRequired, //id документа
    libs: PropTypes.array, //список библиотек
    renderer: PropTypes.func, //частные компонеты документа
    recalcDoc: PropTypes.func, //перерасчет сумм документа
    focusElement: PropTypes.string //елемент на который будет отдан фокус при редактировании
};

DocumentTemplate.defaultProps = {
    initData: [],
    docId: 0,
    edited: false,
    requiredFields: [],
    pages: [],
    libs: []
};

module.exports = DocumentTemplate;


