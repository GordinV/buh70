'use strict';

const PropTypes = require('prop-types');
const React = require('react');
const fetchData = require('./../../../libs/fetchData');
const DocContext = require('./../../doc-context.js');
const Menu = require('./../../components/menu-toolbar/menu-toolbar.jsx');
const DocRights = require('./../../../config/doc_rights');
const checkRights = require('./../../../libs/checkRights');
let LIBS_URL = require('./../../../config/constants').LIBS.POST_LOAD_LIBS_URL;
const URL = require('./../../../config/constants').DOCS.POST_LOAD_DOCS_URL;

const
    Form = require('../../components/form/form.jsx'),
    ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx'),
    DocToolBar = require('./../../components/doc-toolbar/doc-toolbar.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx'),
    ModalReport = require('./../../components/modalpage/modalpage-report/index.jsx'),
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
            docData: {},
            isReport: false,
            txtReport: []
        };

        this.docData = Object.keys(props.initData).length ? props.initData : {id: props.docId};
        this.backup = {};
        this.requiredFields = [];
        this.serverValidation = [];
        this.bpm = [];
        this.pages = props.pages;
        this.loadingLibs = {};


        this._bind('btnAddClick', 'btnEditClick', 'btnLogoutClick', 'validation',
            'handleInputChange', 'prepareParamsForToolbar', 'btnDeleteClick', 'btnPrintClick', 'btnEmailClick',
            'btnPdfClick',
            'btnSaveClick', 'btnCancelClick', 'btnTaskClick', 'fetchData', 'createLibs', 'loadLibs', 'hasLibInCache',
            'addRow', 'editRow', 'handleGridBtnClick', 'handleGridRowInput', 'handleGridRow', 'validateGridRow',
            'modalPageClick', 'handleGridRowChange', 'handlePageClick', 'modalPageBtnClick', 'btnLogsClick',
            'handleGridCellClick', 'modalReportePageBtnClick');


        this.gridRowData = {}; //будем хранить строку грида

    }

    componentDidUpdate() {
        // сохраним последнее значение дока этого типа
        if (this.state.docId) {
            DocContext.setDocId = this.state.docId;
        }
    }

    /**
     * пишем исходные данные в хранилище, регистрируем обработчики событий
     */
    componentDidMount() {
        // сохраним в контексте тип документа, с которым мы работает
        DocContext.setDocTypeId = this.props.docTypeId;

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
            let kpv = new Date().toISOString().slice(0, 10);
            if (this.docData && this.docData.kpv) {
                kpv = this.docData.kpv;
            }
            // грузим справочники
            this.loadLibs(null, kpv);
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
                      ref="menu"
                      history={this.props.history}
                      rekvId={DocContext.getAsutusId}
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
                <ModalReport
                    show={this.state.isReport}
                    report={this.state.txtReport}
                    modalPageBtnClick={this.modalReportePageBtnClick}>
                </ModalReport>

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
        this.setState({edited: true, reloadData: true,warning: '', warningType: ''});
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
        let url = `/print/${this.props.docTypeId}/${DocContext.getUuid}/${this.state.docId}`;
        window.open(`${url}`);

    }

    btnPdfClick() {
        let url = `/pdf/${this.props.docTypeId}/${DocContext.getUuid}/${this.state.docId}`;
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
            DocContext.setEmailParams = {
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
        if (this.props.docTypeId !== 'PAEVA_TAABEL') {
            this.setState({
                edited: false,
                warning: 'Salvestan...',
                warningType: 'notValid',
            });

        }

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
                let docTypeId = this.props.docTypeId,
                    docId = this.docData.id;

                // сохраним в контексте последние изменения
                DocContext.setDocId = this.docData.id;

                //если было создание нового докмента и этот док был карта ребенка, то сделаем переадрессацию на добавление услуг

                // если есть в кеше , то чистим
                DocContext.setLib = [];

                // обновим справочник
                if (DocContext.getLib) {
                    this.loadLibs(docTypeId.toLowerCase());
                }


                if (docTypeId.toUpperCase() === 'LAPS' && this.props.docId === 0) {
                    // делаем редайрект на карту услуг
                    docTypeId = 'LAPSE_KAART';
                    docId = 0;
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
    btnTaskClick(taskName, kpv, gruppId, tekst, kogus) {
        const task = this.bpm.find(task => {
            return task.name === taskName
        });
        if (!task) {
            this.setState({
                warning: `Viga, task ${taskName} ei leidnud`,
                warningType: 'error'

            });
            return;
        }

        let api = `/newApi/task/${task.task}`;

        this.setState({warning: 'Töötan...', warningType: 'notValid'});

        this.fetchData('Post', api, kpv || gruppId || tekst || kogus ? {
            seisuga: kpv,
            gruppId: gruppId,
            viitenumber: tekst,
            kogus: kogus
        } : null).then((response) => {
            const dataRow = response.result;
            const dataMessage = response.data.error_message ? response.data.error_message : '';

            let docId = dataRow.docId;
            let docTypeId = dataRow.docTypeId ? dataRow.docTypeId : null;

            if (docId && docTypeId) {
                this.setState({
                    warning: `Edukalt ${dataMessage}`,
                    warningType: 'ok'
                }, () => {

                    setTimeout(() => {
                        // koostatud uus dok, teeme reload
                        const current = `/${this.props.module}/${this.props.docTypeId}/${this.state.docId}`;
                        if (task.task == 'KoostaTagasimakse' || task.task == 'KoostaUlekanneMakse') {

                            // осуществит переход на карточку контр-агента
                            this.props.history.push(`/lapsed/${docTypeId}/${docId}`);
                        } else {
                            this.props.history.replace(`/reload`);
                            setTimeout(() => {
                                this.props.history.replace(current);
                            });
                        }

                    }, 2000)
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
        // перерасчет итогов
        if (this.props.recalcDoc) {
            this.props.recalcDoc();
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
                this.props.trigger(this, idx, columnId, value);
            }
        }
        this.validation();

    }

    /**
     * вызовет метод валидации данных справочника (кода) и вернет результат проверки
     * @returns {string}
     */
    validation() {
        if (!this.state.edited) return '';

        let warning = '',
            notRequiredFields = [], // пишем в массив поля с отсутствующими данными
            expressionFields = [], // пишем выражение
            notMinMaxRule = [];

        if (this.requiredFields) {

            this.requiredFields.forEach((field) => {
                if (field.name && field.name in this.docData) {
                    let value = this.docData[field.name];

                    if (!value && field.type !== 'B') {
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

                    // проверка на выражение
                    if (field.expression) {
                        let data = this.docData;
                        let expression = field.expression;
                        let result = eval(field.expression);
                        if (!result) {
                            expressionFields.push(field.name);
                        }

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

            if (expressionFields.length > 0) {
                warning = warning ? warning : '' + ' vale andmed (' + expressionFields.join(', ') + ') ';
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
        let docRights = DocRights[this.props.docTypeId] ? DocRights[this.props.docTypeId] : [];
        let userRoles = DocContext.getRoles;

        return {
            btnAdd: {
                show: checkRights(userRoles, docRights, 'add'),
                disabled: false
            },
            btnEdit: {
                show: checkRights(userRoles, docRights, 'edit'),
                disabled: false
            },
            btnSave: {
                show: this.state.edited,
                disabled: this.state.isDisableSave
            },
            btnDelete: {
                show: checkRights(userRoles, docRights, 'delete'),
                disabled: false
            },
            btnPrint: {
                show: checkRights(userRoles, docRights, 'print'),
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
            userId: DocContext.getUserId,
            uuid: DocContext.getUuid,
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
                                let docRights = DocRights[this.props.docTypeId] ? DocRights[this.props.docTypeId] : [];
                                let userRoles = DocContext.getRoles;

                                // только доступные таски должны попасть в список
                                this.bpm = response.data.data[0].bpm.filter(task => {
                                    return checkRights(userRoles, docRights, task.task);
                                });
                            }


                            //should return data and called for reload
                            this.setState({reloadData: false, warning: '', warningType: null});
                            resolved(response.data.data[0]);
                        }

                        if (response.data.action && response.data.action === 'save' && response.data.result.error_code) {

                            let error_teatis = response.data.result && response.data.result.error_message ? response.data.result.error_message : '';
                            // error in save
                            this.setState({
                                warning: `Tekkis viga: salvestamine ebaõnnestus ${error_teatis}`,
                                warningType: 'error',
                                txtReport: response.data,
                                isReport: !!(response.data.data && response.data.data.length)
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
     * libName - код справочника
     * kpv - дата, по умолчанию сегодня
     */
    loadLibs(libName, kpv) {
        let libsCount = libName ? 1 : this.props.libs.length;

        let libsToLoad = libName ? [libName] : Object.keys(this.libs);
        // start loading
        if (!this.loadingLibs[libName]) {
            this.loadingLibs[libName] = true;
        } else {
            // уже идет загрузка
            return;
        }

        libsToLoad.forEach((lib) => {

            let hasSqlWhere = (lib in this.state.libParams);

            new Date().toISOString().slice(0, 10); //ajutiselt

            let params = Object.assign({
                module: this.props.module,
                userId: DocContext.getUserId,
                uuid: DocContext.getUuid,
            }, hasSqlWhere ? {
                sql: this.state.libParams[lib],
                kpv: kpv ? kpv : new Date().toISOString().slice(0, 10)
            } : {});

            // проверим наличие данных в кеше, если нет, то грузим
            if (!!this.state.libParams[lib] || !this.hasLibInCache(lib)) {
                fetchData.fetchDataPost(`${LIBS_URL}/${lib}`, params)
                    .then(response => {
                        if (response && 'data' in response) {
                            this.libs[lib] = response.data.result.result.data;

                            // save lib in cache
                            DocContext.setLib = {[lib]: this.libs[lib]};
                            libsCount--;
                            // отметка что справочник загружен
                            this.loadingLibs[lib] = false;

                            if (!libsCount && !this.state.loadedLibs) {
                                //all libs loaded;
                                this.setState({
                                    loadedLibs: true,
                                    warning: 'Kõik püsiandmed laaditud õnnestus',
                                    warningType: 'ok'
                                });

                            }

                        }

                    })
                    .catch(error => {
                        console.error('loadLibs error', error);
                    });
            } else {
                // берем данные из кеша
                this.libs[lib] = DocContext.getLib.filter(row => {
                    let kpv = this.docData.valid ? this.docData.valid : new Date().toISOString().slice(0, 10);
                    kpv = this.docData.kpv ? this.docData.kpv : kpv;
                    // есди в справочнике есть дата и она не пустая
                    if (!row.valid || new Date(kpv) <= new Date(row.valid)) {
                        return row;
                    }
                });
                this.loadingLibs[lib] = false;

                libsCount--;

                if (!libsCount && !this.state.loadedLibs) {
                    //all libs loaded;
                    this.setState({
                        loadedLibs: true,
                        warning: 'Kõik püsiandmed laaditud õnnestus',
                        warningType: 'ok'
                    });

                }

            }

            if (libsCount <= 1 && !this.state.loadedLibs) {
                //all libs loaded;
                this.setState({
                    loadedLibs: true,
                    warning: 'Kõik püsiandmed laaditud õnnestus',
                    warningType: 'ok'
                });

            }

        });
    }

    /**
     * проверит наличии в кеше данных и если нет, то вернет false
     * @param lib
     * @returns {boolean}
     */
    hasLibInCache(lib) {
        return (!DocContext.getLib || DocContext.getLib.length === 0) ? false : true;
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
        this.setState({gridRowEdit: true, gridRowEvent: 'edit', warning: '', warningStyle: ''});
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
        const rea = this.docData.gridConfig.filter(row => {
            if (row.id === name) {
                return row;
            }
        });


        let columnType = rea.length && rea[0].type ? rea[0].type : 'text';

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


    /**
     * уберет окно с отчетом
     */
    modalReportePageBtnClick(event) {
        let isReport = event && event == 'Ok' ? false : true;
        this.setState({isReport: isReport})
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
    isGridDataSave: false,
    reload: false
};

module
    .exports = DocumentTemplate;


