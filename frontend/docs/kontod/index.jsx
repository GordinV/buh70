'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const styles = require('./kontod-register.styles');

/**
 * Класс реализует документ справочника признаков.
 */
class Kontod extends React.PureComponent {
    constructor(props) {
        super(props);

    }

    render() {
        return <Documents initData={this.props.initData} userData={this.props.userData}
                          docTypeId='KONTOD'
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return <div>Kontod register special render</div>
    }
}


module.exports = Kontod;


