'use strict';

const React = require('react');
const PropTypes = require('prop-types');

const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    Select = require('../../../components/select/select.jsx'),
    SelectData = require('../../../components/select-data/select-data.jsx'),
    ButtonEdit = require('../../../components/button-register/button-register-edit/button-register-edit.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    DokProp = require('../../../components/docprop/docprop.jsx'),
    relatedDocuments = require('../../../mixin/relatedDocuments.jsx'),
    ModalPage = require('../../../components/modalpage/modalPage.jsx'),
    styles = require('./sorder-style');

const DOC_TYPE_ID = 'SORDER';
const DocContext = require('./../../../doc-context.js');


const LIBRARIES = [
    {id: 'kontod', filter: ''},
    {id: 'dokProps', filter: ''},
    {id: 'tunnus', filter: ''},
    {id: 'project', filter: ''},
    {id: 'nomenclature', filter: `where dok = 'SORDER'`},
    {id: 'kassa', filter: ''}
];

class Sorder extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            loadedData: false,
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            lapsId: null,
            module: 'lapsed',
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

        this.pages = [{pageName: 'Sissetuliku kassaorder', docTypeId: 'SORDER'}];

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
                                 initData={this.props.initData}
                                 module={this.state.module}
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
        let bpm = self.docData && self.docData.bpm ? self.docData.bpm : [],
            isEditeMode = self.state.edited;

        // формируем зависимости
        if (self.docData.relations) {
            relatedDocuments(self);
        }

        let isNewDoc = !self.docData.id || self.docData.id == 0;
        if ((!self.docData.id || self.docData.id == 0) && self.docData.arvid && this.state.isAskToCreateFromArv) {
            this.setState({getSMK: true, isAskToCreateFromArv: false, arvId: self.docData.arvid});
        }

        return (
                <div style={styles.doc}>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputText title='Number:'
                                       name='number'
                                       value={String(self.docData.number) || ''}
                                       ref="input-number"
                                       onChange={self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                        </div>
                        <div style={styles.docColumn}>
                            <DokProp title="Konteerimine: "
                                     name='doklausid'
                                     libs="dokProps"
                                     value={self.docData.doklausid}
                                     defaultValue={self.docData.dokprop || ''}
                                     ref="dokprop"
                                     onChange={self.handleInputChange}
                                     readOnly={!isEditeMode}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputDate title='Kuupäev:'
                                       name='kpv'
                                       value={self.docData.kpv}
                                       ref='input-kpv'
                                       onChange={self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                            <Select title="Kassa:"
                                    name='kassa_id'
                                    libs="kassa"
                                    value={self.docData.kassa_id}
                                    data={self.libs['kassa']}
                                    defaultValue={String(self.docData.kassa) || ''}
                                    ref="select-kassaId"
                                    onChange={self.handleInputChange}
                                    readOnly={!isEditeMode}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <SelectData title="Raha saaja:"
                                        name='asutusid'
                                        libName="asutused"
                                        sqlFields={['nimetus', 'regkood']}
                                        data={[]}
                                        value={self.docData.asutusid || 0}
                                        defaultValue={self.docData.asutus}
                                        boundToGrid='nimetus'
                                        boundToData='asutus'
                                        ref="select-asutusid"
                                        btnDelete={false}
                                        onChange={self.handleInputChange}
                                        readOnly={!isEditeMode}/>
                        </div>
                        <div style={styles.docColumn}>
                            <ButtonEdit
                                ref='btnEdit'
                                value={'Muuda'}
                                onClick={this.btnEditAsutusClick}
                                show={!isEditeMode}
                                style={styles.btnEdit}
                                disabled={false}
                            />
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            {!isNewDoc ?
                                <InputText title="Arve nr."
                                           name='_arvnr'
                                           value={self.docData.arvnr || ''}
                                           ref="input-arvnr"
                                           show={!isNewDoc}
                                           onChange={self.handleInputChange}
                                           readOnly={true}/>
                                : null
                            }
                            {isNewDoc ? <SelectData title="Arve nr."
                                                    name='arvid'
                                                    libName="arv"
                                                    sqlFields={['number', 'kpv', 'asutus']}
                                                    data={[]}
                                                    value={self.docData.arvid || ''}
                                                    ref="select-arve"
                                                    btnDelete={false}
                                                    userData={self.userData}
                                                    onChange={self.handleInputChange}
                                                    readOnly={!isEditeMode}/> : null}

                            <InputText title='Dokument:'
                                       name='dokument'
                                       value={self.docData.dokument || ''}
                                       ref='input-dokument'
                                       onChange={self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <TextArea title="Nimi"
                                  name='nimi'
                                  ref="textarea-nimi"
                                  value={self.docData.nimi || ''}
                                  onChange={self.handleInputChange}
                                  readOnly={!isEditeMode}/>
                    </div>
                    <div style={styles.docRow}>
                        <TextArea title="Aadress:"
                                  name='aadress'
                                  ref="textarea-aadress"
                                  value={self.docData.aadress || ''}
                                  onChange={self.handleInputChange}
                                  readOnly={!isEditeMode}/>
                    </div>
                    <div style={styles.docRow}>
                        <TextArea title="Alus:"
                                  name='alus'
                                  ref="textarea-alus"
                                  value={self.docData.alus || ''}
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
                        <InputNumber title="Summa: "
                                     name='summa'
                                     ref="input-summa"
                                     value={Number(self.docData.summa) || 0}
                                     width='auto'
                                     disabled={true}
                        />
                    </div>
                    <div style={styles.docRow}>
                        <TextArea title="Märkused:"
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
                        Kas koosta kassaorder?
                    </ModalPage>
                </div>
        );
    }

    /**
     * will create SORDER
     */
    modalPageBtnClick(btnEvent) {
        this.setState({getSMK: false});
        if (btnEvent === 'Ok') {
            const Doc = this.refs['document'];
            let api = `/calc/koostaSorder`;

            const params = {
                docTypeId: DOC_TYPE_ID,
                module: this.props.module ? this.props.module : DocContext.module,
                userId: DocContext.userData.userId,
                uuid: DocContext.userData.uuid,
                docs: [Number(this.state.arvId)],
                seisuga: Doc.docData && Doc.docData.kpv ? Doc.docData.kpv : null,
                context: DocContext[api] ? DocContext[api] : null,
                taskName: 'koostaSorder'
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
                                const current = `/${this.props.module ? this.props.module : DocContext.module}/${DOC_TYPE_ID}/${newDocId}`;
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
     * валидатор для строки грида
     * @param gridRowData строка грида
     * @returns {string}
     */
    gridValidateFields() {
        let warning = '';
        let doc = this.refs['document'];
        if (doc && doc.gridRowData) {

            // только после проверки формы на валидность
            if (doc.gridRowData && !doc.gridRowData['nomid']) warning = warning + ' Код операции';
            if (!doc.gridRowData['summa']) warning = warning + ' Сумма';

            this.recalcRowSumm();
            this.recalcDocSumma('summa');

        }
        return warning;

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

        let nomDataName = doc.libs['nomenclature'].filter(lib => {
            if (lib.id === doc.gridRowData['nomid']) return lib;
        });

        if (doc.gridRowData['nomid']) {
            doc.gridRowData['kood'] = nomDataName[0].kood;
            doc.gridRowData['nimetus'] = nomDataName[0].name;
        }

    }

    /**
     * Перерасчет сумм документа
     */
    recalcDocSumma() {
        let doc = this.refs['document'];
        doc.docData['summa'] = 0;
        doc.docData.gridData.forEach(row => {
            doc.docData['summa'] += Number(row['summa']);
        });
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

        return (<div className='.modalPage'>
                <ModalPage
                    modalObjects={modalObjects}
                    ref="modalpage-grid-row"
                    show={true}
                    modalPageBtnClick={self.modalPageClick}
                    modalPageName='Rea lisamine / parandamine'>
                    <div ref="grid-row-container">
                        {self.state.gridWarning.length ? (
                            <div style={styles.docRow}>
                                <span>{self.state.gridWarning}</span>
                            </div>
                        ) : null}

                        <div style={styles.docRow}>
                            <Select title="Teenus"
                                    name='nomid'
                                    libs="nomenclature"
                                    data={self.libs['nomenclature']}
                                    value={row.nomid || 0}
                                    defaultValue={row.kood || ''}
                                    ref='nomid'
                                    placeholder='Teenuse kood'
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>

                            <InputNumber title='Summa: '
                                         name='summa'
                                         value={Number(row.summa) || 0}
                                         bindData={false}
                                         ref='summa'
                                         onChange={self.handleGridRowInput}/>
                        </div>
                        <div style={styles.docRow}>

                            <Select title="Korr. konto"
                                    name='konto'
                                    libs="kontod"
                                    data={self.libs['kontod']}
                                    value={row.konto || ''}
                                    ref='konto'
                                    collId="kood"
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Tunnus:"
                                    name='tunnus'
                                    libs="tunnus"
                                    data={self.libs['tunnus']}
                                    value={row.tunnus || ''}
                                    ref='tunnus'
                                    collId="kood"
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Project:"
                                    name='proj'
                                    libs="project"
                                    data={self.libs['project']}
                                    value={row.proj || ''}
                                    ref='project'
                                    collId="kood"
                                    onChange={self.handleGridRowChange}/>
                        </div>
                    </div>
                    <div><span>{validateMessage}</span></div>
                </ModalPage>
            </
                div>
        );
    }

}


Sorder.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

Sorder.defaultProps = {
    initData: {},
    userData: {}
};

module.exports = (Sorder);
