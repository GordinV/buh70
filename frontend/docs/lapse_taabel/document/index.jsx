'use strict';

const PropTypes = require('prop-types');
const React = require('react');


const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    ButtonEdit = require('../../../components/button-register/button-register-edit/button-register-edit.jsx'),
    Select = require('../../../components/select/select.jsx'),
    SelectData = require('../../../components/select-data/select-data.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    CheckBox = require('../../../components/input-checkbox/input-checkbox.jsx'),
    Loading = require('./../../../components/loading/index.jsx'),
    styles = require('./styles');

const DocContext = require('../../../doc-context');

class Laps extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            module: 'lapsed',
            loadedData: false,
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            lapsId: props.lapsId ? props.lapsId : props.match.params.paramId ? Number(props.match.params.paramId) : 0
        };

        this.renderer = this.renderer.bind(this);
        this.handlePageClick = this.handlePageClick.bind(this);
        this.handleGridBtnClick = this.handleGridBtnClick.bind(this);
        this.btnEditNomClick = this.btnEditNomClick.bind(this);
        this.btnEditLapsClick = this.btnEditLapsClick.bind(this);
        this.lapsIdChangehandler = this.lapsIdChangehandler.bind(this);
        this.recalcDocSumma = this.recalcDocSumma.bind(this);


        this.pages = [
            {pageName: 'Lapse taabel', docTypeId: 'LAPSE_TAABEL'}
        ];
    }

    componentDidMount() {
        if (!this.state.lapsId && DocContext['laps']) {
            //есть значение ид ребенка
            this.setState({lapsId: DocContext['laps']});
        }

    }

    componentDidUpdate(prevProps, prevState) {
        // обновим справочники ребенка
        if (this.state.lapsId !== prevState.lapsId) {
            const doc = this.refs['document'];
            doc.createLibs();
        }
    }

    render() {
        let filter = this.state.lapsId ? `where lapsid = ${this.state.lapsId}` : '';

        const LIBRARIES = [{id: 'lapse_kaart', filter: filter}];

        let initData = this.props.initData ? this.props.initData : {};

        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='LAPSE_TAABEL'
                                 module={this.state.module}
                                 initData={initData}
                                 libs={LIBRARIES}
                                 pages={this.pages}
                                 renderer={this.renderer}
                                 handleGridBtnClick={this.handleGridBtnClick}
                                 recalcDoc={this.recalcDocSumma}
                                 history={this.props.history}
        />
    }

    /**
     *Вернет кастомные компоненты документа
     */

    renderer(self) {
        //|| !self.state.loadedLibs
        if (!self || !self.docData || !self.libs['lapse_kaart']) {
            // не загружены данные
            return (<div style={styles.doc}>
                <Loading label={'Laadimine...'}/>
            </div>);
        }

        // не успевает подгрузиться справочник, перегрузка формы
        if (!self.libs['lapse_kaart'].length) {
            setTimeout(() => {
                this.forceUpdate()
            }, 1);
        }

        let isEditMode = self.state.edited;

        if ((self.docData.id === 0 || !self.docData.parentid) && this.state.lapsId) {
            //new record
            self.docData.parentid = this.state.lapsId;
        }

        if (!this.state.lapsId && self.docData.parentid) {
            this.setState({lapsId: self.docData.parentid})
        }

        let kpv = new Date(),
            kuu = kpv.getMonth(),
            aasta = kpv.getFullYear();

        let buttonEditNom = styles.btnEditNom;

        //фильтр на используемы номенклатуры
        const nomData = self.libs['lapse_kaart'] ? self.libs['lapse_kaart'].filter(row => row.lapsid === self.docData.parentid) : [];

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <SelectData title="Lapse nimi:"
                                    name='parentid'
                                    libName="laps"
                                    sqlFields={['nimi', 'isikukood']}
                                    data={[]}
                                    value={self.docData.parentid || 0}
                                    defaultValue={self.docData.nimi}
                                    boundToGrid='nimi'
                                    boundToData='nimi'
                                    ref="select-parentid"
                                    btnDelete={false}
                                    userData={self.userData}
                                    onChange={this.lapsIdChangehandler}
                                    readOnly={!isEditMode}/>
                    </div>
                    <div style={styles.docColumn}>
                        <ButtonEdit
                            ref='btnEdit'
                            value={'Muuda'}
                            onClick={this.btnEditLapsClick}
                            show={!isEditMode}
                            style={buttonEditNom}
                            disabled={false}
                        />
                    </div>

                </div>

                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <Select title="Kood:"
                                name='lapse_kaart_id'
                                libs="lapse_kaart"
                                data={nomData}
                                value={self.docData.lapse_kaart_id || 0}
                                defaultValue={self.docData.nimetus}
                                ref="select-lapse_kaart_id"
                                btnDelete={isEditMode}
                                onChange={self.handleInputChange}
                                readOnly={!isEditMode}/>
                    </div>

                    <div style={styles.docColumn}>
                        <ButtonEdit
                            ref='btnEdit'
                            value={'Muuda'}
                            onClick={this.btnEditNomClick}
                            show={!isEditMode}
                            style={buttonEditNom}
                            disabled={false}
                        />
                    </div>
                </div>

                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputNumber ref="input-kogus"
                                     title='Kogus:'
                                     name='kogus'
                                     value={Number(self.docData.kogus) || Number(null)}
                                     readOnly={!isEditMode}
                                     onChange={self.handleInputChange}/>

                        <InputNumber ref="input-hind"
                                     title='Hind:'
                                     name='hind'
                                     value={Number(self.docData.hind) || Number(null)}
                                     readOnly={true}/>

                        <InputNumber ref="input-soodustus"
                                     title='Soodustus:'
                                     name='soodustus'
                                     value={Number(self.docData.soodustus) || Number(null)}
                                     readOnly={!isEditMode}
                                     onChange={self.handleInputChange}/>

                        <InputNumber ref="input-summa"
                                     title='Summa:'
                                     name='summa'
                                     value={(Number(self.docData.summa)).toFixed(2) || Number(null)}
                                     readOnly={true}/>

                        <CheckBox title="Kas ümberarvestus?"
                                  name='kas_umberarvestus'
                                  value={Boolean(self.docData.kas_umberarvestus)}
                                  ref={'checkbox_kas_umberarvestus'}
                                  readOnly={true}
                        />

                        <InputNumber ref="input-kuu"
                                     title='Kuu:'
                                     name='kuu'
                                     value={Number(self.docData.kuu) || Number(kuu)}
                                     readOnly={!isEditMode}
                                     onChange={self.handleInputChange}/>

                        <InputNumber ref="input-aasta"
                                     title='Aasta:'
                                     name='aasta'
                                     value={Number(self.docData.aasta) || Number(aasta)}
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
            default:
                console.log('Vigane click');
        }

    }


    //обработчик события по клику кнопки Редактирование сноменклатуры
    btnEditNomClick() {
        let docId = this.refs['document'].docData.lapse_kaart_id;

        // осуществит переход на карточку контр-агента
        this.props.history.push(`/lapsed/lapse_kaart/${docId}`);

    }

    //обработчик события по клику кнопки Редактирование ребенка
    btnEditLapsClick() {
        let docLapsId = this.refs['document'].docData.parentid;

        // осуществит переход на карточку контр-агента
        this.props.history.push(`/lapsed/laps/${docLapsId}`);

    }

    lapsIdChangehandler(inputName, inputValue) {
        const Doc = this.refs['document'];

        // отдать значение документу
        Doc.handleInputChange(inputName, inputValue);

        // обновить справочник
        Doc.createLibs();

    }

    recalcDocSumma() {
        let doc = this.refs['document'];

        let summa = 0;
        doc.docData['summa'] = ((Number(doc.docData['hind']) - Number(doc.docData['soodustus'])) * Number(doc.docData['kogus'])).toFixed(2)  ;
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