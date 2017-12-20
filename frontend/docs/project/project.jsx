'use strict';

const PropTypes = require('prop-types');

const React = require('react');

const
    DocumentTemplate = require('./../documentTemplate/index.jsx'),
    InputText = require('../../components/input-text/input-text.jsx'),
    TextArea = require('../../components/text-area/text-area.jsx'),
    styles = require('./project-styles');

class Project extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            loadedData: false
        };
        this.renderer = this.renderer.bind(this);

        this.requiredFields = [
            {
                name: 'kood',
                type: 'C'
            },
            {name: 'nimetus', type: 'C'}
        ];
    }

    render() {
        return <DocumentTemplate docId = {this.props.docId }
                                 ref = 'document'
                                 docTypeId='PROJECT'
                                 requiredFields = {this.requiredFields}
                                 userData = {this.props.userData}
                                 initData = {this.props.initData}
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
        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <InputText title="Kood "
                               name='kood'
                               ref="input-kood"
                               readOnly = {!self.state.edited}
                               value={self.docData.kood}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                    <InputText title="Nimetus "
                               name='nimetus'
                               ref="input-nimetus"
                               readOnly = {!self.state.edited}
                               value={self.docData.nimetus}
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


Project.propTypes = {
    docId: PropTypes.number.isRequired,
    initData: PropTypes.object,
    userData: PropTypes.object
};

module.exports = Project;


