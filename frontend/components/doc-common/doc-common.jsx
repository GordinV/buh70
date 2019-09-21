
const PropTypes = require('prop-types');

const React = require('react'),
    InputText = require('./../input-text/input-text.jsx'),
    InputDate = require('../input-datetime/index.jsx'),

    styles = require('./doc-common-styles');

class DocCommon extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            readOnly: props.readOnly
        }
    }

    render() {
        return (
            <div ref='wrapper' style = {styles.wrapper}>
                            <InputText ref="id"
                                       title='Id'
                                       name='id'
                                       value={String(this.props.data.id)}
                                       disabled={true}
                                       width="75%"/>
                            <InputDate ref="created"
                                       title='Created'
                                       name='created'
                                       value={this.props.data.created}
                                       disabled={true}
                                       width="75%"/>
                            <InputDate ref="lastupdate"
                                       title='Updated'
                                       name='lastupdate'
                                       value={this.props.data.lastupdate}
                                       disabled={true}
                                       width="75%"/>
                            <InputText ref="status"
                                       title='Status'
                                       name='status'
                                       value={this.props.data.status}
                                       disabled={true}
                                       width="75%"/>
            </div>
        );
    }

/*
    componentWillReceiveProps(nextProps) {
        this.forceUpdate();
    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
            return {nextProps};
    }
*/



}

DocCommon.propTypes = {
    readOnly: PropTypes.bool,
    data: PropTypes.object.isRequired
};

DocCommon.defaultProps = {
    readOnly: true,
    data: []
};

module.exports = DocCommon;