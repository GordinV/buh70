'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const styles = require('./arv-register-styles');
const DOC_TYPE_ID = 'ARV';

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
    }

    render() {
        return <DocumentRegister initData={this.props.initData}
                                 userData={this.props.userData}
                                 history = {this.props.history ? this.props.history: null}
                                 ref = 'register'
                                 docTypeId={DOC_TYPE_ID}
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer() {
        return <div>Arve register special render</div>
    }
}


module.exports = (Documents);


