'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const styles = require('./sorder-register-styles');

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);

    }

    render() {
        return <DocumentRegister initData={this.props.initData} userData={this.props.userData}
                                 docTypeId='SORDER'
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer() {
        return <div>Sorder register special render</div>
    }
}


module.exports = Documents;


