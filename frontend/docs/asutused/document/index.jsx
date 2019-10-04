'use strict';
const React = require('react');
const PropTypes = require('prop-types');

const
    DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    styles = require('./asutused.styles');


class Asutused extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            docId: props.docId ? props.docId: Number(props.match.params.docId),
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
        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId='ASUTUSED'
                                 requiredFields={this.requiredFields}
                                 initData={this.props.initData}
                                 renderer={this.renderer}/>
    }

    renderer(self) {

        let isEditeMode = self.state.edited;

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <InputText title="Reg.kood "
                               name='regkood'
                               ref="input-regkood"
                               readOnly={!isEditeMode}
                               value={self.docData.regkood || ''}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                    <InputText title="Nimetus "
                               name='nimetus'
                               ref="input-nimetus"
                               readOnly={!isEditeMode}
                               value={self.docData.nimetus || ''}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                    <InputText title="Om.vorm"
                               name='omvorm'
                               ref="input-omvorm"
                               readOnly={!isEditeMode}
                               value={self.docData.omvorm || ''}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                                <TextArea title="Aadress"
                                          name='aadress'
                                          ref="textarea-aadress"
                                          onChange={self.handleInputChange}
                                          value={self.docData.aadress || ''}
                                          readOnly={!isEditeMode}/>
                </div>
                <div style={styles.docRow}>
                                <TextArea title="Kontakt"
                                          name='kontakt'
                                          ref="textarea-kontakt"
                                          onChange={self.handleInputChange}
                                          value={self.docData.kontakt || ''}
                                          readOnly={!isEditeMode}/>
                </div>
                <div style={styles.docRow}>
                    <InputText title="Telefon"
                               name='tel'
                               ref="input-tel"
                               value={self.docData.tel || ''}
                               readOnly={!isEditeMode}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                    <InputText title="Email"
                               name='email'
                               ref="input-email"
                               value={self.docData.email || ''}
                               readOnly={!isEditeMode}
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
                <div style={styles.docRow}>
                                <TextArea title="Märkused"
                                          name='mark'
                                          ref="textarea-mark"
                                          onChange={self.handleInputChange}
                                          value={self.docData.mark || ''}
                                          readOnly={!isEditeMode}/>
                </div>
            </div>
        );
    }

}

Asutused.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object
};

Asutused.defaultProps = {
    initData:{},
    userData:{}
};

module.exports = (Asutused);
