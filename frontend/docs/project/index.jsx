'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const styles = require('./project-register-styles');

/**
 * Класс реализует документ справочника признаков.
 */
class Project extends React.PureComponent {
    constructor(props) {
        super(props);

    }

    render() {
        return <Documents initData={this.props.initData} userData={this.props.userData}
                          docTypeId='PROJECT'
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return <div>Project register special render</div>
    }
}


module.exports = Project;


