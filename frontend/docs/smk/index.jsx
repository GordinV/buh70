'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const styles = require('./smk-register-styles');
const DOCUMENT_TYPE = 'SMK';

/**
 * Класс реализует документ приходного платежного ордера.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);

    }

    render() {
        return <DocumentRegister initData={this.props.initData} userData={this.props.userData}
                                 docTypeId={DOCUMENT_TYPE}
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer() {
        return <div>SMK register special render</div>
    }
}


module.exports = Documents;


