'use strict';
const React = require('react');
const PropTypes = require('prop-types');

const DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    Select = require('../../../components/select/select.jsx'),
    SelectData = require('../../../components/select-data/select-data.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    DokProp = require('../../../components/docprop/docprop.jsx'),
    relatedDocuments = require('../../../mixin/relatedDocuments.jsx'),
    ModalPage = require('./../../../components/modalpage/modalPage.jsx'),
    Loading = require('./../../../components/loading/index.jsx'),
    ButtonUuendaLib = require('../../../components/button-register/button-uuenda-lib/index.jsx'),
    styles = require('./smk-style');

const DOC_TYPE_ID = 'SMK';
const DocContext = require('./../../../doc-context.js');

const LIBRARIES = [
    {id: 'kontod', filter: ''},
    {id: 'dokProps', filter: `WHERE kood = 'SMK'`},
    {id: 'users', filter: ''},
    {id: 'tunnus', filter: ''},
    {id: 'project', filter: ''},
    {id: 'nomenclature', filter: `where dok in ('MK','SMK')`},
    {id: 'asutused', filter: `where id in (select asutusid from lapsed.vanemad)`},
    {id: 'vanem', filter: ``},
    {id: 'aa', filter: ''}
];

class Smk extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            loadedData: false,
            lapsId: null,
            module: this.props.module,
            isAskToCreateFromArv: true, // если указан счет, а док.ид = 0 , то можно создпть ордер по счету
            getSMK: false,
            arvId: 0
        };

        this.createGridRow = this.createGridRow.bind(this);
        this.recalcDocSumma = this.recalcDocSumma.bind(this);
        this.recalcRowSumm = this.recalcRowSumm.bind(this);

        this.renderer = this.renderer.bind(this);
        this.gridValidateFields = this.gridValidateFields.bind(this);
        this.modalPageBtnClick = this.modalPageBtnClick.bind(this);

        this.pages = [{pageName: 'Sissemakse korraldus', docTypeId: 'SMK'}];
    }

    componentDidMount() {
        if (this.props.history && this.props.history.location.state) {
            let lapsId = this.props.history.location.state.lapsId;
            let module = this.props.history.location.state.module ? this.props.history.location.state.module : 'lapsed';
            this.setState({lapsId: lapsId, module: module});
        }

    }


    render() {
        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId={DOC_TYPE_ID}
                                 history={this.props.history}
                                 module={this.state.module}
                                 initData={this.props.initData}
                                 reload={true}
                                 libs={LIBRARIES}
                                 pages={this.pages}
                                 renderer={this.renderer}
                                 createGridRow={this.createGridRow}
                                 gridValidator={this.gridValidateFields}
                                 recalcDoc={this.recalcDocSumma}
                                 focusElement={'input-number'}

        />

    }

    /**
     * Вернет кастомные компоненты документа
     * @returns {XML}
     */
    renderer(self) {
        if (!self || !self.docData || !self.docData.kpv) {
            return (<div style={styles.doc}>
                <Loading label={'Laadimine...'}/>
            </div>);
        }

        let isEditeMode = self.state.edited;

        // формируем зависимости
        if (self.docData.relations) {
            relatedDocuments(self);
        }

        let isNewDoc = !self.docData.id || self.docData.id === 0;
        if ((!self.docData.id || self.docData.id === 0) && self.docData.arvid && this.state.isAskToCreateFromArv) {
            this.setState({getSMK: true, isAskToCreateFromArv: false, arvId: self.docData.arvid});
        }

        // queryArvTasu
        let gridArvData = self.docData.queryArvTasu,
            gridArvColumns = self.docData.gridArvConfig;


        return (
            <div>
                <div className='div-doc'>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputText title='Number'
                                       name='number'
                                       value={String(self.docData.number || '')}
                                       ref="input-number"
                                       onChange={self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                            <InputDate title='Kuupäev '
                                       name='kpv'
                                       value={self.docData.kpv || '01-07-2020'}
                                       ref='input-kpv'
                                       onChange={self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                            <Select title="Arveldus arve"
                                    name='aa_id'
                                    libs="aa"
                                    value={Number(self.docData.aa_id) || 0}
                                    data={self.libs['aa']}
                                    defaultValue={String(self.docData.pank) || ''}
                                    onChange={self.handleInputChange}
                                    ref="select-aaId"
                                    readOnly={!isEditeMode}/>

                            <InputDate title='Maksepäev '
                                       name='maksepaev'
                                       value={self.docData.maksepaev || ''}
                                       ref='input-maksepaev'
                                       onChange={self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                            <InputText title='Viitenumber '
                                       name='viitenr'
                                       value={self.docData.viitenr || ''}
                                       ref='input-viitenr'
                                       onChange={self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                        </div>
                        <div style={styles.docColumn}>
                            <DokProp title="Konteerimine: "
                                     name='doklausid'
                                     data={self.libs['dokProps']}
                                     dokTypeId={'SMK'}
                                     value={Number(self.docData.doklausid) || 0}
                                     defaultValue={self.docData.dokprop || ''}
                                     history={this.props.history}
                                     ref="dokprop"
                                     onChange={self.handleInputChange}
                                     readOnly={!isEditeMode}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <TextArea title="Selgitus"
                                  name='selg'
                                  ref="textarea-selg"
                                  value={self.docData.selg || ''}
                                  onChange={self.handleInputChange}
                                  readOnly={!isEditeMode}/>
                    </div>

                    <div style={styles.docRow}>
                        <DataGrid source='details'
                                  gridData={self.docData.gridData}
                                  gridColumns={self.docData.gridConfig}
                                  showToolBar={isEditeMode}
                                  handleGridRow={self.handleGridRow}
                                  handleGridBtnClick={self.handleGridBtnClick}
                                  readOnly={!isEditeMode}
                                  style={styles.grid.headerTable}
                                  ref="data-grid"/>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>

                            <InputText title="Kokku: "
                                       name='summa'
                                       ref="input-summa"
                                       value={String(self.docData.summa) || '0.00'}
                                       width='auto'
                                       disabled={true}/>
                        </div>
                        <div style={styles.docColumn}>
                            <InputText title="Määramata summa: "
                                       name='mk_jaak'
                                       ref="input-jaak"
                                       value={String(self.docData.jaak) || '0.00'}
                                       width='auto'
                                       disabled={true}/>
                        </div>
                    </div>

                </div>
                <div style={styles.docRow}>
                    <TextArea title="Märkused"
                              name='muud'
                              ref="textarea-muud"
                              value={self.docData.muud || ''}
                              onChange={self.handleInputChange}
                              readOnly={!isEditeMode}/>
                </div>

                {self.state.gridRowEdit ?
                    this.createGridRow(self)
                    : null}

                <ModalPage ref='modalpageCreateOrder'
                           modalPageBtnClick={this.modalPageBtnClick}
                           modalPageName='Kas koosta SMK'
                           show={this.state.getSMK}>
                    Kas koosta SMK?
                </ModalPage>

                <br/>
                <div style={styles.docRow}>
                    <label ref="label">
                        {'Arved'}
                    </label>
                </div>
                <div style={styles.docRow}>
                    <DataGrid source='arved'
                              gridData={gridArvData}
                              gridColumns={gridArvColumns}
                              showToolBar={false}
                              handleGridBtnClick={self.handleGridBtnClick}
                              docTypeId={'arv'}
                              readOnly={true}
                              style={styles.grid.headerTable}
                              ref="arved-data-grid"/>
                </div>


            </div>
        );
    }

    /**
     * will create SMK
     */
    modalPageBtnClick(btnEvent) {
        this.setState({getSMK: false});
        if (btnEvent === 'Ok') {
            const Doc = this.refs['document'];
            let api = `/calc/koostaMK`;

            const params = {
                docTypeId: DOC_TYPE_ID,
                module: this.props.module ? this.props.module : DocContext.module,
                userId: DocContext.userData.userId,
                uuid: DocContext.userData.uuid,
                docs: [Number(this.state.arvId)],
                seisuga: Doc.docData && Doc.docData.kpv ? Doc.docData.kpv : null,
                context: DocContext[api] ? DocContext[api] : null,
                taskName: 'koostaMK'
            };

            Doc.fetchData('Post', api, {data: params}).then((response) => {
                if (response && response.error_message) {
                    Doc.setState({
                        warning: `viga: ${response.error_message}`,
                        warningType: 'error'
                    });
                } else {
                    if (response && response.result) {
                        let newDocId = response.data && response.data && response.data.result && response.data.result.doc_id ? response.data.result.doc_id : 0;
                        Doc.setState({
                            warning: 'Edukalt, suunatan ...',
                            warningType: 'ok'
                        });

                        // переходим на созданнй док
                        if (newDocId) {
                            setTimeout(() => {
                                const current = `/${this.props.module ? this.props.module : DocContext.module}/smk/${newDocId}`;
                                this.props.history.replace(`/reload`);
                                setTimeout(() => {
                                    this.props.history.replace(current);
                                });

                            }, 2000);
                        }
                    } else {
                        Doc.setState({
                            warning: 'Tekkis viga',
                            warningType: 'error'
                        });
                    }
                }

            }).catch((error) => {
                console.error('api call error', error);
                Doc.setState({
                    warning: `Viga ${error}`,
                    warningType: 'error'
                });
            });
        }
    }

    /**
     * формирует объекты модального окна редактирования строки грида
     * @returns {XML}
     */
    createGridRow(self) {
        let row = self.gridRowData ? self.gridRowData : {},
            validateMessage = '', // self.state.warning
            buttonOkReadOnly = validateMessage.length > 0 || !self.state.checked,
            modalObjects = ['btnOk', 'btnCancel'];

        if (buttonOkReadOnly) {
            // уберем кнопку Ок
            modalObjects.splice(0, 1);
        }

        if (!row) return <div/>;

        // наложить фильтр на список плательщиков, если указан витенумбер
        let data = self.libs['asutused'];
        if (self.docData.viitenr && self.libs['vanem'] && self.libs['vanem'].length && self.libs['asutused'] && self.libs['asutused'].length) {

            // найти родителя
            let vanem = self.libs['vanem'].filter(row => row.viitenr === self.docData.viitenr);

            if (vanem && vanem.length) {
                // нашли родителя, ставим фильтр
                data = data.filter(row => !!vanem.find(kiri => kiri.id === row.id));
            }
        }

        // сортировка по ид коду
        data = data.sort((a, b) => {
            return a.kood.localeCompare(b.kood, 'en', {sensitivity: 'base'})
        });

        return (<div className='.modalPage'>
                <ModalPage
                    modalObjects={modalObjects}
                    ref="modalpage-grid-row"
                    show={true}
                    modalPageBtnClick={self.modalPageClick}
                    modalPageName='Rea lisamine / parandamine'>
                    <div ref="grid-row-container">
                        <div style={styles.docRow}>
                            <Select title="Operatsioon"
                                    name='nomid'
                                    data={self.libs['nomenclature']}
                                    value={row.nomid || 0}
                                    collId='id'
                                    defaultValue={row.kood || ''}
                                    ref='nomid'
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Partner"
                                    name='asutusid'
                                    data={data}
                                    value={row.asutusid}
                                    defaultValue={row.asutus || ''}
                                    collId='id'
                                    ref='asutusid'
                                    onChange={self.handleGridRowChange}/>
                            <ButtonUuendaLib
                                self={self}
                                lib={'asutused'}
                            />

                        </div>
                        <div style={styles.docRow}>
                            <InputText title='Arveldus arve: '
                                       name='aa'
                                       value={row.aa || ''}
                                       bindData={false}
                                       ref='aa'
                                       onChange={self.handleGridRowInput}/>
                        </div>
                        <div style={styles.docRow}>
                            <InputNumber title='Summa: '
                                         name='summa'
                                         value={Number(row.summa)}
                                         bindData={false}
                                         ref='summa'
                                         onChange={self.handleGridRowInput}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Korr. konto"
                                    name='konto'
                                    libs="kontod"
                                    data={self.libs['kontod']}
                                    value={row.konto}
                                    ref='konto'
                                    collId="kood"
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Tunnus:"
                                    name='tunnus'
                                    libs="tunnus"
                                    data={self.libs['tunnus']}
                                    value={row.tunnus}
                                    ref='tunnus'
                                    collId="kood"
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Project:"
                                    name='proj'
                                    libs="project"
                                    data={self.libs['project']}
                                    value={row.proj}
                                    ref='project'
                                    collId="kood"
                                    onChange={self.handleGridRowChange}/>
                        </div>
                    </div>
                    <div><span>{validateMessage}</span></div>
                </ModalPage>
            </
                div>
        )
            ;
    }

    /**
     * перерасчет итоговой суммы документа
     */
    recalcDocSumma() {
        let doc = this.refs['document'];
        doc.docData['summa'] = 0;
        doc.docData.gridData.forEach(row => {
            doc.docData['summa'] += Number(row['summa']);
        });
    }

    /**
     * подставит код операции
     */
    recalcRowSumm() {
        let doc = this.refs['document'];

        if (!Object.keys(doc.gridRowData).length) {
            return;
        }

        //подставим наименование услогу

        if (doc.gridRowData['nomid']) {
            let nomDataName = doc.libs['nomenclature'].find(lib => lib.id === Number(doc.gridRowData['nomid']));

            if (nomDataName) {
                doc.gridRowData['kood'] = nomDataName.kood;
                doc.gridRowData['nimetus'] = nomDataName.nimetus;
            }
        }

        //подставим наименование
        if (doc.gridRowData['asutusid']) {

            let asutusDataName = doc.libs['asutused'].find(lib => lib.id === Number(doc.gridRowData['asutusid']));

            if (asutusDataName) {
                doc.gridRowData['asutus'] = asutusDataName.nimetus;
                doc.gridRowData['aa'] = asutusDataName.pank;

            }

        }


    }


    /**
     * валидатор для строки грида
     * @returns {string}
     */
    gridValidateFields() {
        let warning = '';
        let doc = this.refs['document'];
        if (doc && doc.gridRowData) {

            // только после проверки формы на валидность
            if (doc.gridRowData && !doc.gridRowData['nomid']) warning = warning + ' Код операции';
            if (!doc.gridRowData['summa']) warning = warning + ' Сумма';
            if (!doc.gridRowData['asutusid']) warning = warning + ' Платильщик';

            this.recalcRowSumm();
            this.recalcDocSumma('summa');

        }
        return warning;

    }


}

Smk.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

Smk.defaultProps = {
    initData: {},
    userData: {}
};


module.exports = (Smk);
