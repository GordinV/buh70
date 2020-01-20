'use strict';
const React = require('react');
const PropTypes = require('prop-types');

const DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),

    styles = require('./styles');

/**
 * Класс реализует документ справочника признаков.
 */
class Config extends React.PureComponent {
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
                              docTypeId='CONFIG'
                              history={this.props.history}
                              module={this.props.module}
                              initData={this.props.initData}
                              renderer={this.renderer}
                              focusElement={'input-number'}
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
                        <InputText title="Prefiks: "
                                   name='number'
                                   ref="input-number"
                                   readOnly={!self.state.edited}
                                   value={self.docData.number || ''}
                                   onChange={self.handleInputChange}/>
                        <InputText title="Arvete tahtpäev "
                                   name='tahtpaev'
                                   ref="input-tahtpaev"
                                   readOnly={!self.state.edited}
                                   value={self.docData.tahtpaev || ''}
                                   onChange={self.handleInputChange}/>
                        <InputNumber title="Arve võlgnevuse limiit: "
                                     name='limiit'
                                     ref="input-limiit"
                                     readOnly={!self.state.edited}
                                     value={self.docData.limiit || 0}
                                     onChange={self.handleInputChange}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <TextArea title="Omniva e-arvete server"
                              name='earved'
                              ref="textarea-earved"
                              onChange={self.handleInputChange}
                              value={self.docData.earved || ''}
                              readOnly={!self.state.edited}/>
                </div>

            </div>);
    }

}

Config.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object
};

Config.defaultProps = {
    initData: {},
};


module.exports = (Config);
