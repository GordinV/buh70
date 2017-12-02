'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    flux = require('fluxify');

const
    Form = require('../../components/form/form.jsx'),
    InputText = require('../../components/input-text/input-text.jsx'),
    InputDate = require('../../components/input-date/input-date.jsx'),
    InputNumber = require('../../components/input-number/input-number.jsx'),
    DocCommon = require('../../components/doc-common/doc-common.jsx'),
    Select = require('../../components/select/select.jsx'),
//    SelectData = require('../../components/select-data/select-data.jsx'),
    TextArea = require('../../components/text-area/text-area.jsx'),
    DataGrid = require('../../components/data-grid/data-grid.jsx'),
    GridButtonAdd = require('../../components/button-register/button-register-add/button-register-add.jsx'),
    GridButtonEdit = require('../../components/button-register/button-register-edit/button-register-edit.jsx'),
    GridButtonDelete = require('../../components/button-register/button-register-delete/button-register-delete.jsx'),
    DokProp = require('../../components/docprop/docprop.jsx'),
    relatedDocuments = require('../../mixin/relatedDocuments.jsx'),
    ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx'),
    MenuToolBar = require('./../../mixin/menuToolBar.jsx'),
    DocToolBar = require('./../../components/doc-toolbar/doc-toolbar.jsx'),
    validateForm = require('../../mixin/validateForm'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx'),
    styles = require('./arve.styles');

const LIBDOK = 'ARV',
    LIBRARIES = ['asutused', 'kontod', 'dokProps', 'users', 'aa', 'tunnus', 'project', 'nomenclature'];

// Create a store
const docStore = require('../../stores/doc_store.js');

const now = new Date();

class Arve extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            edited: this.props.data.row.id == 0,
            showMessageBox: 'none',
            relations: this.props.data.relations,
            gridRowEdit: false,
            gridRowEvent: null,
            checked: false,
            warning: '',
        };

        this.docData = this.props.data.row;
        this.gridData = this.props.data.details;
        this.gridConfig = this.props.data.gridConfig;
        this.gridRowData = null;
        this.libs = this.createLibs();


        this.pages = [{pageName: 'Arve'}];
        this.requiredFields = [
            {
                name: 'kpv',
                type: 'D',
                min: now.setFullYear(now.getFullYear() - 1),
                max: now.setFullYear(now.getFullYear() + 1)
            },
            {
                name: 'tahtaeg',
                type: 'D',
                min: now.setFullYear(now.getFullYear() - 1),
                max: now.setFullYear(now.getFullYear() + 1)
            },
            {name: 'asutusid', type: 'N', min: null, max: null},
            {name: 'summa', type: 'N', min: -9999999, max: 999999}
        ];
        this.handleToolbarEvents = this.handleToolbarEvents.bind(this);
        this.validation = this.validation.bind(this);

        this.modalPageClick = this.modalPageClick.bind(this);
        this.handleGridBtnClick = this.handleGridBtnClick.bind(this);
        this.addRow = this.addRow.bind(this);
        this.handleGridRowChange = this.handleGridRowChange.bind(this);
        this.validateGridRow = this.validateGridRow.bind(this);
        this.handleGridRowInput = this.handleGridRowInput.bind(this);
        this.createGridRow = this.createGridRow.bind(this);
        this.handleInputChange = this.handleInputChange.bind(this);
    }

    componentDidMount() {

        if (window) {
            window.addEventListener('beforeunload', this.componentCleanup);
        }


        // пишем исходные данные в хранилище, регистрируем обработчики событий
        let self = this,
            data = Object.assign({}, self.props.data.row),
            details = Object.assign([], self.props.data.details),
            gridConfig = self.props.data.gridConfig;

        // сохраняем данные в хранилище
        flux.doAction('dataChange', data);
        flux.doAction('docIdChange', data.id);
        flux.doAction('detailsChange', details); // данные грида
        flux.doAction('gridConfigChange', gridConfig); // данные грида

        // грузим справочники
        LIBRARIES.forEach(lib => {
            flux.doAction("loadLibs", lib);
        });

        // если новый документ (id == 0)

        if (data.id == 0) {
            flux.doAction('editedChange', true);
            flux.doAction('savedChange', false);
        }

        // отслеживаем режим редактирования
        docStore.on('change:edited', function (newValue, previousValue) {
            if (newValue !== previousValue) {
                self.setState({edited: newValue});
            }
        });

        docStore.on('change:libs', (newValue) => {
            let isChanged = false,
                libsData = this.libs;

            if (newValue.length > 0) {

                newValue.forEach(lib => {
                    if (lib.id === 'dokProps') {
                        // оставим только данные этого документа

                    }
                    if (this.libs[lib.id] && lib.data.length > 0) {
                        libsData[lib.id] = lib.data;
                        isChanged = true;
                    }
                });
            }

            if (isChanged) {
                this.libs = libsData;
                this.forceUpdate();
            }
        });
    }

    /**
     * снимет все подписки
     */
    componentCleanup() {
/*
        docStore.off('change:edited');
        docStore.off('change:libs');
*/
    }

    componentWillUnmount() {
        this.componentCleanup();
    }

    render() {
        // формируем зависимости
        relatedDocuments(this);

        let isEditMode = this.state.edited,
            validationMessage = this.validation();

        const btnParams = {
            btnStart: {
                show: true
            }
        };

        return (
            <div>
                {MenuToolBar(btnParams, this.props.userData)}
                <Form pages={this.pages}
                      ref="form"
                      handlePageClick={this.handlePageClick}
                      disabled={isEditMode}>
                    <ToolbarContainer ref='toolbar-container'>
                        <div className='doc-toolbar-warning'>
                            {validationMessage ? <span>{validationMessage}</span> : null }
                        </div>
                        <div>
                            <DocToolBar bpm={this.props.bpm}
                                        ref='doc-toolbar'
                                        edited={isEditMode}
                                        docStatus={this.docData.doc_status}
                                        validator={this.validation}
                                        eventHandler={this.handleToolbarEvents}/>
                        </div>
                    </ToolbarContainer>
                    <div style={styles.doc}>
                        <div style={styles.docRow}>
                            <DocCommon
                                ref='doc-common'
                                data={this.docData}
                                readOnly={!isEditMode}/>
                        </div>
                        <div style={styles.docRow}>
                            <div style={styles.docColumn}>
                                <InputText ref="input-number"
                                           title='Number'
                                           name='number'
                                           value={this.docData.number}
                                           readOnly={!isEditMode}
                                           onChange={this.handleInputChange}/>
                                <InputDate title='Kuupäev '
                                           name='kpv' value={this.docData.kpv}
                                           ref='input-kpv'
                                           readOnly={!isEditMode}
                                           onChange={this.handleInputChange}/>
                                <InputDate title='Tähtaeg '
                                           name='tahtaeg'
                                           value={this.docData.tahtaeg}
                                           ref="input-tahtaeg"
                                           readOnly={!isEditMode}
                                           onChange={this.handleInputChange}/>
                                <Select title="Asutus"
                                        name='asutusid'
                                        libs="asutused"
                                        data={this.libs['asutused']}
                                        value={this.docData.asutusid}
                                        defaultValue={this.docData.asutus}
                                        ref="select-asutusid"
                                        btnDelete={isEditMode}
                                        onChange={this.handleInputChange}
                                        readOnly={!isEditMode}/>
                                {/*
                                 <SelectData title="Asutus widget"
                                 name='asutusid'
                                 value={this.docData.asutusid}
                                 defaultValue={this.docData.asutus}
                                 collName="asutus"
                                 ref="selectData-asutusid"
                                 onChange={this.handleInputChange}
                                 readOnly={!isEditeMode}/>
                                 */}
                                <InputText title='Lisa '
                                           name='lisa'
                                           value={this.docData.lisa}
                                           ref='input-lisa'
                                           readOnly={!isEditMode}
                                           onChange={this.handleInputChange}/>
                            </div>
                            <div style={styles.docColumn}>
                                <DokProp title="Konteerimine: "
                                         name='doklausid'
                                         libs="dokProps"
                                         value={this.docData.doklausid}
                                         defaultValue={this.docData.dokprop}
                                         ref="dokprop-doklausid"
                                         readOnly={!isEditMode}/>
                            </div>
                        </div>
                        <div style={styles.docRow}>
                        <TextArea title="Märkused"
                                  name='muud'
                                  ref="textarea-muud"
                                  onChange={this.handleInputChange}
                                  value={this.docData.muud || ''}
                                  readOnly={!isEditMode}/>
                        </div>

                        {isEditMode ?
                            <div style={styles.docRow}>
                                <ToolbarContainer
                                    ref='grid-toolbar-container'
                                    position={'left'}>
                                    <GridButtonAdd onClick={this.handleGridBtnClick} ref="grid-button-add"/>
                                    <GridButtonEdit onClick={this.handleGridBtnClick} ref="grid-button-edit"/>
                                    <GridButtonDelete onClick={this.handleGridBtnClick} ref="grid-button-delete"/>
                                </ToolbarContainer>
                            </div> : null}

                        <div style={styles.docRow}>
                            <DataGrid source='details'
                                      gridData={this.gridData}
                                      gridColumns={this.gridConfig}
                                      handleGridRow={this.handleGridRow}
                                      readOnly={!isEditMode}
                                      ref="data-grid"/>
                        </div>
                        <div style={styles.docRow}>
                            <InputText title="Summa "
                                       name='summa'
                                       ref="input-summa"
                                       value={this.docData.summa}
                                       disabled={true}
                                       onChange={this.handleInputChange}
                                       pattern="^[0-9]+(\.[0-9]{1,4})?$"/>
                            <InputText title="Käibemaks "
                                       name='kbm'
                                       ref="input-kbm"
                                       disabled={true}
                                       value={this.docData.kbm}
                                       onChange={this.handleInputChange}
                                       pattern="^[0-9]+(\.[0-9]{1,4})?$"/>
                        </div>
                        {this.state.gridRowEdit ?
                            this.createGridRow()
                            : null}
                    </div>
                </Form >
            </div>
        );
    }

    /**
     * валидация формы
     */
    validation() {
        if (!this.state.edited) return '';

        let requiredFields = this.requiredFields;
        return require('../../mixin/validateForm')(this, requiredFields);
    }


    /**
     * отработаем Ok из модального окна
     * @param btnEvent
     */
    modalPageClick(btnEvent) {
        if (btnEvent == 'Ok') {

            // ищем по ид строку в данных грида, если нет, то добавим строку
            if (!this.gridData.some(row => {
                    if (row.id === this.gridRowData.id) return true;
                })) {
                // вставка новой строки
                this.gridData.splice(0, 0, this.gridRowData);
            } else {
                this.gridData = this.gridData.map(row => {
                    if (row.id === this.gridRowData.id) {
                        // нашли, замещаем
                        return this.gridRowData;
                    } else {
                        return row;
                    }
                })
            }

        }

        this.recalcDocSumma();
        this.setState({gridRowEdit: false});

    }

    /**
     * Обработчик события клик по вкладке
     * @param page
     */
    handlePageClick(page) {
        if (page.docId) {
            document.location.href = "/document/" + page.docTypeId + page.docId;
        }
    }

    /**
     * метод вызывается при выборе задачи
     * @param e
     */
    handleSelectTask(e) {
        return e.target.value;
    }

    /**
     *  toolbar event handler
     * @param event
     */
    handleToolbarEvents(event) {
        switch (event) {
            case 'CANCEL':
                this.docData = JSON.parse(flux.stores.docStore.backup.docData); // восстановим данные
                this.gridData = JSON.parse(flux.stores.docStore.backup.gridData);

                if (this.state.warning !== '') {
                    this.setState({warning: ''});
                } else {
                    this.forceUpdate();
                }
                break;
            default:
                console.error('handleToolbarEvents, no event handler for ', event);
        }
    }

    /**
     * Обработчик изменений инпутов
     * @param inputName
     * @param inputValue
     * @returns {boolean}
     */
    handleInputChange(inputName, inputValue) {

        // изменения допустимы только в режиме редактирования
        if (!this.state.edited) {
            console.error('not in edite mode');
            return false;
        }

        this.docData[inputName] = inputValue;
        this.forceUpdate();
    }

    /**
     * Подготовка параметров для панели инструментов
     * @param isEditMode
     * @returns {{btnAdd: {show: boolean, disabled: *}, btnEdit: {show: boolean, disabled: *}, btnPrint: {show: boolean, disabled: boolean}, btnSave: {show: *, disabled: boolean}}}
     */
    prepaireToolBarParameters(isEditMode) {
        return {
            btnAdd: {
                show: !isEditMode,
                disabled: isEditMode
            },
            btnEdit: {
                show: !isEditMode,
                disabled: isEditMode
            },
            btnPrint: {
                show: true,
                disabled: true
            },
            btnSave: {
                show: isEditMode,
                disabled: false
            }
        };
    }

    /**
     * обработчик для событий клик панели инструментов грида
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
     * удалит активную строку
     */
    deleteRow() {
        let gridActiveRow = this.refs['data-grid'].state.activeRow;

        this.gridData.splice(gridActiveRow, 1);

        // перерасчет итогов
        this.recalcDocSumma();

        // изменим состояние
        this.forceUpdate();
    }

    /**
     * откроет активную строку для редактирования
     */
    editRow() {
        this.gridRowData = this.gridData[this.refs['data-grid'].state.activeRow];

        // откроем модальное окно для редактирования
        this.setState({gridRowEdit: true, gridRowEvent: 'edit'});
    }

    /**
     * добавит в состояние новую строку
     */
    addRow() {
        let newRow = {};

        for (let i = 0; i < this.gridConfig.length; i++) {
            let field = this.gridConfig[i].id;
            newRow[field] = '';
        }

        newRow.id = 'NEW' + Math.random(); // генерим новое ид

        this.gridRowData = newRow;
        // откроем модальное окно для редактирования
        this.setState({gridRowEdit: true, gridRowEvent: 'add'});

    }

    /**
     * Создаст компонет строки грида
     * @returns {XML}
     */
    createGridRow() {
        let validateMessage = '',
            modalObjects = ['btnOk', 'btnCancel'],
            buttonOkReadOnly = validateMessage.length > 0 || !this.state.checked;

        if (buttonOkReadOnly) {
            // уберем кнопку Ок
            modalObjects.splice(0, 1);
        }


        if (!this.gridRowData) return <div/>;

        let nomData = this.libs['nomenclature'].filter(lib => {
            if (!lib.dok || lib.dok === LIBDOK) return lib;
        });

        return (<div className='.modalPage'>
            <ModalPage
                modalObjects={modalObjects}
                ref="modalpage-grid-row"
                show={true}
                modalPageBtnClick={this.modalPageClick}
                modalPageName='Rea lisamine / parandamine'>
                <div ref="grid-row-container">
                    <div style={styles.docRow}>
                        <Select title="Teenus"
                                name='nomid'
                                libs="nomenclature"
                                data={nomData}
                                readOnly={false}
                                value={this.gridRowData.nomid}
                                defaultValue={this.gridRowData.kood}
                                ref='nomid'
                                placeholder='Teenuse kood'
                                onChange={this.handleGridRowChange}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputNumber title='Kogus '
                                     name='kogus'
                                     value={Number(this.gridRowData.kogus)}
                                     readOnly={false}
                                     disabled={false}
                                     bindData={false}
                                     ref='kogus'
                                     className='ui-c2'
                                     onChange={this.handleGridRowInput}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputNumber title='Hind '
                                     name='hind'
                                     value={Number(this.gridRowData.hind)}
                                     readOnly={false}
                                     disabled={false}
                                     bindData={false}
                                     ref='hind'
                                     className='ui-c2'
                                     onChange={this.handleGridRowInput}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputNumber title='Kbm-ta: '
                                     name='kbmta'
                                     value={Number(this.gridRowData.kbmta)}
                                     disabled={true}
                                     bindData={false}
                                     ref='kbmta'
                                     className='ui-c2'
                                     onChange={this.handleGridRowChange}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputNumber title='Kbm: '
                                     name='kbm'
                                     value={Number(this.gridRowData.kbm)}
                                     disabled={true}
                                     bindData={false}
                                     ref='kbm'
                                     className='ui-c2'
                                     onBlur={this.handleGridRowInput}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputNumber title='Summa: '
                                     name='Summa'
                                     value={Number(this.gridRowData.summa)}
                                     disabled={true}
                                     bindData={false}
                                     ref='summa'
                                     className='ui-c2'
                                     onChange={this.handleGridRowInput}/>
                    </div>
                </div>
                <div><span>{validateMessage}</span></div>
            </ModalPage>
        </div>);
    }

    /**
     * отслеживаем изменения данных на форм
     * @param name
     * @param value
     */
    handleGridRowChange(name, value) {
        if (value !== this.gridRowData[name] && name === 'nomid') {
            // произошло изменение услуги, обнулим значения
            this.gridRowData['kogus'] = 0;
            this.gridRowData['hind'] = 0;
            this.gridRowData['summa'] = 0;
            this.gridRowData['kbm'] = 0;
            this.gridRowData['kbmta'] = 0;
            this.gridRowData['nomid'] = value;
        }
        // ищем по справочнику поля код и наименование

        let libData = this.libs['nomenclature'];
        libData.forEach(row => {
            if (row.id == value) {
                this.gridRowData['kood'] = row.kood;
                this.gridRowData['nimetus'] = row.name;
            }
        });

        this.gridRowData[name] = value;
//        this.forceUpdate();
        this.validateGridRow();

    }

    /**
     * Обработчик для строки грида
     * @param name
     * @param value
     */
    handleGridRowInput(name, value) {
        this.gridRowData[name] = value;

        // пересчет сумм
        this.recalcRowSumm();
//        this.forceUpdate();
        this.validateGridRow();
    }

    /**
     * перерасчет суммы строки и расчет налога
     */
    recalcRowSumm() {
        this.gridRowData['kogus'] = Number(this.gridRowData.kogus);
        this.gridRowData['hind'] = Number(this.gridRowData.hind);
        this.gridRowData['kbmta'] = Number(this.gridRowData['kogus']) * Number(this.gridRowData['hind']);
        this.gridRowData['kbm'] = Number(this.gridRowData['kbmta'] * 0.20); // @todo врменно
        this.gridRowData['summa'] = Number(this.gridRowData['kbmta']) + Number(this.gridRowData['kbm']);
    }

    /**
     * Перерасчет итоговых сумм документа
     */
    recalcDocSumma() {
        this.docData['summa'] = 0;
        this.docData['kbm'] = 0;
        this.gridData.forEach(row => {
            this.docData['summa'] += Number(row['summa']);
            this.docData['kbm'] += Number(row['kbm']);
        });
    }

    /**
     * will check values on the form and return string with warning
     */
    validateGridRow() {
        let warning = '';

        // только после проверки формы на валидность
        if (!this.gridRowData['nomid']) warning = warning + ' код услуги';
        if (!this.gridRowData['kogus']) warning = warning + ' кол-во';
        if (!this.gridRowData['hind']) warning = warning + ' цена';

        if (warning.length > 2) {
            // есть проблемы
            warning = 'Отсутсвуют данные:' + warning;
        }
        this.setState({checked: true, warning: warning});
    }

    /**
     * вернет объект библиотек документа
     * @returns {{}}
     */
    createLibs() {
        let libs = {};
        LIBRARIES.forEach((lib) => {
            libs[lib] = [];
        });
        return libs;
    }
}

Arve.propTypes = {
    data: PropTypes.object.isRequired,
    bpm: PropTypes.array,
    edited: PropTypes.bool,
    showMessageBox: PropTypes.string,
    gridData: PropTypes.array,
    relations: PropTypes.array,
    gridConfig: PropTypes.array,
    gridRowEdit: PropTypes.bool,
    gridRowEvent: PropTypes.string,
    gridRowData: PropTypes.object,
    libs: PropTypes.object,
    checked: PropTypes.bool,
    warning: PropTypes.string

};


/*
 Arve.defaultProps = {
 disabled: false,
 show: true
 };
 */


module.exports = Arve;


