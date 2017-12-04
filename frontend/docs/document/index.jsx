'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const styles = require('./document-register-styles');

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);

    }

    render() {
        return <DocumentRegister initData={this.props.initData} userData={this.props.userData}
                          docTypeId='DOCUMENT'
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return <div>Document register special render</div>
    }
}


module.exports = Documents;


