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
    styles = require('./vmk-style');

const LIBDOK = 'VMK',
    LIBRARIES = ['asutused', 'kontod', 'dokProps', 'tunnus', 'project', 'nomenclature', 'aa'];

let now = new Date();

class Vmk extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            docId: props.docId ? props.docId: Number(props.match.params.docId),
            loadedData: false
        };

        this.createGridRow = this.createGridRow.bind(this);
        this.recalcDocSumma = this.recalcDocSumma.bind(this);
        this.recalcRowSumm = this.recalcRowSumm.bind(this);

        this.renderer = this.renderer.bind(this);
        this.gridValidateFields = this.gridValidateFields.bind(this);

        this.pages = [{pageName: 'Väljamakse korraldus'}];
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

    }


    render() {
        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='VMK'
                                 requiredFields={this.requiredFields}
                                 initData={this.props.initData}
                                 libs={LIBRARIES}
                                 pages={this.pages}
                                 renderer={this.renderer}
                                 createGridRow={this.createGridRow}
                                 gridValidator={this.gridValidateFields}
                                 recalcDoc={this.recalcDocSumma}
        />

    }

    renderer (self) {
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
                        <DocCommon
                            ref='doc-common'
                            data={self.docData}
                            readOnly={!isEditeMode}/>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputText title='Number'
                                       name='number'
                                       value={String(self.docData.number) || ''}
                                       ref="input-number"
                                       onChange = {self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                            <InputDate title='Kuupäev '
                                       name='kpv'
                                       value={self.docData.kpv}
                                       ref='input-kpv'
                                       onChange = {self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                            <Select title="Arvelsus arve"
                                    name='aa_id'
                                    libs="aa"
                                    value={self.docData.aa_id}
                                    data={self.libs['aa']}
                                    defaultValue={self.docData.pank || ''}
                                    onChange = {self.handleInputChange}
                                    ref="select-aaId"
                                    readOnly={!isEditeMode}/>
                            <InputText title="Arve nr."
                                       name='arvnr'
                                       value={self.docData.arvnr || ''}
                                       ref="input-arvnr"
                                       onChange = {self.handleInputChange}
                                       readOnly={true}/>
                            <InputDate title='Maksepäev '
                                       name='maksepaev'
                                       value={self.docData.maksepaev}
                                       ref='input-maksepaev'
                                       onChange = {self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                            <InputText title='Viitenumber '
                                       name='viitenr'
                                       value={self.docData.viitenr || ''}
                                       ref='input-viitenr'
                                       onChange = {self.handleInputChange}
                                       readOnly={!isEditeMode}/>
                        </div>
                        <div style={styles.docColumn}>
                            <DokProp title="Konteerimine: "
                                     name='doklausid'
                                     libs="dokProps"
                                     value={self.docData.doklausid}
                                     defaultValue={self.docData.dokprop || ''}
                                     ref="dokprop"
                                     onChange = {self.handleInputChange}
                                     readOnly={!isEditeMode}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                            <TextArea title="Selgitus"
                                      name='selg'
                                      ref="textarea-selg"
                                      value={self.docData.selg || ''}
                                      onChange = {self.handleInputChange}
                                      readOnly={!isEditeMode}/>
                    </div>
                    <div style={styles.docRow}>
                        <DataGrid source='details'
                                  gridData={self.docData.gridData}
                                  gridColumns={self.docData.gridConfig}
                                  handleGridRow={self.handleGridRow}
                                  handleGridBtnClick = {self.handleGridBtnClick}
                                  readOnly={!isEditeMode}
                                  showToolBar = {isEditeMode}
                                  style={styles.grid.headerTable}
                                  ref="data-grid"/>
                    </div>
                    <div style={styles.docRow}>
                        <InputText title="Kokku: "
                                   name='summa'
                                   ref="input-summa"
                                   value={String(self.docData.summa)}
                                   width='auto'
                                   disabled={true}
                        />
                    </div>
                    <div style={styles.docRow}>
                            <TextArea title="Märkused"
                                      name='muud'
                                      ref="textarea-muud"
                                      value={self.docData.muud || ''}
                                      onChange = {self.handleInputChange}
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
        let row = Object.assign({}, self.gridRowData),
            validateMessage = '',
            modalObjects = ['btnOk', 'btnCancel'],
            buttonOkReadOnly = validateMessage.length > 0 || !self.state.checked;

        if (buttonOkReadOnly) {
            // уберем кнопку Ок
            modalObjects.splice(0, 1);
        }

        if (!row) return <div/>;

        let nomData = self.libs['nomenclature'].filter(lib => {
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
                            <Select title="Operatsioon"
                                    name='nomid'
                                    data={nomData}
                                    value={row.nomid}
                                    collId = 'id'
                                    defaultValue={row.kood || ''}
                                    ref='nomid'
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Partner"
                                    name='asutusid'
                                    data={self.libs['asutused']}
                                    value={row.asutusid}
                                    defaultValue={row.asutus || ''}
                                    collId='id'
                                    ref='asutusid'
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>

                            <InputText title='Arveldus arve: '
                                       name='aa'
                                       value={String(row.aa) || ''}
                                       bindData={false}
                                       ref='aa'
                                       onChange={self.handleGridRowInput}/>

                        </div>
                        <div style={styles.docRow}>

                            <InputNumber title='Summa: '
                                         name='summa'
                                         value={Number(row.summa || 0)}
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
            ;
    }


    /**
     *  перерасчет итоговой суммы документа
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

        let asutusDataName = doc.libs['asutused'].filter(lib => {
            if (lib.id === doc.gridRowData['asutusid']) return lib;
        });

        if (doc.gridRowData['asutusid']) {
            doc.gridRowData['asutus'] = asutusDataName[0].name;
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
            if (!doc.gridRowData['asutusid']) warning = warning + ' Получатель';

            this.recalcRowSumm();
            this.recalcDocSumma('summa');

        }
        return warning;

    }

}

Vmk.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

Vmk.defaultProps = {
    initData:{},
    userData:{}
};

module.exports = (Vmk);