'use strict';

const PropTypes = require('prop-types');
const React = require('react');
const DocContext = require('../../../doc-context');

const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    ButtonEdit = require('../../../components/button-register/button-register-edit/button-register-edit.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    Select = require('../../../components/select/select.jsx'),
    CheckBox = require('../../../components/input-checkbox/input-checkbox.jsx'),
    SelectData = require('../../../components/select-data/select-data.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    Loading = require('./../../../components/loading/index.jsx'),
    styles = require('./styles');

const LIBRARIES = [
    {
        id: 'tunnus', filter: ''
    },
    {
        id: 'nomenclature',
        filter: `where dok = 'ARV'`
    },
    {
        id: 'lapse_grupp',
        filter: ``
    }];


class LapseKaart extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            module: 'lapsed'
        };

        this.renderer = this.renderer.bind(this);
        this.handlePageClick = this.handlePageClick.bind(this);
        this.handleGridBtnClick = this.handleGridBtnClick.bind(this);
        this.btnEditNomClick = this.btnEditNomClick.bind(this);
        this.btnEditLapsClick = this.btnEditLapsClick.bind(this);
        this.btnEditLapseGruppClick = this.btnEditLapseGruppClick.bind(this);
        this.handleInputChange = this.handleInputChange.bind(this);

        this.pages = [
            {pageName: 'Teenus', docTypeId: 'LAPSE_KAART'}
        ];

        this.libs = {}; // libs cache

    }

    componentDidMount() {
        let lapsId;

        //если параметр на ребенка задан в стейте, то используем его. Иначе ищем его в контексте
        if (this.props.history && this.props.history.location.state) {
            lapsId = this.props.history.location.state.lapsId;
        } else {
            lapsId = DocContext['laps'] ? DocContext['laps'] : null;
        }
        this.setState({lapsId: lapsId});

    }

    render() {
        let initData = this.props.initData ? this.props.initData : {};

        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 module={this.state.module}
                                 docTypeId='LAPSE_KAART'
                                 userData={this.props.userData}
                                 initData={initData}
                                 libs={LIBRARIES}
                                 pages={this.pages}
                                 renderer={this.renderer}
                                 handleGridBtnClick={this.handleGridBtnClick}
                                 handleInputChange={this.handleInputChange}
                                 history={this.props.history}
        />
    }

    /**
     *Вернет кастомные компоненты документа
     */

    renderer(self) {
        //|| !self.state.loadedLibs
        if (!self || !self.docData ) {
            // не загружены данные
            return (<div style={styles.doc}>
                <Loading label={'Laadimine...'}/>
            </div>);
        }

        let isEditMode = self.state.edited;

        if ((!Number(self.docData.id) || !self.docData.parentid) && this.state.lapsId) {
            //new record
            self.docData.parentid = this.state.lapsId;
        }

        let buttonEditNom = styles.btnEditNom;

        let yksus;
        if (self.libs['lapse_grupp'] && self.docData.yksus) {
            yksus = self.libs['lapse_grupp'].find(yksus => yksus.kood === self.docData.yksus);
        }

        const all_yksused = (yksus ? yksus.all_yksused : []).map((item, index) => {
            return {id: index++, nimetus: item}
        });

        // фильтр на номенклатуры
        let nomData = [{id: 0, kood: '', nimetus: '', hind: 0, kogus: 0, kas_inf3: false}];
        // берем только услуги для группы, добавляяем цену и ед.измерения и сортируем
        try {
            if (yksus) {
                if (DocContext.libs && DocContext.libs[yksus.id]) {
                    // берем из кеша
                    nomData = DocContext.libs[yksus.id]
                } else {
                    nomData = (yksus.teenused && self.libs['nomenclature'].length > 0 ? yksus.teenused : []).map(nom => {
                        const row = self.libs['nomenclature'].find(lib => lib.id === Number(nom.nomid));

                        if (row) {
                            const teenuseNimetus = row.nimetus ? `${row.nimetus} (hind: ${Number(nom.hind).toFixed(2)}) ` : '';
                            return {...row, nimetus: teenuseNimetus, id: Number(nom.nomid)}
                        }
                    }).sort((a, b) => {
                        return a.kood.localeCompare(b.kood)
                    });

                    DocContext.libs[yksus.id] = nomData;
                    this.forceUpdate();                }
            }

        } catch (e) {
            console.error(e, nomData);
        }


        // проверим стоит ли разрешить редактирование
        let isEditLapsid = !!self.docData.parentid;

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <SelectData title="Lapse nimi:"
                                    name='parentid'
                                    userData={self.userData}
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
                                    history={this.props.history}
                                    readOnly={isEditLapsid}/>
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
                        <Select title="Üksus:"
                                name='yksus'
                                libs="lapse_grupp"
                                data={self.libs['lapse_grupp']}
                                value={self.docData.yksus || ''}
                                defaultValue={self.docData.yksys || ''}
                                ref="select-lapse_grupp"
                                collId={'kood'}
                                btnDelete={isEditMode}
                                onChange={self.handleInputChange}
                                readOnly={!isEditMode}
                        />
                    </div>
                    <div style={styles.docColumn}>
                        <ButtonEdit
                            ref='btnEdit'
                            value={'Muuda'}
                            onClick={this.btnEditLapseGruppClick}
                            show={!isEditMode}
                            disabled={false}
                            style={buttonEditNom}
                        />
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <Select title="All üksus:"
                                name='all_yksus'
                                libs="lapse_all_yksus"
                                data={all_yksused}
                                value={self.docData.all_yksus || ''}
                                defaultValue={self.docData.all_yksys || ''}
                                ref="select-lapse_all_yksus"
                                collId={'nimetus'}
                                onChange={self.handleInputChange}
                                readOnly={!isEditMode}
                        />
                    </div>
                </div>

                <div style={styles.docRow}>
                    <div style={styles.docColumn}>

                        <Select title="Kood:"
                                name='nomid'
                                libs="nomenclature"
                                data={nomData}
                                value={self.docData.nomid || 0}
                                defaultValue={self.docData.kood}
                                ref="select-nomid"
                                collId={'id'}
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
                            disabled={false}
                            style={buttonEditNom}
                        />
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputNumber ref="input-hind"
                                     title='Hind:'
                                     name='hind'
                                     value={Number(self.docData.hind) || 0}
                                     readOnly={!isEditMode}
                                     onChange={self.handleInputChange}/>
                    </div>
                    <div style={styles.docColumn}>
                        <InputNumber ref="input-kogus"
                                     title='Kogus:'
                                     name='kogus'
                                     value={Number(self.docData.kogus) || 0}
                                     readOnly={!isEditMode}
                                     onChange={self.handleInputChange}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <Select title="Tunnus:"
                                name='tunnus'
                                libs="tunnus"
                                data={self.libs['tunnus']}
                                value={self.docData.tunnus || ''}
                                defaultValue={self.docData.tunnus || ''}
                                ref="select-tunnus"
                                collId={'kood'}
                                btnDelete={isEditMode}
                                onChange={self.handleInputChange}
                                readOnly={!isEditMode}
                        />
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputDate title='Kehtib alates:'
                                   name='alg_kpv'
                                   value={self.docData.alg_kpv || ''}
                                   ref='input-alg_kpv'
                                   readOnly={!isEditMode}
                                   onChange={self.handleInputChange}/>

                    </div>
                    <div style={styles.docColumn}>
                        <InputDate title='Kehtib kuni:'
                                   name='lopp_kpv'
                                   value={self.docData.lopp_kpv || ''}
                                   ref='input-lopp_kpv'
                                   readOnly={!isEditMode}
                                   onChange={self.handleInputChange}/>

                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <CheckBox title="Kas ettemaks?"
                                  name='kas_ettemaks'
                                  value={Boolean(self.docData.kas_ettemaks)}
                                  ref={'checkbox_kas_ettemaks'}
                                  onChange={self.handleInputChange}
                                  readOnly={!isEditMode}
                        />
                    </div>
                    {self.docData.kas_ettemaks ?
                        <div style={styles.docColumn}>
                            < InputNumber
                                ref="input-ettemaksu_period"
                                title='Ettemaksu period:'
                                name='ettemaksu_period'
                                value={Number(self.docData.ettemaksu_period) || 0}
                                readOnly={!isEditMode}
                                onChange={self.handleInputChange}
                            />
                        </div> : null
                    }
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <CheckBox title="Kas arvesta eraldi?"
                                  name='kas_eraldi'
                                  value={Boolean(self.docData.kas_eraldi)}
                                  ref={'checkbox_kas_eraldi'}
                                  onChange={self.handleInputChange}
                                  readOnly={!isEditMode}
                        />

                        <CheckBox title="Kas INF3?"
                                  name='kas_inf3'
                                  value={Boolean(self.docData.kas_inf3)}
                                  ref={'checkbox_kas_inf3'}
                                  onChange={self.handleInputChange}
                                  readOnly={!isEditMode}
                        />
                    </div>
                    < div style={styles.docColumn}>
                        < InputNumber
                            ref="input-soodus"
                            title='Soodustus:'
                            name='soodus'
                            value={Number(self.docData.soodus) || 0}
                            readOnly={!isEditMode}
                            onChange={self.handleInputChange}
                        />

                        <InputDate title='Kehtib alates:'
                                   name='sooduse_alg'
                                   value={self.docData.sooduse_alg || ''}
                                   ref='input-soodus_alg'
                                   readOnly={!isEditMode}
                                   onChange={self.handleInputChange}/>

                        < InputDate
                            title='Kehtib kuni:'
                            name='sooduse_lopp'
                            value={self.docData.sooduse_lopp || ''}
                            ref='input-soodus_lopp'
                            readOnly={
                                !isEditMode
                            }
                            onChange={self.handleInputChange}
                        />

                        <CheckBox title="Kas soodustus protsentides?"
                                  name='kas_protsent'
                                  value={Boolean(self.docData.kas_protsent)}
                                  ref={'checkbox_kas_protsent'}
                                  onChange={self.handleInputChange}
                                  readOnly={!isEditMode}
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
            </div>
        );
    }

    /**
     * отработает клик по вкладе и осуществит переход на заданную страницу
     * @param pageDocTypeId
     */
    handlePageClick(pageDocTypeId) {
        this.props.history.push(`/lapsed/${pageDocTypeId}`)
    }

    //handler for input for this document type
    handleInputChange(inputName, inputValue) {
        if (inputName === 'nomid') {
            const Doc = this.refs['document'];

            // надо задать цену и кол-во из того, что привязанно в группе

            let yksus;
            if (Doc.libs['lapse_grupp'] && Doc.docData.yksus) {
                yksus = Doc.libs['lapse_grupp'].find(obj => obj.kood === Doc.docData.yksus);
            }

            if (yksus.teenused) {
                let teenus = yksus.teenused.find(obj => obj.nomid == inputValue);

                Doc.docData.kogus = teenus.kogus ? teenus.kogus : Doc.docData.kogus;
                Doc.docData.hind = teenus.hind ? teenus.hind : Doc.docData.hind;
                // подменим номид на ид, так как ид виртуальный
                Doc.docData.nomid = teenus.nomid ? teenus.nomid : Doc.docData.nomid;

                // если это создание карточки, то добавим inf3
                let is_new = (!('id' in Doc.docData) || !Doc.docData.id) ? true : false;

                if (is_new) {
                    const row = Doc.libs['nomenclature'].find(lib => lib.id === Number(Doc.docData.nomid));
                    if (row && row.hasOwnProperty('kas_inf3')) {
                        Doc.docData.kas_inf3 = row.kas_inf3;
                    }
                }

            }


        }

    }

    // обработчик события клик на гриде родителей
    handleGridBtnClick(btnName, activeRow, id, docTypeId) {
        switch (btnName) {
            case "edit":
                this.props.history.push(`/lapsed/${docTypeId}/${id}`);
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

    btnEditLapseGruppClick() {
        let docLapseGruppKood = this.refs['document'].docData.yksus;
        // ищем ид

        let lapseGruppId = this.refs['document'].libs['lapse_grupp'].find(row => row.kood === docLapseGruppKood).id;

        if (lapseGruppId) {
            // осуществит переход на карточку контр-агента
            this.props.history.push(`/lapsed/lapse_grupp/${lapseGruppId}`);
        }

    }


    //обработчик события по клику кнопки Редактирование ребенка
    btnEditLapsClick() {
        let docLapsId = this.refs['document'].docData.parentid;

        // осуществит переход на карточку контр-агента
        this.props.history.push({
            pathname: `/lapsed/laps/${docLapsId}`,
            state: {teenusId: this.state.docId, module: this.state.module}
        });


    }


}

LapseKaart.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

LapseKaart.defaultProps = {
    params: {docId: 0},
    initData: {},
    userData: {}
};


module.exports = (LapseKaart);