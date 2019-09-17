'use strict';

const PropTypes = require('prop-types');
const React = require('react');

const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    ButtonEdit = require('../../../components/button-register/button-register-edit/button-register-edit.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    Select = require('../../../components/select/select.jsx'),
    SelectData = require('../../../components/select-data/select-data.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    ModalPage = require('../../../components/modalpage/modalPage.jsx'),
    styles = require('./styles');

const LIBDOK = 'LAPSE_KAART',
    LIBRARIES = ['tunnus', 'nomenclature'];

const now = new Date();

class Laps extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            loadedData: false,
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            lapsId: props.lapsId ? props.lapsId : props.match.params.lapsId ? Number(props.match.params.lapsId) : 0
        };

        this.renderer = this.renderer.bind(this);
        this.handlePageClick = this.handlePageClick.bind(this);
        this.handleGridBtnClick = this.handleGridBtnClick.bind(this);
        this.btnEditNomClick = this.btnEditNomClick.bind(this);


        this.pages = [
            {pageName: 'Teenus', docTypeId: 'LAPSE_KAART'}
        ];

        this.requiredFields = [
            {
                name: 'parentid',
                type: 'I',
            },
            {name: 'nomid', type: 'I'},
            {name: 'hind', type: 'N'},

        ];
    }


    render() {
        let initData = this.props.initData ? this.props.initData : {};

        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='LAPSE_KAART'
                                 requiredFields={this.requiredFields}
                                 userData={this.props.userData}
                                 initData={initData}
                                 libs={LIBRARIES}
                                 pages={this.pages}
                                 renderer={this.renderer}
                                 handleGridBtnClick={this.handleGridBtnClick}
                                 history={this.props.history}
                                 focusElement={'input-kood'}
        />
    }

    /**
     *Вернет кастомные компоненты документа
     */

    renderer(self) {
        let bpm = self.docData && self.docData.bpm ? self.docData.bpm : [],
            isEditMode = self.state.edited;


        if ((self.docData.id == 0 || !self.docData.parentid) && this.state.lapsId) {
            //new record
            self.docData.parentid = this.state.lapsId;
        }

        let doc = this.refs['document'];
        let libs = doc ? doc.libs : {};
        const nomData = self.libs['nomenclature'].filter(lib => {
            if (!lib.dok || lib.dok === LIBDOK) return lib;
        });

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <SelectData title="Lapse nimi:"
                                name='parentid'
                                libName="laps"
                                sqlFields={['nimi', 'isikukood']}
                                data={[]}
                                value={self.docData.parentid || 0}
                                defaultValue={self.docData.lapse_nimi}
                                boundToGrid='nimi'
                                boundToData='lapse_nimi'
                                ref="select-parentid"
                                btnDelete={false}
                                onChange={self.handleInputChange}
                                readOnly={!isEditMode}/>


                </div>
                <div style={styles.docRow}>
                    <div style={styles.docRow}>
                        <Select title="Kood:"
                                name='nomid'
                                libs="nomenclature"
                                data={self.libs['nomenclature']}
                                value={self.docData.nomid || 0}
                                defaultValue={self.docData.kood}
                                ref="select-nomid"
                                btnDelete={isEditMode}
                                onChange={self.handleInputChange}
                                readOnly={!isEditMode}/>

                        <ButtonEdit
                            ref='btnEdit'
                            onClick={this.btnEditNomClick}
                            show={!isEditMode}
                            disabled={false}
                        />
                    </div>

                </div>
                <div style={styles.docRow}>

                    <div style={styles.docColumn}>

                        <InputNumber ref="input-hind"
                                     title='Hind:'
                                     name='hind'
                                     value={self.docData.hind || 0}
                                     readOnly={!isEditMode}
                                     onChange={self.handleInputChange}/>

                        <InputText title='Üksus:'
                                   name='yksus'
                                   value={self.docData.yksus || ''}
                                   ref='input-yksus'
                                   readOnly={!isEditMode}
                                   onChange={self.handleInputChange}/>


                        <Select title="Tunnus:"
                                name='tunnus'
                                libs="tunnus"
                                data={self.libs['tunnus']}
                                value={self.docData.tunnus}
                                defaultValue={self.docData.tunnus}
                                ref="select-tunnus"
                                collId={'kood'}
                                btnDelete={isEditMode}
                                onChange={self.handleInputChange}
                                readOnly={!isEditMode}/>

                    </div>
                    <div style={styles.docColumn}>
                        <InputNumber ref="input-soodus"
                                     title='Soodustus:'
                                     name='soodus'
                                     value={Number(self.docData.soodus) || 0}
                                     readOnly={!isEditMode}
                                     onChange={self.handleInputChange}/>

                        <InputDate title='Kehtib alates:'
                                   name='sooduse_alg'
                                   value={self.docData.sooduse_alg}
                                   ref='input-soodus_alg'
                                   readOnly={!isEditMode}
                                   onChange={self.handleInputChange}/>

                        <InputDate title='Kehtib kuni:'
                                   name='sooduse_lopp'
                                   value={self.docData.sooduse_lopp}
                                   ref='input-soodus_lopp'
                                   readOnly={!isEditMode}
                                   onChange={self.handleInputChange}/>

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
            </div>
        );
    }


    handlePageClick(pageDocTypeId) {
//        document.location.href = `/lapsed/${pageDocTypeId}/`;//@todo Обновить
        this.props.history.push(`/lapsed/${pageDocTypeId}`)
    }


    // обработчик события клик на гриде родителей
    handleGridBtnClick(btnName, activeRow, id, docTypeId) {
        switch (btnName) {
            case "edit":
                this.props.history.push(`/lapsed/${docTypeId}/${id}/0`);
                break;
            case "add":
                this.props.history.push(`/lapsed/${docTypeId}/0/${this.state.docId}`);
                break;
            case "delete":
                console.log('btnDelete clicked');
                break;
            default:
                console.log('Vigane click');
        }

    }

    //обработчик события по клику кнопки Редактирование сноменклатуры
    btnEditNomClick() {
        let docNomId = this.refs['document'].docData.nomid;

        // осуществит переход на карточку контр-агента
        this.props.history.push(`/lapsed/nomenclature/${docNomId}`);

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