'use strict';
const React = require('react');
const PropTypes = require('prop-types');

const DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    CheckBox = require('../../../components/input-checkbox/input-checkbox.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    styles = require('./styles');

/**
 * Класс реализует документ справочника признаков.
 */
class ArveteSaatmine extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            loadedData: false
        };
        this.renderer = this.renderer.bind(this);
    }

    render() {
        return (
            <DocumentTemplate docId={this.state.docId}
                              ref='document'
                              docTypeId='ARVETE_SAATMINE'
                              module={this.props.module}
                              initData={this.props.initData}
                              renderer={this.renderer}
                              focusElement={'input-kood'}
                              history={this.props.history}

            />
        )
    }

    /**
     * Метод вернет кастомный компонент
     * @param self
     * @returns {*}
     */
    renderer(self) {
        if (!self.docData) {
            return null;
        }
        let eelmiseAlusStatus = false;
        if (self.docData.id) {
            // запомним прежний статус . Если отправка начата, то статус менять более нельзя
            eelmiseAlusStatus = Boolean(self.docData.eelmise_alus_status);
        }

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputDate title="Alg. kuupäev"
                                   name='alg_kpv'
                                   ref="input-alg_kpv"
                                   readOnly={!self.state.edited}
                                   value={self.docData.alg_kpv || ''}
                                   onChange={self.handleInputChange}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputDate title="Lõpp kuupäev"
                                   name='lopp_kpv'
                                   ref="input-lopp_kpv"
                                   readOnly={!self.state.edited}
                                   value={self.docData.lopp_kpv || ''}
                                   onChange={self.handleInputChange}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <CheckBox title="Kas alusta arvete saatmine ?:"
                                  name='kas_alusta'
                                  value={Boolean(self.docData.kas_alusta)}
                                  ref={'checkbox_kas_alusta'}
                                  onChange={self.handleInputChange}
                                  readOnly={eelmiseAlusStatus ? eelmiseAlusStatus: !self.state.edited}
                        />
                    </div>
                    {Boolean(self.docData.kas_alusta) ?
                        <div style={styles.docColumn}>
                            <label style={styles.label}>Saatmine algab: {self.docData.saatmine_alustatakse} </label>
                            <label style={styles.label}>Vastav kasutaja: {self.docData.al_ametnik ? self.docData.al_ametnik : self.docData.kasutaja} </label>

                        </div>
                         : null}
                </div>
                {/*Строка с паузой актуальна только, при начатой отправке */}
                {Boolean(self.docData.kas_alusta) ?
                    (<div style={styles.docRow}>
                        <div style={styles.docColumn}>
                            <CheckBox title="Paus arvete saatmine:"
                                      name='paus'
                                      value={Boolean(self.docData.paus)}
                                      ref={'checkbox_paus'}
                                      onChange={self.handleInputChange}
                                      readOnly={eelmiseAlusStatus && !self.state.edited}
                            />
                        </div>
                        {Boolean(self.docData.paus) ?
                            (<div style={styles.docColumn}>
                                <label style={styles.label}>Vastav kasutaja: {self.docData.p_ametnik ? self.docData.p_ametnik : self.docData.kasutaja} </label>
                                <label style={styles.label}>Paus alates: {self.docData.paus_timestamp} </label>
                        </div>): null }
                    </div>) : null}

                <div style={styles.docRow}>
                    <TextArea title="Muud"
                              name='muud'
                              ref="textarea-muud"
                              onChange={self.handleInputChange}
                              value={self.docData.muud || ''}
                              readOnly={!self.state.edited}/>
                </div>
            </div>
        );
    }

}

ArveteSaatmine.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object
};

ArveteSaatmine.defaultProps = {
    initData: {},
};


module.exports = (ArveteSaatmine);
