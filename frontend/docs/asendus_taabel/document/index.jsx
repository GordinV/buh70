'use strict';

const PropTypes = require('prop-types');
const React = require('react');


const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    ButtonEdit = require('../../../components/button-register/button-register-edit/button-register-edit.jsx'),
    Select = require('../../../components/select/select.jsx'),
    SelectData = require('../../../components/select-data/select-data.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    CheckBox = require('../../../components/input-checkbox/input-checkbox.jsx'),
    Loading = require('./../../../components/loading/index.jsx'),
    styles = require('./styles');

const DocContext = require('../../../doc-context');
const LIBRARIES = require('./../../../../config/constants').ASENDUS_TAABEL.LIBRARIES;

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
        this.handleInput = this.handleInput.bind(this);


        this.pages = [
            {pageName: 'Lapse asendus taabel', docTypeId: 'ASENDUS_TAABEL'}
        ];
        this.nomData = [];
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
        let initData = this.props.initData ? this.props.initData : {};

        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='ASENDUS_TAABEL'
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
        if (!self || !self.docData || !self.docData.loaded_data || !self.libs['nomenclature'].length || !self.libs['lapse_grupp'].length) {
            // не загружены данные
            return (<div style={styles.doc}>
                <Loading label={'Laadimine...'}/>
            </div>);
        }

        if (self.docData.yksusid) {
            this.handleInput('yksusid', self.docData.yksusid, true);
        }

        console.log('self.docData', self.docData);
        if (!this.nomData.length) {
            //массив номенклатур не задан, весь справочник
            this.nomData = self.libs['nomenclature'];

        }

        try {
            let isEditMode = self.state.edited;

            let kpv = new Date(),
                kuu = kpv.getMonth(),
                aasta = kpv.getFullYear();

            return (
                <div style={styles.doc}>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputText title="Lapse viitenumber:"
                                       name='viitenumber'
                                       value={self.docData.viitenumber || ''}
                                       ref="input-viitenumber"
                                       onChange={this.handleInput}
                                       readOnly={!isEditMode}/>
                        </div>
                        <div style={styles.docColumn}>
                            <label>
                                {`${self.docData.nimi ? self.docData.nimi + ',' + self.docData.asutus : 'Puudub'}`}
                            </label>
                        </div>

                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <Select title="Üksus:"
                                    name='yksusid'
                                    libs="lapse_grupp"
                                    data={self.libs['lapse_grupp']}
                                    value={self.docData.yksusid || 0}
                                    defaultValue={self.docData.yksys || ''}
                                    ref="select-lapse_grupp"
                                    collId={'id'}
                                    btnDelete={isEditMode}
                                    onChange={this.handleInput}
                                    readOnly={!isEditMode}
                            />
                        </div>
                    </div>

                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <Select title="Kood:"
                                    name='nomid'
                                    libs="nomenclature"
                                    data={this.nomData}
                                    value={Number(self.docData.nomid) || 0}
                                    defaultValue={self.docData.kood || ''}
                                    ref='nomid'
                                    collId={'id'}
                                    placeholder='Teenuse kood'
                                    onChange={this.handleInput}
                                    readOnly={!isEditMode}/>
                        </div>
                    </div>

                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputNumber ref="input-kogus"
                                         title='Kogus:'
                                         name='kogus'
                                         value={(self.docData.kogus) || ''}
                                         readOnly={!isEditMode}
                                         onChange={this.handleInput}/>

                            <InputNumber ref="input-hind"
                                         title='Hind:'
                                         name='hind'
                                         value={(self.docData.hind) || ''}
                                         readOnly={true}/>

                            <InputNumber ref="input-summa"
                                         title='Summa:'
                                         name='summa'
                                         value={self.docData.summa || ''}
                                         readOnly={true}/>

                            <InputNumber ref="input-kuu"
                                         title='Kuu:'
                                         name='kuu'
                                         value={(self.docData.kuu) || Number(kuu)}
                                         readOnly={!isEditMode}
                                         onChange={self.handleInputChange}/>

                            <InputNumber ref="input-aasta"
                                         title='Aasta:'
                                         name='aasta'
                                         value={(self.docData.aasta) || Number(aasta)}
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
        } catch (e) {
            console.error('page error ', e);
            return (<div> Andmed ei ole laadidud, proovi uuesti</div>)

        }
    }


    handlePageClick(pageDocTypeId) {
//        document.location.href = `/lapsed/${pageDocTypeId}/`;//@todo Обновить
        this.props.history.push(`/lapsed/${pageDocTypeId}`)
    }


    /**
     * Локальны обработчик изменений
     * @param inputName
     * @param inputValue
     * @param notReload
     */
    handleInput(inputName, inputValue, notReload) {
        const Doc = this.refs['document'];
        console.log('input change', inputName, inputValue);

        switch (inputName) {
            case 'yksusid': {
                let yksusId = inputValue;
                let yksus = Doc.libs['lapse_grupp'].find(yksus => {
                    return yksus.id == yksusId
                });
                let nomData = [];

                if (DocContext.libs && yksusId && DocContext.libs[yksusId] && DocContext.libs[yksusId].length) {
                    // берем из кеша
                    this.nomData = DocContext.libs[yksus.id];
                }
                // фильтруем , сотавим только услуги группы
                if (yksusId && yksus) {
                    nomData = (yksus.teenused && Doc.libs['nomenclature'].length > 0 ? yksus.teenused : []).map(nom => {
                        const row = Doc.libs['nomenclature'].find(lib => {
                            return lib.id ? lib.id === Number(nom.nomid) : false
                        });

                        if (row && row.id) {
                            const teenuseNimetus = row.nimetus ? `${row.nimetus} (hind: ${Number(nom.hind).toFixed(2)}) ` : '';
                            return {...row, nimetus: teenuseNimetus, id: Number(nom.nomid)}
                        } else {
                            return {
                                id: Number(nom.nomid),
                                kood: 'Ei kehti',
                                nimetus: 'Ei kehti',
                                hind: 0,
                                kogus: 0,
                                kas_inf3: false
                            };
                        }
                    }).sort((a, b) => {
                        return a.kood.localeCompare(b.kood)
                    });

                    if (nomData && nomData.length) {
                        // запомним в массиве
                        this.nomData = nomData;
                        DocContext.libs[yksusId] = nomData;
                    } else {
                        this.nomData = [];
                    }
                }
                break;
            }
            case 'nomid': {
                let nom = this.nomData.find(row => {
                    console.log('nom find', row, inputValue);
                    return row.id == inputValue
                });
                // нашли, правим цену и сумму
                if (nom && nom.id && nom.hind) {
                    Doc.docData.hind = Number(nom.hind);
                    Doc.docData.summa = Number(nom.hind) * Number(Doc.docData.kogus);
                }
                break;
            }
            case 'kogus': {
                // нашли, правим цену и сумму
                Doc.docData.summa = Number(Doc.docData.hind) * Number(inputValue);
                break;
            }

            case 'viitenumber': {
                if (inputValue.length == 10) {
                    // есть вн, делаем запрос
                    let api = `/newApi/task/getIsik`;

                    Doc.fetchData('Post', api, {
                        doc_id: 0,
                        seisuga: null,
                        kogus: 0,
                        viitenumber: inputValue
                    }).then((response) => {
                        if (response.data && response.data.error_code) {
                            Doc.setState({
                                warning: response.data.error_message,
                                warningType: 'error'
                            }, () => {
                                this.forceUpdate();
                            });

                        } else {
// обрабатываем результат
                            try {
                                Doc.docData.isikukood = response.data.data[0].isikukood;
                                Doc.docData.nimi = response.data.data[0].nimi;
                                Doc.docData.asutus = response.data.data[0].asutus;
                                Doc.docData.lapsId = response.data.data[0].id;
                                Doc.docData.parentid = response.data.data[0].id;

                                Doc.handleInputChange(inputName, inputValue);

                            } catch (e) {
                                console.error('Viga: ', response.data);
                            }
                        }
                    });
                } else {
                    // затираем ИК и имя
                    Doc.docData.isikukood = null;
                    Doc.docData.nimi = null;
                    Doc.docData.asutus = null;
                    Doc.docData.lapsId = null;
                    //Doc.handleInputChange(inputName, inputValue);
                }

                break;
            }
        }
        if (!notReload) {
            // прокинем изменения дальше
            Doc.handleInputChange(inputName, inputValue);
        }


    }

}

module.exports = (Laps);