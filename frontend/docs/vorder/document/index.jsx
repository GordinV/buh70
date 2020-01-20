'use strict';
const React = require('react');
const PropTypes = require('prop-types');

const DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    DocCommon = require('../../../components/doc-common/doc-common.jsx'),
    Select = require('../../../components/select/select.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    DokProp = require('../../../components/docprop/docprop.jsx'),
    relatedDocuments = require('../../../mixin/relatedDocuments.jsx'),
    ModalPage = require('./../../../components/modalpage/modalPage.jsx'),
    styles = require('./vorder-style');

const LIBDOK = 'VORDER',
    LIBRARIES = ['asutused', 'kontod', 'dokProps', 'tunnus', 'project', 'nomenclature', 'kassa'];

let now = new Date();

class Vorder extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            loadedData: false,
            docId: props.docId ? props.docId: Number(props.match.params.docId)
        };

        this.createGridRow = this.createGridRow.bind(this);
        this.recalcDocSumma = this.recalcDocSumma.bind(this);
        this.recalcRowSumm = this.recalcRowSumm.bind(this);

        this.renderer = this.renderer.bind(this);
        this.gridValidateFields = this.gridValidateFields.bind(this);

        this.pages = [{pageName: 'Väljamakse kassaorder'}];
    }

    render() {
        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='SORDER'
                                 initData={this.props.initData}
                                 reload={true}
                                 libs={LIBRARIES}
                                 pages={this.pages}
                                 renderer={this.renderer}
                                 createGridRow={this.createGridRow}
                                 gridValidator={this.gridValidateFields}
                                 recalcDoc={this.recalcDocSumma}
                                 focusElement={'input-number'}        />
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

        let doc = this.refs['document'];
        let libs = doc ? doc.libs : {};

        return (
            <div>
                <div className='div-doc'>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputText title='Number'
                                       name='number'
                                       value={String(self.docData.number) || ''}
                                       ref="input-number"
                                       onChange={self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                            <InputDate title='Kuupäev '
                                       name='kpv'
                                       value={self.docData.kpv}
                                       ref='input-kpv'
                                       onChange={self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                            <Select title="Kassa"
                                    name='kassa_id'
                                    libs="kassa"
                                    value={self.docData.kassa_id}
                                    data={self.libs['kassa']}
                                    defaultValue={self.docData.kassa || ''}
                                    ref="select-kassaId"
                                    onChange={self.handleInputChange}
                                    readOnly={!isEditeMode}/>
                            <Select title="Partner"
                                    name='asutusid'
                                    data={self.libs['asutused']}
                                    libs="asutused"
                                    value={self.docData.asutusid}
                                    defaultValue={self.docData.asutus || ''}
                                    onChange={self.handleInputChange}
                                    ref="select-asutusId"
                                    readOnly={!isEditeMode}/>
                            <InputText title="Arve nr."
                                       name='arvnr'
                                       value={self.docData.arvnr || ''}
                                       ref="input-arvnr"
                                       onChange={self.handleInputChange}
                                       readOnly={true}/>
                            <InputText title='Dokument '
                                       name='dokument'
                                       value={self.docData.dokument || ''}
                                       ref='input-dokument'
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
                            <TextArea title="Nimi"
                                      name='nimi'
                                      ref="textarea-nimi"
                                      value={self.docData.nimi || ''}
                                      onChange={self.handleInputChange}
                                      readOnly={!isEditeMode}/>
                    </div>
                    <div style={styles.docRow}>
                            <TextArea title="Aadress"
                                      name='aadress'
                                      ref="textarea-aadress"
                                      value={self.docData.aadress || ''}
                                      onChange={self.handleInputChange}
                                      readOnly={!isEditeMode}/>
                    </div>
                    <div style={styles.docRow}>
                            <TextArea title="Alus"
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
                                  showToolBar = {isEditeMode}
                                  handleGridRow={self.handleGridRow}
                                  handleGridBtnClick = {self.handleGridBtnClick}
                                  style={styles.grid.headerTable}
                                  readOnly={!isEditeMode}
                                  ref="data-grid"/>
                    </div>
                    <div style={styles.docRow}>
                        <InputText title="Summa: "
                                   name='summa'
                                   ref="input-summa"
                                   value={String(self.docData.summa || 0)}
                                   width='auto'
                                   disabled={true}
                        />
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

                </div>
            </div>
        );
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


        let nomData = [];

        nomData = self.libs['nomenclature'].filter(lib => {
            if (!lib.dok || lib.dok === LIBDOK) return lib;
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
                            <Select title="Teenus"
                                    name='nomid'
                                    libs="nomenclature"
                                    data={nomData}
                                    value={row.nomid}
                                    defaultValue={row.kood || ''}
                                    collId = 'id'
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
                                    data={self.libs['kontod']}
                                    value={row.konto || ''}
                                    ref='konto'
                                    collId="kood"
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Tunnus:"
                                    name='tunnus'
                                    data={self.libs['tunnus']}
                                    value={row.tunnus || ''}
                                    ref='tunnus'
                                    collId="kood"
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Project:"
                                    name='proj'
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
                div >
        )
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

        let nomDataName = doc.libs['nomenclature'].filter(lib => {
            if (lib.id === doc.gridRowData['nomid']) return lib;
        });

        if (doc.gridRowData['nomid']) {
            doc.gridRowData['kood'] = nomDataName[0].kood;
            doc.gridRowData['nimetus'] = nomDataName[0].name;
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


}

Vorder.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

Vorder.defaultProps = {
    initData:{},
    userData:{}
};

module.exports = (Vorder);