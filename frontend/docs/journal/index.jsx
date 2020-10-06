'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const styles = require('./journal-register-styles');

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
    }

    render() {
        return <DocumentRegister initData={this.props.initData}
                                 ref = 'register'
                                 history = {this.props.history ? this.props.history: null}
                                 docTypeId='JOURNAL'
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer() {
        return null
    }

}

module.exports = (Documents);


