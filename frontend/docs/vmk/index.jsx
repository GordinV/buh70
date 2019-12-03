'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const styles = require('./vmk-register-styles');
const DOC_TYPE_ID = 'VMK';

/**
 * Класс реализует документ приходного платежного ордера.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
    }

    render() {
        return <DocumentRegister initData={this.props.initData}
                                 ref = 'register'
                                 history = {this.props.history ? this.props.history: null}
                                 docTypeId={DOC_TYPE_ID}
                                 module={this.props.module}
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer() {
        return <div>VMK register special render</div>
    }

}

module.exports = (Documents);


