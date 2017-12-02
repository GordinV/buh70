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
    TextArea = require('../../components/text-area/text-area.jsx'),
    DataGrid = require('../../components/data-grid/data-grid.jsx'),
    GridButtonAdd = require('../../components/button-register/button-register-add/button-register-add.jsx'),
    GridButtonEdit = require('../../components/button-register/button-register-edit/button-register-edit.jsx'),
    GridButtonDelete = require('../../components/button-register/button-register-delete/button-register-delete.jsx'),
    relatedDocuments = require('../../mixin/relatedDocuments.jsx'),
    ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx'),
    DocToolBar = require('./../../components/doc-toolbar/doc-toolbar.jsx'),
    MenuToolBar = require('./../../mixin/menuToolBar.jsx'),
    validateForm = require('../../mixin/validateForm'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx'),
    styles = require('./journal-styles.js');

const LIBRARIES = ['asutused', 'kontod', 'tunnus', 'project'];

// Create a store
const docStore = require('../../stores/doc_store.js');

class Journal extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            edited: false,
            showMessageBox: 'none',
            gridRowEdit: false,
            gridRowEvent: null,
            checked: false,
            relations: this.props.data.relations,
            warning: ''
        };

        this.docData = this.props.data.row;
        this.gridData = this.props.data.details;
        this.gridRowData = null;
        this.libs = this.createLibs();


        this.pages = [{pageName: 'Journal'}];
        this.addRow = this.addRow.bind(this);
        this.editRow = this.editRow.bind(this);
        this.deleteRow = this.deleteRow.bind(this);
        this.handleGridBtnClick = this.handleGridBtnClick.bind(this);
        this.handleGridRowChange = this.handleGridRowChange.bind(this);
        this.validateGridRow = this.validateGridRow.bind(this);
        this.handleGridRowInput = this.handleGridRowInput.bind(this);
        this.createGridRow = this.createGridRow.bind(this);
        this.modalPageClick = this.modalPageClick.bind(this);
        this.validation = this.validation.bind(this);
        this.handleToolbarEvents = this.handleToolbarEvents.bind(this);
        this.handleInput = this.handleInput.bind(this);

    }

    /**
     * пишем исходные данные в хранилище, регистрируем обработчики событий
     */
    componentDidMount() {
        let self = this;

        // сохраняем данные в хранилище
        flux.doAction('dataChange', this.docData);
        flux.doAction('docIdChange', this.docData.id);
        flux.doAction('detailsChange', this.gridData); // данные грида
        flux.doAction('gridConfigChange', this.props.data.gridConfig); // данные грида
        flux.doAction('gridName', 'journal-grid-row'); // задаем имя компонента строки грида (для редактирования


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
                    if (this.libs[lib.id] && lib.data.length > 0) {
                        libsData[lib.id] = lib.data;
                        isChanged = true;
                    }
                });
            }

            if (isChanged) {
                self.setState({libs: libsData});
            }
        });


        // грузим справочники
        LIBRARIES.forEach(lib => {
            flux.doAction("loadLibs", lib);
        });

        if (this.docData.id == 0) {
            flux.doAction('editedChange', true);
            flux.doAction('savedChange', false);
        }

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

    render() {
        let bpm = this.props.bpm,
            isEditMode = this.state.edited,
            validationMessage = this.validation(),
            gridData = this.gridData,
            gridColumns = this.props.data.gridConfig;

        // формируем зависимости
        relatedDocuments(this);

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
                            <DocToolBar bpm={bpm}
                                        ref='doc-toolbar'
                                        edited={isEditMode}
                                        docStatus={this.docData.doc_status}
                                        validator={this.validation}
                                        eventHandler={this.handleToolbarEvents}/>
                        </div>
                    </ToolbarContainer>
                    <div style={styles.doc}>
                        <div style={styles.docRow}>
                            <DocCommon ref='doc-common'
                                       data={this.docData}
                                       readOnly={!isEditMode}/>
                        </div>
                        <div style={styles.docColumn}>
                            <InputText
                                title='Number'
                                name='number'
                                value={String(this.docData.number)}
                                disabled={true}
                                onChange={this.handleInput}
                                ref="input-number"
                                readOnly={true}/>
                            <InputDate title='Kuupäev '
                                       name='kpv'
                                       value={this.docData.kpv}
                                       ref='input-kpv'
                                       onChange={this.handleInput}
                                       readOnly={!isEditMode}/>
                            <Select title="Partner"
                                    name='asutusid'
                                    libs="asutused"
                                    data={this.libs['asutused']}
                                    value={this.docData.asutusid}
                                    collId='id'
                                    defaultValue={this.docData.asutus}
                                    onChange={this.handleInput}
                                    ref="select-asutusid"
                                    readOnly={!isEditMode}/>
                            <InputText
                                title='Dokument '
                                name='dok'
                                value={this.docData.dok}
                                ref='input-dok'
                                onChange={this.handleInput}
                                readOnly={!isEditMode}/>
                        </div>
                        <div style={styles.docRow}>
                            <TextArea title="Selgitus"
                                      name='selg'
                                      ref="textarea-selg"
                                      value={this.docData.selg}
                                      onChange={this.handleInput}
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
                                      gridData={gridData}
                                      gridColumns={gridColumns}
                                      handleGridRow={this.handleGridRow}
                                      readOnly={!isEditMode}
                                      ref="data-grid"/>
                        </div>
                        <div style={styles.docRow}>
                            <InputNumber
                                title="Summa: "
                                name='summa'
                                ref="input-summa"
                                value={Number(this.docData.summa)}
                                disabled={true}
                                pattern="^[0-9]+(\.[0-9]{1,4})?$"/>
                        </div>
                        <div style={styles.docRow}>
                        <TextArea title="Märkused"
                                  name='muud'
                                  ref="textarea-muud"
                                  value={this.docData.muud || ''}
                                  onChange={this.handleInput}
                                  readOnly={!isEditMode}/>
                        </div>
                        {this.state.gridRowEdit ?
                            this.createGridRow()
                            : null}
                    </div>

                </Form>
            </div>
        );
    }

    validation() {
        if (!this.state.edited) return '';

        let requiredFields = this.requiredFields;

        return require('../../mixin/validateForm')(this, requiredFields);
    }

    /**
     * Обработчик для инпутов
      * @param name
     * @param value
     * @returns {boolean}
     */
    handleInput(name, value) {
        console.log('called input handler', name, value);
        // изменения допустимы только в режиме редактирования
        if (!this.state.edited) {
            console.error('not in edite mode');
            return false;
        }

        this.docData[name] = value;
        this.forceUpdate();
    }

    /**
     *  управление модальным окном
     * @param gridEvent
     */
    handleGridRow(gridEvent) {
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
                });
            }

        }

        this.recalcDocSumma();
        this.setState({gridRowEdit: !!this.state.warning});
    }

    /**
     * Обработчик события клика на вкладку страницы
     * @param page
     */
    handlePageClick(page) {
        if (page.docId) {
            document.location.href = "/document/" + page.docTypeId + page.docId;
        }
    }

    /**
     * Создаст и вернет компонент сроки грида
     * @returns {XML}
     */
    createGridRow() {
        let row = this.gridRowData,
            validateMessage = this.state.warning,
            buttonOkReadOnly = validateMessage.length > 0 || !this.state.checked,
            modalObjects = ['btnOk', 'btnCancel'];

        if (buttonOkReadOnly) {
            // уберем кнопку Ок
            modalObjects.splice(0, 1);
        }

        if (!row) return <div/>;

        return (<div className='.modalPage'>
            <ModalPage
                modalObjects={modalObjects}
                ref="modalpage-grid-row"
                show={true}
                modalPageBtnClick={this.modalPageClick}
                modalPageName='Rea lisamine / parandamine'>
                <div ref="grid-row-container">
                    <div style={styles.docRow}>
                        <Select title="Deebet"
                                name='deebet'
                                libs="kontod"
                                data={this.libs['kontod']}
                                readOnly={false}
                                value={row.deebet}
                                ref='deebet'
                                collId="kood"
                                onChange={this.handleGridRowChange}/>
                    </div>
                    <div style={styles.docRow}>
                        <Select title="Kreedit"
                                name='kreedit'
                                data={this.libs['kontod']}
                                readOnly={false}
                                value={row.kreedit}
                                ref='kreedit'
                                collId="kood"
                                onChange={this.handleGridRowChange}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputNumber title='Summa: '
                                     name='summa'
                                     value={row.summa}
                                     disabled={false}
                                     bindData={false}
                                     ref='summa'
                                     onChange={this.handleGridRowInput}/>
                    </div>
                    <div style={styles.docRow}>
                        <Select title="Tunnus"
                                name='tunnus'
                                libs="tunnus"
                                data={this.libs['tunnus']}
                                readOnly={false}
                                value={row.tunnus}
                                ref='tunnus'
                                placeholder='Tunnus'
                                collId="kood"
                                onChange={this.handleGridRowChange}/>
                    </div>
                    <div style={styles.docRow}>
                        <Select title="Project"
                                name='proj'
                                libs="project"
                                data={this.libs['project']}
                                readOnly={false}
                                value={row.proj}
                                ref='proj'
                                placeholder='Projekt'
                                collId="kood"
                                onChange={this.handleGridRowChange}/>
                    </div>
                </div>
                <div><span>{validateMessage}</span></div>
            </ModalPage>
        </div>);
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
     * Обработчик для строк грида
     * @param name
     * @param value
     */
    handleGridRowInput(name, value) {
        if (name == 'number') {
            //@todo hardcode, переписать с учетом типа поля из конфигурации грида
            this.gridRowData[name] = Number(value);
        } else {
            this.gridRowData[name] = value;
        }

        // перерасчет итогов
        this.recalcDocSumma();
        this.forceUpdate();
        this.validateGridRow();
    }

    /**
     * удалит активную строку
     */
    deleteRow() {
        this.gridData.splice(this.refs['data-grid'].state.activeRow, 1);

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
        let gridColumns = this.props.data.gridConfig,
            newRow = {};

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
     * Перерасчет итоговых сумм
     * @returns {*}
     */
    recalcDocSumma() {
        let gridData = this.gridData;

        this.docData['summa'] = 0;

        gridData.forEach(row => {
            this.docData['summa'] += Number(row['summa']);
        });
    }

    /**
     * will check values on the form and return string with warning
     */
    validateGridRow() {
        let warning = '';

        // только после проверки формы на валидность
        if (!this.gridRowData['deebet']) warning = warning + ' Дебет';
        if (!this.gridRowData['kreedit']) warning = warning + ' Кредит';
        if (!this.gridRowData['summa']) warning = warning + ' Сумма';

        if (warning.length > 2) {
            // есть проблемы
            warning = 'Отсутсвуют данные:' + warning;
        }

        this.setState({checked: true, warning: warning});
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

Journal.propTypes = {
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

module.exports = Journal;
