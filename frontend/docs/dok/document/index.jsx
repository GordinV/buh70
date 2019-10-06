'use strict';

const PropTypes = require('prop-types');
const React = require('react');

const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    Select = require('../../../components/select/select.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    styles = require('./document-styles'),
    DOCUMENT_TYPES = [{id: 1, kood: 'document', name: 'document'}, {id: 2, kood: 'library', name: 'library'}];


/**
 * Реализует документ справочника Типы документов
 */
class Document extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            docId: props.docId ? props.docId: Number(props.match.params.docId),
            loadedData: false
        };
        this.renderer = this.renderer.bind(this);
    }

    render() {
        return <DocumentTemplate docId = {this.state.docId }
                                 ref = 'document'
                                 docTypeId='DOK'
                                 initData = {this.props.initData}
                                 renderer={this.renderer}/>
    }

    renderer(self) {
        if (!self.docData) {
            return null;
        }

        return (
            <div>
                <div style={styles.doc}>
                    <div style={styles.docRow}>
                        <InputText title="Kood "
                                   name='kood'
                                   ref="input-kood"
                                   value={self.docData.kood}
                                   readOnly={!self.state.edited}
                                   onChange={self.handleInputChange}/>
                    </div>
                    <div style={styles.docRow}>
                        <InputText title="Nimetus "
                                   name='nimetus'
                                   ref="input-nimetus"
                                   value={self.docData.nimetus}
                                   readOnly={!self.state.edited}
                                   onChange={self.handleInputChange}/>
                    </div>

                    <div style={styles.docRow}>
                        <Select title="Tüüp:"
                                name='type'
                                data={DOCUMENT_TYPES}
                                collId='kood'
                                value={self.docData.type}
                                defaultValue={self.docData.type}
                                ref="select-type"
                                btnDelete={!self.state.edited}
                                onChange={self.handleInputChange}
                                readOnly={!self.state.edited}/>
                    </div>
                    {/*
                         <div style={styles.docRow}>
                         <Select title="Moduul:"
                         name='module'
                         data={MODULES}
                         collId='kood'
                         value={this.state.docData.module}
                         defaultValue={this.state.docData.module}
                         ref="select-module"
                         btnDelete={isEditeMode}
                         onChange={this.handleInputChange}
                         readOnly={!isEditeMode}/>
                         </div>
                         */}
                    <div style={styles.docRow}>
                                <TextArea title="Muud"
                                          name='muud'
                                          ref="textarea-muud"
                                          onChange={self.handleInputChange}
                                          value={self.docData.muud || ''}
                                          readOnly={!self.state.edited}/>
                    </div>
                </div>
            </div>
        );
    }


}

Document.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object
};

Document.defaultProps = {
    initData:{},
    userData:{}
};

module.exports = (Document);


