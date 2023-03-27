'use strict';

const PropTypes = require('prop-types');
const React = require('react');

const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    ButtonEdit = require('../../../components/button-register/button-register-edit/button-register-edit.jsx'),
    SelectData = require('../../../components/select-data/select-data.jsx'),
    Select = require('../../../components/select/select.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    CheckBox = require('../../../components/input-checkbox/input-checkbox.jsx'),
    Loading = require('./../../../components/loading/index.jsx'),
    createEmptyFilterData = require('./../../../../libs/createEmptyFilterData'),
    styles = require('./styles');

const fetchData = require('./../../../../libs/fetchData');

const LIBRARIES = [];
const DOCS = ['ARV', 'SMK', 'VMK'];
const DocContext = require('./../../../doc-context.js');

class Vanem extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            loadedData: false,
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            lapsId: null,
            module: 'lapsed'
        };

        this.renderer = this.renderer.bind(this);
        this.handleLasteGridBtnClick = this.handleLasteGridBtnClick.bind(this);
        this.btnEditAsutusClick = this.btnEditAsutusClick.bind(this);
        this.setFilter = this.setFilter.bind(this);

        this.pages = [
            {pageName: 'Vanem kaart', docTypeId: 'VANEM'},
        ];
    }


    componentDidMount() {
        if (this.props.history && this.props.history.location.state) {
            let lapsId = this.props.history.location.state.lapsId;
            let module = this.props.history.location.state.module;
            this.setState({lapsId: lapsId, module: module});
        }

    }

    render() {
        let initData = this.props.initData ? this.props.initData : {};

        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='VANEM'
                                 history={this.props.history}
                                 module={this.state.module}
                                 userData={this.props.userData}
                                 initData={initData}
                                 libs={LIBRARIES}
                                 pages={this.pages}
                                 renderer={this.renderer}
                                 handleGridBtnClick={this.handleLasteGridBtnClick}
        />
    }

    /**
     *Вернет кастомные компоненты документа
     */

    renderer(self) {
        if (!self || self.docData.vanem_nimi == 'undefined') {
            // не загружены данные
            return (<div style={styles.doc}>
                <Loading label={'Laadimine...'}/>
            </div>);
        }


        let isEditMode = self.state.edited,
            gridLasteData = self.docData.lapsed,
            gridLasteColumns = self.docData.gridConfig;

        if (this.state.lapsId) {
            self.docData.parentid = this.state.lapsId;
        }

        if (self.docData.vanem_nimi) {
            // наложим фильтры
            this.setFilter(self.docData.vanem_nimi)
        }

        return (
            <div style={styles.doc}>
                {self.docData && self.docData.asutusid && Boolean(self.docData.kas_email) && !(self.docData.email) ? (<div style={styles.docRow}>
                    <div style={styles.warning}>Puudub e-posti aadress</div>
                </div>) : null
                }

                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <SelectData title="Vanem:"
                                    name='asutusid'
                                    libName="asutused"
                                    history = {this.props.history}
                                    sqlFields={['nimetus', 'regkood']}
                                    data={[]}
                                    value={self.docData.asutusid || 0}
                                    defaultValue={self.docData.vanem_nimi}
                                    boundToGrid='nimetus'
                                    boundToData='vanem_nimi'
                                    ref="select-asutusid"
                                    btnDelete={false}
                                    onChange={self.handleInputChange}
                                    readOnly={!isEditMode}/>
                    </div>
                    <div style={styles.docColumn}>
                        <ButtonEdit
                            ref='btnEdit'
                            value={'Muuda'}
                            onClick={this.btnEditAsutusClick}
                            show={!isEditMode}
                            style={styles.btnEdit}
                            disabled={false}
                        />
                    </div>
                </div>

                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title='Sugulus:'
                                   name='suhtumine'
                                   value={self.docData.suhtumine || ''}
                                   ref='input-suhtumine'
                                   readOnly={!isEditMode}
                                   onChange={self.handleInputChange}/>
                        <CheckBox title="Arveldus:"
                                  name='arved'
                                  value={Boolean(self.docData.arved)}
                                  ref={'checkbox_arved'}
                                  onChange={self.handleInputChange}
                                  readOnly={!isEditMode}
                        />
                        {self.docData.arved ?
                            <CheckBox title="Print paberil ?"
                                      name='kas_paberil'
                                      value={Boolean(self.docData.kas_paberil)}
                                      ref={'checkbox_kas_paberil'}
                                      onChange={self.handleInputChange}
                                      readOnly={!isEditMode}
                            /> : null
                        }
                        {self.docData.arved ?
                            <CheckBox title="Kas email ?"
                                      name='kas_email'
                                      value={Boolean(self.docData.kas_email)}
                                      ref={'checkbox_kas_email'}
                                      onChange={self.handleInputChange}
                                      readOnly={!isEditMode}
                            /> : null
                        }
                        <CheckBox title="Lapse seaduslik esindaja"
                                  name='kas_esindaja'
                                  value={Boolean(self.docData.kas_esindaja)}
                                  ref={'checkbox_kas_esindaja'}
                                  onChange={self.handleInputChange}
                                  readOnly={!isEditMode}
                        />
                    </div>
                </div>

                {self.docData.arved ?
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <CheckBox title="E-arve ?"
                                      name='kas_earve'
                                      value={Boolean(self.docData.kas_earve)}
                                      ref={'checkbox_kas_earve'}
                                      onChange={self.handleInputChange}
                                      readOnly={!isEditMode}
                            />
                        </div>
                    </div> : null}
                {self.docData.arved && self.docData.kas_earve ?
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <Select title="E-arve pank:"
                                    name='pank'
                                    data={[{id: 0, kood: '', nimetus: ''}, {
                                        id: 1,
                                        kood: 'SWED',
                                        nimetus: 'Swedpank'
                                    }, {id: 2, kood: 'SEB', nimetus: 'Seb pank'}]}
                                    collId='kood'
                                    value={self.docData.pank || ''}
                                    defaultValue={self.docData.pank}
                                    ref="select-pank"
                                    btnDelete={isEditMode}
                                    onChange={self.handleInputChange}
                                    readOnly={!isEditMode}
                                    style={styles.pank}
                            />
                        </div>
                        <div style={styles.docColumn}>
                            <InputText title='E-arve IBAN:'
                                       name='iban'
                                       value={self.docData.iban || ''}
                                       ref='input-iban'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>

                        </div>
                    </div>
                    : null}
                <div style={styles.docRow}>
                    <TextArea title="Märkused"
                              name='muud'
                              ref="textarea-muud"
                              onChange={self.handleInputChange}
                              value={self.docData.muud || ''}
                              readOnly={!isEditMode}/>
                </div>
                < div
                    style={styles.docRow}>
                    < label
                        ref="label">
                        {'Lapsed'}
                    </label>
                </div>
                <div style={styles.docRow}>

                    <DataGrid source='lapsed'
                              gridData={gridLasteData}
                              gridColumns={gridLasteColumns}
                              showToolBar={!isEditMode}
                              handleGridBtnClick={self.handleGridBtnClick}
                              readOnly={!isEditMode}
                              style={styles.grid.headerTable}
                              docTypeId={'laps'}
                              ref="laspsed-data-grid"/>
                </div>

            </div>
        );
    }


    handleLasteGridBtnClick(btnName, activeRow, id, docTypeId) {

        switch (btnName) {
            case "edit":
                this.props.history.push({
                    pathname: `/lapsed/${docTypeId}/${id}`,
                    state: {vanemId: this.state.docId, module: this.state.module}
                });

                break;
            case "Muuda":
                this.props.history.push({
                    pathname: `/lapsed/${docTypeId}/${id}`,
                    state: {vanemId: this.state.docId, module: this.state.module}
                });

                break;
            case "add":
                this.props.history.push({
                    pathname: `/lapsed/${docTypeId}/0`,
                    state: {vanemId: this.state.docId, module: this.state.module}
                });
                break;
            case "delete":
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



    // обработчик события клиска на кнопке редактирования контр-агента
    btnEditAsutusClick() {
        let docAsutusId = this.refs['document'].docData.asutusid;

        // осуществит переход на карточку контр-агента
        this.props.history.push(`/lapsed/asutused/${docAsutusId}`);
    }

    /**
     * установим фильтр на документа
     */
    setFilter(nimi) {

        // проверим наличие фильтра
        DOCS.forEach(doc => {
            if (!DocContext.filter[doc] || !DocContext.filter[doc].length) {
                // создаем пустой фильтр для заданного типа
                DocContext.filter[doc] = createEmptyFilterData(DocContext.gridConfig[doc], [], doc);
            }

            // накладываем фильтр
            DocContext.filter[doc].forEach(row => {
                if (row.id == 'asutus') {
                    row.value = nimi;
                }
            });

        });

    }
}

Vanem.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

Vanem.defaultProps = {
    params: {docId: 0},
    initData: {},
    userData: {}
};


module.exports = (Vanem);