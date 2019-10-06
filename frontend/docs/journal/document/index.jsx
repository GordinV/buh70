'use strict';

const PropTypes = require('prop-types');
const React = require('react');

const
    DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    DocCommon = require('../../../components/doc-common/doc-common.jsx'),
    Select = require('../../../components/select/select.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    relatedDocuments = require('../../../mixin/relatedDocuments.jsx'),
    ModalPage = require('./../../../components/modalpage/modalPage.jsx'),
    styles = require('./journal-styles.js');

const LIBRARIES = ['asutused', 'kontod', 'tunnus', 'project'];

class Journal extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            docId: props.docId ? props.docId: Number(props.match.params.docId),
            loadedData: false
        };

        this.pages = [{pageName: 'Journal'}];
        this.createGridRow = this.createGridRow.bind(this);
        this.recalcDocSumma = this.recalcDocSumma.bind(this);

        this.renderer = this.renderer.bind(this);
        this.gridValidateFields = this.gridValidateFields.bind(this);

    }

    render() {
        let initData = this.props.initData ? this.props.initData: {};
        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='JOURNAL'
                                 initData={initData}
                                 libs={LIBRARIES}
                                 pages={this.pages}
                                 renderer={this.renderer}
                                 createGridRow={this.createGridRow}
                                 gridValidator={this.gridValidateFields}
                                 recalcDoc={this.recalcDocSumma}
        />
    }

    renderer(self) {
        let bpm = self.docData && self.docData.bpm ? self.docData.bpm : [],
            isEditeMode = self.state.edited,
            gridData = self.docData.gridData,
            gridColumns = self.docData.gridConfig;

        const gridRowValidator = this.gridValidateFields();

        // формируем зависимости
        if (self.docData.relations) {
            relatedDocuments(self);
        }

        let doc = this.refs['document'];
        let libs = doc ? doc.libs : {};
        return (
            <div>
                <div style={styles.doc}>
                    <div style={styles.docRow}>
                        <DocCommon ref='doc-common'
                                   data={self.docData}
                                   readOnly={!isEditeMode}/>
                    </div>
                    <div style={styles.docColumn}>
                        <InputText
                            title='Number'
                            name='number'
                            value={String(self.docData.number) || ''}
                            ref="input-number"
                            readOnly={true}/>
                        <InputDate title='Kuupäev '
                                   name='kpv'
                                   value={self.docData.kpv}
                                   ref='input-kpv'
                                   onChange={self.handleInputChange}
                                   readOnly={!isEditeMode}/>
                        <Select title="Partner"
                                name='asutusid'
                                libs="asutused"
                                data={self.libs['asutused']}
                                value={self.docData.asutusid || ''}
                                collId='id'
                                defaultValue={self.docData.asutus}
                                onChange={self.handleInputChange}
                                ref="select-asutusid"
                                readOnly={!isEditeMode}/>
                        <InputText
                            title='Dokument '
                            name='dok'
                            value={self.docData.dok || ''}
                            ref='input-dok'
                            onChange={self.handleInputChange}
                            readOnly={!isEditeMode}/>
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
                        <div style={styles.gridContainer}>
                            <DataGrid source='details'
                                      gridData={gridData}
                                      gridColumns={gridColumns}
                                      handleGridRow={this.handleGridRow}
                                      readOnly={!isEditeMode}
                                      showToolBar = {isEditeMode}
                                      handleGridBtnClick = {self.handleGridBtnClick}
                                      style={styles.grid.headerTable}
                                      ref="data-grid"/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <InputNumber
                            title="Summa: "
                            name='summa'
                            ref="input-summa"
                            value={Number(self.docData.summa || 0)}
                            disabled={true}
                            width={styles.summa.width}
                            pattern="^[0-9]+(\.[0-9]{1,4})?$"/>
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
     * Создаст и вернет компонент сроки грида
     * @returns {XML}
     */
    createGridRow(self) {
        let row = self.gridRowData,
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
                        <Select title="Deebet"
                                name='deebet'
                                libs="kontod"
                                data={self.libs['kontod']}
                                readOnly={false}
                                value={row.deebet}
                                ref='deebet'
                                collId="kood"
                                onChange={self.handleGridRowChange}/>
                    </div>
                    <div style={styles.docRow}>
                        <Select title="Kreedit"
                                name='kreedit'
                                data={self.libs['kontod']}
                                readOnly={false}
                                value={row.kreedit}
                                ref='kreedit'
                                collId="kood"
                                onChange={self.handleGridRowChange}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputNumber title='Summa: '
                                     name='summa'
                                     value={Number(row.summa) || 0}
                                     disabled={false}
                                     bindData={false}
                                     ref='summa'
                                     width='auto'
                                     onChange={self.handleGridRowInput}/>
                    </div>
                    <div style={styles.docRow}>
                        <Select title="Tunnus"
                                name='tunnus'
                                libs="tunnus"
                                data={self.libs['tunnus']}
                                readOnly={false}
                                value={row.tunnus}
                                ref='tunnus'
                                placeholder='Tunnus'
                                collId="kood"
                                onChange={self.handleGridRowChange}/>
                    </div>
                    <div style={styles.docRow}>
                        <Select title="Project"
                                name='proj'
                                libs="project"
                                data={self.libs['project']}
                                readOnly={false}
                                value={row.proj}
                                ref='proj'
                                placeholder='Projekt'
                                collId="kood"
                                onChange={self.handleGridRowChange}/>
                    </div>
                </div>
                <div><span>{validateMessage}</span></div>
            </ModalPage>
        </div>);
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
            if (doc.gridRowData && !doc.gridRowData['deebet']) warning = warning + ' Дебет';
            if (!doc.gridRowData['kreedit']) warning = warning + ' Кредит';
            if (!doc.gridRowData['summa']) warning = warning + ' Сумма';

            this.recalcDocSumma('summa');

        }
        return warning;

    }

    /**
     * Перерасчет итоговых сумм
     * @returns {*}
     */
    recalcDocSumma(field) {
        let docData = this.refs['document'].docData;

        docData[field] = 0;

        if (docData.gridData && docData.gridData.length) {
            docData.gridData.forEach(row => {
                docData[field] += Number(row[field]);
            });
        }
    }


}

Journal.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

Journal.defaultProps = {
    initData:{},
    userData:{}
};

module.exports = (Journal);
