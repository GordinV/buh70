'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const styles = require('./tunnused-styles');

/**
 * Класс реализует документ справочника признаков.
 */
class Tunnused extends React.PureComponent {
    constructor(props) {
        super(props);

    }

    render() {
        return <Documents initData={this.props.initData} userData={this.props.userData}
                          docTypeId='TUNNUS'
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return <div>Tunnused register special render</div>
    }
}


module.exports = Tunnused;


