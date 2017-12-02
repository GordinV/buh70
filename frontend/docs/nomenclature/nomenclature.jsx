'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    flux = require('fluxify');

const
    Form = require('../../components/form/form.jsx'),
    InputText = require('../../components/input-text/input-text.jsx'),
    Select = require('../../components/select/select.jsx'),
    TextArea = require('../../components/text-area/text-area.jsx'),
    InputNumber = require('../../components/input-number/input-number.jsx'),
    ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx'),
    MenuToolBar = require('./../../mixin/menuToolBar.jsx'),
    DocToolBar = require('./../../components/doc-toolbar/doc-toolbar.jsx'),
    validateForm = require('../../mixin/validateForm'),
    styles = require('./nomenclature-styles'),
    LIBRARIES = ['kontod', 'tunnus', 'project'];


// Create a store
const docStore = require('../../stores/doc_store.js');

const DOKUMENTS = [
        {id: 1, kood: 'ARV', name: 'Arved'}
    ],
    CURRENCIES = [{id: 1, kood: 'EUR', name: 'EUR'}],
    TAXIES = [
        {id: 1, kood: null, name: '-%'},
        {id: 2, kood: 0, name: '0%'},
        {id: 3, kood: 5, name: '5%'},
        {id: 4, kood: 10, name: '10%'},
        {id: 5, kood: 18, name: '18%'},
        {id: 6, kood: 20, name: '20%'}
    ];

class Nomenclature extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            edited: this.props.data.row.id == 0,
            warning: ''
        };

        this.docData = props.data.row;

        this.libs = this.createLibs();

        this.requiredFields = [
            {
                name: 'kood',
                type: 'C',
                min: null,
                max: null
            },
            {name: 'nimetus', type: 'C', min: null, max: null},
            {name: 'regkood', type: 'C', min: null, max: null}
        ];
        this.handleToolbarEvents = this.handleToolbarEvents.bind(this);
        this.validation = this.validation.bind(this);
        this.handleInputChange = this.handleInputChange.bind(this);
    }

    validation() {
        if (!this.state.edited) return '';

        let requiredFields = this.requiredFields;
        return require('../../mixin/validateForm')(this, requiredFields);
    }

    /**
     * пишем исходные данные в хранилище, регистрируем обработчики событий
     */
    componentDidMount() {

        let self = this,
            data = this.docData;

        window.addEventListener('beforeunload', this.componentCleanup);

        // сохраняем данные в хранилище
        flux.doAction('dataChange', data);

        // если новый документ (id == 0)

        if (data.id == 0) {
            flux.doAction('editedChange', true);
            flux.doAction('savedChange', false);
        }

        // отслеживаем режим редактирования
        docStore.on('change:edited', function (newValue, previousValue) {
            if (newValue !== previousValue) {
                self.setState({edited: newValue});
            }
        });

        // грузим справочники
        LIBRARIES.forEach(lib => {
            flux.doAction("loadLibs", lib);
        });

        docStore.on('change:libs', (newValue, previousValue) => {
            let isChanged = false,
                libsData = this.libs;

            if (newValue.length > 0) {

                newValue.forEach(lib => {
                    if (lib.id === 'dokProps') {
                        // оставим только данные этого документа

                    }
                    if (this.libs[lib.id] && lib.data.length > 0) {
                        libsData[lib.id] = lib.data;
                        isChanged = true;
                    }
                });
            }

            if (isChanged) {
                self.libs = libsData;
                self.forceUpdate();
            }
        });
    }

    /**
     * снимет все подписки
     */
    componentCleanup() {
        docStore.off('change:edited');
        docStore.off('change:libs');
    }

    render() {
        let isEditeMode = this.state.edited,
            validationMessage = this.validation();

        const btnParams = {
            btnStart: {
                show: true
            }
        };

        return (
            <div>
                {MenuToolBar(btnParams, this.props.userData)}

                <Form pages={this.pages}
                      ref="form"
                      handlePageClick={this.handlePageClick}
                      disabled={isEditeMode}>
                    <ToolbarContainer ref='toolbar-container'>
                        <div className='doc-toolbar-warning'>
                            {validationMessage ? <span>{validationMessage}</span> : null }
                        </div>
                        <div>
                            <DocToolBar ref='doc-toolbar'
                                        edited={isEditeMode}
                                        validator={this.validation}
                                        eventHandler={this.handleToolbarEvents}/>
                        </div>
                    </ToolbarContainer>
                    <div style={styles.doc}>
                        <div style={styles.docRow}>
                            <InputText title="Kood "
                                       name='kood'
                                       ref="input-kood"
                                       value={this.docData.kood}
                                       onChange={this.handleInputChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <InputText title="Nimetus "
                                       name='nimetus'
                                       ref="input-nimetus"
                                       value={this.docData.nimetus}
                                       onChange={this.handleInputChange}/>
                        </div>

                        <div style={styles.docRow}>
                            <Select title="Dokument:"
                                    name='dok'
                                    data={DOKUMENTS}
                                    value={this.docData.dok || ''}
                                    defaultValue={this.docData.dok}
                                    ref="select-dok"
                                    btnDelete={isEditeMode}
                                    onChange={this.handleInputChange}
                                    readOnly={!isEditeMode}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Maksumäär:"
                                    name='vat'
                                    data={TAXIES}
                                    collId='kood'
                                    value={this.docData.vat || ''}
                                    defaultValue={this.docData.vat}
                                    ref="select-vat"
                                    btnDelete={isEditeMode}
                                    onChange={this.handleInputChange}
                                    readOnly={!isEditeMode}/>
                        </div>

                        <div style={styles.docRow}>
                            <div style={styles.docColumn}>
                                <InputNumber title="Hind: "
                                             name='hind'
                                             ref="input-hind"
                                             value={Number(this.docData.hind)}
                                             onChange={this.handleInputChange}/>
                            </div>
                            <div style={styles.docColumn}>
                                <div style={styles.docRow}>
                                    <Select title="Valuuta:"
                                            name='valuuta'
                                            data={CURRENCIES}
                                            collId='kood'
                                            value={this.docData.valuuta || 'EUR'}
                                            defaultValue={this.docData.valuuta}
                                            ref="select-valuuta"
                                            btnDelete={isEditeMode}
                                            onChange={this.handleInputChange}
                                            readOnly={!isEditeMode}/>
                                    <InputNumber title="Kuurs: "
                                                 name='kuurs'
                                                 ref="input-kuurs"
                                                 value={Number(this.docData.kuurs) || 1}
                                                 onChange={this.handleInputChange}/>
                                </div>
                            </div>
                        </div>
                        <div style={styles.docRow}>
                            <div style={styles.docColumn}>
                                <Select title="Konto (Meie teenused)"
                                        name='konto_db'
                                        libs="kontod"
                                        data={this.libs['kontod']}
                                        readOnly={!isEditeMode}
                                        value={this.docData['konto_db'] || ''}
                                        ref='select_konto_db'
                                        collId="kood"
                                        onChange={this.handleInputChange}/>
                            </div>
                            <div style={styles.docColumn}>
                                <Select title="Konto (Ostetud teenused)"
                                        name='konto_kr'
                                        libs="kontod"
                                        data={this.libs['kontod']}
                                        readOnly={!isEditeMode}
                                        value={this.docData.konto_kr || ''}
                                        ref='select_konto_kr'
                                        collId="kood"
                                        onChange={this.handleInputChange}/>
                            </div>
                        </div>
                        <div style={styles.docRow}>

                            <Select title="Projekt:"
                                    name='projekt'
                                    libs="project"
                                    data={this.libs['project']}
                                    readOnly={!isEditeMode}
                                    value={this.docData['projekt'] || ''}
                                    ref='select_projekt'
                                    collId="kood"
                                    onChange={this.handleInputChange}/>
                        </div>
                        <div style={styles.docRow}>
                            <Select title="Tunnus:"
                                    name='tunnus'
                                    libs="tunnus"
                                    data={this.libs['tunnus']}
                                    readOnly={!isEditeMode}
                                    value={this.docData['tunnus'] || ''}
                                    ref='select_tunnus'
                                    collId="kood"
                                    onChange={this.handleInputChange}/>
                        </div>
                        <div style={styles.docRow}>
                                <TextArea title="Muud"
                                          name='muud'
                                          ref="textarea-muud"
                                          onChange={this.handleInputChange}
                                          value={this.docData.muud || ''}
                                          readOnly={!isEditeMode}/>
                        </div>
                    </div>
                </Form >
            </div>
        );
    }

    /**
     * Обработчик для панели сохранения
     * @param event
     */
    handleToolbarEvents(event) {
        // toolbar event handler

        switch (event) {
            case 'CANCEL':
                this.docData = JSON.parse(flux.stores.docStore.backup.docData); // восстановим данные

                if (this.state.warning !== '') {
                    this.setState({warning: ''});
                } else {
                    this.forceUpdate();
                }
                break;
            default:
                console.error('handleToolbarEvents, no event handler for ', event);
        }
    }

    /**
     * Обработчик для инпутов.
     * @param inputName
     * @param inputValue
     * @returns {boolean}
     */
    handleInputChange(inputName, inputValue) {
        // обработчик изменений
        // изменения допустимы только в режиме редактирования
        if (!this.state.edited) {
            console.error('not in edite mode');
            return false;
        }

        this.docData[inputName] = inputValue;
        this.forceUpdate();
    }


    /**
     * вернет объект библиотек документа
     * @returns {{}}
     */
    createLibs() {
        let libs = {};
        LIBRARIES.forEach((lib) => {
            libs[lib] = [];
        })
        return libs;
    }
}

Nomenclature.propTypes = {
    data: PropTypes.object.isRequired,
    edited: PropTypes.bool,
    showMessageBox: PropTypes.string,
    checked: PropTypes.bool,
    warning: PropTypes.string

};


module.exports = Nomenclature;


