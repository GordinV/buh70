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

const {LIBRARIES} = require('./../../../../config/constants').LAPSE_KAART;

class LapseKaart extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            module: 'lapsed',
            kas_soodustus: false
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
        if (!self || !self.docData || !self.state.loadedLibs) {
            // не загружены данные
            return (<div style={styles.doc}>
                <Loading label={'Laadimine...'}/>
            </div>);
        }

        // не успевает подгрузиться справочник, перегрузка формы
        if (!self.libs['nomenclature'].length) {
            setTimeout(() => {
                this.forceUpdate()
            }, 1);
        }


        let isEditMode = self.state.edited;

        if ((!Number(self.docData.id) || !self.docData.parentid) && this.state.lapsId) {
            //new record
            self.docData.parentid = this.state.lapsId;
        }

        let buttonEditNom = styles.btnEditNom;

        let yksus;
        let all_yksused = [{id: 0, nimetus: ''}];
        if (self.libs['lapse_grupp'] && self.docData.yksus) {
            yksus = self.libs['lapse_grupp'].find(yksus => yksus.kood === self.docData.yksus);

            all_yksused = (yksus && yksus.all_yksused ? yksus.all_yksused : []).map((item, index) => {
                return {id: index++, nimetus: item}
            });
        }

        let nomData = [];
        // берем только услуги для группы, добавляяем цену и ед.измерения и сортируем
        try {
            if (yksus) {
                if (DocContext.libs && yksus.id && DocContext.libs[yksus.id] && DocContext.libs[yksus.id].length) {
                    // берем из кеша
                    nomData = DocContext.libs[yksus.id];
                    // добавим пустую строку
/*
                    if (!nomData || nomData.length || !(nomData.find(({id}) => {
                        return id == 0;
                    }))) {
                        nomData.unshift({id: 0, kood: '', nimetus: '', hind: 0, kogus: 0, kas_inf3: false});
                    }
*/
                } else {
                    nomData = (yksus.teenused && self.libs['nomenclature'].length > 0 ? yksus.teenused : []).map(nom => {
                        const row = self.libs['nomenclature'].find(lib => {
                            return lib.id ? lib.id === Number(nom.nomid) : false
                        });

                        if (row && row.id) {
                            const teenuseNimetus = row.nimetus ? `${row.nimetus} (hind: ${Number(nom.hind).toFixed(2)}) ` : '';
                            return {...row, nimetus: teenuseNimetus, id: Number(nom.nomid)}
                        } else {
                            return {id: Number(nom.nomid), kood: 'Ei kehti', nimetus: 'Ei kehti', hind: 0, kogus: 0, kas_inf3: false};
                        }
                    }).sort((a, b) => {
                        return a.kood.localeCompare(b.kood)
                    });
                    setTimeout(1);

                    if (nomData.length && yksus.id) {
                        // сохраним в кеше
                        DocContext.libs[yksus.id] = nomData;

                        // на всякий, вызовем ре рендер страницы
                        this.forceUpdate();
                    }
                }
            } else {
                // фильтр на номенклатуры
                nomData = [{id: 0, kood: '', nimetus: '', hind: 0, kogus: 0, kas_inf3: false}];
            }


        } catch (e) {
            console.error(e, nomData);
        }

        // накладываем фильтр на справочник старых витенумберов на ребенка
        let viitenr = [{id: 0, kood: '', nimetus: '', laps_id: self.docData.parentid}];
        let defaultViitenr;

        if (self.libs['viitenr'] && self.libs['viitenr'].length && self.docData.parentid) {
            viitenr.push(...self.libs['viitenr'].filter(kaart => kaart.laps_id == self.docData.parentid));

            // считаем кол-во старых номеров
            let index = viitenr.length - 1;
            defaultViitenr = viitenr[index].kood;

            if (!self.docData.viitenr) {
                // если не задан старый витенумбер, то добавим последний из регистра
                self.docData.viitenr = defaultViitenr;
            }
        }

        // проверим стоит ли разрешить редактирование
        let isEditLapsid = !!self.docData.parentid;

        // если услуга имеет тип - льгота, то отметим это
        let kas_naida_soodustus = true;
        if (self && self.docData && nomData && nomData.length && self.docData.nomid) {
            let teenus = nomData.find(row => {
                return row.id === self.docData.nomid && row.tyyp === 'SOODUSTUS'
            });
            if (teenus) {
                kas_naida_soodustus = false;
            }
            setTimeout(1);
        }

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
                        <Select title="Vana viitenumber:"
                                name='viitenr'
                                libs="viitenr"
                                data={viitenr}
                                value={self.docData.viitenr || ''}
                                defaultValue={self.docData.viitenr || ''}
                                ref="select-viitenr"
                                collId={'kood'}
                                btnDelete={isEditMode}
                                onChange={self.handleInputChange}
                                readOnly={!isEditMode}
                        />
                    </div>

                </div>

                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <Select title={"Kood" + (self.docData.kas_umberarvestus ? '(Ümberarvestus)' : '') + ":"}
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
{/*
// А. Варгунин 28.04.2023
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
*/}
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputNumber ref="input-hind"
                                     title='Hind:'
                                     name='hind'
                                     value={self.docData.hind}
                                     readOnly={!isEditMode}
                                     onChange={self.handleInputChange}/>
                    </div>
                    <div style={styles.docColumn}>
                        <InputNumber ref="input-kogus"
                                     title='Kogus:'
                                     name='kogus'
                                     value={(self.docData.kogus) || ''}
                                     readOnly={!isEditMode}
                                     onChange={self.handleInputChange}/>
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
                                value={Number(self.docData.ettemaksu_period) || ''}
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

                    </div>
                    {kas_naida_soodustus ?
                        < div style={styles.docColumn}>
                            < InputNumber
                                ref="input-soodus"
                                title='Soodustus:'
                                name='soodus'
                                value={Number(self.docData.soodus) || ''}
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
                        </div> : null}

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