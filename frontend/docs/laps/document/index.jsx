'use strict';

const DocContext = require('../../../doc-context');

const PropTypes = require('prop-types');
const React = require('react');
const fetchData = require('./../../../../libs/fetchData');
const toolbarParams = {
    btnAdd: {
        show: true,
        disabled: false
    },
    btnEdit: {
        show: true,
        disabled: false
    },
    btnDelete: {
        show: false,
        disabled: false
    },
    btnPrint: {
        show: true,
        disabled: false
    }
};

const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    styles = require('./laps.styles');

const LIBRARIES = [];

class Laps extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            loadedData: false,
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            vanemId: null,
            module: 'lapsed'
        };

        this.renderer = this.renderer.bind(this);
        this.handlePageClick = this.handlePageClick.bind(this);
        this.handleGridBtnClick = this.handleGridBtnClick.bind(this);
        this.fetchData = this.fetchData.bind(this);

        this.docId = props.docId ? props.docId : Number(props.match.params.docId);

        this.pages = [
            {pageName: 'Lapse kaart', docTypeId: 'LAPS'},
            {pageName: 'Taabel', handlePageClick: this.handlePageClick, docTypeId: 'LAPSE_TAABEL'},
            {pageName: 'Arved', handlePageClick: this.handlePageClick, docTypeId: 'ARV'},
            {pageName: 'Maksekoraldused', handlePageClick: this.handlePageClick, docTypeId: 'SMK'},
            {pageName: 'Kassaorderid', handlePageClick: this.handlePageClick, docTypeId: 'SORDER'}
        ];
    }

    componentDidMount() {
        if (this.props.history && this.props.history.location.state) {
            let vanemId = this.props.history.location.state.vanemId;
            let module = this.props.history.location.state.module ? this.props.history.location.state.module : 'lapsed';
            this.setState({vanemId: vanemId, module: module});
        }

        //сохраним последний docId
        if (this.state.docId) {
            DocContext.lapsId = this.state.docId;
        }

    }

    render() {

        return (
            <DocumentTemplate docId={this.state.docId}
                              ref='document'
                              history={this.props.history}
                              module={this.state.module}
                              docTypeId='LAPS'
                              initData={this.props.initData ? this.props.initData : {}}
                              libs={LIBRARIES}
                              pages={this.pages}
                              renderer={this.renderer}
                              handleGridBtnClick={this.handleGridBtnClick}
                              focusElement={'input-isikukood'}
            />
        )
    }

    /**
     *Вернет кастомные компоненты документа
     */

    renderer(self) {
        let isEditMode = self.state.edited,
            gridVanemadData = self.docData.vanemad,
            gridVanemadColumns = self.docData.gridConfig,
            gridTeenusteData = self.docData.teenused,
            gridTeenusteColumns = self.docData.gridTeenusteConfig;


        if (self.docData.id === 0) {
            //neew record
            self.docData.vanemid = this.state.vanemId;
        }

        let doc = this.refs['document'];

        if (!this.docId && self.docData.id) {
            this.docId = self.docData.id;
        }


        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText ref="input-isikukood"
                                   title='Isikukood:'
                                   name='isikukood'
                                   value={self.docData.isikukood || ''}
                                   readOnly={!isEditMode}
                                   maxLength="11"
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
                    <label ref="label">
                        {'Vanemad'}
                    </label>
                </div>
                <div style={styles.docRow}>

                    <DataGrid source='vanemad'
                              gridData={gridVanemadData}
                              gridColumns={gridVanemadColumns}
                              showToolBar={!isEditMode}
                              toolbarParams={toolbarParams}
                              handleGridBtnClick={self.handleGridBtnClick}
                              readOnly={!isEditMode}
                              style={styles.grid.headerTable}
                              docTypeId={'vanem'}
                              ref="vanemad-data-grid"/>
                </div>

                <div style={styles.docRow}>
                    <label ref="label">
                        {'Teenused'}
                    </label>
                </div>
                <div style={styles.docRow}>

                    <DataGrid source='teenused'
                              gridData={gridTeenusteData}
                              gridColumns={gridTeenusteColumns}
                              showToolBar={!isEditMode}
                              handleGridBtnClick={self.handleGridBtnClick}
                              docTypeId={'lapse_kaart'}
                              readOnly={!isEditMode}
                              style={styles.grid.headerTable}
                              ref="teenuste-data-grid"/>
                </div>
            </div>
        );
    }


    handlePageClick(pageDocTypeId) {
        // данные для фильтра
        let isikukood = this.refs['document'].docData.isikukood;

        this.props.history.push({
            pathname: `/lapsed/${pageDocTypeId}`,
            state: {isikukood: isikukood, type: 'text'}
        });

    }


    // обработчик события клик на гриде родителей
    handleGridBtnClick(btnName, activeRow, id, docTypeId) {

        switch (btnName) {
            case "edit":

                this.props.history.push({
                    pathname: `/lapsed/${docTypeId}/${id}`,
                    state: {lapsId: this.docId, module: this.state.module}
                });
                break;
            case "add":
                this.props.history.push({
                    pathname: `/lapsed/${docTypeId}/0`,
                    state: {lapsId: this.docId, module: this.state.module}
                });
                break;
            case "delete":
                //send post to delete row
                this.fetchData(docTypeId, id).then(() => {

                    const current = this.props.location.pathname;
                    this.props.history.replace(`/reload`);
                    setTimeout(() => {
                        this.props.history.replace(current);
                    });

                });
                break;
            default:
                console.log('Vigane click');
        }

    }

    // отправит запрос на удаление с параметром тип документа и ид

    fetchData(docTypeId, id) {

        const url = `/newApi/delete`;

        const params = {
            parameter: docTypeId,
            module: 'lapsed',
            userId: DocContext.userData.userId,
            uuid: DocContext.userData.uuid,
            docId: id
        };

        return fetchData['fetchDataPost'](url, params)
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