'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const styles = require('./nomenclature-register-styles');

/**
 * Класс реализует документ справочника признаков.
 */
class Nomenclatures extends React.PureComponent {
    constructor(props) {
        super(props);

    }

    render() {
        return <Documents initData={this.props.initData} userData={this.props.userData}
                          docTypeId='NOMENCLATURE'
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return <div>NOMENCLATURE register special render</div>
    }
}


module.exports = Nomenclatures;


