'use strict';

const PropTypes = require('prop-types');
const React = require('react');
const fetchData = require('./../../../libs/fetchData');
const DocContext = require('./../../doc-context.js');
const Menu = require('./../../components/menu-toolbar/menu-toolbar.jsx');

const URL = 'newApi/document';

const
    Form = require('../../components/form/form.jsx'),
    ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx'),
    DocToolBar = require('./../../components/doc-toolbar/doc-toolbar.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx'),
    styles = require('./document-styles');


/**
 * Класс реализует базовый документ .
 */
class DocumentTemplate extends React.Component {
    constructor(props) {
        super(props);
        this.libs = {};
        this.state = {
            docId: this.props.docId, //если Id документа не передан, то создаем новый док
            edited: this.props.docId === 0,
            reloadData: !Object.keys(props.initData).length,
            gridRowEdit: false,
            gridRowEvent: null,
            warning: '',
            warningStyle: '',
            gridWarning: '',
            checked: true,
            loadedLibs: false,
            libParams: {},
            logs: [],
            isDisableSave: props.isDisableSave,
            docData: {}
        };

        this.docData = Object.keys(props.initData).length ? props.initData : {id: props.docId};
        this.backup = {};
        this.requiredFields = [];
        this.serverValidation = [];
        this.bpm = [];
        this.pages = props.pages;

        this._bind('btnAddClick', 'btnEditClick', 'btnLogoutClick', 'validation',
            'handleInputChange', 'prepareParamsForToolbar', 'btnDeleteClick', 'btnPrintClick', 'btnEmailClick',
            'btnSaveClick', 'btnCancelClick', 'btnTaskClick', 'fetchData', 'createLibs', 'loadLibs', 'hasLibInCache',
            'addRow', 'editRow', 'handleGridBtnClick', 'handleGridRowInput', 'handleGridRow', 'validateGridRow',
            'modalPageClick', 'handleGridRowChange', 'handlePageClick', 'modalPageBtnClick', 'btnLogsClick',
            'handleGridCellClick');


        this.gridRowData = {}; //будем хранить строку грида

    }

    componentDidUpdate() {
        // сохраним последнее значение дока этого типа
        if (this.state.docId) {
            DocContext[(this.props.docTypeId).toLowerCase()] = this.state.docId;
        }
    }

    /**
     * пишем исходные данные в хранилище, регистрируем обработчики событий
     */
    componentDidMount() {
        // сохраним в контексте тип документа, с которым мы работает
        DocContext.docTypeId = this.props.docTypeId;

        if (this.state.reloadData) {
            //делаем запрос на получение данных
            this.fetchData();
        }

        this.libs = this.createLibs(); //создаст объект для хранения справочников
        if (this.props.focusElement) {
            const focusElement = this.refs[this.props.focusElement];
            if (focusElement) {
                focusElement.focus()
            }
        }

    }


    render() {
        let isInEditMode = this.state.edited;

        if (this.props.libs.length && !this.state.loadedLibs) {
            this.loadLibs();
        }

        const warningStyle = styles[this.state.warningType] ? styles[this.state.warningType] : null;

        let dialogString = this.serverValidation.length > 0 ? `Dokument ${this.serverValidation[0].name} = ${this.serverValidation[0].value} juba olemas. Kas jätka?` : '';
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
            <div>
                <Menu params={btnParams}
                      history={this.props.history}
                      rekvId={DocContext.userData ? DocContext.userData.asutusId : 0}
                      module={this.props.module}/>
                {this.renderDocToolBar()}
                <Form pages={this.pages}
                      ref="form"
                      handlePageClick={this.handlePageClick}
                      disabled={isInEditMode}>
                    <ToolbarContainer ref='toolbar-container'>
                        <div className='doc-toolbar-warning' style={warningStyle}>
                            {this.state.warning ? <span>{this.state.warning}</span> : null}
                        </div>
                    </ToolbarContainer>
                    <div style={styles.doc}>
                        {/*рендерим частные компоненты */}
                        {this.props.renderer ? this.props.renderer(this) : null}
                    </div>
                </Form>
                <ModalPage
                    show={this.serverValidation.length > 0}
                    modalPageName='Kontrol'
                    modalObjects={['btnOk', 'btnCancel']}
                    modalPageBtnClick={this.modalPageBtnClick.bind(this)}>
                    <div ref="container">
                        <img ref="image" src={styles.modalValidate.iconImage}/>
                        <span> {dialogString} </span>
                    </div>

                </ModalPage>
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
            this.props.history.push(`/${this.props.module}/${this.props.docTypeId}/0`);
        }

        this.setState({docId: 0, edited: true}, () => {
            this.fetchData().then(() => {
                    this.forceUpdate();
                }
            );
        });

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
        let url = `/print/${this.props.docTypeId}/${DocContext.userData.uuid}/${this.state.docId}`;
        window.open(`${url}`);

    }

    /**
     * обработчик для кнопки отправки почты
     */
    btnEmailClick() {
        // если документ тип счет или извещение, то отправим напрямую, иначе переадрисуем на письмо
        if ((this.props.docTypeId).toLowerCase() == 'arv' || (this.props.docTypeId).toLowerCase() == 'teatis') {
            this.fetchData('Post', '/email').then((response) => {
                if (response.status === 200) {
                    this.setState({
                        reloadData: false,
                        warning: 'Email saadetud edukalt',
                        warningType: 'ok',
                    });

                } else {
                    let errorMessage = response.error_message ? response.error_message : '';
                    this.setState({
                        reloadData: false,
                        warning: `Tekkis viga ${errorMessage}`,
                        warningType: 'error',
                    });
                }
            });

        } else {
            // сохраним параметры для формирования вложения в контексте
            DocContext['email-params'] = {
                docId: this.state.docId,
                docTypeId: this.props.docTypeId,
                queryType: 'id' // ид - документ, where -
            };

            this.props.history.push(`/${this.props.module}/e-mail/0`);
        }
    }

    /**
     * Обработчик для кнопки сохранить
     */
    btnSaveClick() {
        this.fetchData('Put').then((response) => {
            if (!response) return false;
            //call to save
            this.docData = response.data[0];

            this.setState({
                reloadData: false,
                warning: 'Salvestatud edukalt',
                warningType: 'ok',
                edited: false,
                docId: this.docData.id ? this.docData.id : 0
            }, () => {
                // сохраним в контексте последние изменения
                DocContext[this.props.docTypeId] = this.docData.id;

                //если было создание нового докмента и этот док был карта ребенка, то сделаем переадрессацию на добавление услуг
                let docTypeId = this.props.docTypeId,
                    docId = this.docData.id;

                if (docTypeId.toUpperCase() === 'LAPS' && this.props.docId === 0) {
                    // делаем редайрект на карту услуг
                    docTypeId = 'LAPSE_KAART';
                    docId = 0;
                }

                // если есть в кеше , то читим
                let lib = this.props.docTypeId.toLowerCase();

                if (DocContext.libs && DocContext.libs[lib] && DocContext.libs[lib].length > 0) {
                    DocContext.libs[lib] = []
                }

                if (this.props.reload) {
                    // reload / redirect
                    setTimeout(() => {
                        const current = `/${this.props.module ? this.props.module : 'lapsed'}/${docTypeId}/${docId}`;
                        this.props.history.replace(`/reload`);
                        setTimeout(() => {
                            this.props.history.replace(current);
                        });

                    }, 2000);
                }

            });

        });
    }

    /**
     * Обработчик события клика дял кнопки Отказ от сохранения
     */
    btnCancelClick() {
        //востановим прежнее состояние
        if (this.state.docId) {
            this.restoreFromBackup();
        } else {
            this.props.history.goBack();
        }
        //режим редактирования
        this.setState({edited: false, warning: '', warningType: null});

    }

    /**
     *
     */
    btnTaskClick(taskName, kpv) {
        const task = this.bpm.find(task => task.name === taskName);
        let api = `/newApi/task/${task.task}`;

        this.fetchData('Post', api, kpv ? {seisuga: kpv} : null).then((response) => {
            const dataRow = response.result;
            const dataMessage = response.data.error_message ? response.data.error_message : '';

            let docId = dataRow.docId;
            let docTypeId = dataRow.docTypeId ? dataRow.docTypeId : null;

            if (docId && docTypeId) {
                this.setState({
                    warning: `Edukalt`,
                    warningType: 'ok'
                }, () => {

                    setTimeout(() => {
                        // koostatud uus dok, teeme reload
                        const current = `/${this.props.module}/${this.props.docTypeId}/${this.state.docId}`;
                        this.props.history.replace(`/reload`);
                        setTimeout(() => {
                            this.props.history.replace(current);
                        });
                    }, 2000);
                });
            } else if (dataMessage) {
                this.setState({
                    warning: `Viga, ${dataMessage}`,
                    warningType: 'error'
                })
            }
        });
    }

    /**
     * Выполнит запрос и покажет логи
     */
    btnLogsClick() {
        let api = `/newApi/logs/`;

        this.fetchData('Post', api).then((response) => {
            const dataRows = response.data;
            this.setState({showLogs: true, logs: dataRows});
        });

    }

    /**
     * Сделает копию текущего состояния данных
     */
    makeBackup() {
        this.backup = JSON.stringify(this.docData);
    }

    /**
     * востановить текущее состояние из копии
     */
    restoreFromBackup() {
        this.docData = JSON.parse(this.backup);
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
        if (this.props.handleInputChange) {
            this.props.handleInputChange(inputName, inputValue);
        }
        this.validation();
        this.forceUpdate();
    }

    /**
     * обработчика грида
     * @param gridData
     */
    handleGridCellClick(action, docId, idx, columnId, value) {
        if (this.docData && this.docData.gridData) {
            this.docData.gridData[idx][columnId] = value;
            this.setState({docData: this.docData});

            // если есть триггер, вызовем его
            if (this.props.trigger) {
                this.props.trigger(this);
            }
        }
        this.validation();

    }

    /**
     * вызовет метод валидации и вернет результат проверки
     * @returns {string}
     */
    validation() {

        if (!this.state.edited) return '';

        let warning = '',
            notRequiredFields = [], // пишем в массив поля с отсутствующими данными
            notMinMaxRule = [];

        if (this.requiredFields) {

            this.requiredFields.forEach((field) => {
                if (field.name && field.name in this.docData) {
                    let value = this.docData[field.name];

                    if (!value && field.type !=='B') {
                        notRequiredFields.push(field.name);
                    } else {
                        if (field.serverValidation) {
                            // send paring to server to validate

                            this.fetchData('Post', `/newApi/validate/${field.serverValidation}/${value}`).then(response => {
                                if (response.data.data.length) {

                                    let docId = response.data.data[0].id;
                                    let _warning = this.state.warning;
                                    if (docId && docId !== this.state.docId) {
                                        //переадресовка
                                        this.serverValidation.push({
                                            name: field.name,
                                            value: value,
                                            result: docId
                                        });

                                        _warning = _warning + `${value} (${field.name}) juba olemas`;

                                        //svae in state
                                        this.setState({
                                            warning: _warning,
                                            warningType: 'notValid'
                                        });
                                        this.forceUpdate();
                                    }
                                }

                            });
                        }
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

                if (field.trigger) {
                    field.trigger();
                }
            });

            if (notRequiredFields.length > 0) {
                warning = warning + ' puudub vajalikud andmed (' + notRequiredFields.join(', ') + ') ';
            }

            if (notMinMaxRule.length > 0) {
                warning = warning ? warning : '' + ' min/max on vale(' + notMinMaxRule.join(', ') + ') ';
            }

            this.setState({
                warning: warning,
                warningType: warning.length ? 'notValid' : null
            });
        }

        return warning; // вернем извещение об итогах валидации
    }

    /**
     * Вернет компонет - панель инструментов документа
     * @returns {XML}
     */
    renderDocToolBar() {
        const toolbar = this.prepareParamsForToolbar();
        return (
            <ToolbarContainer ref='toolbarContainer'>
                <DocToolBar ref='doc-toolbar'
                            docTypeId={this.props.docTypeId}
                            bpm={this.bpm ? this.bpm : []}
                            logs={this.state.logs}
                            docId={this.state.docId}
                            edited={this.state.edited}
                            docStatus={this.docData.doc_status}
                            validator={this.validation}
                            btnAddClick={this.btnAddClick}
                            btnEditClick={this.btnEditClick}
                            btnCancelClick={this.btnCancelClick}
                            btnPrintClick={this.btnPrintClick}
                            btnEmailClick={this.btnEmailClick}
                            btnSaveClick={this.btnSaveClick}
                            btnLogsClick={this.btnLogsClick}
                            btnTaskClick={this.btnTaskClick}
                            toolbarParams={toolbar}
                />
            </ToolbarContainer>
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
                disabled: this.state.isDisableSave
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
    fetchData(protocol, api, api_params) {

        let url = api ? api : `${URL}/${this.props.docTypeId}/${this.state.docId}`;
        let method = 'fetchDataPost';
        let params = {
            docTypeId: this.props.docTypeId ? this.props.docTypeId : DocContext.docTypeId,
            module: this.props.module ? this.props.module : DocContext.module,
            userId: DocContext.userData.userId,
            uuid: DocContext.userData.uuid,
            docId: this.state.docId,
            context: DocContext[api] ? DocContext[api] : null
        };

        if (protocol) {
            //request call not default
            method = 'fetchData' + protocol;
            params = Object.assign({}, params, this.docData, api_params ? api_params : {});
        }

        return new Promise((resolved, rejected) => {
            fetchData[method](url, params).then(response => {
                    if (response.status && response.status === 401) {
                        document.location = `/login`;
                    }

                    if (response.data) {

                        //execute select calls
                        if (response.data.action && response.data.action === 'select') {
                            this.docData = response.data.data[0];

                            // will store required fields info
                            if (response.data.data[0].requiredFields) {
                                this.requiredFields = response.data.data[0].requiredFields;
                            }

                            // will store bpm info
                            if (response.data.data[0].bpm) {
                                this.bpm = response.data.data[0].bpm;
                            }

                            //should return data and called for reload
                            this.setState({reloadData: false, warning: '', warningType: null});
                            resolved(response.data.data[0]);
                        }

                        if (response.data.action && response.data.action === 'save' && response.data.result.error_code) {
                            // error in save
                            this.setState({
                                warning: `Tekkis viga ${response.data.result.error_message}`,
                                warningType: 'error'
                            });
                            return rejected();

                        }

                        return resolved(response.data);
                    } else {
                        console.error('Fetch viga ', response, params);
                        this.setState({
                            warning: `Tekkis viga ${response.data.error_message ? response.data.error_message : ''}`,
                            warningType: 'error'
                        });
                        return rejected();
                    }
                }
            ).catch((e) => {
                console.error(`catched fetch error ${e}`);
                this.setState({
                    warning: `Tekkis viga ${e}`,
                    warningType: 'error'
                });

                return rejected();
            });

        });
    }

    /**
     * Обеспечит загрузку данных для библиотек
     */
    loadLibs(libName) {
        let libsCount = this.props.libs.length;

        let postUrl = '/newApi/loadLibs';

        let libsToLoad = libName ? [libName] : Object.keys(this.libs);

        libsToLoad.forEach((lib) => {
            let hasSqlWhere = (lib in this.state.libParams);

            let params = Object.assign({
                module: this.props.module,
                userId: DocContext.userData.id,
                uuid: DocContext.userData.uuid,
            }, hasSqlWhere ? {
                sql: this.state.libParams[lib]
            } : {});

            if (!!this.state.libParams[lib] || !this.hasLibInCache(lib)) {

                fetchData.fetchDataPost(`${postUrl}/${lib}`, params)
                    .then(response => {
                        if (response && 'data' in response) {
                            this.libs[lib] = response.data.result.result.data;
                            libsCount--;
                        }
                        // save lib in cache
                        DocContext.libs[lib] = this.libs[lib];

                        if (libsCount === 0) {
                            //all libs loaded;
                            if (this.state.loadedLibs) {
                                this.forceUpdate();
                            } else {
                                this.setState({loadedLibs: true});
                            }
                        }

                    })
                    .catch(error => {
                        console.error('loadLibs error', error);
                    });
            } else {
                this.libs[lib] = DocContext.libs[lib];
            }
        });
    }

    /**
     * проверит наличии в кеше данных и если нет, то вернет false
     * @param lib
     * @returns {boolean}
     */
    hasLibInCache(lib) {
        if (!DocContext.libs) {
            DocContext.libs = {};
        }
        return (!DocContext.libs[lib] || DocContext.libs[lib].length === 0) ? false : true;
    }

    /**
     * вернет объект библиотек документа
     * @returns {{}}
     */
    createLibs() {
        let libs = {};
        let libParams = {};
        this.props.libs.forEach((lib) => {
            if (typeof lib == 'object') {
                //object
                libs[lib.id] = [];
                libParams[lib.id] = lib.filter;
            } else {
                libs[lib] = [];
            }
        });
        this.setState({libParams: libParams}, () => this.loadLibs());
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
        if (page.handlePageClick) {
            page.handlePageClick(page.docTypeId);
        } else if (page.docId) {
            const current = `/${DocContext.module}/${page.docTypeId}/${page.docId}`;
            this.props.history.replace(`/reload`);
            setTimeout(() => {
                this.props.history.replace(current);
            });
        }
    }

    /**
     * обработчик событий для панели инструментов грида
     */
    handleGridBtnClick(btnName, activeRow, id, docTypeId) {

        if (this.props.handleGridBtnClick) {
            // если есть обработчик, то отдаем туда, иначе вызываем метод на редактирование строки
            this.props.handleGridBtnClick(btnName, activeRow, id, docTypeId);

        } else {
            switch (btnName.toLowerCase()) {
                case 'add':
                    this.addRow();
                    break;
                case 'lisa':
                    this.addRow();
                    break;
                case 'edit':
                    this.editRow();
                    break;
                case 'muuda':
                    this.editRow();
                    break;
                case 'delete':
                    this.deleteRow();
                    break;
                case 'kustuta':
                    this.deleteRow();
                    break;
                default:
                    console.log('Vigane click . ', btnName.toLowerCase());

            }
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
        this.forceUpdate();
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
        let showModal = false;
        if (btnEvent === 'Ok') {
            // ищем по ид строку в данных грида, если нет, то добавим строку
            if (!this.docData.gridData.length || !this.docData.gridData.some(row => row.id === this.gridRowData.id)) {
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

            showModal = !!this.state.warning;

        }

        if (this.props.recalcDoc) {
            this.props.recalcDoc();
        }
        this.setState({gridRowEdit: showModal});
        return showModal;
    }

    _bind(...methods) {
        methods.forEach((method) => {
            if (this[method]) {
                this[method] = this[method].bind(this)
            }
        });
    }

    /**
     * обработчик для кнопки модального окна
     * @param btnEvent
     */
    modalPageBtnClick(btnEvent) {
        //получим значение
        let docId = this.serverValidation[0].result;

        // обнулим итог валидации
        this.serverValidation = [];

        if (btnEvent === 'Ok') {
            // редайрект
            // koostatud uus dok,
            this.props.history.push(`/${this.props.module}/${this.props.docTypeId}/${docId}`);

            const current = `/${this.props.module}/${this.props.docTypeId}/${docId}`;
            this.props.history.replace(`/reload`);
            setTimeout(() => {
                this.props.history.replace(current);
            });
        } else {
            this.forceUpdate();
        }
    }

}

DocumentTemplate
    .propTypes = {
    initData: PropTypes.object, //Содержание документа
    requiredFields: PropTypes.array, // обязательные поля
    edited: PropTypes.bool, //режим редактирования
    docTypeId: PropTypes.string.isRequired, //тип документа
    docId: PropTypes.number.isRequired, //id документа
    libs: PropTypes.array, //список библиотек
    renderer: PropTypes.func, //частные компонеты документа
    recalcDoc: PropTypes.func, //перерасчет сумм документа
    focusElement: PropTypes.string //елемент на который будет отдан фокус при редактировании
};

DocumentTemplate
    .defaultProps = {
    initData: [],
    docId: 0,
    edited: false,
    requiredFields: [],
    pages: [],
    libs: [],
    isDisableSave: false,
    isGridDataSave: false
};

module
    .exports = DocumentTemplate;


