'use strict';
const React = require('react');
const PropTypes = require('prop-types');

const DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    Loading = require('./../../../components/loading/index.jsx');

const styles = require('./tunnus-styles');

/**
 * Класс реализует документ справочника признаков.
 */
class Tunnus extends React.PureComponent {
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
                              docTypeId='TUNNUS'
                              module={this.props.module}
                              initData={this.props.initData}
                              userData={this.props.userData}
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
            // не загружены данные
            return (<div style={styles.doc}>
                <Loading label={'Laadimine...'}/>
            </div>);
        }

        return (
            <div style={styles.doc}>
                <div style={styles.docColumn}>
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
                        <InputDate title='Kehtiv kuni:'
                                   name='valid'
                                   value={self.docData.valid}
                                   ref='input-valid'
                                   readOnly={!self.state.edited}
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

Tunnus.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object
};

Tunnus.defaultProps = {
    initData: {},
};


module.exports = (Tunnus);
