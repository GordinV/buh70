'use strict';
const React = require('react');
const PropTypes = require('prop-types');

const
    DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    Select = require('../../../components/select/select.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    CheckBox = require('../../../components/input-checkbox/input-checkbox.jsx'),
    styles = require('./nomenclature-styles');

const {LIBRARIES, TAXIES, UHIK, TYYP} = require('./../../../../config/constants').NOMENCLATURE;


class Nomenclature extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            loadedData: false
        };
        this.renderer = this.renderer.bind(this);
    }

    render() {
        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='NOMENCLATURE'
                                 module={this.props.module}
                                 initData={this.props.initData}
                                 history={this.props.history}
                                 userData={this.props.userData}
                                 libs={LIBRARIES}
                                 renderer={this.renderer}
                                 focusElement={'input-kood'}
        />
    }

    /**
     * Метод вернет кастомный компонент
     * @param self инстенс базавого документа
     * @returns {*}
     */
    renderer(self) {
        if (!self.docData) {
            return null;
        }

        let isEditeMode = self.state.edited;

        return (
            <div>
                <div style={styles.doc}>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputText title="Kood "
                                       name='kood'
                                       ref="input-kood"
                                       value={self.docData.kood}
                                       onChange={self.handleInputChange}/>
                            <InputText title="Nimetus "
                                       name='nimetus'
                                       ref="input-nimetus"
                                       value={self.docData.nimetus}
                                       onChange={self.handleInputChange}/>
                            <InputText title="Lühike nimetus "
                                       name='luno'
                                       ref="input-luno"
                                       value={self.docData.luno || ''}
                                       onChange={self.handleInputChange}/>
                            <Select title="Dokument:"
                                    name='dok'
                                    data={self.libs['document']}
                                    value={self.docData.dok || ''}
                                    ref="select-dok"
                                    collId="kood"
                                    btnDelete={isEditeMode}
                                    onChange={self.handleInputChange}
                                    readOnly={!isEditeMode}/>
                            <Select title="Maksumäär:"
                                    name='vat'
                                    data={TAXIES}
                                    collId='kood'
                                    value={self.docData.vat || ''}
                                    defaultValue={self.docData.vat}
                                    ref="select-vat"
                                    btnDelete={isEditeMode}
                                    onChange={self.handleInputChange}
                                    readOnly={!isEditeMode}/>
                            <InputNumber title="Hind: "
                                         name='hind'
                                         ref="input-hind"
                                         value={Number(self.docData.hind || null)}
                                         readOnly={!isEditeMode}
                                         onChange={self.handleInputChange}/>
                            <Select title="Mõttühik:"
                                    name='uhik'
                                    data={UHIK}
                                    collId='kood'
                                    value={self.docData.uhik || ''}
                                    defaultValue={self.docData.uhik}
                                    ref="select-uhik"
                                    btnDelete={isEditeMode}
                                    onChange={self.handleInputChange}
                                    readOnly={!isEditeMode}/>
                            <Select title="Koolituse liigid:"
                                    name='oppe_tyyp'
                                    data={self.libs['koolituse_liik']}
                                    collId='kood'
                                    value={self.docData.oppe_tyyp || ''}
                                    defaultValue={self.docData.oppe_tyyp}
                                    ref="select-oppe_tyyp"
                                    btnDelete={isEditeMode}
                                    onChange={self.handleInputChange}
                                    readOnly={!isEditeMode}/>
                            <Select title="Tüüp:"
                                    name='tyyp'
                                    data={TYYP}
                                    collId='kood'
                                    value={self.docData.tyyp || ''}
                                    defaultValue={self.docData.tyyp}
                                    ref="select-tyyp"
                                    btnDelete={isEditeMode}
                                    onChange={self.handleInputChange}
                                    readOnly={!isEditeMode}/>

                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <Select title="Korr.konto:"
                                    name='konto'
                                    libs="kontod"
                                    data={self.libs['kontod']}
                                    readOnly={!isEditeMode}
                                    value={self.docData['konto'] || ''}
                                    ref='select_konto'
                                    collId="kood"
                                    onChange={self.handleInputChange}/>
                        </div>
                        <div style={styles.docColumn}>
                            <Select title="Tunnus:"
                                    name='tunnus'
                                    libs="tunnus"
                                    data={self.libs['tunnus']}
                                    readOnly={!isEditeMode}
                                    value={self.docData['tunnus'] || ''}
                                    ref='select_tunnus'
                                    collId="kood"
                                    onChange={self.handleInputChange}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <Select title="Tegevus:"
                                    name='tegev'
                                    data={self.libs['tegev']}
                                    value={self.docData['tegev'] || ''}
                                    ref='tegev'
                                    readOnly={!isEditeMode}
                                    collId="kood"
                                    onChange={self.handleInputChange}/>
                        </div>
                        <div style={styles.docColumn}>
                            <Select title="Projekt:"
                                    name='projekt'
                                    libs="project"
                                    data={self.libs['project']}
                                    readOnly={!isEditeMode}
                                    value={self.docData['projekt'] || ''}
                                    ref='select_projekt'
                                    collId="kood"
                                    onChange={self.handleInputChange}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <Select title="Allikas:"
                                    name='allikas'
                                    data={self.libs['allikas']}
                                    value={self.docData['allikas'] || ''}
                                    ref='allikas'
                                    readOnly={!isEditeMode}
                                    collId="kood"
                                    onChange={self.handleInputChange}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <Select title="Artikkel:"
                                    name='artikkel'
                                    data={self.libs['artikkel']}
                                    value={self.docData['artikkel'] || ''}
                                    ref='artikkel'
                                    readOnly={!isEditeMode}
                                    collId="kood"
                                    onChange={self.handleInputChange}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <CheckBox title="Kas INF3?"
                                      name='kas_inf3'
                                      value={Boolean(self.docData.kas_inf3)}
                                      ref={'checkbox_kas_inf3'}
                                      onChange={self.handleInputChange}
                                      readOnly={!isEditeMode}
                            />
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputDate title='Kehtiv kuni:'
                                       name='valid'
                                       value={self.docData.valid}
                                       ref='input-valid'
                                       readOnly={!isEditeMode}
                                       onChange={self.handleInputChange}/>

                        </div>
                    </div>

                    <div style={styles.docRow}>
                        <TextArea title="Muud"
                                  name='muud'
                                  ref="textarea-muud"
                                  onChange={self.handleInputChange}
                                  value={self.docData.muud || ''}
                                  readOnly={!isEditeMode}/>
                    </div>
                </div>
            </div>
        );
    }

}

Nomenclature.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object
};

Nomenclature.defaultProps = {
    initData: {},
    userData: {}
};


module.exports = (Nomenclature);