'use strict';

const PropTypes = require('prop-types');

const React = require('react');


const
    DocumentTemplate = require('./../documentTemplate/index.jsx'),
    InputText = require('../../components/input-text/input-text.jsx'),
    Select = require('../../components/select/select.jsx'),
    TextArea = require('../../components/text-area/text-area.jsx'),
    InputNumber = require('../../components/input-number/input-number.jsx'),
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
            loadedData: false
        };


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

        this.renderer = this.renderer.bind(this);
    }

    render() {
        return <DocumentTemplate docId={this.props.docId}
                                 ref='document'
                                 docTypeId='NOMENCLATURE'
                                 requiredFields={this.requiredFields}
                                 userData={this.props.userData}
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
                        <InputText title="Kood "
                                   name='kood'
                                   ref="input-kood"
                                   value={self.docData.kood}
                                   onChange={self.handleInputChange}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputText title="Nimetus "
                                   name='nimetus'
                                   ref="input-nimetus"
                                   value={self.docData.nimetus}
                                   onChange={self.handleInputChange}/>
                    </div>

                    <div style={styles.docRow}>
                        <Select title="Dokument:"
                                name='dok'
                                data={self.libs['document']}
                                value={self.docData.dok || ''}
                                ref="select-dok"
                                btnDelete={isEditeMode}
                                onChange={self.handleInputChange}
                                readOnly={!isEditeMode}/>
                    </div>
                    <div style={styles.docRow}>
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

                    <div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <InputNumber title="Hind: "
                                         name='hind'
                                         ref="input-hind"
                                         value={Number(self.docData.hind || 0)}
                                         onChange={this.handleInputChange}/>
                        </div>
                        <div style={styles.docColumn}>
                            <div style={styles.docRow}>
                                <Select title="Valuuta:"
                                        name='valuuta'
                                        data={CURRENCIES}
                                        collId='kood'
                                        value={self.docData.valuuta || 'EUR'}
                                        defaultValue={self.docData.valuuta}
                                        ref="select-valuuta"
                                        btnDelete={isEditeMode}
                                        onChange={self.handleInputChange}
                                        readOnly={!isEditeMode}/>
                                <InputNumber title="Kuurs: "
                                             name='kuurs'
                                             ref="input-kuurs"
                                             value={Number(self.docData.kuurs || 1)}
                                             onChange={self.handleInputChange}/>
                            </div>
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
                    <div style={styles.docRow}>
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
    docId: PropTypes.number.isRequired,
    initData: PropTypes.object,
    userData: PropTypes.object
};


module.exports = Nomenclature;



