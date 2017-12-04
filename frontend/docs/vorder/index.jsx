'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const styles = require('./vorder-register-styles');

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);

    }

    render() {
        return <DocumentRegister initData={this.props.initData} userData={this.props.userData}
                                 docTypeId='VORDER'
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer() {
        return <div>Vorder register special render</div>
    }
}


module.exports = Documents;


