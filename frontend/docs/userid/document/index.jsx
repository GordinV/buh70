'use strict';
const React = require('react');
const PropTypes = require('prop-types');

const DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
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
