'use strict';

const PropTypes = require('prop-types');
const React = require('react');

const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    Select = require('../../../components/select/select.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    relatedDocuments = require('../../../mixin/relatedDocuments.jsx'),
    ModalPage = require('../../../components/modalpage/modalPage.jsx'),
    styles = require('./laps.styles');

const LIBDOK = 'LAPS',
    LIBRARIES = ['asutused'];

const now = new Date();

class Laps extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            loadedData: false,
            docId: props.docId ? props.docId : Number(props.match.params.docId)
        };

        this.createGridRow = this.createGridRow.bind(this);

        this.renderer = this.renderer.bind(this);
        this.gridValidateFields = this.gridValidateFields.bind(this);
        this.handlePageClick = this.handlePageClick.bind(this);
        this.handleTeenusteGridBtnClick = this.handleTeenusteGridBtnClick.bind(this);
        this.handleVanemadGridBtnClick = this.handleVanemadGridBtnClick.bind(this);


        this.pages = [
            {pageName: 'Lapse kaart', docTypeId:'LAPS'},
            {pageName:'Arved', handlePageClick: this.handlePageClick, docTypeId:'ARV'},
            {pageName:'Maksekoraldused', handlePageClick: this.handlePageClick, docTypeId:'SMK'},
            {pageName:'Kassaorderid', handlePageClick: this.handlePageClick, docTypeId:'SORDER'}
            ];
        this.requiredFields = [
            {
                name: 'isikukood',
                type: 'C',
            },
            {name: 'nimi', type: 'C'}
        ];
    }

    render() {
        let initData = this.props.initData ? this.props.initData : {};

        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='LAPS'
                                 requiredFields={this.requiredFields}
                                 userData={this.props.userData}
                                 initData={initData}
                                 libs={LIBRARIES}
                                 pages={this.pages}
                                 renderer={this.renderer}
                                 createGridRow={this.createGridRow}
                                 gridValidator={this.gridValidateFields}
                                 focusElement={'input-isikukood'}
        />
    }

    /**
     *Вернет кастомные компоненты документа
     */

    renderer(self) {
        let bpm = self.docData && self.docData.bpm ? self.docData.bpm : [],
            isEditMode = self.state.edited,
            gridVanemadData = self.docData.vanemad,
            gridVanemadColumns = self.docData.gridConfig,
            gridTeenusteData = self.docData.teenused,
            gridTeenusteColumns = self.docData.gridTeenusteConfig;

        console.log('rendered', self.docData);

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
                        <div style={styles.docColumn}>
                            <InputText ref="input-isikukood"
                                       title='Isikukood:'
                                       name='isikukood'
                                       value={self.docData.isikukood || ''}
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                            <InputText title='Nimi:'
                                       name='nimi'
                                       value={self.docData.nimi || ''}
                                       ref='input-nimi'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                            <InputText title='Viitenumber:'
                                       name='viitenumber'
                                       value={self.docData.viitenumber || ''}
                                       ref='input-viitenumber'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                        </div>
                        <div style={styles.docColumn}>
                            <InputText ref="input-jaak"
                                       title='Jääk:'
                                       name='jaak'
                                       value={self.docData.jaak || ''}
                                       readOnly={true}
                                       />
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
                        <label   ref="label">
                            {'Vanemad'}
                        </label>
                    </div>
                    <div style={styles.docRow}>

                        <DataGrid source='vanemad'
                                  gridData={gridVanemadData}
                                  gridColumns={gridVanemadColumns}
                                  showToolBar={!isEditMode}
                                  handleGridBtnClick={this.handleVanemadGridBtnClick}
                                  readOnly={!isEditMode}
                                  style={styles.grid.headerTable}
                                  ref="vanemad-data-grid"/>
                    </div>

                    <div style={styles.docRow}>
                        <label   ref="label">
                            {'Teenused'}
                        </label>
                    </div>
                    <div style={styles.docRow}>

                        <DataGrid source='teenused'
                                  gridData={gridTeenusteData}
                                  gridColumns={gridTeenusteColumns}
                                  showToolBar={!isEditMode}
                                  handleGridBtnClick={this.handleTeenusteGridBtnClick}
                                  readOnly={!isEditMode}
                                  style={styles.grid.headerTable}
                                  ref="teenuste-data-grid"/>
                    </div>
                </div>
            </div>
        );
    }

//style={styles.label}


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

    handlePageClick(pageDocTypeId) {
//        document.location.href = `/lapsed/${pageDocTypeId}/`;//@todo Обновить
        this.props.history.push(`/lapsed/${pageDocTypeId}`)
    }

    handleTeenusteGridBtnClick(btnName) {
        console.log('teenuste handleGridBtnClick', btnName);
        this.props.history.push(`/lapsed/teenused/${id}`);

    }

    handleVanemadGridBtnClick(btnName) {
        console.log('vanemad handleGridBtnClick', btnName);
        let id = 0;
        this.props.history.push(`/lapsed/vanemad/${id}`);
    }

}

Laps.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

Laps.defaultProps = {
    params: {docId: 0},
    initData: {},
    userData: {}
};


module.exports = (Laps);