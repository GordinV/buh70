'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const styles = require('./tunnused-styles');
const DOC_TYPE_ID = 'tunnus';

/**
 * Класс реализует документ справочника признаков.
 */
class Tunnused extends React.PureComponent {
    constructor(props) {
        super(props);
    }

    render() {
        return <Documents initData={this.props.initData}
                          userData={this.props.userData}
                          history={this.props.history ? this.props.history : null}
                          module={this.props.module}
                          ref='register'
                          docTypeId={DOC_TYPE_ID}
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return <div>Tunnused register special render</div>
    }
}


module.exports = (Tunnused);


