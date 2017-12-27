'use strict';

const {withRouter} = require('react-router-dom');
const PropTypes = require('prop-types');
const React = require('react');

const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    DocCommon = require('../../../components/doc-common/doc-common.jsx'),
    Select = require('../../../components/select/select.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    DokProp = require('../../../components/docprop/docprop.jsx'),
    relatedDocuments = require('../../../mixin/relatedDocuments.jsx'),
    ModalPage = require('../../../components/modalpage/modalPage.jsx'),
    styles = require('./arve.styles');

const LIBDOK = 'ARV',
    LIBRARIES = ['asutused', 'kontod', 'dokProps', 'users', 'aa', 'tunnus', 'project', 'nomenclature'];


const now = new Date();

class Arve extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            loadedData: false,
            docId: props.docId ? props.docId: Number(props.match.params.docId)
        };

        this.createGridRow = this.createGridRow.bind(this);
        this.recalcDocSumma = this.recalcDocSumma.bind(this);

        this.renderer = this.renderer.bind(this);
        this.gridValidateFields = this.gridValidateFields.bind(this);

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

    }

    render() {
        let initData = this.props.initData ? this.props.initData: {};

        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='ARV'
                                 requiredFields={this.requiredFields}
                                 userData={this.props.userData}
                                 initData={initData}
                                 libs={LIBRARIES}
                                 pages={this.pages}
                                 renderer={this.renderer}
                                 createGridRow={this.createGridRow}
                                 gridValidator={this.gridValidateFields}
                                 recalcDoc={this.recalcDocSumma}
        />
    }

    /**
     *Вернет кастомные компоненты документа
     */

    renderer(self) {
        let bpm = self.docData && self.docData.bpm ? self.docData.bpm : [],
            isEditMode = self.state.edited,
            gridData = self.docData.gridData,
            gridColumns = self.docData.gridConfig;

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
                        <DocCommon
                            ref='doc-common'
                            data={self.docData}
                            readOnly={!isEditMode}/>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputText ref="input-number"
                                       title='Number'
                                       name='number'
                                       value={self.docData.number || ''}
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                            <InputDate title='Kuupäev '
                                       name='kpv' value={self.docData.kpv}
                                       ref='input-kpv'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                            <InputDate title='Tähtaeg '
                                       name='tahtaeg'
                                       value={self.docData.tahtaeg}
                                       ref="input-tahtaeg"
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                            <Select title="Asutus"
                                    name='asutusid'
                                    libs="asutused"
                                    data={self.libs['asutused']}
                                    value={self.docData.asutusid || 0}
                                    defaultValue={self.docData.asutus}
                                    ref="select-asutusid"
                                    btnDelete={isEditMode}
                                    onChange={self.handleInputChange}
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
                                       value={self.docData.lisa || ''}
                                       ref='input-lisa'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                        </div>
                        <div style={styles.docColumn}>
                            <DokProp title="Konteerimine: "
                                     name='doklausid'
                                     libs="dokProps"
                                     value={self.docData.doklausid}
                                     defaultValue={self.docData.dokprop}
                                     ref="dokprop-doklausid"
                                     readOnly={!isEditMode}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <TextArea title="Märkused"
                                  name='muud'
                                  ref="textarea-muud"
                                  onChange={self.handleInputChange}
                                  value={self.docData.muud || ''}
                                  readOnly={!isEditMode}/>
                    </div>

                    <div style={styles.docRow}>
                        <DataGrid source='details'
                                  gridData={gridData}
                                  gridColumns={gridColumns}
                                  showToolBar={isEditMode}
                                  handleGridRow={this.handleGridRow}
                                  handleGridBtnClick={self.handleGridBtnClick}
                                  readOnly={!isEditMode}
                                  style={styles.grid.headerTable}
                                  ref="data-grid"/>
                    </div>
                    <div style={styles.docRow}>
                        <InputNumber title="Summa "
                                     name='summa'
                                     ref="input-summa"
                                     value={Number(self.docData.summa) || 0}
                                     disabled={true}
                                     width={'auto'}
                                     onChange={self.handleInputChange}/>
                        <InputNumber title="Käibemaks "
                                     name='kbm'
                                     ref="input-kbm"
                                     disabled={true}
                                     width={'auto'}
                                     value={Number(self.docData.kbm) || 0}
                                     onChange={self.handleInputChange}
                        />
                    </div>
                    {self.state.gridRowEdit ?
                        this.createGridRow(self)
                        : null}
                </div>
            </div>
        );
    }


    /**
     * Создаст компонет строки грида
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
                    {self.state.gridWarning.length ? (
                        <div style={styles.docRow}>
                            <span>{self.state.gridWarning}</span>
                        </div>
                    ) : null}

                    <div style={styles.docRow}>
                        <Select title="Teenus"
                                name='nomid'
                                libs="nomenclature"
                                data={nomData}
                                readOnly={false}
                                value={row.nomid}
                                collId='id'
                                ref='nomid'
                                placeholder='Teenuse kood'
                                onChange={self.handleGridRowChange}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputNumber title='Kogus '
                                     name='kogus'
                                     value={Number(row.kogus)}
                                     readOnly={false}
                                     disabled={false}
                                     bindData={false}
                                     ref='kogus'
                                     onChange={self.handleGridRowInput}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputNumber title='Hind '
                                     name='hind'
                                     value={Number(row.hind)}
                                     readOnly={false}
                                     disabled={false}
                                     bindData={false}
                                     ref='hind'
                                     onChange={self.handleGridRowInput}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputNumber title='Kbm-ta: '
                                     name='kbmta'
                                     value={Number(row.kbmta)}
                                     disabled={true}
                                     bindData={false}
                                     ref='kbmta'
                                     onChange={self.handleGridRowChange}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputNumber title='Kbm: '
                                     name='kbm'
                                     value={Number(row.kbm)}
                                     disabled={true}
                                     bindData={false}
                                     ref='kbm'
                                     onBlur={self.handleGridRowInput}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputNumber title='Summa: '
                                     name='Summa'
                                     value={Number(row.summa)}
                                     disabled={true}
                                     bindData={false}
                                     ref='summa'
                                     onChange={self.handleGridRowInput}/>
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
            if (doc.gridRowData && !doc.gridRowData['nomid']) warning = warning + ' Код операции';
            if (!doc.gridRowData['kogus']) warning = warning + ' Количество';
            if (!doc.gridRowData['summa']) warning = warning + ' Сумма';

            this.recalcRowSumm();
            this.recalcDocSumma('summa');

        }
        return warning;

    }

    /**
     * перерасчет суммы строки и расчет налога
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

        let vat = nomDataName[0].vat ? Number(nomDataName[0].vat) / 100 : 0;
        if (doc.gridRowData['nomid']) {
            doc.gridRowData['kood'] = nomDataName[0].kood;
            doc.gridRowData['nimetus'] = nomDataName[0].name;
        }

        doc.gridRowData['kogus'] = Number(doc.gridRowData.kogus);
        doc.gridRowData['hind'] = Number(doc.gridRowData.hind);
        doc.gridRowData['kbmta'] = Number(doc.gridRowData['kogus']) * Number(doc.gridRowData['hind']);
        doc.gridRowData['kbm'] = Number(doc.gridRowData['kbmta']) * vat;
        doc.gridRowData['summa'] = Number(doc.gridRowData['kbmta']) + Number(doc.gridRowData['kbm']);
    }

    /**
     * Перерасчет итоговых сумм документа
     */
    recalcDocSumma() {
        let doc = this.refs['document'];

        doc.docData['summa'] = 0;
        doc.docData['kbm'] = 0;
        doc.docData.gridData.forEach(row => {
            doc.docData['summa'] += Number(row['summa']);
            doc.docData['kbm'] += Number(row['kbm']);
        });
    }

}

Arve.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

Arve.defaultProps = {
    params: {docId: 0},
    initData:{},
    userData:{}
};


module.exports = withRouter(Arve);