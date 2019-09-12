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
    ModalPage = require('../../../components/modalpage/modalPage.jsx'),
    styles = require('./styles');

const LIBDOK = 'VANEM',
    LIBRARIES = [];

const now = new Date();

class Vanem extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            loadedData: false,
            docId: props.docId ? props.docId : Number(props.match.params.docId)
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
        this.requiredFields = [
            {
                name: 'asutusid',
                type: 'I',
            },
            {name: 'parentid', type: 'I'}
        ];
    }

    render() {
        let initData = this.props.initData ? this.props.initData : {};

        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='VANEM'
                                 requiredFields={this.requiredFields}
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

        // формируем зависимости
        if (self.docData.relations) {
            relatedDocuments(self);
        }

        let asutusGrid = [
            {id: "id", name: "id", width: "50px", show: false},
            {id: "regkood", name: "Isikukood", width: "100px"},
            {id: "nimetus", name: "Nimi", width: "100px"}
        ];

        return (
            <div>
                <div style={styles.doc}>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <div style={styles.docRow}>
                                <SelectData title="Vanem:"
                                            name='asutusid'
                                            libName="asutused"
                                            sqlFields={['nimetus', 'regkood']}
                                            data={[]}
                                            config={asutusGrid}
                                            value={self.docData.asutusid || 0}
                                            defaultValue={self.docData.vanem_nimi}
                                            boundToGrid='nimetus'
                                            boundToData='vanem_nimi'
                                            ref="select-asutusid"
                                            btnDelete={false}
                                            onChange={self.handleInputChange}
                                            readOnly={!isEditMode}/>
                                <ButtonEdit
                                    ref='btnEdit'
                                    onClick={this.btnEditAsutusClick}
                                    show={!isEditMode}
                                    disabled={false}
                                />
                            </div>
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
                                  ref="laspsed-data-grid"/>
                    </div>

                </div>
            </div>
        );
    }

    handlePageClick(pageDocTypeId) {
//        document.location.href = `/lapsed/${pageDocTypeId}/`;//@todo Обновить
        this.props.history.push(`/lapsed/${pageDocTypeId}`)
    }

    handleLasteGridBtnClick(btnName, id) {

        switch (btnName) {
            case "edit":
                this.props.history.push(`/lapsed/laps/${id}`);

                break;
            case "add":
                console.log('btnAdd clicked');
                this.props.history.push(`/lapsed/laps/0`);
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