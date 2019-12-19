'use strict';

const PropTypes = require('prop-types');
const React = require('react');

const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    SelectData = require('../../../components/select-data/select-data.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    ButtonEdit = require('../../../components/button-register/button-register-edit/button-register-edit.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    relatedDocuments = require('../../../mixin/relatedDocuments.jsx'),

    styles = require('./styles');

const LIBDOK = 'TEATIS',
    LIBRARIES = [];

const now = new Date();

class Teatis extends React.PureComponent {
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
        this.btnEditAsutusClick = this.btnEditAsutusClick.bind(this);

        this.pages = [
            {pageName: 'Teatis', docTypeId: 'TEATIS'},
        ];
    }


    render() {
        let initData = this.props.initData ? this.props.initData : {};

        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='TEATIS'
                                 history={this.props.history}
                                 module={this.state.module}
                                 userData={this.props.userData}
                                 initData={initData}
                                 libs={LIBRARIES}
                                 pages={this.pages}
                                 renderer={this.renderer}
        />
    }

    /**
     *Вернет кастомные компоненты документа
     */

    renderer(self) {
        let isEditMode = self.state.edited;

        // формируем зависимости
        if (self.docData.relations) {
            relatedDocuments(self);
        }


        return (
            <div style={styles.doc}>

                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title='Number:'
                                   name='number'
                                   value={self.docData.number || ''}
                                   ref='input-number'
                                   readOnly={!isEditMode}
                                   onChange={self.handleInputChange}/>

                        <InputDate title='Kuupäev '
                                   name='kpv'
                                   value={self.docData.kpv}
                                   ref='input-kpv'
                                   readOnly={!isEditMode}
                                   onChange={self.handleInputChange}/>

                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <SelectData title="Saaja:"
                                    name='asutusid'
                                    libName="asutused"
                                    sqlFields={['nimetus', 'regkood']}
                                    data={[]}
                                    value={self.docData.asutusid || 0}
                                    defaultValue={self.docData.asutus}
                                    boundToGrid='nimetus'
                                    boundToData='asutus'
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
                    <TextArea title="Sisu"
                              name='sisu'
                              ref="textarea-sisu"
                              onChange={self.handleInputChange}
                              value={self.docData.sisu || ''}
                              readOnly={!isEditMode}/>
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
        let nimi = this.refs['document'].docData.vanem_nimi;

        this.props.history.push({
            pathname: `/lapsed/${pageDocTypeId}`,
            state: {asutus: nimi, type: 'text'}
        });

    }

    // обработчик события клиска на кнопке редактирования контр-агента
    btnEditAsutusClick() {
        let docAsutusId = this.refs['document'].docData.asutusid;

        // осуществит переход на карточку контр-агента
        this.props.history.push(`/lapsed/asutused/${docAsutusId}`);
    }
}

Teatis.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

Teatis.defaultProps = {
    params: {docId: 0},
    initData: {},
    userData: {}
};


module.exports = (Teatis);