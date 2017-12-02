'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    flux = require('fluxify');

const Form = require('../../components/form/form.jsx'),
    InputText = require('../../components/input-text/input-text.jsx'),
    InputDate = require('../../components/input-date/input-date.jsx'),
    InputNumber = require('../../components/input-number/input-number.jsx'),
    DocCommon = require('../../components/doc-common/doc-common.jsx'),
    Select = require('../../components/select/select.jsx'),
    TextArea = require('../../components/text-area/text-area.jsx'),
    DataGrid = require('../../components/data-grid/data-grid.jsx'),
    GridButtonAdd = require('../../components/button-register/button-register-add/button-register-add.jsx'),
    GridButtonEdit = require('../../components/button-register/button-register-edit/button-register-edit.jsx'),
    GridButtonDelete = require('../../components/button-register/button-register-delete/button-register-delete.jsx'),
    DokProp = require('../../components/docprop/docprop.jsx'),
    relatedDocuments = require('../../mixin/relatedDocuments.jsx'),
    ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx'),
    DocToolBar = require('./../../components/doc-toolbar/doc-toolbar.jsx'),
    MenuToolBar = require('./../../mixin/menuToolBar.jsx'),
    validateForm = require('../../mixin/validateForm'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx'),
    styles = require('./smk-style');

const LIBDOK = 'SMK',
    LIBRARIES = ['asutused', 'kontod', 'dokProps', 'tunnus', 'project', 'nomenclature', 'aa'];

const docStore = require('../../stores/doc_store.js');

let now = new Date();

class Smk extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            edited: false,
            relations: this.props.data.relations,
            gridRowEdit: false,
            gridRowEvent: null
        };

        this.docData = this.props.data.row;
        this.gridData = this.props.data.details;
        this.gridConfig =  this.props.data.gridConfig;
        this.gridRowData = null;
        this.libs = this.createLibs();

        this.pages = [{pageName: 'Sissemakse korraldus'}];
        this.requiredFields = [
            {
                name: 'kpv',
                type: 'D',
                min: now.setFullYear(now.getFullYear() - 1),
                max: now.setFullYear(now.getFullYear() + 1)
            },
            {name: 'asutusid', type: 'I'},
            {name: 'nimi', type: 'C'},
            {name: 'summa', type: 'N'}
        ];

        this.handleToolbarEvents = this.handleToolbarEvents.bind(this);
        this.validation = this.validation.bind(this);
        this.modalPageClick = this.modalPageClick.bind(this);
        this.handleGridBtnClick = this.handleGridBtnClick.bind(this);
        this.addRow = this.addRow.bind(this);
        this.editRow = this.editRow.bind(this);
        this.deleteRow = this.deleteRow.bind(this);
        this.handleGridRowChange = this.handleGridRowChange.bind(this);
        this.validateGridRow = this.validateGridRow.bind(this);
        this.handleGridRowInput = this.handleGridRowInput.bind(this);
        this.createGridRow = this.createGridRow.bind(this);
        this.componentDidMount = this.componentDidMount.bind(this);
        this.handleInput = this.handleInput.bind(this);
    }

    /**
     * пишем исходные данные в хранилище, регистрируем обработчики событий
     */
    componentDidMount() {
        let self = this,
            data = this.props.data.row,
            details = this.props.data.details,
            gridConfig = this.props.data.gridConfig;

        window.addEventListener('beforeunload', this.componentCleanup);

        // сохраняем данные в хранилище
        flux.doAction('dataChange', data);
        flux.doAction('docIdChange', data.id);
        flux.doAction('detailsChange', details); // данные грида
        flux.doAction('gridConfigChange', gridConfig); // данные грида

        docStore.on('change:libs', (newValue, previousValue) => {
            let isChanged = false,
                libs = newValue,
                libsData = self.libs;

            if (newValue.length > 0) {

                libs.forEach(lib => {
                    if (self.libs[lib.id] && lib.data.length > 0) {
                        libsData[lib.id] = lib.data;
                        isChanged = true;
                    }
                });
            }

            if (isChanged) {
                self.setState({libs: libsData});
            }
        });

        // отслеживаем режим редактирования
        docStore.on('change:edited', function (newValue, previousValue) {
            if (newValue !== previousValue) {
                self.setState({edited: newValue});
            }
        });

        // если новый документ (id == 0)

        if (data.id == 0) {
            flux.doAction('editedChange', true);
            flux.doAction('savedChange', false);
        }

        // грузим справочники
        LIBRARIES.forEach(lib => {
            flux.doAction("loadLibs", lib);
        });

    }

    /**
     * снимет все подписки
     */
    componentCleanup() {
        docStore.off('change:edited');
        docStore.off('change:libs');
    }

    render () {
        // формируем зависимости
        relatedDocuments(this);

        let isEditeMode = this.state.edited,
            validationMessage = this.validation();

        const btnParams = {
            btnStart: {
                show: true
            }
        }

        return (
            <div>
                {MenuToolBar(btnParams, this.props.userData)}
                <Form pages={this.pages}
                  ref="form"
                  handlePageClick={this.handlePageClick}
                  disabled={isEditeMode}>
                <ToolbarContainer ref='toolbar-container'>
                    <div style={styles.docToolbarWarning}>
                        {validationMessage ? <span>{validationMessage}</span> : null }
                    </div>
                    <div>
                        <DocToolBar bpm={this.props.bpm}
                                    ref='doc-toolbar'
                                    edited={isEditeMode}
                                    docStatus={this.docData.doc_status}
                                    validator={this.validation}
                                    eventHandler={this.handleToolbarEvents}/>
                    </div>
                </ToolbarContainer>
                <div className='div-doc'>
                    <div style={styles.docRow}>
                        <DocCommon
                            ref='doc-common'
                            data={this.docData}
                            readOnly={!isEditeMode}/>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputText title='Number'
                                       name='number'
                                       value={this.docData.number}
                                       ref="input-number"
                                       onChange = {this.handleInput}
                                       readOnly={!isEditeMode}/>
                            <InputDate title='Kuupäev '
                                       name='kpv'
                                       value={this.docData.kpv}
                                       ref='input-kpv'
                                       onChange = {this.handleInput}
                                       readOnly={!isEditeMode}/>
                            <Select title="Arveldus arve"
                                    name='aa_id'
                                    libs="aa"
                                    value={this.docData.aa_id}
                                    data={this.libs['aa']}
                                    defaultValue={this.docData.pank}
                                    onChange = {this.handleInput}
                                    ref="select-aaId"
                                    readOnly={!isEditeMode}/>
                            <InputText title="Arve nr."
                                       name='arvnr'
                                       value={this.docData.arvnr || ''}
                                       ref="input-arvnr"
                                       onChange = {this.handleInput}
                                       readOnly={true}/>
                            <InputDate title='Maksepäev '
                                       name='maksepaev'
                                       value={this.docData.maksepaev}
                                       ref='input-maksepaev'
                                       onChange = {this.handleInput}
                                       readOnly={!isEditeMode}/>
                            <InputText title='Viitenumber '
                                       name='viitenr'
                                       value={this.docData.viitenr || ''}
                                       ref='input-viitenr'
                                       onChange = {this.handleInput}
                                       readOnly={!isEditeMode}/>
                        </div>
                        <div style={styles.docColumn}>
                            <DokProp title="Konteerimine: "
                                     name='doklausid'
                                     libs="dokProps"
                                     value={this.docData.doklausid}
                                     defaultValue={this.docData.dokprop}
                                     ref="dokprop"
                                     onChange = {this.handleInput}
                                     readOnly={!isEditeMode}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                            <TextArea title="Selgitus"
                                      name='selg'
                                      ref="textarea-selg"
                                      value={this.docData.selg || ''}
                                      onChange = {this.handleInput}
                                      readOnly={!isEditeMode}/>
                    </div>
                    {isEditeMode ?
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
                                  readOnly={!isEditeMode}
                                  ref="data-grid"/>
                    </div>
                    <div style={styles.docRow}>
                        <InputText title="Kokku: "
                                   name='summa'
                                   ref="input-summa"
                                   value={this.docData.summa}
                                   disabled={true}
                                   pattern="^[0-9]+(\.[0-9]{1,4})?$"/>
                    </div>
                    <div style={styles.docRow}>
                            <TextArea title="Märkused"
                                      name='muud'
                                      ref="textarea-muud"
                                      value={this.docData.muud || ''}
                                      onChange = {this.handleInput}
                                      readOnly={!isEditeMode}/>
                    </div>

                    {this.state.gridRowEdit ?
                        this.createGridRow()
                        : null}

                </div>
            </Form>
            </div>
        );
    }

    /**
     * toolbar event handler
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
     * валидация данных формы
     * @returns {string}
     */
    validation() {
        if (!this.state.edited) return '';

        let requiredFields = this.requiredFields;
        let warning = require('../../mixin/validateForm')(this, requiredFields);
        return warning;
    }

    /**
     * формирует объекты модального окна редактирования строки грида
     * @returns {XML}
     */
    createGridRow() {
        let style = styles.gridRow,
            row = Object.assign({}, this.gridRowData),
            validateMessage = '',
            modalObjects = ['btnOk', 'btnCancel'],
            buttonOkReadOnly = validateMessage.length > 0 || !this.state.checked;

        if (buttonOkReadOnly) {
            // уберем кнопку Ок
            modalObjects.splice(0, 1);
        }

        if (!row) return <div/>;

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
                            <Select title="Operatsioon"
                                    name='nomid'
                                    libs="nomenclature"
                                    data={nomData}
                                    value={row.nomid}
                                    defaultValue={row.kood}
                                    ref='nomid'
                                    onChange={this.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Partner"
                                    name='asutusid'
                                    libs="asutused"
                                    data={this.libs['asutused']}
                                    value={row.asutusid}
                                    defaultValue={row.asutus}
                                    ref='asutusid'
                                    onChange={this.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <InputText title='Arveldus arve: '
                                         name='aa'
                                         value={row.aa}
                                         bindData={false}
                                         ref='aa'
                                         onChange={this.handleGridRowInput}/>
                        </div>
                        <div style={styles.docRow}>
                            <InputNumber title='Summa: '
                                         name='summa'
                                         value={Number(row.summa)}
                                         bindData={false}
                                         ref='summa'
                                         onChange={this.handleGridRowInput}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Korr. konto"
                                    name='konto'
                                    libs="kontod"
                                    data={this.libs['kontod']}
                                    value={row.konto}
                                    ref='konto'
                                    collId="kood"
                                    onChange={this.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Tunnus:"
                                    name='tunnus'
                                    libs="tunnus"
                                    data={this.libs['tunnus']}
                                    value={row.tunnus}
                                    ref='tunnus'
                                    collId="kood"
                                    onChange={this.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Project:"
                                    name='proj'
                                    libs="project"
                                    data={this.libs['project']}
                                    value={row.proj}
                                    ref='project'
                                    collId="kood"
                                    onChange={this.handleGridRowChange}/>
                        </div>
                    </div>
                    <div><span>{validateMessage}</span></div>
                </ModalPage>
            </
                div >
        )
            ;
    }

    /**
     * управление модальным окном
     * @param gridEvent
     * @param data
     */
    handleGridRow(gridEvent, data) {
        this.gridRowData = data;
        this.setState({gridRowEdit: true, gridRowEvent: gridEvent});
    }

    /**
     * отработаем Ok из модального окна
     * @param btnEvent
     * @param data
     */
    modalPageClick(btnEvent, data) {
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
     * перерасчет итоговой суммы документа
     */
    recalcDocSumma() {
        let gridData = this.gridData;

        this.docData['summa'] = 0;
        this.gridData.forEach(row => {
            this.docData['summa'] += Number(row['summa']);
        });
    }

    /**
     * обработчик для события клик панели инструментов грида
     * @param btnName
     * @param id
     */
    handleGridBtnClick(btnName, id) {
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
     *  удалит активную строку
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
     * отслеживаем изменения данных на форме
     * @param name
     * @param value
     */
    handleGridRowChange(name, value) {
        if (value !== this.gridRowData[name] && name === 'nomid') {
            // произошло изменение услуги, обнулим значения
            this.gridRowData['summa'] = 0;
            this.gridRowData['nomid'] = value;
//            rowData['konto'] = value;

            // ищем по справочнику поля код и наименование
            let libData = this.libs['nomenclature'];
            libData.forEach(row => {
                if (row.id == value) {
                    this.gridRowData['kood'] = row.kood;
                    this.gridRowData['nimetus'] = row.name;
                }
            });
        }

        if (name === 'asutusid') {
            let libData = this.libs['asutused'];
            libData.forEach(row => {
                if (row.id == value) {
                    this.gridRowData['asutus'] = row.name;
                    return;
                }
            });
        }

        this.gridRowData[name] = value;
        this.forceUpdate();
        this.validateGridRow();

    }

    /**
     * Обработчик для изменения инпутов документов
     * @param name
     * @param value
     * @returns {boolean}
     */
    handleInput(name, value) {
        // изменения допустимы только в режиме редактирования
        if (!this.state.edited) {
            console.error('not in edite mode');
            return false;
        }

        this.docData[name] = value;
        this.forceUpdate();
    }

    /**
     * Обработчик на измеенения для инпутов строки грида
     * @param name
     * @param value
     */
    handleGridRowInput(name, value) {
        // пересчет сумм
        let rowData = this.gridRowData;

        this.gridRowData[name] = value;
        this.forceUpdate();
        this.validateGridRow();
    }

    /**
     *  will check values on the form and return string with warning
     */
    validateGridRow() {
        let warning = '';
        // только после проверки формы на валидность
        if (!this.gridRowData['nomid']) warning = warning + ' код услуги';
        if (!this.gridRowData['summa']) warning = warning + ' сумма';

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
        })
        return libs;
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

}

module.exports = Smk;
