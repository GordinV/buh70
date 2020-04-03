'use strict';
const React = require('react');
const PropTypes = require('prop-types');

const DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    CheckBox = require('../../../components/input-checkbox/input-checkbox.jsx'),
    styles = require('./styles');

/**
 * Класс реализует документ справочника признаков.
 */
class User extends React.PureComponent {
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
                              docTypeId='USERID'
                              module={this.props.module}
                              initData={this.props.initData}
                              renderer={this.renderer}
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
        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title="Kasutaja tunnus:  "
                                   name='kasutaja'
                                   ref="input-kasutaja"
                                   readOnly={true}
                                   value={self.docData.kasutaja || ''}
                                   onChange={self.handleInputChange}/>
                        <InputText title="Nimi: "
                                   name='ametnik'
                                   ref="input-ametnik"
                                   readOnly={!self.state.edited}
                                   value={self.docData.ametnik || ''}
                                   onChange={self.handleInputChange}/>
                        <InputText title="Email: "
                                   name='email'
                                   ref="input-email"
                                   readOnly={!self.state.edited}
                                   value={self.docData.email || ''}
                                   onChange={self.handleInputChange}/>
                        <InputText title="Smtp: "
                                   name='smtp'
                                   ref="input-smtp"
                                   readOnly={!self.state.edited}
                                   value={self.docData.smtp || ''}
                                   onChange={self.handleInputChange}/>
                        <InputText title="Port: "
                                   name='port'
                                   ref="input-port"
                                   readOnly={!self.state.edited}
                                   value={self.docData.port || ''}
                                   onChange={self.handleInputChange}/>
                        <InputText title="Email kasutaja: "
                                   name='user'
                                   ref="input-user"
                                   readOnly={!self.state.edited}
                                   value={self.docData.user || ''}
                                   onChange={self.handleInputChange}/>
                        <InputText title="Email parool: "
                                   name='pass'
                                   ref="input-pass"
                                   readOnly={!self.state.edited}
                                   value={self.docData.pass || ''}
                                   onChange={self.handleInputChange}/>
                        <CheckBox title="Kas raamatupidaja?"
                                  name='is_kasutaja'
                                  value={Boolean(self.docData.is_kasutaja)}
                                  ref={'checkbox_is_kasutaja'}
                                  onChange={self.handleInputChange}
                                  readOnly={true}
                        />
                        <CheckBox title="Kas peakasutaja?"
                                  name='is_peakasutaja'
                                  value={Boolean(self.docData.is_peakasutaja)}
                                  ref={'checkbox_is_peakasutaja'}
                                  onChange={self.handleInputChange}
                                  readOnly={true}
                        />
                        <CheckBox title="Kas administraator?"
                                  name='is_admin'
                                  value={Boolean(self.docData.is_admin)}
                                  ref={'checkbox_is_admin'}
                                  onChange={self.handleInputChange}
                                  readOnly={true}
                        />
                        <CheckBox title="Kas vaatleja?"
                                  name='is_vaatleja'
                                  value={Boolean(self.docData.is_vaatleja)}
                                  ref={'checkbox_is_vaatleja'}
                                  onChange={self.handleInputChange}
                                  readOnly={true}
                        />
                        <CheckBox title="Kas laste arvestaja?"
                                  name='is_arvestaja'
                                  value={Boolean(self.docData.is_arvestaja)}
                                  ref={'checkbox_is_arvestaja'}
                                  onChange={self.handleInputChange}
                                  readOnly={true}
                        />
                        <CheckBox title="Kas eelarve taotluse koostaja?"
                                  name='is_eel_koostaja'
                                  value={Boolean(self.docData.is_eel_koostaja)}
                                  ref={'checkbox_is_eel_koostaja'}
                                  onChange={self.handleInputChange}
                                  readOnly={true}
                        />
                        <CheckBox title="Kas eelarve taotluse allkriastaja?"
                                  name='is_eel_allkirjastaja'
                                  value={Boolean(self.docData.is_eel_allkirjastaja)}
                                  ref={'checkbox_is_eel_allkirjastaja'}
                                  onChange={self.handleInputChange}
                                  readOnly={true}
                        />
                        <CheckBox title="Kas eelarve taotluse esitaja?"
                                  name='is_eel_esitaja'
                                  value={Boolean(self.docData.is_eel_esitaja)}
                                  ref={'checkbox_is_eel_esitaja'}
                                  onChange={self.handleInputChange}
                                  readOnly={true}
                        />
                        <CheckBox title="Kas asutuste korraldaja?"
                                  name='is_asutuste_korraldaja'
                                  value={Boolean(self.docData.is_asutuste_korraldaja)}
                                  ref={'checkbox_is_asutuste_korraldaja'}
                                  onChange={self.handleInputChange}
                                  readOnly={true}
                        />
                        <CheckBox title="Kas rekl.maksu administraator?"
                                  name='is_rekl_administrator'
                                  value={Boolean(self.docData.is_rekl_administrator)}
                                  ref={'checkbox_is_rekl_administrator'}
                                  onChange={self.handleInputChange}
                                  readOnly={true}
                        />
                        <CheckBox title="Kas rekl.maksu haldur?"
                                  name='is_rekl_maksuhaldur'
                                  value={Boolean(self.docData.is_rekl_maksuhaldur)}
                                  ref={'checkbox_is_rekl_maksuhaldur'}
                                  onChange={self.handleInputChange}
                                  readOnly={true}
                        />
                        <CheckBox title="Kas ladu kasutaja?"
                                  name='is_ladu_kasutaja'
                                  value={Boolean(self.docData.is_ladu_kasutaja)}
                                  ref={'checkbox_is_ladu_kasutaja'}
                                  onChange={self.handleInputChange}
                                  readOnly={true}
                        />
                    </div>
                </div>

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

User.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object
};

User.defaultProps = {
    initData: {},
};


module.exports = (User);
