'use strict';
const React = require('react');
const {withRouter} = require('react-router-dom');
const PropTypes = require('prop-types');

const
    DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    Select = require('../../../components/select/select.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    styles = require('./kontod-styles');


const KONTO_TYYP = [
    {id: 1, kood: "SD", name: "SD"},
    {id: 2, kood: "SK", name: "SK"},
    {id: 3, kood: "D", name: "D"},
    {id: 4, kood: "K", name: "K"}
];

class Kontod extends React.PureComponent {
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
        return <DocumentTemplate docId = {this.state.docId }
                                 ref = 'document'
                                 docTypeId='KONTOD'
                                 requiredFields = {this.requiredFields}
                                 userData = {this.props.userData}
                                 initData = {this.props.initData}
                                 renderer={this.renderer}/>
    }

    renderer(self) {

        if (!self.docData) {
            return null;
        }

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <InputText title="Kood "
                               name='kood'
                               ref="input-kood"
                               readOnly={!self.state.edited}
                               value={self.docData.kood || ''}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                    <InputText title="Nimetus "
                               name='nimetus'
                               ref="input-nimetus"
                               readOnly={!self.state.edited}
                               value={self.docData.nimetus || ''}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                    <Select title="Konto tüüp"
                            name='tyyp'
                            data={KONTO_TYYP}
                            value={self.docData.tyyp || 0}
                            defaultValue={self.docData.konto_tyyp}
                            ref="select-tyyp"
                            btnDelete={self.state.edited}
                            onChange={self.handleInputChange}
                            readOnly={!self.state.edited}/>
                </div>
                <div style={styles.docRow}>
                    <InputDate title='Kehtiv kuni:'
                               name='valid'
                               value={self.docData.valid || ''}
                               ref='input-valid'
                               readOnly={!self.state.edited}
                               onChange={self.handleInputChange}/>
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

Kontod.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object
};

Kontod.defaultProps = {
    initData:{},
    userData:{}
};
module.exports = withRouter(Kontod);