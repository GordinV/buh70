'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const styles = require('./asutus-register-styles');

/**
 * Класс реализует документ справочника признаков.
 */
class Asutused extends React.PureComponent {
    constructor(props) {
        super(props);

    }

    render() {
        return <Documents initData={this.props.initData} userData={this.props.userData}
                          docTypeId='ASUTUSED'
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return <div>ASUTUSED register special render</div>
    }
}


module.exports = Asutused;


