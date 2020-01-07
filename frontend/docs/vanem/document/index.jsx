'use strict';

const PropTypes = require('prop-types');
const React = require('react');

const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    Select = require('../../../components/select/select.jsx'),
    ButtonEdit = require('../../../components/button-register/button-register-edit/button-register-edit.jsx'),
    SelectData = require('../../../components/select-data/select-data.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    CheckBox = require('../../../components/input-checkbox/input-checkbox.jsx'),

    styles = require('./styles');

const LIBDOK = 'VANEM',
    LIBRARIES = [];

const now = new Date();

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
        this.handlePageClick = this.handlePageClick.bind(this);
        this.handleLasteGridBtnClick = this.handleLasteGridBtnClick.bind(this);
        this.btnEditAsutusClick = this.btnEditAsutusClick.bind(this);

        this.pages = [
            {pageName: 'Vanem kaart', docTypeId: 'VANEM'},
            {pageName: 'Arved', handlePageClick: this.handlePageClick, docTypeId: 'ARV'},
            {pageName: 'Maksekoraldused', handlePageClick: this.handlePageClick, docTypeId: 'SMK'},
            {pageName: 'Kassaorderid', handlePageClick: this.handlePageClick, docTypeId: 'SORDER'}
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
                                 focusElement={'input-isikukood'}
        />
    }

    /**
     *Вернет кастомные компоненты документа
     */

    renderer(self) {
        let isEditMode = self.state.edited,
            gridLasteData = self.docData.lapsed,
            gridLasteColumns = self.docData.gridConfig;

        if (this.state.lapsId) {
            self.docData.parentid = this.state.lapsId;
        }

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <SelectData title="Vanem:"
                                    name='asutusid'
                                    libName="asutused"
                                    sqlFields={['nimetus', 'regkood']}
                                    data={[]}
                                    value={self.docData.asutusid || 0}
                                    defaultValue={self.docData.vanem_nimi}
                                    boundToGrid='nimetus'
                                    boundToData='vanem_nimi'
                                    ref="select-asutusid"
                                    btnDelete={false}
                                    userData={self.userData}
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
                        <Select title="Arveldus:"
                                name='arved'
                                data={[{name: 'Jah'}, {name: 'Ei'}]}
                                value={self.docData.arved || 'Ei'}
                                collId='name'
                                defaultValue={self.docData.arved}
                                ref="select-arved"
                                btnDelete={false}
                                onChange={self.handleInputChange}
                                readOnly={!isEditMode}/>
                        {self.docData.arved === 'Jah' ?
                            <CheckBox title="Print paberil ?"
                                      name='kas_paberil'
                                      value={Boolean(self.docData.kas_paberil)}
                                      ref={'checkbox_kas_paberil'}
                                      onChange={self.handleInputChange}
                                      readOnly={!isEditMode}
                            /> : null
                        }
                        {self.docData.arved === 'Jah' ?
                            <CheckBox title="E-arve ?"
                                      name='kas_earve'
                                      value={Boolean(self.docData.kas_earve)}
                                      ref={'checkbox_kas_earve'}
                                      onChange={self.handleInputChange}
                                      readOnly={!isEditMode}
                            /> : null
                        }
                        {self.docData.arved === 'Jah' ?
                            <CheckBox title="Kas email ?"
                                      name='kas_email'
                                      value={Boolean(self.docData.kas_email)}
                                      ref={'checkbox_kas_email'}
                                      onChange={self.handleInputChange}
                                      readOnly={!isEditMode}
                            /> : null
                        }


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

    handlePageClick(pageDocTypeId) {
        let nimi = this.refs['document'].docData.vanem_nimi;

        this.props.history.push({
            pathname: `/lapsed/${pageDocTypeId}`,
            state: {asutus: nimi, type: 'text'}
        });

    }

    handleLasteGridBtnClick(btnName, activeRow, id, docTypeId) {

        switch (btnName) {
            case "edit":
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
                console.log('btnDelete clicked');
                break;
            default:
                console.log('Vigane click');
        }

    }

    // обработчик события клиска на кнопке редактирования контр-агента
    btnEditAsutusClick() {
        let docAsutusId = this.refs['document'].docData.asutusid;

        // осуществит переход на карточку контр-агента
        this.props.history.push(`/lapsed/asutused/${docAsutusId}`);
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