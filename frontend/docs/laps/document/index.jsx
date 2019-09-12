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

        this.renderer = this.renderer.bind(this);
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