'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const styles = require('./vmk-register-styles');
const DOCUMENT_TYPE = 'VMK';

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
        return <div>VMK register special render</div>
    }
}


module.exports = Documents;


