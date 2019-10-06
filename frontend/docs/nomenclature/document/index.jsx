'use strict';
const React = require('react');
const PropTypes = require('prop-types');

const
    DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    Select = require('../../../components/select/select.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    styles = require('./nomenclature-styles'),
    LIBRARIES = ['kontod', 'tunnus', 'project', 'document'];


const DOKUMENTS = [
        {id: 1, kood: 'ARV', name: 'Arved'}
    ],
    CURRENCIES = [{id: 1, kood: 'EUR', name: 'EUR'}],
    TAXIES = [
        {id: 1, kood: null, name: '-%'},
        {id: 2, kood: '0', name: '0%'},
        {id: 3, kood: '5', name: '5%'},
        {id: 4, kood: '10', name: '10%'},
        {id: 5, kood: '18', name: '18%'},
        {id: 6, kood: '20', name: '20%'}
    ];

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
                                 initData={this.props.initData}
                                 libs={LIBRARIES}
                                 renderer={this.renderer}/>
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
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputText title="Nimetus "
                                       name='nimetus'
                                       ref="input-nimetus"
                                       value={self.docData.nimetus}
                                       onChange={self.handleInputChange}/>
                        </div>
                    </div>

                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <Select title="Dokument:"
                                    name='dok'
                                    data={self.libs['document']}
                                    value={self.docData.dok || ''}
                                    ref="select-dok"
                                    collId="kood"
                                    btnDelete={isEditeMode}
                                    onChange={self.handleInputChange}
                                    readOnly={!isEditeMode}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
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
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputNumber title="Hind: "
                                         name='hind'
                                         ref="input-hind"
                                         value={Number(self.docData.hind || null)}
                                         readOnly={!isEditeMode}
                                         onChange={self.handleInputChange}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <Select title="Konto (Meie teenused)"
                                    name='konto_db'
                                    libs="kontod"
                                    data={self.libs['kontod']}
                                    readOnly={!isEditeMode}
                                    value={self.docData['konto_db'] || ''}
                                    ref='select_konto_db'
                                    collId="kood"
                                    onChange={self.handleInputChange}/>
                        </div>
                        <div style={styles.docColumn}>
                            <Select title="Konto (Ostetud teenused)"
                                    name='konto_kr'
                                    libs="kontod"
                                    data={self.libs['kontod']}
                                    readOnly={!isEditeMode}
                                    value={self.docData.konto_kr || ''}
                                    ref='select_konto_kr'
                                    collId="kood"
                                    onChange={self.handleInputChange}/>
                        </div>
                    </div>
                    <div style={styles.docRow}>
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