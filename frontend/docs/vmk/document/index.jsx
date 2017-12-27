const VmkDocument = require('./../vmk.jsx');
const React = require('react');
const {withRouter} = require('react-router-dom');

class Doc extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            docId: Number(props.match.params.docId)
        }
    }

    render() {
        return <div>
            <VmkDocument docId = {this.state.docId} userData = {{}}/>
        </div>

    }
}

module.exports = withRouter(Doc);