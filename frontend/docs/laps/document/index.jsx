'use strict';

const DocContext = require('../../../doc-context');

const PropTypes = require('prop-types');
const React = require('react');
const fetchData = require('./../../../../libs/fetchData');
const createEmptyFilterData = require('./../../../../libs/createEmptyFilterData');
const compareDate = require('./../../../../libs/compareDates');

const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    styles = require('./laps.styles');

const LIBRARIES = [{id: 'lapse_grupp', filter: ``}];

const DOCS = ['ARV', 'SMK', 'VMK', 'LAPSE_TAABEL'];


class Laps extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            loadedData: false,
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            vanemId: null,
            module: 'lapsed',
            kehtiv: '2019-12-31'
        };

        this.renderer = this.renderer.bind(this);
        this.handlePageClick = this.handlePageClick.bind(this);
        this.handleGridBtnClick = this.handleGridBtnClick.bind(this);
        this.fetchData = this.fetchData.bind(this);
        this.setFilter = this.setFilter.bind(this);
        this.handleInputChange = this.handleInputChange.bind(this);

        this.docId = props.docId ? props.docId : Number(props.match.params.docId);

        this.pages = [
            {pageName: 'Lapse kaart', docTypeId: 'LAPS'},
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
                              reload={true}
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
        let gridSoodustusteData = [];


        if (self.docData.id === 0) {
            //neew record
            self.docData.vanemid = this.state.vanemId;
        } else {
            // наложим фильтры
            this.setFilter(self.docData.isikukood)
        }

        if (!this.docId && self.docData.id) {
            this.docId = self.docData.id;
        }

        // наложить фильтр на действующие услуги
        if (gridTeenusteData && gridTeenusteData.length) {

            // фильтруем льготы
            gridSoodustusteData = gridTeenusteData.filter(row => {
                return compareDate(row.lopp_kpv, this.state.kehtiv) && row.tyyp && row.tyyp === 'SOODUSTUS';
            });

            //услуги без льгот
            gridTeenusteData = gridTeenusteData.filter(row => {
                return compareDate(row.lopp_kpv, this.state.kehtiv) && (!row.tyyp || row.tyyp === '');
            });

        }

        console.log('data', self.docData);

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
                                   readOnly={true}
                                   disabled={true}
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
                              handleGridBtnClick={self.handleGridBtnClick}
                              readOnly={isEditMode}
                              style={styles.grid.headerTable}
                              docTypeId={'vanem'}
                              ref="vanemad-data-grid"/>
                </div>

                <div style={styles.docRow}>
                    <div style={styles.docColumn}>

                        <label ref="label">
                            {'Teenused'}
                        </label>
                    </div>
                    <div style={styles.docColumn}>
                        <InputDate title='Kehtiv seisuga: '
                                   name='kehtivSeisuga'
                                   value={this.state.kehtiv}
                                   ref='input-kehtiv'
                                   readOnly={false}
                                   styles={styles.kehtivSeisuga}
                                   onChange={this.handleInputChange}/>
                    </div>
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
                <div style={styles.docRow}>
                    <label ref="label">
                        {'Soodustused'}
                    </label>
                </div>
                <div style={styles.docRow}>

                    <DataGrid source='soodustused'
                              gridData={gridSoodustusteData}
                              gridColumns={gridTeenusteColumns}
                              showToolBar={!isEditMode}
                              handleGridBtnClick={self.handleGridBtnClick}
                              docTypeId={'lapse_kaart'}
                              readOnly={!isEditMode}
                              style={styles.grid.headerTable}
                              ref="soodustused-data-grid"/>
                </div>
            </div>
        );
    }


    /**
     * установим фильтр на документа
     */
    setFilter(isikukood) {

        // проверим наличие фильтра
        DOCS.forEach(doc => {
            if (!DocContext.filter[doc] || !DocContext.filter[doc].length) {
                // создаем пустой фильтр для заданного типа
                DocContext.filter[doc] = createEmptyFilterData(DocContext.gridConfig[doc], [], doc);
            }

            // накладываем фильтр
            DocContext.filter[doc].forEach(row => {
                if (row.id == 'isikukood') {
                    row.value = isikukood;
                }
            });

        });

    }

    handlePageClick(pageDocTypeId) {
        // данные для фильтра
        let isikukood = this.refs['document'].docData.isikukood;

        // register name
        if (DocContext.menu) {
            let docType = DocContext['menu'].find(row => row.kood.toUpperCase() === pageDocTypeId.toUpperCase());
            if (docType) {
                DocContext.pageName = docType;
            }
        } else {
            const page = this.pages.find(row => row.docTypeId == pageDocTypeId);
            if (page && page.pageName) {
                DocContext.pageName = page.pageName;
            }
        }

        // проверим наличие фильтра
        if (!DocContext.filter[pageDocTypeId] || !DocContext.filter[pageDocTypeId].length) {
            // создаем пустой фильтр для заданного типа
            DocContext.filter[pageDocTypeId] = createEmptyFilterData(DocContext.gridConfig[pageDocTypeId], [], pageDocTypeId);
        }


        // накладываем фильтр
        DocContext.filter[pageDocTypeId].forEach(row => {
            if (row.id == 'isikukood') {
                row.value = isikukood;
            }
        });

        let route = `/lapsed/${pageDocTypeId}`;
        this.props.history.replace(`/reload`);
        setTimeout(() => {
            this.props.history.replace(route);
        });

    }


    // обработчик события клик на гриде родителей
    handleGridBtnClick(btnName, activeRow, id, docTypeId) {
        switch (btnName.toUpperCase()) {
            case "EDIT":

                this.props.history.push({
                    pathname: `/lapsed/${docTypeId}/${id}`,
                    state: {lapsId: this.docId, module: this.state.module}
                });
                break;
            case "MUUDA":

                this.props.history.push({
                    pathname: `/lapsed/${docTypeId}/${id}`,
                    state: {lapsId: this.docId, module: this.state.module}
                });
                break;

            case "ADD" :
                this.props.history.push({
                    pathname: `/lapsed/${docTypeId}/0`,
                    state: {lapsId: this.docId, module: this.state.module}
                });
                break;
            case "LISA" :
                this.props.history.push({
                    pathname: `/lapsed/${docTypeId}/0`,
                    state: {lapsId: this.docId, module: this.state.module}
                });
                break;
            case "DELETE":
                //send post to delete row
                this.fetchData(docTypeId, id).then((response) => {
                    let isTrue = response && response.status && response.status === 200 ? 'Ok' : 'Error';
                    let errorMessage = 'Viga';
                    if (isTrue && response.data && response.data.error) {
                        // error
                        isTrue = false;
                        errorMessage = response.data.error_message;
                    }
                    const Doc = this.refs['document'];
                    // обновим справочник
                    Doc.loadLibs('vanem');

                    if (isTrue === 'Ok') {


                        Doc.setState({
                            reloadData: true,
                            warning: 'Kiri kustutatud',
                            warningType: 'ok',
                        }, () => {
                            setTimeout(() => {
                                const current = this.props.location.pathname;
                                this.props.history.replace(`/reload`);
                                setTimeout(() => {
                                    this.props.history.replace(current);
                                });

                            }, 2000)
                        });

                    } else {
                        Doc.setState({
                            reloadData: false,
                            warning: `${errorMessage}`,
                            warningType: 'error',
                        });
                    }

                });
                break;
            case "KUSTUTA":
                //send post to delete row
                this.fetchData(docTypeId, id).then((response) => {
                    let isTrue = response && response.status && response.status === 200 ? 'Ok' : 'Error';
                    const Doc = this.refs['document'];
                    if (isTrue === 'Ok') {

                        // обновим справочник
                        Doc.loadLibs('vanem');

                        // извещение
                        Doc.setState({
                            reloadData: true,
                            warning: 'Kiri kustutatud',
                            warningType: 'ok',
                        });

                    } else {
                        let errorMessage = response.data && response.data.error_message ? response.data.error_message : 'Viga';
                        Doc.setState({
                            reloadData: false,
                            warning: `${errorMessage}`,
                            warningType: 'error',
                        });
                    }

                });
                break;
            default:
                console.log('Vigane click', btnName);
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

    /**
     * отработает фильтр на данные услуг
     */
    handleInputChange(inputName, inputValue) {
        // обработчик изменений
        this.setState({kehtiv: inputValue});

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