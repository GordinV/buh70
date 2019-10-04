'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const styles = require('./nomenclature-register-styles');
const DOC_TYPE_ID = 'nomenclature';

/**
 * Класс реализует документ справочника признаков.
 */
class Nomenclatures extends React.PureComponent {
    constructor(props) {
        super(props);
    }

    render() {
        return <Documents initData={this.props.initData}
                          history = {this.props.history ? this.props.history: null}
                          ref = 'register'
                          module={this.props.module}
                          docTypeId={DOC_TYPE_ID}
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return <div>NOMENCLATURE register special render</div>
    }

}

module.exports = (Nomenclatures);


