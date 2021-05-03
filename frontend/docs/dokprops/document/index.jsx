'use strict';

const React = require('react');
const PropTypes = require('prop-types');

const
    DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    Select = require('../../../components/select/select.jsx'),
    styles = require('./styles');
const  LIBRARIES = [{id: 'kontod', filter: ''}];

class Project extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            loadedData: false,
            docTypeId:  this.props.history.location.state ? this.props.history.location.state.docPropId: ''
    };
        this.renderer = this.renderer.bind(this);

    }

    render() {
        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 history={this.props.history}
                                 libs={LIBRARIES}
                                 docTypeId='DOKPROPS'
                                 initData={this.props.initData}
                                 renderer={this.renderer}/>
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
        if (!self.docData.dok && this.props.history) {
            self.docData.dok = this.props.history.location.state.dokPropId;
        }

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title="Dokument "
                                   name='dok'
                                   ref="input-dok"
                                   readOnly={true}
                                   value={self.docData.dok}
                        />

                        <Select title="Korr. konto: "
                                name='konto'
                                libs="kontod"
                                data={self.libs['kontod']}
                                value={self.docData['konto'] || ''}
                                readOnly={!self.state.edited}
                                ref='select_konto'
                                collId="kood"
                                onChange={self.handleInputChange}/>

                        <Select title="KBM.konto: "
                                name='kbmkonto'
                                libs="kontod"
                                data={self.libs['kontod']}
                                value={self.docData.kbmkonto}
                                readOnly={!self.state.edited}
                                ref='kbmkonto'
                                collId="kood"
                                onChange={self.handleInputChange}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <TextArea title="Selgitus"
                              name='selg'
                              ref="textarea-selg"
                              onChange={self.handleInputChange}
                              value={self.docData.selg || ''}
                              readOnly={!self.state.edited}/>
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

Project.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object
};

Project.defaultProps = {
    initData: {},
    userData: {}
};
module.exports = (Project);