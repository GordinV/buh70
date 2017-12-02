
const PropTypes = require('prop-types');

const React = require('react'),
    flux = require('fluxify'),
    InputText = require('./../input-text/input-text.jsx'),
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
                            <InputText ref="created"
                                       title='Created'
                                       name='created'
                                       value={this.props.data.created}
                                       disabled={true}
                                       width="75%"/>
                            <InputText ref="lastupdate"
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
    onChangeHandler(inputName, inputValue) {
        // обработчик изменений
        let data = flux.stores.docStore.data;
        data[inputName] = inputValue;
        // задать новое значение поля
        flux.doAction('dataChange', data);
    }
*/
}

DocCommon.propTypes = {
    readOnly: PropTypes.bool,
    data: PropTypes.object.isRequired
}

DocCommon.defaultProps = {
    readOnly: true
}

module.exports = DocCommon;